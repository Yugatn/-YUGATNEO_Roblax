-- Original arcade cabinet. Not a console emulator or third-party ROM loader.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Retro=require(script.Parent:WaitForChild("RetroEngine"))
local Rewards=require(script.Parent:WaitForChild("WorldRewards"))
local event=ReplicatedStorage:FindFirstChild("RetroCabinetEvent") or Instance.new("RemoteEvent")
event.Name="RetroCabinetEvent"
event.Parent=ReplicatedStorage
local world=Instance.new("Folder")
world.Name="YUGATNEO_RETRO_ARCADE"
world.Parent=workspace
local dark=Color3.fromRGB(7,18,37)
local cyan=Color3.fromRGB(28,246,209)
local floor=Instance.new("Part")
floor.Name="RetroPlatform"
floor.Size=Vector3.new(46,1.5,65)
floor.Position=Vector3.new(203,-0.9,34)
floor.Color=dark
floor.Material=Enum.Material.Metal
floor.Anchored=true
floor.Parent=world
local bridge=Instance.new("Part")
bridge.Name="RetroPath"
bridge.Size=Vector3.new(40,1.5,13)
bridge.Position=Vector3.new(163,-0.9,32)
bridge.Color=dark
bridge.Material=Enum.Material.Metal
bridge.Anchored=true
bridge.Parent=world
local cabinet=Instance.new("Part")
cabinet.Name="EightBitSnakeCabinet"
cabinet.Size=Vector3.new(9,11,5)
cabinet.Position=Vector3.new(201,5,25)
cabinet.Material=Enum.Material.SmoothPlastic
cabinet.Color=Color3.fromRGB(38,75,100)
cabinet.Anchored=true
cabinet.Parent=world
local surface=Instance.new("SurfaceGui")
surface.Face=Enum.NormalId.Front
surface.PixelsPerStud=35
surface.Parent=cabinet
local text=Instance.new("TextLabel")
text.Size=UDim2.fromScale(1,1)
text.BackgroundTransparency=1
text.Text="YUGATNEO RETRO\n8-BIT SNAKE\nPress E to play"
text.TextColor3=cyan
text.TextScaled=true
text.TextWrapped=true
text.Font=Enum.Font.Code
text.Parent=surface
local prompt=Instance.new("ProximityPrompt")
prompt.ActionText="Play 8-bit snake"
prompt.ObjectText="YUGATNEO original arcade"
prompt.HoldDuration=0.25
prompt.MaxActivationDistance=14
prompt.RequiresLineOfSight=false
prompt.Parent=cabinet
local future=Instance.new("Part")
future.Name="SixteenBitFighterPlaceholder"
future.Size=Vector3.new(9,11,5)
future.Position=Vector3.new(201,5,49)
future.Color=Color3.fromRGB(105,48,127)
future.Anchored=true
future.Parent=world
local futureGui=Instance.new("BillboardGui")
futureGui.Size=UDim2.fromOffset(260,70)
futureGui.StudsOffset=Vector3.new(0,7,0)
futureGui.AlwaysOnTop=true
futureGui.MaxDistance=200
futureGui.Parent=future
local futureLabel=Instance.new("TextLabel")
futureLabel.Size=UDim2.fromScale(1,1)
futureLabel.BackgroundTransparency=1
futureLabel.Text="16-BIT FIGHTER\nENGINE PROTOTYPE / NOT YET PLAYABLE"
futureLabel.TextColor3=cyan
futureLabel.TextScaled=true
futureLabel.TextWrapped=true
futureLabel.Parent=futureGui
local sessions={}
local lastInput={}
local roundSerial=0
local function near(player)
 if player:GetAttribute("InChessMatch") then return false end
 local char=player.Character
 local root=char and char:FindFirstChild("HumanoidRootPart")
 return root and (root.Position-cabinet.Position).Magnitude<24
end
local function payload(state)
 return {body=state.body,food=state.food,score=state.score,width=state.width,
   height=state.height,alive=state.alive}
end
prompt.Triggered:Connect(function(player)
 if not near(player) or sessions[player] then return end
 roundSerial+=1
 local id=roundSerial
 local state=Retro.newSnake(Random.new())
 sessions[player]={id=id,state=state}
 event:FireClient(player,"Start",payload(state))
 task.spawn(function()
  local random=Random.new(id+math.floor(os.clock()*1000))
  while sessions[player] and sessions[player].id==id and state.alive do
   task.wait(0.24)
   if sessions[player] and sessions[player].id==id and near(player) then
    Retro.stepSnake(state,random)
    event:FireClient(player,"State",payload(state))
   else
    break
   end
  end
  if sessions[player] and sessions[player].id==id then
   if state.score>=40 then Rewards.award(player,12,"retro arcade milestone","snake_milestone") end
   event:FireClient(player,"End",payload(state))
   sessions[player]=nil
  end
 end)
end)
event.OnServerEvent:Connect(function(player,action,direction)
 local now=os.clock()
 if now-(lastInput[player] or -100)<0.08 then return end
 lastInput[player]=now
 local session=sessions[player]
 if not session then return end
 if action=="Exit" then
  sessions[player]=nil
 elseif action=="Turn" and near(player) and type(direction)=="string" then
  Retro.turnSnake(session.state,direction)
 end
end)
Players.PlayerRemoving:Connect(function(player)
 sessions[player]=nil
 lastInput[player]=nil
end)
print("[YUGATNEO] Original 8-bit Snake arcade cabinet ready.")
