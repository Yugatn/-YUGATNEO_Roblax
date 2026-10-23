-- STORY X / LUMEN CIRCUIT: original neon trail bike dimension.
-- Server owns collision, result, all travel and all rewarded progression.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Engine=require(script.Parent:WaitForChild("LightCycleEngine"))
local Rewards=require(script.Parent:WaitForChild("WorldRewards"))
local event=ReplicatedStorage:FindFirstChild("LightCycleEvent") or Instance.new("RemoteEvent")
event.Name="LightCycleEvent"
event.Parent=ReplicatedStorage
local folder=Instance.new("Folder")
folder.Name="STORY_X_LUMEN_CIRCUIT"
folder.Parent=workspace
local origin=Vector3.new(1850,37,0)
local width,height,cell=34,22,5.2
local cyan=Color3.fromRGB(25,250,230)
local colors={
 Color3.fromRGB(25,235,240),Color3.fromRGB(255,142,35),
 Color3.fromRGB(202,82,250),Color3.fromRGB(65,255,104),
 Color3.fromRGB(255,68,137),Color3.fromRGB(240,230,72)
}
local function block(name,size,cf,color,collide,material,transparent,parent)
 local p=Instance.new("Part")
 p.Name=name;p.Size=size;p.CFrame=cf;p.Anchored=true;p.CanCollide=collide==true
 p.Color=color;p.Material=material or Enum.Material.Metal;p.Transparency=transparent or 0
 p.Parent=parent or folder
 return p
end
local function billboard(base,message)
 local ui=Instance.new("BillboardGui")
 ui.Size=UDim2.fromOffset(560,105);ui.StudsOffsetWorldSpace=Vector3.new(0,9,0)
 ui.AlwaysOnTop=true;ui.MaxDistance=500;ui.Parent=base
 local t=Instance.new("TextLabel")
 t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1
 t.TextColor3=cyan;t.TextStrokeTransparency=0.35;t.TextWrapped=true
 t.TextScaled=true;t.Font=Enum.Font.GothamBlack;t.Text=message;t.Parent=ui
end
local function gridWorld(x,y)
 return origin+Vector3.new((x-(width+1)/2)*cell,1.6,(y-(height+1)/2)*cell)
end
local floor=block("ArenaFloor",Vector3.new(width*cell+9,2,height*cell+9),
 CFrame.new(origin),Color3.fromRGB(8,18,33),true)
for i=0,width do
 block("LineX"..i,Vector3.new(0.13,0.2,height*cell),CFrame.new(
 origin+Vector3.new((i-width/2)*cell,1.13,0)),Color3.fromRGB(13,79,92),false,Enum.Material.Neon)
end
for j=0,height do
 block("LineY"..j,Vector3.new(width*cell,0.2,0.13),CFrame.new(
 origin+Vector3.new(0,1.13,(j-height/2)*cell)),Color3.fromRGB(13,79,92),false,Enum.Material.Neon)
end
local halfX=(width*cell)/2+5
local halfZ=(height*cell)/2+5
for _,x in ipairs({-halfX,halfX}) do
 block("WallX",Vector3.new(1.7,11,height*cell+10),
  CFrame.new(origin+Vector3.new(x,6,0)),Color3.fromRGB(13,128,153),true)
end
for _,z in ipairs({-halfZ,halfZ}) do
 block("WallZ",Vector3.new(width*cell+10,11,1.7),
  CFrame.new(origin+Vector3.new(0,6,z)),Color3.fromRGB(13,128,153),true)
end
local lobby=origin+Vector3.new(0,7,-halfZ-27)
block("SpectatorTerrace",Vector3.new(150,3,39),CFrame.new(lobby+Vector3.new(0,-1,0)),
 Color3.fromRGB(13,29,46),true)
billboard(block("LumenWelcome",Vector3.new(10,2,2),CFrame.new(lobby+Vector3.new(0,3,-13)),
 cyan,false,Enum.Material.Neon),"STORY X / LUMEN CIRCUIT\nSPACE • REACTION • STRATEGY")
local promptPart=block("JoinConsole",Vector3.new(7,4,4),CFrame.new(lobby+Vector3.new(-25,2,-8)),
 colors[1],true,Enum.Material.Neon)
billboard(promptPart,"ENTER RACE / TRAINING")
local leavePart=block("ReturnConsole",Vector3.new(7,4,4),CFrame.new(lobby+Vector3.new(26,2,-8)),
 colors[2],true,Enum.Material.Neon)
billboard(leavePart,"EXIT / MATRIX")
local function prompt(parent,action,label,fn)
 local p=Instance.new("ProximityPrompt")
 p.ActionText=action;p.ObjectText=label;p.HoldDuration=0.3
 p.MaxActivationDistance=12;p.RequiresLineOfSight=false;p.Parent=parent
 p.Triggered:Connect(fn)
 return p
end
local function characterRoot(p)
 local char=p.Character
 local humanoid=char and char:FindFirstChildOfClass("Humanoid")
 local root=char and char:FindFirstChild("HumanoidRootPart")
 if not root or not humanoid or humanoid.Health<=0 then return nil end
 return root
end
local function travel(p,pos)
 local root=characterRoot(p)
 if root then root.AssemblyLinearVelocity=Vector3.zero root.CFrame=CFrame.new(pos) end
end
-- Light-field entry console on a spiral turn, not a generic unexplained portal.
local step=82
local angle=math.pi+step*(math.pi*6/144)
local path=Vector3.new(500+120*math.cos(angle),4+step*0.68,120*math.sin(angle))
local tangent=Vector3.new(math.cos(angle),0,math.sin(angle)).Unit
local entry=path+tangent*23
block("SpiralLaserBridge",Vector3.new(16,1.5,32),
 CFrame.lookAt((path+entry)*0.5,entry),Color3.fromRGB(12,35,48),true)
block("SpiralLaserPlaza",Vector3.new(26,1.5,24),
 CFrame.new(entry),Color3.fromRGB(16,27,48),true)
local laser=block("LightFieldLaser",Vector3.new(2,9,2),
 CFrame.new(entry+Vector3.new(0,5,0)),cyan,false,Enum.Material.Neon)
billboard(laser,"ACTIVATE LIGHT FIELD\nLUMEN CIRCUIT")
local gate=block("LaserGate",Vector3.new(12,8,0.5),
 CFrame.new(entry+Vector3.new(0,5,-8)),cyan,false,Enum.Material.Neon,0.75)
prompt(laser,"Activate laser","Lumen Circuit",function(p)
 if p:GetAttribute("InChessMatch") then return end
 travel(p,lobby+Vector3.new(0,4,0))
 event:FireClient(p,"Entered",{})
end)
-- Six seated *control pods*. Rider vehicles are holographic projections onto the course.
-- This avoids fighting Roblox network-owned bike physics during authoritative turns.
local seats={}
for i=1,6 do
 local pos=lobby+Vector3.new(-48+(i-1)*19,2,8)
 block("ConsolePod_"..i,Vector3.new(9,1,10),CFrame.new(pos+Vector3.new(0,-1.4,0)),
  colors[i],true)
 local seat=Instance.new("Seat");seat.Name="RiderSeat_"..i
 seat.Size=Vector3.new(3,1.5,3);seat.CFrame=CFrame.new(pos)
 seat.Anchored=true;seat.Color=colors[i];seat.Parent=folder
 seats[i]=seat
end
local queue, queuedAt, active,visuals={},nil,nil,nil
local nextRound=0
local lastRemote={}
local function inQueue(uid)
 for _,id in ipairs(queue) do if id==uid then return true end end
 return false
end
local function removeQueue(uid)
 for i=#queue,1,-1 do if queue[i]==uid then table.remove(queue,i) end end
end
local function inArena(p)
 local root=characterRoot(p)
 return root and (root.Position-lobby).Magnitude<115
end
local function queueInfo()
 event:FireAllClients("Queue",{waiting=#queue,active=active~=nil})
end
local function createBike(uid,index,state)
 local m=Instance.new("Model");m.Name="Bike_"..uid;m.Parent=visuals
 local body=block("LightBike",Vector3.new(3.8,1.2,5),CFrame.new(0,0,0),
  colors[index],false,Enum.Material.Neon,0,m)
 local front=block("Nose",Vector3.new(2,0.7,1.5),
  CFrame.new(0,0.2,-2.5),Color3.fromRGB(235,245,255),
  false,Enum.Material.Neon,0,m)
 m.PrimaryPart=body
 return m
end
local function frameFor(x,y,dir)
 local p=gridWorld(x,y)+Vector3.new(0,1.4,0)
 local direction={Up=Vector3.new(0,0,-1),Down=Vector3.new(0,0,1),
  Left=Vector3.new(-1,0,0),Right=Vector3.new(1,0,0)}
 return CFrame.lookAt(p,p+direction[dir])
end
local function placeTrace(position,index)
 return block("LightTrace",Vector3.new(cell-0.35,2,cell-0.35),
  CFrame.new(position+Vector3.new(0,0.4,0)),colors[index],
  false,Enum.Material.Neon,0.12,visuals)
end
local function finishRound()
 if not active or not active.engine.over then return end
 local round=active
 local outcome=Engine.public(round.engine)
 event:FireAllClients("MatchEnd",outcome)
 for _,uid in ipairs(round.ids) do
  local p=Players:GetPlayerByUserId(uid)
  if p then
   Rewards.award(p,uid==outcome.winner and 20 or 5,
    "lumen race","lumen_"..round.id.."_"..uid)
   event:FireClient(p,"Released",{winner=outcome.winner})
  end
 end
 task.delay(7,function()
  if active~=round then return end
  if visuals then visuals:Destroy() visuals=nil end
  active=nil
  queuedAt=#queue>0 and os.clock() or nil
  queueInfo()
 end)
end
local function begin()
 if active or #queue==0 then return end
 local picked={}
 for i=1,math.min(6,#queue) do
  local uid=table.remove(queue,1)
  local p=Players:GetPlayerByUserId(uid)
  if p and inArena(p) then table.insert(picked,uid) end
 end
 if #picked==0 then queuedAt=#queue>0 and os.clock() or nil return end
 nextRound+=1
 local e=Engine.newMatch(picked,width,height)
 visuals=Instance.new("Folder")
 visuals.Name="LumenRound_"..nextRound
 visuals.Parent=folder
 local bikes={}
 for i,uid in ipairs(picked) do
  local rider=e.riders[uid]
  bikes[uid]={model=createBike(uid,i,rider),index=i}
  bikes[uid].model:PivotTo(frameFor(rider.x,rider.y,rider.direction))
  placeTrace(gridWorld(rider.x,rider.y),i)
 end
 active={id=nextRound,ids=picked,engine=e,bikes=bikes,started=os.clock(),ticks=0}
 queuedAt=#queue>0 and os.clock() or nil
 event:FireAllClients("MatchStart",{riders=Engine.public(e),participantIds=picked,
  tickSeconds=0.23,center={origin.X,origin.Y,origin.Z},cell=cell})
 queueInfo()
end
prompt(promptPart,"Join race","Light cycles",function(p)
 if not inArena(p) or inQueue(p.UserId) or active and active.engine.riders[p.UserId] then return end
 table.insert(queue,p.UserId)
 queuedAt=queuedAt or os.clock()
 event:FireClient(p,"Waiting",{position=#queue})
 queueInfo()
end)
prompt(leavePart,"Return to Matrix","Exit without penalty",function(p)
 removeQueue(p.UserId)
 -- A rider leaving forfeits; never freeze everybody else's round.
 if active and active.engine.riders[p.UserId] then
  active.engine.riders[p.UserId].alive=false
  local remains=0
  for _,r in pairs(active.engine.riders) do if r.alive then remains+=1 end end
  if remains<=1 and active.engine.count>1 then
   active.engine.over=true
   for uid,r in pairs(active.engine.riders) do if r.alive then active.engine.winner=uid end end
   finishRound()
  end
 end
 travel(p,Vector3.new(0,6,12))
 event:FireClient(p,"Exited",{})
 queueInfo()
end)

event.OnServerEvent:Connect(function(p,action,detail)
 if type(action)~="string" then return end
 local now=os.clock()
 if now-(lastRemote[p] or -100)<0.045 then return end
 lastRemote[p]=now
 if action=="Turn" then
  if not active or type(detail)~="string" or #detail>6 then return end
  if active.engine.riders[p.UserId] and inArena(p) then
   Engine.turn(active.engine,p.UserId,detail)
  end
 elseif action=="LeaveQueue" then
  removeQueue(p.UserId)
  event:FireClient(p,"Exited",{})
  queueInfo()
 elseif action=="GetStatus" then
  event:FireClient(p,"Queue",{waiting=#queue,active=active~=nil})
 elseif action=="Join" and inArena(p) then
  if not inQueue(p.UserId) and not(active and active.engine.riders[p.UserId]) then
   table.insert(queue,p.UserId)
   queuedAt=queuedAt or now
   event:FireClient(p,"Waiting",{position=#queue})
   queueInfo()
  end
 end
end)
local accumulator=0
RunService.Heartbeat:Connect(function(dt)
 accumulator+=dt
 if accumulator<0.23 then return end
 accumulator=0
 if not active then
  if #queue>0 and queuedAt and os.clock()-queuedAt>=8 then begin() end
  return
 end
 if active.engine.over then return end
 local updates=Engine.step(active.engine)
 for _,move in ipairs(updates) do
  local bike=active.bikes[move.id]
  if bike then
   if move.dead then bike.model:Destroy()
   else
    bike.model:PivotTo(frameFor(move.x,move.y,move.direction))
    placeTrace(gridWorld(move.x,move.y),bike.index)
   end
  end
 end
 event:FireAllClients("Tick",{tick=active.engine.roundTicks,updates=updates})
 if active.engine.over then finishRound() end
end)
Players.PlayerRemoving:Connect(function(p)
 removeQueue(p.UserId)
 lastRemote[p]=nil
 if active and active.engine.riders[p.UserId] then
  active.engine.riders[p.UserId].alive=false
  local survivors={}
  for uid,r in pairs(active.engine.riders) do if r.alive then table.insert(survivors,uid) end end
  if #survivors<=1 and active.engine.count>1 then
   active.engine.over=true
   active.engine.winner=survivors[1]
   finishRound()
  end
 end
 queueInfo()
end)
print("[YUGATNEO] Lumen Circuit built: laser gate, 6 bike pods, server trail race.")
