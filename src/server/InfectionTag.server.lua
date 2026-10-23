-- STORY X: cooperative, non-violent infection tag ("ням-ням"), no damage, no gore.
-- Continuous contact must last 3 seconds with unobstructed line of sight.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Rewards=require(script.Parent:WaitForChild("WorldRewards"))
local TagRules=require(script.Parent:WaitForChild("InfectionRules"))
local event=ReplicatedStorage:FindFirstChild("StoryXTagEvent") or Instance.new("RemoteEvent")
event.Name="StoryXTagEvent";event.Parent=ReplicatedStorage
local folder=Instance.new("Folder");folder.Name="STORY_X_ZOMBIE_TAG";folder.Parent=workspace
local origin=Vector3.new(3010,28,0)
local rng=Random.new()
local queue,roster={},{}
local round={phase="Lobby",number=0,duration=1800,entered=0,starts=0,escapeAt=nil,initial=0}
local progress,lastRequest={},{}
local bright=Color3.fromRGB(67,237,204)
local purple=Color3.fromRGB(149,103,243)
local function part(name,size,position,color,parent,material)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.Position=position
 p.Color=color;p.Anchored=true;p.CanCollide=true
 p.Material=material or Enum.Material.Metal;p.Parent=parent or folder
 return p
end
local function banner(anchor,msg)
 local ui=Instance.new("BillboardGui");ui.Size=UDim2.fromOffset(400,90)
 ui.StudsOffsetWorldSpace=Vector3.new(0,6,0);ui.AlwaysOnTop=true;ui.MaxDistance=350
 ui.Parent=anchor
 local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1)
 label.BackgroundTransparency=1;label.TextWrapped=true;label.TextScaled=true
 label.Font=Enum.Font.GothamBlack;label.TextColor3=bright;label.Text=msg;label.Parent=ui
end
local function prox(base,text,fn)
 local prompt=Instance.new("ProximityPrompt");prompt.ActionText=text
 prompt.ObjectText="Зомби-догонялки";prompt.HoldDuration=0.3
 prompt.MaxActivationDistance=12;prompt.RequiresLineOfSight=false;prompt.Parent=base
 prompt.Triggered:Connect(fn)
end
local function root(p)
 local c=p.Character
 local h=c and c:FindFirstChildOfClass("Humanoid")
 return h and h.Health>0 and c:FindFirstChild("HumanoidRootPart")
end
local function move(p,pos)
 local r=root(p)
 if r then r.AssemblyLinearVelocity=Vector3.zero;r.CFrame=CFrame.new(pos) end
end
local function near(p,pos,range)
 local r=root(p)
 return r and (r.Position-pos).Magnitude<=range
end
local function roleCount(role)
 local n=0
 for _,v in pairs(roster) do if v.role==role then n+=1 end end
 return n
end
local function removeQueue(uid)
 for i=#queue,1,-1 do if queue[i]==uid then table.remove(queue,i) end end
end
local function rows()
 local out={}
 for uid,m in pairs(roster) do table.insert(out,{id=uid,name=m.name,role=m.role}) end
 return out
end
local function status(message)
 local survivors=roleCount("Runner")
 local infected=roleCount("Chaser")
 local remaining=0
 if round.phase=="Playing" or round.phase=="FinalEscape" then
  remaining=math.max(0,math.ceil((round.escapeAt or round.ends)-os.clock()))
 end
 local data={phase=round.phase,queued=#queue,players=rows(),infected=infected,
  survivors=survivors,remaining=remaining,duration=round.duration,
  message=message or "",round=round.number}
 for uid in pairs(roster) do
  local p=Players:GetPlayerByUserId(uid)
  if p then event:FireClient(p,"TagState",data) end
 end
 for _,uid in ipairs(queue) do
  local p=Players:GetPlayerByUserId(uid)
  if p then event:FireClient(p,"TagState",data) end
 end
end
-- Two-tier environment: natural climbing, guarded sheds, cars, hideable benches.
part("PlayField",Vector3.new(170,2,170),origin,Color3.fromRGB(30,58,53))
for _,x in ipairs({-84,84}) do
 part("Boundary",Vector3.new(2,13,168),origin+Vector3.new(x,6,0),Color3.fromRGB(25,87,90))
end
for _,z in ipairs({-84,84}) do
 part("Boundary",Vector3.new(170,13,2),origin+Vector3.new(0,6,z),Color3.fromRGB(25,87,90))
end
for i=1,6 do
 local angle=i*math.pi/3
 local center=origin+Vector3.new(math.cos(angle)*56,0,math.sin(angle)*55)
 part("TreeTrunk_"..i,Vector3.new(5,18,5),center+Vector3.new(0,10,0),
  Color3.fromRGB(80,63,43))
 part("TreePerch_"..i,Vector3.new(15,2,15),center+Vector3.new(0,18,0),
  Color3.fromRGB(38,110,76))
 local truss=Instance.new("TrussPart");truss.Name="ClimbTree_"..i
 truss.Size=Vector3.new(3,19,3)
 truss.CFrame=CFrame.new(center+Vector3.new(5,10,0))
 truss.Anchored=true;truss.Color=Color3.fromRGB(88,83,62);truss.Parent=folder
end
for i=1,3 do
 local base=origin+Vector3.new(-56+(i-1)*54,0,13)
 part("HideHouseFloor_"..i,Vector3.new(24,1,20),base+Vector3.new(0,2,0),
  Color3.fromRGB(58,67,80))
 part("HideHouseRoof_"..i,Vector3.new(24,1,20),base+Vector3.new(0,23,0),
  Color3.fromRGB(47,61,84))
 for _,x in ipairs({-11,11}) do
  part("HideWall_"..i,Vector3.new(1.5,21,20),base+Vector3.new(x,13,0),
   Color3.fromRGB(54,65,80))
 end
 part("HideBack_"..i,Vector3.new(24,21,1.5),base+Vector3.new(0,13,10),
  Color3.fromRGB(54,65,80))
 part("HideLoft_"..i,Vector3.new(24,1,10),base+Vector3.new(0,13,5),
  Color3.fromRGB(72,86,90))
 local stairs=Instance.new("TrussPart");stairs.Name="HideLadder_"..i
 stairs.Size=Vector3.new(3,20,3)
 stairs.CFrame=CFrame.new(base+Vector3.new(8,12,-7))
 stairs.Anchored=true;stairs.Color=purple;stairs.Parent=folder
 part("HideTable_"..i,Vector3.new(8,1,7),base+Vector3.new(-3,6,0),
  Color3.fromRGB(93,76,65))
end
for i=1,3 do
 local car=Instance.new("Model");car.Name="HideCar_"..i;car.Parent=folder
 local base=origin+Vector3.new(-40+(i-1)*34,5,-50)
 part("CarBody",Vector3.new(12,4,7),base,Color3.fromRGB(59,118,148),car)
 part("CarRoof",Vector3.new(7,1,6),base+Vector3.new(0,4,0),
  Color3.fromRGB(42,69,85),car)
 local seat=Instance.new("Seat");seat.Name="HideSeat";seat.Size=Vector3.new(2,1,3)
 seat.Position=base+Vector3.new(0,3,0);seat.Anchored=true;seat.Parent=car
end
local lobby=origin+Vector3.new(0,2,-65)
local startPost=part("QueueMarker",Vector3.new(7,5,5),lobby+Vector3.new(0,2,0),purple)
banner(startPost,"JOIN / ZOMBIE TAG\n3 SEC «НЯМ-НЯМ»")
local exit=part("ExitMarker",Vector3.new(7,5,5),lobby+Vector3.new(21,2,0),bright)
banner(exit,"LEAVE GAME")
local durationPost=part("TimerOptions",Vector3.new(7,5,5),lobby+Vector3.new(-21,2,0),purple)
banner(durationPost,"30 / 60 MINUTES")
-- Physical dimension entrance on another spiral segment.
local step=140
local angle=math.pi+step*math.pi*6/144
local path=Vector3.new(500+120*math.cos(angle),4+step*0.68,120*math.sin(angle))
local radial=Vector3.new(math.cos(angle),0,math.sin(angle))
local entry=path+radial*26
local bridge=part("SpiralTagBridge",Vector3.new(13,1.6,33),(path+entry)*0.5,
 Color3.fromRGB(26,48,55))
bridge.CFrame=CFrame.lookAt((path+entry)*0.5,entry)
part("SpiralTagPlatform",Vector3.new(27,1.6,26),entry,Color3.fromRGB(22,39,55))
local gate=part("InfectionTagGate",Vector3.new(8,8,2),entry+Vector3.new(0,4,0),purple)
gate.CanCollide=false
banner(gate,"ZOMBIE TAG / NO WEAPONS\nHIDE • CLIMB • SURVIVE")
local function cleanupRound(winner)
 if round.phase~="Playing" and round.phase~="FinalEscape" then return end
 round.phase="Finished";round.escapeAt=nil
 status(winner=="Chasers" and "Победа догоняющих: все пойманы!" or
  "Победа выживших: успели спрятаться!")
 for uid,m in pairs(roster) do
  local p=Players:GetPlayerByUserId(uid)
  if p then
   Rewards.award(p,((winner=="Chasers" and m.role=="Chaser") or
    (winner=="Runners" and m.role=="Runner")) and 20 or 5,
    "Story X zombie tag","tag_"..round.number.."_"..uid)
  end
 end
 task.delay(9,function()
  if round.phase~="Finished" then return end
  for uid,m in pairs(roster) do
   local p=Players:GetPlayerByUserId(uid)
   if p then
    p:SetAttribute("StoryXTeamMode",nil)
    local c=p.Character
    if c then
     local marker=c:FindFirstChild("StoryXInfectedHighlight")
     if marker then marker:Destroy() end
    end
   end
  end
  roster={};progress={};round.phase="Lobby"
  status()
 end)
end
local function visualizeRole(player,infected)
 local c=player.Character
 if not c then return end
 local old=c:FindFirstChild("StoryXInfectedHighlight")
 if old then old:Destroy() end
 if not infected then return end
 local h=Instance.new("Highlight")
 h.Name="StoryXInfectedHighlight";h.Adornee=c
 h.FillColor=Color3.fromRGB(130,100,235)
 h.OutlineColor=Color3.fromRGB(206,175,255)
 h.FillTransparency=0.6
 h.DepthMode=Enum.HighlightDepthMode.Occluded
 h.Parent=c
end
local function start()
 if round.phase~="Lobby" or #queue<2 then return end
 local fresh={}
 for _,uid in ipairs(queue) do
  if Players:GetPlayerByUserId(uid) and #fresh<12 then
   table.insert(fresh,uid)
  end
 end
 queue={}
 if #fresh<2 then status() return end
 round.number+=1;round.phase="Playing";round.started=os.clock()
 -- Playtime is 30m or 60m when published; short Studio override aids testing.
 round.ends=os.clock()+TagRules.timeLimit(round.duration/60,RunService:IsStudio())
 round.initial=#fresh-1;round.escapeAt=nil
 roster={};progress={}
 local first=rng:NextInteger(1,#fresh)
 for i,uid in ipairs(fresh) do
  local p=Players:GetPlayerByUserId(uid)
  if p then
   local infected=i==first
   roster[uid]={role=infected and "Chaser" or "Runner",
    name=p.DisplayName,infectAt=os.clock()+5}
   p:SetAttribute("StoryXTeamMode","ZOMBIE_TAG")
   local position=origin+Vector3.new(-24+(i-1)%6*9,5,52+math.floor((i-1)/6)*8)
   move(p,position)
   visualizeRole(p,infected)
  end
 end
 status("Раунд начался! Держись рядом 3 секунды, чтобы передать заражение.")
end
local countStart
countStart=function()
 if round.phase~="Lobby" or #queue<2 then return end
 round.phase="Countdown";status("Старт через 12 секунд")
 task.delay(12,function()
  if round.phase=="Countdown" then
   round.phase="Lobby"
   start()
  end
 end)
end
local function join(player)
 if player:GetAttribute("InChessMatch") then return end
 if player:GetAttribute("StoryXTeamMode") and player:GetAttribute("StoryXTeamMode")~="ZOMBIE_TAG" then return end
 if round.phase~="Lobby" and round.phase~="Countdown" then return end
 if table.find(queue,player.UserId) then return end
 if #queue>=12 then return end
 queue[#queue+1]=player.UserId
 player:SetAttribute("StoryXTeamMode","ZOMBIE_TAG")
 move(player,origin+Vector3.new(0,5,-49))
 status()
 if #queue>=2 and round.phase=="Lobby" then countStart() end
end
local function leave(player)
 removeQueue(player.UserId)
 roster[player.UserId]=nil
 player:SetAttribute("StoryXTeamMode",nil)
 local c=player.Character
 if c then
  local h=c:FindFirstChild("StoryXInfectedHighlight")
  if h then h:Destroy() end
 end
 move(player,Vector3.new(0,6,12))
 status()
end
prox(gate,"Войти в догонялки",join)
prox(startPost,"Записаться в игру",join)
prox(exit,"Вернуться в Матрицу",leave)
prox(durationPost,"30 / 60 минут",function(p)
 if (round.phase=="Lobby" or round.phase=="Countdown") and
     table.find(queue,p.UserId) and near(p,durationPost.Position,13) then
  round.duration=round.duration==1800 and 3600 or 1800
  status("Выбрано "..round.duration/60.." минут")
 end
end)
event.OnServerEvent:Connect(function(p,action)
 if type(action)~="string" then return end
 local now=os.clock()
 if now-(lastRequest[p] or -100)<0.35 then return end
 lastRequest[p]=now
 if action=="GetState" then status()
 elseif action=="Leave" then
  if table.find(queue,p.UserId) or roster[p.UserId] then leave(p) end
 end
end)
local function unobstructed(chaser,runner,from,to)
 local r=RaycastParams.new()
 r.FilterType=Enum.RaycastFilterType.Exclude
 r.FilterDescendantsInstances={chaser.Character,runner.Character}
 local result=workspace:Raycast(from,to-from,r)
 return result==nil
end
local accumulator=0
local lastHudUpdate=0
RunService.Heartbeat:Connect(function(dt)
 accumulator+=dt
 if accumulator<0.15 then return end
 accumulator=0
 if round.phase~="Playing" and round.phase~="FinalEscape" then return end
 local now=os.clock()
 if now>=round.ends or (round.escapeAt and now>=round.escapeAt) then
  cleanupRound("Runners");return
 end
 local infectedIds,runners={},{}
 for uid,r in pairs(roster) do
  if r.role=="Chaser" then infectedIds[#infectedIds+1]=uid
  else runners[#runners+1]=uid end
 end
 if #runners==0 then cleanupRound("Chasers");return end
 if #infectedIds==0 then cleanupRound("Runners");return end
 local infectedChanged=false
 for _,cid in ipairs(infectedIds) do
  local chaser=Players:GetPlayerByUserId(cid)
  local cpos=chaser and root(chaser)
  if cpos and now>=(roster[cid].infectAt or 0) then
   for _,uid in ipairs(runners) do
    local survivor=Players:GetPlayerByUserId(uid)
    local spos=survivor and root(survivor)
    local k=cid..":"..uid
    if spos and (cpos.Position-spos.Position).Magnitude<=5.8 and
     unobstructed(chaser,survivor,cpos.Position,spos.Position) then
     progress[k]=progress[k] or now
     local held=now-progress[k]
     event:FireClient(chaser,"TagProgress",{target=uid,seconds=math.min(3,held)})
     if TagRules.captured(progress[k],now,true,(cpos.Position-spos.Position).Magnitude) and roster[uid] and roster[uid].role=="Runner" then
      roster[uid].role="Chaser"
      roster[uid].infectAt=now+5
      visualizeRole(survivor,true)
      progress={}
      infectedChanged=true
      event:FireClient(survivor,"Tagged",{message="Ням-ням! Теперь ты помогаешь искать."})
      break
     end
    else
     progress[k]=nil
    end
   end
  end
  if infectedChanged then break end
 end
 if infectedChanged then
  local survived=roleCount("Runner")
  if TagRules.finalEscapeAllowed(round.initial,survived) and not round.escapeAt then
   round.phase="FinalEscape"
   round.escapeAt=math.min(round.ends,now+60)
   status("Финальный побег! Осталось продержаться 60 секунд.")
  else
   status("Один из игроков присоединился к догоняющим.")
  end
  if survived==0 then cleanupRound("Chasers") end
 end
end)
Players.PlayerRemoving:Connect(function(p)
 lastRequest[p]=nil
 removeQueue(p.UserId)
 roster[p.UserId]=nil
 if round.phase=="Countdown" and #queue<2 then
  round.phase="Lobby"
 end
 if round.phase=="Playing" or round.phase=="FinalEscape" then
  if roleCount("Runner")==0 then cleanupRound("Chasers")
  elseif roleCount("Chaser")==0 then cleanupRound("Runners") end
 end
 status()
end)
print("[STORY X] Zombie tag: 3-second LOS infection and multi-level hiding playground ready.")
