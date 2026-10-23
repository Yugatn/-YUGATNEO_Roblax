-- STORY X shared cooperative defense / zombie-tag overlays.
-- The client sends only actions. The server owns AI, damage, team roles and infection.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local defense=ReplicatedStorage:WaitForChild("StoryXDefenseEvent")
local tag=ReplicatedStorage:WaitForChild("StoryXTagEvent")
local gui=Instance.new("ScreenGui")
gui.Name="STORY_X_TEAM_HUD";gui.ResetOnSpawn=false;gui.DisplayOrder=48
gui.Parent=player:WaitForChild("PlayerGui")
local panel=Instance.new("Frame")
panel.AnchorPoint=Vector2.new(1,1)
panel.Position=UDim2.new(1,-18,1,-20)
panel.Size=UDim2.fromOffset(320,282)
panel.BackgroundColor3=Color3.fromRGB(9,23,38)
panel.BackgroundTransparency=0.05;panel.Visible=false
panel.Parent=gui
local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,12);c.Parent=panel
local scale=Instance.new("UIScale");scale.Parent=panel
local function label(y,height,size)
 local l=Instance.new("TextLabel")
 l.Position=UDim2.fromOffset(12,y);l.Size=UDim2.new(1,-24,0,height)
 l.BackgroundTransparency=1;l.TextColor3=Color3.fromRGB(215,250,241)
 l.TextSize=size;l.Font=Enum.Font.GothamBold
 l.TextWrapped=true;l.TextXAlignment=Enum.TextXAlignment.Left
 l.Parent=panel
 return l
end
local title=label(10,28,19)
local status=label(42,54,14)
local detail=label(104,61,13)
local tips=label(176,49,12)
local lastMode=nil
local function button(text,x,w,handler)
 local b=Instance.new("TextButton")
 b.Position=UDim2.fromOffset(x,232);b.Size=UDim2.fromOffset(w,37)
 b.BackgroundColor3=Color3.fromRGB(35,97,110)
 b.TextColor3=Color3.fromRGB(245,255,249)
 b.Font=Enum.Font.GothamBold;b.TextSize=13;b.Text=text
 b.Parent=panel
 local corner=Instance.new("UICorner")
 corner.CornerRadius=UDim.new(0,7);corner.Parent=b
 b.Activated:Connect(handler)
 return b
end
local action=button("START WAVES",12,133,function()
 if lastMode and lastMode~="ZOMBIE_TAG" then defense:FireServer("Start",lastMode) end
end)
local leave=button("EXIT",154,75,function()
 if lastMode=="ZOMBIE_TAG" then tag:FireServer("Leave")
 elseif lastMode then defense:FireServer("Exit",lastMode) end
 panel.Visible=false
end)
button("HIDE UI",237,71,function()panel.Visible=false end)
local function adapt()
 local camera=workspace.CurrentCamera
 if not camera then return end
 local v=camera.ViewportSize
 scale.Scale=math.clamp(math.min(v.X/365,v.Y/355),0.64,1)
end
adapt()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(adapt)
local function showDefense(s)
 lastMode=s.mode
 panel.Visible=true
 title.Text=s.mode=="METAL_SENTINELS" and "DEFENSE / METAL SENTINELS" or "DEFENSE / SHADOW SWARM"
 status.Text="Stage: "..s.phase.."  •  "..s.round.."/"..s.rounds..
  " waves  •  Core: "..math.max(0,s.core).." / 150"
 local me,roles=nil,{}
 for _,m in ipairs(s.roster or {}) do
  if m.id==player.UserId then me=m end
  table.insert(roles,m.name..": "..m.role)
 end
 detail.Text="My role: "..(me and me.role or "Spectator")..
  "  •  Charges: "..(me and me.ammo or 0).."\nEnemies: "..
  tostring(s.enemyCount or 0).."  •  Team: "..#roles
 tips.Text=(s.message and s.message~="" and s.message.."\n" or "")..
  "Click/tap robot targets to fire. Engineer repairs core; Support reloads at stations."
 action.Visible=s.phase=="Lobby"
end
defense.OnClientEvent:Connect(function(kind,details)
 if kind=="DefenseState" then showDefense(details)
 elseif kind=="DefenseExited" then panel.Visible=false;lastMode=nil end
end)
local function showTag(s)
 lastMode="ZOMBIE_TAG"
 panel.Visible=true
 title.Text="ZOMBIE TAG / НЯМ-НЯМ"
 status.Text="Stage: "..s.phase.."  •  "..s.infected..
  " catchers  •  "..s.survivors.." runners"
 local mins=math.floor((s.remaining or 0)/60)
 local secs=(s.remaining or 0)%60
 local currentRole="Waiting"
 for _,m in ipairs(s.players or {}) do
  if m.id==player.UserId then currentRole=m.role end
 end
 detail.Text="My role: "..currentRole..string.format("\nRemaining: %02d:%02d",mins,secs)
 tips.Text="Tag a runner for 3 continuous seconds nearby. No damage. Hide behind walls, in cars, in trees."
 if s.message and s.message~="" then tips.Text=s.message.."\n"..tips.Text end
 action.Visible=false
end
tag.OnClientEvent:Connect(function(kind,data)
 if kind=="TagState" then showTag(data)
 elseif kind=="TagProgress" then
  local secs=math.floor((data.seconds or 0)*10)/10
  status.Text="НЯМ-НЯМ... "..secs.."/3 seconds"
 elseif kind=="Tagged" then
  status.Text=(data and data.message) or "Ты теперь догоняющий!"
 end
end)
player.CharacterAdded:Connect(function()
 if not player:GetAttribute("StoryXTeamMode") then panel.Visible=false end
end)
