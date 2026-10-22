-- YUGATNEO Library: an optional shared reading room, private notes, text search race,
-- comprehension quiz, and server-issued cosmetic currency. No unlicensed book excerpts.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local DataStoreService=game:GetService("DataStoreService")
local TextService=game:GetService("TextService")
local Books=require(script.Parent:WaitForChild("BookCatalog"))
local Rewards=require(script.Parent:WaitForChild("RewardService"))
local remote=RS:FindFirstChild("LibraryEvent") or Instance.new("RemoteEvent")
remote.Name="LibraryEvent"
remote.Parent=RS
local notesStore=DataStoreService:GetDataStore("YUGATNEO_LIBRARY_NOTES_V1")
local world=Instance.new("Folder")
world.Name="YUGATNEO_LIBRARY"
world.Parent=workspace
local CENTER=Vector3.new(110,0,-85)
local savedNotes, round, sessionBest, lastAction, saving={},{},{},{},{}
local function make(name,size,position,color,mat)
    local p=Instance.new("Part")
    p.Name=name
    p.Size=size
    p.Position=position
    p.Anchored=true
    p.Material=mat or Enum.Material.Metal
    p.Color=color
    p.Parent=world
    return p
end
local function hologram(part,message,width)
    local g=Instance.new("BillboardGui")
    g.AlwaysOnTop=true
    g.MaxDistance=150
    g.Size=UDim2.fromOffset(width or 330,85)
    g.StudsOffset=Vector3.new(0,5,0)
    g.Parent=part
    local label=Instance.new("TextLabel")
    label.Size=UDim2.fromScale(1,1)
    label.BackgroundTransparency=1
    label.Text=message
    label.TextScaled=true
    label.TextWrapped=true
    label.Font=Enum.Font.GothamBold
    label.TextColor3=Color3.fromRGB(91,250,221)
    label.Parent=g
end
local function near(player,maximum)
    local c=player.Character
    local root=c and c:FindFirstChild("HumanoidRootPart")
    local human=c and c:FindFirstChildOfClass("Humanoid")
    return root and human and human.Health>0 and not player:GetAttribute("InChessMatch")
        and (root.Position-CENTER).Magnitude<=maximum
end
make("PathToLibrary",Vector3.new(17,1.5,52),Vector3.new(110,-.8,-32),Color3.fromRGB(10,28,43))
make("LibraryFloor",Vector3.new(80,1.7,67),Vector3.new(110,-1,-86),Color3.fromRGB(13,27,40))
make("BackWall",Vector3.new(80,17,2),Vector3.new(110,8,-119),Color3.fromRGB(17,32,45))
for _,x in ipairs({70,150}) do make("LibrarySide",Vector3.new(2,17,66),Vector3.new(x,8,-86),Color3.fromRGB(17,32,45)) end
local headline=make("LibraryHall",Vector3.new(39,7,2),Vector3.new(110,9,-111),Color3.fromRGB(14,43,53))
headline.CanCollide=false
hologram(headline,"THE LIBRARY OF THE OTHER\nREAD · REMEMBER · UNDERSTAND",700)
local function openBook(player,id)
    if not near(player,75) then return end
    local b=Books.get(id)
    if not b then return end
    local copy={id=b.id, title=b.title, author=b.author, age=b.age,
        language=b.language,genre=b.genre,paragraphs=b.paragraphs}
    local noteData=savedNotes[player] or {}
    remote:FireClient(player,"Book",copy,noteData[id] or "")
end
for i,b in ipairs(Books.list()) do
    local x=81+(i-1)*19.5
    local shelf=make("Bookstand_"..b.id,Vector3.new(11,4,5),Vector3.new(x,2.5,-77),
        i%2==0 and Color3.fromRGB(30,100,128) or Color3.fromRGB(69,69,145))
    hologram(shelf,b.title .. "\n" .. b.age .. " · " .. b.language,260)
    local prompt=Instance.new("ProximityPrompt")
    prompt.ActionText="READ"
    prompt.ObjectText=b.title
    prompt.HoldDuration=.3
    prompt.MaxActivationDistance=12
    prompt.RequiresLineOfSight=false
    prompt.Parent=shelf
    prompt.Triggered:Connect(function(p) openBook(p,b.id) end)
end
-- Three ORIGINAL educational pixel mosaics; not copies of copyrighted paintings.
local artworks={
    {name="Sea and Horizon / art exercise",palette={Color3.fromRGB(18,72,120),Color3.fromRGB(36,145,183),Color3.fromRGB(245,210,110)}},
    {name="Night Sky / art exercise",palette={Color3.fromRGB(20,25,76),Color3.fromRGB(100,72,166),Color3.fromRGB(253,217,119)}},
    {name="Garden / art exercise",palette={Color3.fromRGB(20,91,72),Color3.fromRGB(90,173,115),Color3.fromRGB(235,125,120)}},
}
for n,picture in ipairs(artworks) do
    local x=83+(n-1)*27
    for row=1,8 do
        for col=1,8 do
            local color
            if n==1 then color=picture.palette[row<3 and 3 or row<5 and 2 or 1]
            elseif n==2 then color=picture.palette[((row*3+col*7)%9==0) and 3 or ((row+col)%3==0 and 2 or 1)]
            else color=picture.palette[((row+col)%6==0) and 3 or row<5 and 2 or 1] end
            local pixel=make("Mosaic_"..n.."_"..row.."_"..col,
                Vector3.new(1.75,1.75,.22),
                Vector3.new(x+(col-4.5)*1.75,12-(row-1)*1.75,-117.65),color,Enum.Material.SmoothPlastic)
            pixel.CanCollide=false
        end
    end
end

local function leaderboard()
    local ranking={}
    for uid,data in pairs(sessionBest) do
        for bookId,seconds in pairs(data) do
            local p=Players:GetPlayerByUserId(uid)
            table.insert(ranking,{user=p and p.DisplayName or tostring(uid),
                bookId=bookId,seconds=seconds})
        end
    end
    table.sort(ranking,function(a,b)
        if a.seconds==b.seconds then return a.bookId<b.bookId end
        return a.seconds<b.seconds
    end)
    return ranking
end
local leaderboardAnchor=make("LibraryReadingLeaderboard",
    Vector3.new(1,1,1),Vector3.new(145,7,-103),Color3.fromRGB(23,90,100))
leaderboardAnchor.Transparency=1
leaderboardAnchor.CanCollide=false
local leaderGui=Instance.new("BillboardGui")
leaderGui.Size=UDim2.fromOffset(480,270)
leaderGui.AlwaysOnTop=true
leaderGui.MaxDistance=150
leaderGui.Parent=leaderboardAnchor
local leaderText=Instance.new("TextLabel")
leaderText.Size=UDim2.fromScale(1,1)
leaderText.TextWrapped=true
leaderText.BackgroundColor3=Color3.fromRGB(7,30,46)
leaderText.TextColor3=Color3.fromRGB(250,223,124)
leaderText.Font=Enum.Font.GothamBold
leaderText.TextSize=15
leaderText.Parent=leaderGui
local function shareLeaderboard()
    local records=leaderboard()
    remote:FireAllClients("Leaderboard",records)
    local lines={"READING RACE / SESSION RECORDS"}
    for i,entry in ipairs(records) do
        if i>6 then break end
        table.insert(lines,string.format("%d. %s / %s / %.1fs",i,entry.user,entry.bookId,entry.seconds))
    end
    if #records==0 then table.insert(lines,"Be the first to finish a story!") end
    leaderText.Text=table.concat(lines,"\\n")
end
local function persistNotes(player)
    if saving[player] then return end
    saving[player]=true
    local data=savedNotes[player]
    if data then
        local value={}
        for id,entry in pairs(data) do
            if Books.get(id) and type(entry)=="string" and #entry<=400 then value[id]=entry end
        end
        local ok,err=pcall(function()
            notesStore:UpdateAsync("u_"..player.UserId,function() return value end)
        end)
        if not ok then warn("Library notes persistence unavailable:",err) end
    end
    saving[player]=nil
end
local function join(player)
    local result={}
    local ok,contents=pcall(function() return notesStore:GetAsync("u_"..player.UserId) end)
    if ok and type(contents)=="table" then
        for id,entry in pairs(contents) do
            if Books.get(id) and type(entry)=="string" and #entry<=400 then result[id]=entry end
        end
    end
    if player.Parent then savedNotes[player]=result end
end
Players.PlayerAdded:Connect(function(p) task.spawn(join,p) end)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(join,p) end
remote.OnServerEvent:Connect(function(player,action,id,value)
    if type(action)~="string" or type(id)~="string" or not Books.get(id) then return end
    local now=os.clock()
    if now-(lastAction[player] or -100)<0.18 then return end
    lastAction[player]=now
    if not near(player,75) then return end
    local book=Books.get(id)
    if action=="Open" then openBook(player,id)
    elseif action=="Start" then
        round[player]={bookId=id,at=now,step=1}
        remote:FireClient(player,"Question",{bookId=id,step=1,
            prompt=book.locate,choices={"1","2","3","4"}})
    elseif action=="Answer" then
        local s=round[player]
        if not s or s.bookId~=id or now-s.at>180 or now-s.at<.8 then return end
        if type(value)~="number" or value%1~=0 or value<1 or value>4 then return end
        local expected=s.step==1 and book.locateAnswer or book.understandAnswer
        if value~=expected then
            remote:FireClient(player,"Feedback",false,"Not quite. Try finding the clue in the story.")
            return
        end
        if s.step==1 then
            s.step=2
            remote:FireClient(player,"Question",{bookId=id,step=2,prompt=book.understand,
                choices=book.answers})
        else
            round[player]=nil
            local seconds=math.floor((now-s.at)*10)/10
            sessionBest[player.UserId]=sessionBest[player.UserId] or {}
            local old=sessionBest[player.UserId][id]
            if not old or seconds<old then sessionBest[player.UserId][id]=seconds end
            local earned=Rewards.awardOnce(player,"read_"..id,20)
            remote:FireClient(player,"Completed",{seconds=seconds,reward=earned and 20 or 0})
            shareLeaderboard()
        end
    elseif action=="SaveNote" then
        if type(value)~="string" or #value>350 or #value<1 or not savedNotes[player] then return end
        local ok,filtered=pcall(function()
            local result=TextService:FilterStringAsync(value,player.UserId,Enum.TextFilterContext.PrivateChat)
            return result:GetNonChatStringForUserAsync(player.UserId)
        end)
        if not ok or type(filtered)~="string" or #filtered>400 then
            remote:FireClient(player,"Feedback",false,"Notes filter unavailable; nothing was saved.")
            return
        end
        savedNotes[player][id]=filtered
        task.spawn(persistNotes,player)
        remote:FireClient(player,"Saved",id,filtered)
    end
end)
Players.PlayerRemoving:Connect(function(player)
    persistNotes(player)
    savedNotes[player]=nil
    round[player]=nil
    lastAction[player]=nil
    sessionBest[player.UserId]=nil
end)
game:BindToClose(function()
    for _,player in ipairs(Players:GetPlayers()) do persistNotes(player) end
end)
task.defer(shareLeaderboard)
print("[YUGATNEO] Library open with four original books, private notes and reading races.")
