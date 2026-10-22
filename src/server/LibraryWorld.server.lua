-- Library wing and multiplayer reading race for STORY X.
-- Each winner must locate BOTH the requested paragraph and a comprehension answer.
-- No unchecked user text is ever replicated; notes are local to the client's interface.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Catalog=require(script.Parent:WaitForChild("LibraryCatalog"))
local Rewards=require(script.Parent:WaitForChild("WorldRewards"))
local event=ReplicatedStorage:FindFirstChild("YugatneoLibrary") or Instance.new("RemoteEvent")
event.Name="YugatneoLibrary"
event.Parent=ReplicatedStorage
local folder=Instance.new("Folder")
folder.Name="YUGATNEO_STORY_X_LIBRARY"
folder.Parent=workspace
local origin=Vector3.new(-139,0,64)
local rng=Random.new()
local queue,playersInRound,round,lastRemote={},{},nil,{}
local roundNumber=0
local function piece(name,size,pos,color,material,collide)
 local p=Instance.new("Part")
 p.Name=name
 p.Size=size
 p.Position=pos
 p.Color=color
 p.Material=material or Enum.Material.Wood
 p.CanCollide=collide~=false
 p.Anchored=true
 p.Parent=folder
 return p
end
local dark=Color3.fromRGB(8,20,35)
local cyan=Color3.fromRGB(40,236,215)
local amber=Color3.fromRGB(243,183,69)
local violet=Color3.fromRGB(124,80,206)
piece("PathFromMatrix",Vector3.new(115,1.5,16),Vector3.new(-74,-0.9,48),dark,Enum.Material.Slate)
piece("LibraryFloor",Vector3.new(90,2,78),origin+Vector3.new(0,-1.2,0),dark,Enum.Material.Slate)
piece("LibraryNorthWall",Vector3.new(90,18,2),origin+Vector3.new(0,8,-38),dark)
piece("LibrarySouthWall",Vector3.new(90,18,2),origin+Vector3.new(0,8,38),dark)
piece("LibraryWestWall",Vector3.new(2,18,78),origin+Vector3.new(-44,8,0),dark)
-- East wall intentionally open for walking into the room.
piece("BookHallTitle",Vector3.new(32,5,1),origin+Vector3.new(0,13,-35),violet,Enum.Material.Neon,false)
local function plaque(adornee,text,ink,width,height)
 local gui=Instance.new("BillboardGui")
 gui.Name="Label"
 gui.Size=UDim2.fromOffset(width or 260,height or 70)
 gui.StudsOffsetWorldSpace=Vector3.new(0,4.5,0)
 gui.AlwaysOnTop=true
 gui.MaxDistance=135
 gui.Parent=adornee
 local label=Instance.new("TextLabel")
 label.Size=UDim2.fromScale(1,1)
 label.BackgroundTransparency=1
 label.TextWrapped=true
 label.TextScaled=true
 label.Font=Enum.Font.GothamBold
 label.TextColor3=ink or cyan
 label.TextStrokeTransparency=0.4
 label.Text=text
 label.Parent=gui
end
plaque(folder.BookHallTitle,"LIBRARY X  /  READ • QUESTION • CREATE",cyan,650,95)
local function prompt(block,label,fn)
 local p=Instance.new("ProximityPrompt")
 p.ActionText="Open"
 p.ObjectText=label
 p.HoldDuration=0.2
 p.MaxActivationDistance=12
 p.RequiresLineOfSight=false
 p.Parent=block
 p.Triggered:Connect(fn)
end
local function closeTo(p,pos,range)
 if p:GetAttribute("InChessMatch") then return false end
 local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
 local hum=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
 return root and hum and hum.Health>0 and (root.Position-pos).Magnitude<=range
end
for i,book in ipairs(Catalog.books) do
 local x=origin.X-31+((i-1)%2)*63
 local z=origin.Z-15+math.floor((i-1)/2)*28
 local shelf=piece("BookShelf_"..book.id,Vector3.new(10,9,5),Vector3.new(x,4.5,z),Color3.fromRGB(88,57,43))
 plaque(shelf,book.title,amber,250,80)
 for j=1,6 do
  local pos=shelf.Position+Vector3.new(-3.5+(j-1)*1.4,-2,3.1)
  piece("Book_"..book.id.."_"..j,Vector3.new(0.9,3,0.55),pos,
   j%2==0 and cyan or violet,Enum.Material.SmoothPlastic,false)
 end
 prompt(shelf,book.title,function(p)
  if closeTo(p,shelf.Position,17) then event:FireClient(p,"OpenBook",book.id) end
 end)
end
-- Pixel-art-inspired original abstract pieces; no third-party image licenses required.
local function mural(title,x,z,seed)
 local frame=piece(title.."_Frame",Vector3.new(18,10,0.9),
    Vector3.new(x,8,z),Color3.fromRGB(48,43,70),Enum.Material.Metal)
 frame.CanCollide=false
 local pixels=Random.new(seed)
 for y=1,6 do
  for col=1,11 do
   local c
   if (col+y+seed)%5==0 then c=amber
   elseif pixels:NextInteger(1,2)==1 then c=cyan
   else c=violet end
   local p=piece(title.."Pixel"..y.."_"..col,Vector3.new(1.2,1.1,0.2),
      Vector3.new(x-7.5+col*1.3,3+y*1.3,z+0.6),c,Enum.Material.Neon,false)
   p.CanQuery=false
  end
 end
 plaque(frame,title,amber,200,40)
end
mural("THE OBSERVER",origin.X-24,origin.Z-36.5,13)
mural("DIFFERENT WORLDS",origin.X+24,origin.Z-36.5,29)
local kiosk=piece("ReadingRaceKiosk",Vector3.new(9,5,6),
 origin+Vector3.new(0,2.5,22),violet,Enum.Material.Metal)
plaque(kiosk,"READING RACE\nSEARCH + COMPREHEND",cyan,300,90)
local prize=piece("RewardsKiosk",Vector3.new(8,5,6),origin+Vector3.new(-14,2.5,23),amber,Enum.Material.Metal)
plaque(prize,"STORY X\nREWARDS",cyan,220,75)
prompt(prize,"Reward workshop",function(p)
 if closeTo(p,prize.Position,17) then Rewards.send(p) event:FireClient(p,"Shop") end
end)
local notices=piece("LibraryNoticeBoard",Vector3.new(20,8,0.5),
 origin+Vector3.new(0,6,35.5),cyan,Enum.Material.Neon,false)
local sg=Instance.new("SurfaceGui")
sg.Face=Enum.NormalId.Front
sg.PixelsPerStud=35
sg.Parent=notices
local status=Instance.new("TextLabel")
status.Size=UDim2.fromScale(1,1)
status.BackgroundTransparency=1
status.TextColor3=Color3.new(0,0,0)
status.TextScaled=true
status.TextWrapped=true
status.Font=Enum.Font.GothamBold
status.Parent=sg
local function broadcast()
 local msg=round and ("ROUND "..round.number.." / "..round.phase.." / participants: "..#round.entrants)
  or ("NEXT READING RACE / WAITING: "..#queue)
 status.Text=msg.."\nFind a paragraph, then answer a question."
 event:FireAllClients("RaceStatus",{message=msg})
end
local schedule
local function removeAll(list,userId)
 for i=#list,1,-1 do if list[i]==userId then table.remove(list,i) end end
end
local function winnerSorted()
 local list={}
 if not round then return list end
 for _,uid in ipairs(round.entrants) do
  local result=round.results[uid]
  if result then table.insert(list,{uid=uid,time=result.time}) end
 end
 table.sort(list,function(a,b) return a.time<b.time end)
 return list
end
local function complete(edition)
 if not round or round.number~=edition or round.phase~="Reading" then return end
 round.phase="Finished"
 local ranking=winnerSorted()
 local names={}
 for i,r in ipairs(ranking) do
  local p=Players:GetPlayerByUserId(r.uid)
  if p then
   Rewards.award(p,i==1 and 30 or 12,"library race","library_"..edition)
   table.insert(names,(p.DisplayName or "Reader").." ("..string.format("%.1f",r.time).."s)")
  end
 end
 for _,uid in ipairs(round.entrants) do
  local p=Players:GetPlayerByUserId(uid)
  if p and not round.results[uid] then Rewards.award(p,3,"library practice","library_"..edition) end
 end
 event:FireAllClients("RaceResults",{winners=names,edition=edition})
 broadcast()
 task.delay(8,function()
  if round and round.number==edition then
   round=nil
   broadcast()
   if #queue>0 then schedule() end
  end
 end)
end
local function start(edition)
 if not round or round.number~=edition or round.phase~="Registration" then return end
 if #round.entrants==0 then round=nil broadcast() return end
 round.phase="Reading"
 round.started=os.clock()
 round.deadline=round.started+60
 local clue={
  bookId=round.challenge.bookId,bookTitle=round.challenge.bookTitle,
  prompt=round.challenge.prompt,options=round.challenge.options
 }
 for _,uid in ipairs(round.entrants) do
  local p=Players:GetPlayerByUserId(uid)
  if p then event:FireClient(p,"RaceStart",clue,Catalog.list()) end
 end
 broadcast()
 task.delay(60,function() complete(edition) end)
end
schedule=function()
 if round or #queue==0 then return end
 roundNumber+=1
 local participants={}
 for _,uid in ipairs(queue) do
  if Players:GetPlayerByUserId(uid) then table.insert(participants,uid) end
 end
 table.clear(queue)
 if #participants==0 then return end
 round={number=roundNumber,entrants=participants,phase="Registration",
  challenge=Catalog.challenge(rng),results={}}
 broadcast()
 local currentEdition=roundNumber
 task.delay(10,function() start(currentEdition) end)
end
prompt(kiosk,"Join the next reading race",function(p)
 if not closeTo(p,kiosk.Position,18) then return end
 if round then
  if round.phase=="Registration" and not table.find(round.entrants,p.UserId) then
   table.insert(round.entrants,p.UserId)
   broadcast()
  end
 elseif not table.find(queue,p.UserId) then
  table.insert(queue,p.UserId)
  schedule()
 end
end)
event.OnServerEvent:Connect(function(p,action,a,b,c)
 if type(action)~="string" then return end
 local now=os.clock()
 if now-(lastRemote[p] or -100)<0.25 then return end
 lastRemote[p]=now
 if action=="GetCatalog" then
  if closeTo(p,origin,75) then event:FireClient(p,"Catalog",Catalog.list()) end
 elseif action=="RaceAnswer" then
  if not round or round.phase~="Reading" or now>round.deadline then return end
  if not table.find(round.entrants,p.UserId) or round.results[p.UserId] then return end
  if not closeTo(p,origin,75) then return end
  if type(a)~="string" or #a>32 or type(b)~="number" or type(c)~="number" then return end
  if Catalog.check(round.challenge,a,b,c) then
   round.results[p.UserId]={time=now-round.started}
   event:FireClient(p,"RaceCorrect",round.results[p.UserId].time)
   if #winnerSorted()==#round.entrants then complete(round.number) end
  else
   event:FireClient(p,"RaceIncorrect")
  end
 end
end)
Players.PlayerRemoving:Connect(function(p)
 lastRemote[p]=nil
 removeAll(queue,p.UserId)
 if round then removeAll(round.entrants,p.UserId) end
end)
broadcast()
print("[YUGATNEO] Library loaded: books, pixel art, note-taking interface hook, reading races and rewards.")
