-- STORY X cooperative defense: two original, non-graphic robot/shadow dimensions.
-- Server owns roles, energy blasters, bot hit registration, barricade and rewards.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Rules=require(script.Parent:WaitForChild("DefenseRules"))
local Rewards=require(script.Parent:WaitForChild("WorldRewards"))
local event=ReplicatedStorage:FindFirstChild("StoryXDefenseEvent") or Instance.new("RemoteEvent")
event.Name="StoryXDefenseEvent";event.Parent=ReplicatedStorage
local folder=Instance.new("Folder");folder.Name="STORY_X_COOP_DEFENSE";folder.Parent=workspace
local arenas={}
local function block(parent,name,size,cf,color,collides,material)
 local p=Instance.new("Part")
 p.Name=name;p.Size=size;p.CFrame=cf;p.Anchored=true
 p.CanCollide=collides==true;p.Color=color;p.Material=material or Enum.Material.Metal
 p.Parent=parent;return p
end
local function banner(part,message)
 local gui=Instance.new("BillboardGui");gui.AlwaysOnTop=true
 gui.Size=UDim2.fromOffset(490,95);gui.StudsOffsetWorldSpace=Vector3.new(0,6,0)
 gui.MaxDistance=360;gui.Parent=part
 local l=Instance.new("TextLabel");l.Size=UDim2.fromScale(1,1)
 l.BackgroundTransparency=1;l.TextColor3=Color3.fromRGB(120,255,221)
 l.TextScaled=true;l.TextWrapped=true;l.Font=Enum.Font.GothamBlack;l.Text=message
 l.Parent=gui
end
local function makePrompt(p,caption,action,fn)
 local prompt=Instance.new("ProximityPrompt")
 prompt.ObjectText=caption;prompt.ActionText=action;prompt.HoldDuration=0.2
 prompt.MaxActivationDistance=12;prompt.RequiresLineOfSight=false
 prompt.Parent=p;prompt.Triggered:Connect(fn)
end
local function root(player)
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if not humanoid or humanoid.Health<=0 then return nil end
 return character:FindFirstChild("HumanoidRootPart")
end
local function transport(player,where)
 local r=root(player)
 if r then r.AssemblyLinearVelocity=Vector3.zero;r.CFrame=CFrame.new(where) end
end
local function inRange(player,where,limit)
 local r=root(player)
 return r~=nil and (r.Position-where).Magnitude<=limit
end
local function roster(a)
 local members={}
 for uid,member in pairs(a.members) do
  table.insert(members,{id=uid,name=member.name,role=member.role,ammo=member.ammo})
 end
 return members
end
local function update(a,message)
 local payload={mode=a.id,phase=a.phase,preset=a.preset,
  round=a.round,rounds=Rules.presets[a.preset].rounds,
  core=a.coreHealth,enemyCount=#a.enemies,roster=roster(a),message=message}
 for uid in pairs(a.members) do
  local p=Players:GetPlayerByUserId(uid)
  if p then event:FireClient(p,"DefenseState",payload) end
 end
end
local function removeFrom(a,uid)
 local member=a.members[uid]
 if not member then return end
 a.members[uid]=nil
 local p=Players:GetPlayerByUserId(uid)
 if p then p:SetAttribute("StoryXTeamMode",nil) end
end
local function finish(a,won)
 if a.phase~="Playing" then return end
 a.phase="Finished"
 for _,enemy in ipairs(a.enemies) do if enemy.model then enemy.model:Destroy() end end
 a.enemies={}
 if a.botFolder then a.botFolder:Destroy();a.botFolder=nil end
 for uid in pairs(a.members) do
  local player=Players:GetPlayerByUserId(uid)
  if player then
   local reward=won and 35 or math.min(22,3+a.round*2)
   Rewards.award(player,reward,"Story X co-op defense",a.id.."_"..a.edition.."_"..uid)
  end
 end
 update(a,won and "Команда защитила базу!" or "База повреждена. Можно попробовать снова.")
 task.delay(12,function()
  if a.phase~="Finished" then return end
  for uid in pairs(a.members) do
   local p=Players:GetPlayerByUserId(uid)
   if p then p:SetAttribute("StoryXTeamMode",nil);event:FireClient(p,"DefenseExited",{mode=a.id}) end
  end
  a.phase="Lobby";a.members={};a.coreHealth=150;a.round=0;a.edition+=1
  update(a)
 end)
end
local function createEnemy(a,i,round)
 local model=Instance.new("Model")
 model.Name=(a.kind=="Robots" and "MetalSentinel_" or "ShadowDummy_")..round.."_"..i
 model.Parent=a.botFolder
 local color=a.kind=="Robots" and Color3.fromRGB(200,130,85) or Color3.fromRGB(150,95,210)
 local body=block(model,"Target",Vector3.new(4,6,3),CFrame.new(a.origin),color,false,Enum.Material.Neon)
 local head=block(model,"Sensor",Vector3.new(2,2,2),
  CFrame.new(a.origin+Vector3.new(0,4,0)),Color3.fromRGB(245,221,102),false,Enum.Material.Neon)
 model.PrimaryPart=body
 local spawnAngle=i*2.399+round
 local spawnPos=a.origin+Vector3.new(math.cos(spawnAngle)*57,4,math.sin(spawnAngle)*57)
 model:PivotTo(CFrame.lookAt(spawnPos,a.corePos))
 local bot={model=model,health=Rules.resistance(a.cfg,round),
  position=spawnPos,lastAttack=0,speed=a.kind=="Robots" and 8 or 11}
 local click=Instance.new("ClickDetector");click.MaxActivationDistance=95;click.Parent=body
 click.MouseClick:Connect(function(player)
  if a.phase~="Playing" or bot.health<=0 or not a.members[player.UserId] then return end
  local member=a.members[player.UserId]
  local now=os.clock()
  if now-(member.lastShot or -100)<0.28 or member.ammo<=0 then return end
  local r=root(player)
  if not r or (r.Position-bot.position).Magnitude>95 then return end
  -- Cover blocks fire. A client click alone cannot award any damage.
  local ray=RaycastParams.new()
  ray.FilterType=Enum.RaycastFilterType.Exclude
  ray.FilterDescendantsInstances={player.Character,model,a.botFolder}
  local delta=bot.position-r.Position
  local obstruction=workspace:Raycast(r.Position,delta,ray)
  if obstruction then return end
  member.lastShot=now
  member.ammo-=1
  bot.health-=member.role=="Defender" and 27 or 21
  if bot.health<=0 then bot.model:Destroy() end
  update(a)
 end)
 table.insert(a.enemies,bot)
end
local function beginRound(a)
 if a.phase~="Playing" then return end
 a.round+=1
 if a.round>Rules.presets[a.preset].rounds then finish(a,true) return end
 for _,enemy in ipairs(a.enemies) do if enemy.model then enemy.model:Destroy() end end
 a.enemies={}
 a.cfg=Rules.config(a.preset,math.max(1,#roster(a)))
 local count=Rules.count(a.cfg,a.round)
 for i=1,count do createEnemy(a,i,a.round) end
 update(a,"Волна "..a.round.." / "..a.cfg.rounds)
end
local function start(a)
 if a.phase~="Lobby" or #roster(a)==0 then return end
 a.phase="Playing";a.coreHealth=150;a.round=0
 a.cfg=Rules.config(a.preset,#roster(a))
 if a.botFolder then a.botFolder:Destroy() end
 a.botFolder=Instance.new("Folder");a.botFolder.Name="SessionBots";a.botFolder.Parent=a.folder
 for uid,m in pairs(a.members) do
  m.ammo=60;m.lastShot=0;m.lastSupply=0;m.lastRepair=0
  local p=Players:GetPlayerByUserId(uid)
  if p then transport(p,a.origin+Vector3.new(0,5,-17)) end
 end
 beginRound(a)
end
local function enter(a,player)
 if player:GetAttribute("InChessMatch") then return end
 if player:GetAttribute("StoryXTeamMode") and player:GetAttribute("StoryXTeamMode")~=a.id then return end
 if a.phase=="Finished" then return end
 if a.phase=="Playing" and not a.members[player.UserId] then return end
 if not a.members[player.UserId] then
  if #roster(a)>=3 then return end
  a.members[player.UserId]={name=player.DisplayName,role="Defender",ammo=60,lastShot=0}
 end
 player:SetAttribute("StoryXTeamMode",a.id)
 transport(player,a.origin+Vector3.new(0,5,-47))
 update(a)
end
local function makeArena(id,kind,origin,spiralStep)
 local f=Instance.new("Folder");f.Name=id;f.Parent=folder
 local a={id=id,kind=kind,origin=origin,folder=f,corePos=origin,
   phase="Lobby",members={},enemies={},round=0,edition=1,
   coreHealth=150,preset=kind=="Robots" and "Robots10" or "Shadows10"}
 arenas[id]=a
 block(f,"Ground",Vector3.new(136,2,136),CFrame.new(origin),
  Color3.fromRGB(20,24,34),true)
 for i=1,4 do
  local z=i<=2 and -68 or 68
  local x=i%2==0 and -68 or 68
  block(f,"ArenaEdge_"..i,Vector3.new(2,10,136),CFrame.new(origin+Vector3.new(x,5,0)),
   Color3.fromRGB(35,68,75),true)
  block(f,"ArenaEdgeAlt_"..i,Vector3.new(136,10,2),CFrame.new(origin+Vector3.new(0,5,z)),
   Color3.fromRGB(35,68,75),true)
 end
 local base=block(f,"DefenseCore",Vector3.new(12,13,12),
  CFrame.new(origin+Vector3.new(0,7,0)),Color3.fromRGB(70,238,222),true,Enum.Material.Neon)
 banner(base,id.." / DEFEND THE CORE")
 local rolePos=origin+Vector3.new(-20,3,-46)
 for i,spec in ipairs({{"Defender","ПРИКРЫТИЕ"},{"Engineer","РЕМОНТ"},{"Support","СНАБЖЕНИЕ"}}) do
  local post=block(f,spec[1].."Post",Vector3.new(6,5,6),
   CFrame.new(rolePos+Vector3.new((i-1)*20,0,0)),
   Color3.fromRGB(55,145,160),true)
  banner(post,spec[2])
  makePrompt(post,spec[2],"Выбрать роль",function(p)
   if a.phase~="Lobby" or not inRange(p,post.Position,16) then return end
   if a.members[p.UserId] then a.members[p.UserId].role=spec[1];update(a) end
  end)
 end
 local rejoinPost=block(f,"LobbyJoin",Vector3.new(7,5,6),
  CFrame.new(origin+Vector3.new(39,3,-48)),Color3.fromRGB(49,162,124),true)
 banner(rejoinPost,"JOIN CO-OP TEAM")
 makePrompt(rejoinPost,"Войти в команду","Командная оборона",function(p)
  if a.phase=="Lobby" and inRange(p,rejoinPost.Position,17) then enter(a,p) end
 end)
 local startPost=block(f,"WaveLauncher",Vector3.new(9,5,7),
  CFrame.new(origin+Vector3.new(0,3,-58)),Color3.fromRGB(179,105,230),true)
 banner(startPost,"START 10 / 20 WAVES")
 makePrompt(startPost,"Начать волны","Командная оборона",function(p)
  if a.members[p.UserId] and inRange(p,startPost.Position,17) then start(a) end
 end)
 local difficultyPost=block(f,"Difficulty",Vector3.new(7,4,5),
  CFrame.new(origin+Vector3.new(25,3,-58)),Color3.fromRGB(120,90,235),true)
 makePrompt(difficultyPost,"10 / 20 волн","Выбор длительности",function(p)
  if a.phase~="Lobby" and a.members[p.UserId] then return end
  if not a.members[p.UserId] then return end
  a.preset=a.kind..(a.preset:sub(-2)=="10" and "20" or "10")
  update(a)
 end)
 local repairPost=block(f,"RepairWorkbench",Vector3.new(8,4,6),
  CFrame.new(origin+Vector3.new(-18,3,7)),Color3.fromRGB(43,144,135),true)
 makePrompt(repairPost,"Чинить базу","Инженерный терминал",function(p)
  local m=a.members[p.UserId]
  if a.phase~="Playing" or not m or not inRange(p,repairPost.Position,15) then return end
  local now=os.clock()
  if now-(m.lastRepair or -100)<8 then return end
  m.lastRepair=now;a.coreHealth=Rules.restore(m.role,a.coreHealth)
  update(a,"Команда укрепила защиту")
 end)
 local supplyPost=block(f,"SupplyDepot",Vector3.new(8,4,6),
  CFrame.new(origin+Vector3.new(18,3,7)),Color3.fromRGB(171,135,61),true)
 makePrompt(supplyPost,"Пополнить заряд","Запасы команды",function(p)
  local m=a.members[p.UserId]
  if a.phase~="Playing" or not m or not inRange(p,supplyPost.Position,15) then return end
  local now=os.clock()
  if now-(m.lastSupply or -100)<6 then return end
  m.lastSupply=now;m.ammo=Rules.replenish(m.role,m.ammo)
  update(a)
 end)
 for i=1,6 do
  local angle=i*math.pi/3
  local pos=origin+Vector3.new(math.cos(angle)*29,3,math.sin(angle)*29)
  block(f,"RuinVehicle_"..i,Vector3.new(11,5,6),
   CFrame.new(pos)*CFrame.Angles(0,angle,0),Color3.fromRGB(72,73,83),true)
 end
 local exit=block(f,"ReturnPortal",Vector3.new(9,7,1),
  CFrame.new(origin+Vector3.new(-42,5,-58)),Color3.fromRGB(75,205,240),false,Enum.Material.Neon)
 makePrompt(exit,"Вернуться в Матрицу","Добровольный выход",function(p)
  removeFrom(a,p.UserId);transport(p,Vector3.new(0,6,12));update(a)
  if a.phase=="Playing" and #roster(a)==0 then finish(a,false) end
 end)
 -- On-spire gateway, matching SpiralWorld's helix math.
 local angle=math.pi+spiralStep*math.pi*6/144
 local p0=Vector3.new(500+120*math.cos(angle),4+spiralStep*0.68,120*math.sin(angle))
 local radial=Vector3.new(math.cos(angle),0,math.sin(angle))
 local entry=p0+radial*26
 block(f,"SpiralBridge",Vector3.new(13,1.6,33),
  CFrame.lookAt((p0+entry)/2,entry),Color3.fromRGB(24,44,55),true)
 block(f,"SpiralBalcony",Vector3.new(27,1.7,23),CFrame.new(entry),
  Color3.fromRGB(18,31,50),true)
 local gate=block(f,"DimensionGate",Vector3.new(8,8,2),
  CFrame.new(entry+Vector3.new(0,4,0)),Color3.fromRGB(160,92,240),false,Enum.Material.Neon)
 banner(gate,id=="METAL_SENTINELS" and "METAL SENTINELS / CO-OP" or "SHADOW SWARM / CO-OP")
 makePrompt(gate,"Открыть измерение",id,function(p)enter(a,p)end)
 return a
end
makeArena("METAL_SENTINELS","Robots",Vector3.new(2360,24,0),107)
makeArena("SHADOW_SWARM","Shadows",Vector3.new(2650,24,0),123)
event.OnServerEvent:Connect(function(p,action,mode)
 if type(action)~="string" then return end
 local a=type(mode)=="string" and arenas[mode]
 if not a then return end
 if action=="GetState" then
  if a.members[p.UserId] then update(a) end
 elseif action=="Start" then
  if a.members[p.UserId] and a.phase=="Lobby" and inRange(p,a.origin,80) then start(a) end
 elseif action=="Exit" then
  if a.members[p.UserId] then
   removeFrom(a,p.UserId);transport(p,Vector3.new(0,6,12));update(a)
   if a.phase=="Playing" and #roster(a)==0 then finish(a,false) end
  end
 elseif action=="ChangeRole" and a.phase=="Lobby" and a.members[p.UserId] then
  -- Role selection requires returning to physical role terminal; client cannot bypass it.
  update(a,"Выбирай роль на терминале рядом с базой")
 end
end)
local accumulator=0
local lastHudUpdate=0
RunService.Heartbeat:Connect(function(dt)
 accumulator+=dt;if accumulator<0.13 then return end
 dt=accumulator;accumulator=0
 local now=os.clock()
 if now-lastHudUpdate>=1 then
  lastHudUpdate=now
  for _,arena in pairs(arenas) do
   if arena.phase=="Playing" then update(arena) end
  end
 end
 for _,a in pairs(arenas) do
  if a.phase=="Playing" then
   local living={}
   for _,bot in ipairs(a.enemies) do
    if bot.health>0 and bot.model.Parent then
     local d=a.corePos-bot.position
     local distance=d.Magnitude
     if distance>9 then
      local step=math.min(distance-8,bot.speed*dt)
      bot.position+=d.Unit*step
      bot.model:PivotTo(CFrame.lookAt(bot.position,Vector3.new(a.corePos.X,bot.position.Y,a.corePos.Z)))
     else
      local now=os.clock()
      if now-bot.lastAttack>=1.8 then
       bot.lastAttack=now
       a.coreHealth-=a.kind=="Robots" and 8 or 6
      end
     end
     table.insert(living,bot)
    end
   end
   a.enemies=living
   if a.coreHealth<=0 then finish(a,false)
   elseif #a.enemies==0 then
    beginRound(a)
   end
  end
 end
end)
Players.PlayerRemoving:Connect(function(p)
 for _,a in pairs(arenas) do
  if a.members[p.UserId] then
   removeFrom(a,p.UserId)
   if a.phase=="Playing" and #roster(a)==0 then finish(a,false) end
  end
 end
end)
print("[STORY X] Cooperative bot-defense arenas loaded.")
