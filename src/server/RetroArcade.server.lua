-- Original 8-bit-inspired "Spiral Snake" arcade cabinet.
-- No ROMs/emulators or branded retro art. Server owns the board and scoring.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Retro=require(script.Parent:WaitForChild("RetroEngine"))
local Rewards=require(script.Parent:WaitForChild("WorldRewards"))
local event=ReplicatedStorage:FindFirstChild("YugatneoRetro") or Instance.new("RemoteEvent")
event.Name="YugatneoRetro"
event.Parent=ReplicatedStorage
local workspaceFolder=Instance.new("Folder")
workspaceFolder.Name="YUGATNEO_RETRO"
workspaceFolder.Parent=workspace
local center=Vector3.new(162,0,38)
local floor=Instance.new("Part")
floor.Name="RetroPlaza"
floor.Size=Vector3.new(56,1.5,68)
floor.Position=center+Vector3.new(0,-1.1,0)
floor.Anchored=true
floor.Material=Enum.Material.Metal
floor.Color=Color3.fromRGB(13,22,40)
floor.Parent=workspaceFolder
local cabinet=Instance.new("Part")
cabinet.Name="SnakeCabinet"
cabinet.Size=Vector3.new(12,9,5)
cabinet.Position=center+Vector3.new(0,4.5,0)
cabinet.Anchored=true
cabinet.Material=Enum.Material.Metal
cabinet.Color=Color3.fromRGB(27,79,92)
cabinet.Parent=workspaceFolder
local board=Instance.new("SurfaceGui")
board.Face=Enum.NormalId.Front
board.PixelsPerStud=45
board.Parent=cabinet
local title=Instance.new("TextLabel")
title.Size=UDim2.fromScale(1,1)
title.BackgroundTransparency=1
title.TextScaled=true
title.TextWrapped=true
title.Font=Enum.Font.Code
title.TextColor3=Color3.fromRGB(50,255,190)
title.Text="SPIRAL SNAKE\n8-BIT INSPIRED\nPRESS E"
title.Parent=board
local prompt=Instance.new("ProximityPrompt")
prompt.ActionText="Play Spiral Snake"
prompt.ObjectText="Original retro arcade"
prompt.HoldDuration=0.2
prompt.MaxActivationDistance=14
prompt.RequiresLineOfSight=false
prompt.Parent=cabinet
local games={}
local lastTurn={}
local random=Random.new()
local function near(p)
 if p:GetAttribute("InChessMatch") then return false end
 local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
 return root and (root.Position-cabinet.Position).Magnitude<=65
end
local function send(p,state,action)
 event:FireClient(p,action,{width=state.width,height=state.height,body=state.body,
  food=state.food,alive=state.alive,score=state.score,direction=state.direction})
end
local function begin(p)
 if not near(p) then return end
 local state=Retro.newSnake(random)
 games[p]=state
 send(p,state,"SnakeState")
end
prompt.Triggered:Connect(begin)
event.OnServerEvent:Connect(function(p,action,direction)
 if type(action)~="string" then return end
 if action=="StartSnake" then
  if not games[p] or not games[p].alive then begin(p) end
 elseif action=="StopSnake" then
  games[p]=nil
 elseif action=="TurnSnake" then
  if type(direction)~="string" or #direction>8 then return end
  local now=os.clock()
  if now-(lastTurn[p] or -100)<0.045 then return end
  lastTurn[p]=now
  local state=games[p]
  if state and state.alive and near(p) then Retro.turnSnake(state,direction) end
 end
end)
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt
 if elapsed<0.27 then return end
 elapsed=0
 for p,state in pairs(games) do
  if not p.Parent or not near(p) then
   games[p]=nil
   if p.Parent then event:FireClient(p,"SnakeExit") end
  else
   Retro.stepSnake(state,random)
   send(p,state,"SnakeState")
   if not state.alive then
    games[p]=nil
    local earned=math.clamp(math.floor(state.score/10)*2,0,30)
    if earned>0 then Rewards.award(p,earned,"snake high score") end
    event:FireClient(p,"SnakeEnd",{score=state.score,reward=earned})
   end
  end
 end
end)
Players.PlayerRemoving:Connect(function(p)games[p]=nil lastTurn[p]=nil end)
print("[YUGATNEO] Original 8-bit-style Spiral Snake arcade cabinet registered.")
