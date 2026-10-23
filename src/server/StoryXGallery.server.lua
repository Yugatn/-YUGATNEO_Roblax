-- STORY X GALLERY: original generated art, exhibition rooms and safe quizzes.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local DataStoreService=game:GetService("DataStoreService")
local Catalog=require(script.Parent:WaitForChild("StoryXGalleryCatalog"))
local store=DataStoreService:GetDataStore("YUGATNEO_STORY_X_GALLERY_V1")
local event=Instance.new("RemoteEvent")
event.Name="StoryXGalleryEvent";event.Parent=ReplicatedStorage
local center=Vector3.new(900,20,420)
local folder=Instance.new("Folder");folder.Name="STORY_X_GALLERY";folder.Parent=workspace
local cyan=Color3.fromRGB(40,239,210)
local violet=Color3.fromRGB(168,104,244)
local gold=Color3.fromRGB(252,191,88)
local palette={cyan=cyan,violet=violet,amber=gold,green=Color3.fromRGB(91,233,125)}
local seen,solved,focused,locations,lastAction={},{},{},{},{}
local tours={}
local persisted,saving={},{}
local save -- forward declaration: answer handler must call local persistence routine
local function part(name,size,cf,color,collide,material)
 local p=Instance.new("Part")
 p.Name=name;p.Size=size;p.CFrame=cf;p.Anchored=true
 p.CanCollide=collide~=false;p.Material=material or Enum.Material.Metal
 p.Color=color;p.Parent=folder;return p
end
local function sign(p,txt,tint)
 local g=Instance.new("BillboardGui");g.Size=UDim2.fromOffset(340,75)
 g.StudsOffsetWorldSpace=Vector3.new(0,5,0);g.AlwaysOnTop=true
 g.MaxDistance=140;g.Parent=p
 local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1)
 t.BackgroundTransparency=1;t.TextScaled=true;t.TextWrapped=true
 t.TextColor3=tint;t.Font=Enum.Font.GothamBold;t.Text=txt;t.Parent=g
end
local function prompt(p,action,title,callback)
 local q=Instance.new("ProximityPrompt")
 q.ActionText=action;q.ObjectText=title;q.MaxActivationDistance=12
 q.HoldDuration=0.25;q.RequiresLineOfSight=false;q.Parent=p
 q.Triggered:Connect(callback)
end
local function nearby(player,pos,distance)
 local c=player.Character
 local root=c and c:FindFirstChild("HumanoidRootPart")
 local h=c and c:FindFirstChildOfClass("Humanoid")
 return root and h and h.Health>0 and (root.Position-pos).Magnitude<=distance
end
local function warp(p,pos)
 if p:GetAttribute("InChessMatch") or p:GetAttribute("StoryXTeamMode") then return end
 local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
 if root then root.AssemblyLinearVelocity=Vector3.zero;root.CFrame=CFrame.new(pos) end
end
local function state(p)
 local count=0
 for id in pairs(solved[p] or {}) do if Catalog.find(id) then count+=1 end end
 event:FireClient(p,"Progress",{completed=count,total=#Catalog.exhibits,
  seen=seen[p] or {},solved=solved[p] or {},persistent=persisted[p]==true})
end
local function sendTour(p,message)
 local index=tours[p]
 local exhibit=index and Catalog.exhibits[index]
 event:FireClient(p,"Tour",{
  active=exhibit~=nil,index=index or 0,total=#Catalog.exhibits,
  nextId=exhibit and exhibit.id or nil,
  nextTitle=exhibit and exhibit.title or nil,
  message=message,
 })
end
local floor=part("MuseumFloor",Vector3.new(153,2,128),CFrame.new(center),Color3.fromRGB(10,22,40))
for _,z in ipairs({-64,64}) do
 part("MuseumWall",Vector3.new(153,22,2),CFrame.new(center+Vector3.new(0,11,z)),Color3.fromRGB(13,29,46))
end
for _,x in ipairs({-76,76}) do
 part("MuseumWall",Vector3.new(2,22,128),CFrame.new(center+Vector3.new(x,11,0)),Color3.fromRGB(13,29,46))
end
local sculpture=part("ObserverSphere",Vector3.new(12,12,12),CFrame.new(center+Vector3.new(0,8,0)),cyan,false,Enum.Material.Glass)
sculpture.Shape=Enum.PartType.Ball;sculpture.Transparency=0.4
local core=part("ObserverCore",Vector3.new(4,4,4),CFrame.new(center+Vector3.new(0,8,0)),gold,false,Enum.Material.Neon)
core.Shape=Enum.PartType.Ball
sign(core,"YUGATNEO / STORY X",cyan)
prompt(core,"Начать экскурсию","Маршрут из 10 картин",function(p)
 if not nearby(p,core.Position,16) then return end
 local index=1
 -- Resume at the first not-yet-seen exhibit, never require a quiz answer.
 for i,entry in ipairs(Catalog.exhibits) do
  if not (seen[p] and seen[p][entry.id]) then index=i;break end
 end
 tours[p]=index
 sendTour(p,"Следуй к подсвеченной картине; вопросы необязательны.")
end)
-- Recognizable 15x9 icon language: an eye, two observers, a trace spiral,
-- circuit network, TV, film, archive clock, matrix code, two subjects and X.
local function lit(index,x,y)
 local dx,dy=x-8,y-5
 local radius=math.sqrt(dx*dx+dy*dy)
 if index==1 then
  return math.abs(dx)*0.12+math.abs(dy)*0.43<1.6
     and (math.abs(dy)>=1 or math.abs(dx)<=1)
 elseif index==2 then
  return ((x-4)^2+(y-4)^2<=4) or ((x-12)^2+(y-4)^2<=4)
     or (y>=6 and (x>=2 and x<=6 or x>=10 and x<=14))
 elseif index==3 then
  local theta=math.atan2(dy,dx)
  return math.abs(radius-(theta+3.2)*0.78)<0.8
 elseif index==4 then
  return ((x==4 or x==8 or x==12) and y>=2 and y<=8)
    or ((y==3 or y==7) and x>=2 and x<=14)
 elseif index==5 then
  return (x>=3 and x<=13 and (y==3 or y==8))
    or ((x==3 or x==13) and y>=3 and y<=8)
    or (y==2 and (x==6 or x==10))
 elseif index==6 then
  return (y==2 or y==8) or ((x==3 or x==6 or x==9 or x==12) and y%3==0)
    or (x>=4 and x<=11 and y>=4 and y<=6 and (x+y)%3==0)
 elseif index==7 then
  return (math.abs(radius-3.5)<0.65) or (x==8 and y>=3 and y<=5)
    or (y==5 and x>=8 and x<=11)
 elseif index==8 then
  return (x%3==1 and (y+x)%3~=0) or (y==5 and x>=4 and x<=12)
 elseif index==9 then
  return ((x-5)^2+(y-3)^2<=2) or ((x-11)^2+(y-3)^2<=2)
    or (y>=5 and (x>=3 and x<=7 or x>=9 and x<=13))
 end
 return math.abs(dx-dy)<=0.6 or math.abs(dx+dy)<=0.6
end

local function art(frame,exhibit,index)
 local g=Instance.new("SurfaceGui");g.Face=Enum.NormalId.Front
 g.PixelsPerStud=25;g.Parent=frame
 local bg=Instance.new("Frame");bg.Size=UDim2.fromScale(1,1)
 bg.BackgroundColor3=Color3.fromRGB(5,13,28);bg.BorderSizePixel=0;bg.Parent=g
 if type(exhibit.imageAsset)=="number" and exhibit.imageAsset>0 then
  local img=Instance.new("ImageLabel");img.Size=UDim2.fromScale(1,1)
  img.BackgroundTransparency=1;img.ScaleType=Enum.ScaleType.Fit
  img.Image="rbxassetid://"..tostring(exhibit.imageAsset);img.Parent=bg
  return
 end
 local tint=palette[exhibit.accent] or cyan
 for y=1,9 do for x=1,15 do
  local on=lit(index,x,y)
  if on then
   local px=Instance.new("Frame")
   px.Position=UDim2.fromScale((x-1)/15,(y-1)/9)
   px.Size=UDim2.fromScale(1/15-0.004,1/9-0.004)
   px.BorderSizePixel=0
   px.BackgroundColor3=(x+y)%7==0 and gold or tint
   px.Parent=bg
  end
 end end
end
for i,exhibit in ipairs(Catalog.exhibits) do
 local row=i<=5 and -1 or 1
 local x=-52+((i-1)%5)*26
 local framePosition=center+Vector3.new(x,11,row*45)
 local frame=part("Artwork_"..exhibit.id,Vector3.new(19,12,0.8),
  CFrame.lookAt(framePosition,center+Vector3.new(x,11,0)),
  palette[exhibit.accent] or cyan,false)
 art(frame,exhibit,i)
 local display=part("Kiosk_"..exhibit.id,Vector3.new(4,3.5,4),
  CFrame.new(center+Vector3.new(x,3,row*30)),palette[exhibit.accent] or cyan)
 sign(display,exhibit.title,palette[exhibit.accent] or cyan)
 locations[exhibit.id]=display.Position
 prompt(display,"Открыть","Экспозиция",function(p)
  if not nearby(p,display.Position,17) then return end
  seen[p]=seen[p] or {};solved[p]=solved[p] or {}
  seen[p][exhibit.id]=true;focused[p]=exhibit.id
  local index=tours[p]
  if index and Catalog.exhibits[index].id==exhibit.id then
   if index==#Catalog.exhibits then
    tours[p]=nil
    sendTour(p,"Маршрут завершён: ты изучил все десять глав!")
   else
    tours[p]=index+1
    sendTour(p,"Следующий экспонат: "..Catalog.exhibits[index+1].title)
   end
  end
  event:FireClient(p,"Exhibit",Catalog.public(exhibit))
  state(p)
 end)
end
-- Personal atlas: inspection is read-only, server does not leak quiz answers.
local atlas=part("StoryXAtlasTerminal",Vector3.new(6,4,5),
 CFrame.new(center+Vector3.new(0,3,18)),gold,true,Enum.Material.Neon)
sign(atlas,"АТЛАС X / 10 ГЛАВ",gold)
prompt(atlas,"Открыть атлас","Исследованные экспозиции",function(p)
 if not nearby(p,atlas.Position,16) then return end
 local entries={}
 for _,exhibit in ipairs(Catalog.exhibits) do
  table.insert(entries,Catalog.public(exhibit))
 end
 event:FireClient(p,"Atlas",{
  entries=entries,seen=seen[p] or {},solved=solved[p] or {},
 })
 state(p)
end)
local function exitPost(name,offset,title,position)
 local p=part(name,Vector3.new(7,4,5),CFrame.new(center+offset),violet)
 sign(p,title,cyan)
 prompt(p,"Перейти",title,function(player)
  if nearby(player,p.Position,16) then
   tours[player]=nil;sendTour(player)
   warp(player,position)
  end
 end)
end
exitPost("ToChess",Vector3.new(45,3,5),"ШАХМАТЫ",Catalog.routes.Chess.position)
exitPost("ToLibrary",Vector3.new(-45,3,5),"БИБЛИОТЕКА",Catalog.routes.Library.position)
exitPost("ToArcade",Vector3.new(25,3,5),"АРКАДА",Catalog.routes.Arcade.position)
exitPost("ToMatrix",Vector3.new(-25,3,5),"МАТРИЦА",Catalog.routes.Matrix.position)
local step=58
local angle=math.pi+step*math.pi*6/144
local road=Vector3.new(500+120*math.cos(angle),4+step*0.68,120*math.sin(angle))
local radial=Vector3.new(math.cos(angle),0,math.sin(angle))
local entrance=road+radial*26
local bridge=part("SpiralGalleryBridge",Vector3.new(12,1.6,34),
 CFrame.lookAt((road+entrance)/2,entrance),Color3.fromRGB(14,32,50))
part("SpiralGalleryLanding",Vector3.new(28,1.6,25),CFrame.new(entrance),Color3.fromRGB(14,32,50))
local portal=part("SpiralGalleryPortal",Vector3.new(8,8,2),
 CFrame.new(entrance+Vector3.new(0,4,0)),cyan,false,Enum.Material.Neon)
sign(portal,"ГАЛЕРЕЯ СЮЖЕТА ИКС",gold)
prompt(portal,"Войти","Story X Gallery",function(p)
 if nearby(p,portal.Position,16) then
  warp(p,center+Vector3.new(0,5,-12))
  sendTour(p,"Начни экскурсию у центральной голограммы.")
 end
end)
exitPost("ToSpiral",Vector3.new(0,3,-19),"НА СПИРАЛЬ",entrance+Vector3.new(0,5,0))
event.OnServerEvent:Connect(function(p,action,id,answer)
 if type(action)~="string" then return end
 local now=os.clock()
 if now-(lastAction[p] or -100)<0.3 then return end
 lastAction[p]=now
 if action=="Status" then
  if nearby(p,center,110) then state(p);sendTour(p) end
 elseif action=="StopTour" then
  tours[p]=nil
  sendTour(p,"Экскурсия остановлена. Продолжить можно у сферы в центре.")
 elseif action=="Answer" then
  if type(id)~="string" or type(answer)~="number" then return end
  local pos=locations[id]
  if not pos or focused[p]~=id or not nearby(p,pos,22) then return end
  solved[p]=solved[p] or {}
  local correct=Catalog.check(id,answer)
  if correct then
   solved[p][id]=true
   task.spawn(save,p)
  end
  event:FireClient(p,"AnswerResult",{correct=correct,id=id})
  state(p)
 end
end)
save=function(p)
 if not persisted[p] or saving[p] then return false end
 saving[p]=true
 local seenSnapshot={}
 local solvedSnapshot={}
 for id in pairs(seen[p] or {}) do if Catalog.find(id) then seenSnapshot[id]=true end end
 for id in pairs(solved[p] or {}) do if Catalog.find(id) then solvedSnapshot[id]=true end end
 local ok,err=pcall(function()
  store:UpdateAsync("player_"..p.UserId,function(previous)
   local data=type(previous)=="table" and previous or {}
   local savedSeen=type(data.seen)=="table" and data.seen or {}
   local savedSolved=type(data.solved)=="table" and data.solved or {}
   for id in pairs(seenSnapshot) do savedSeen[id]=true end
   for id in pairs(solvedSnapshot) do savedSolved[id]=true end
   return {seen=savedSeen,solved=savedSolved}
  end)
 end)
 saving[p]=nil
 if not ok then warn("[Story X Gallery] Save failed:",err) end
 return ok
end
local function flush(p)
 local deadline=os.clock()+8
 while saving[p] and os.clock()<deadline do task.wait(0.1) end
 if saving[p] then warn("[Story X Gallery] Pending save timed out",p.UserId);return end
 local success=save(p)
 if success==false and persisted[p] then
  task.wait(0.4)
  save(p)
 end
end
Players.PlayerAdded:Connect(function(p)
 seen[p]={};solved[p]={}
 task.spawn(function()
  local ok,data=pcall(function() return store:GetAsync("player_"..p.UserId) end)
  if p.Parent~=Players then return end
  if ok and type(data)=="table" then
   for _,item in ipairs(Catalog.exhibits) do
    if type(data.seen)=="table" and data.seen[item.id] then seen[p][item.id]=true end
    if type(data.solved)=="table" and data.solved[item.id] then solved[p][item.id]=true end
   end
  end
  persisted[p]=ok
  state(p)
 end)
end)
Players.PlayerRemoving:Connect(function(p)
 flush(p)
 focused[p]=nil;lastAction[p]=nil;seen[p]=nil;solved[p]=nil;tours[p]=nil
 persisted[p]=nil;saving[p]=nil
end)
for _,p in ipairs(Players:GetPlayers()) do
 seen[p]=seen[p] or {};solved[p]=solved[p] or {}
 task.spawn(function()
  local ok,data=pcall(function()return store:GetAsync("player_"..p.UserId)end)
  if p.Parent~=Players then return end
  if ok and type(data)=="table" then
   for _,item in ipairs(Catalog.exhibits) do
    if type(data.seen)=="table" and data.seen[item.id] then seen[p][item.id]=true end
    if type(data.solved)=="table" and data.solved[item.id] then solved[p][item.id]=true end
   end
  end
  persisted[p]=ok;state(p)
 end)
end
task.spawn(function()
 while true do
  task.wait(120)
  for p in pairs(seen) do task.spawn(save,p) end
 end
end)
game:BindToClose(function()
 for _,p in ipairs(Players:GetPlayers()) do flush(p) end
end)
print("[STORY X] Ten interactive gallery scenes and chapter quizzes loaded.")
