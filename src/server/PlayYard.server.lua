-- Cooperative playground: optional Tag and Hide & Seek (no damage, no purchases).
-- One local-server session at a time; every player may withdraw at any time.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Rewards=require(script.Parent:WaitForChild("RewardService"))
local event=RS:FindFirstChild("PlayYardEvent") or Instance.new("RemoteEvent")
event.Name="PlayYardEvent"
event.Parent=RS
local folder=Instance.new("Folder")
folder.Name="YUGATNEO_PLAY_YARD"
folder.Parent=workspace
local CENTER=Vector3.new(-155,0,130)
local queued={Tag={},Hide={}}
local running=nil
local cooldown={}
local function part(name,size,at,color)
    local p=Instance.new("Part")
    p.Name=name
    p.Size=size
    p.Position=at
    p.Anchored=true
    p.Material=Enum.Material.Metal
    p.Color=color
    p.Parent=folder
    return p
end
part("PlayYardBase",Vector3.new(110,2,95),CENTER+Vector3.new(0,-1.5,0),Color3.fromRGB(15,44,51))
for _,x in ipairs({-54,54}) do part("WallX",Vector3.new(2,15,95),CENTER+Vector3.new(x,7,0),Color3.fromRGB(35,72,80)) end
for _,z in ipairs({-47,47}) do part("WallZ",Vector3.new(110,15,2),CENTER+Vector3.new(0,7,z),Color3.fromRGB(35,72,80)) end
for i=1,13 do
    local x=-40+((i*17)%80)
    local z=-29+((i*29)%65)
    part("Cover_"..i,Vector3.new(8+(i%3)*3,9,6+(i%2)*5),CENTER+Vector3.new(x,4,z),Color3.fromRGB(36+(i*8)%50,44,85+(i*13)%70))
end
-- Walkable portal from the main city: no vehicle hazards inside the arena.
local departure=part("PlayYardPortal",Vector3.new(8,.6,8),Vector3.new(-27,1.5,25),Color3.fromRGB(70,250,158))
local portalPrompt=Instance.new("ProximityPrompt")
portalPrompt.ActionText="Visit play yard"
portalPrompt.ObjectText="Tag / Hide and Seek"
portalPrompt.Parent=departure
portalPrompt.Triggered:Connect(function(player)
    local c=player.Character
    local root=c and c:FindFirstChild("HumanoidRootPart")
    if root then root.CFrame=CFrame.new(CENTER+Vector3.new(0,5,-34)) end
end)
local function marker(name,position,label,action)
    local p=part(name,Vector3.new(8,.5,8),position,Color3.fromRGB(64,120,180))
    local prompt=Instance.new("ProximityPrompt")
    prompt.ActionText=label
    prompt.ObjectText="YUGATNEO"
    prompt.Parent=p
    return prompt
end
local tagPrompt=marker("TagSignup",CENTER+Vector3.new(-18,.4,-36),"Join tag","Tag")
local hidePrompt=marker("HideSignup",CENTER+Vector3.new(18,.4,-36),"Join hide and seek","Hide")
local exitPrompt=marker("ExitYard",CENTER+Vector3.new(42,.4,-37),"Back to Matrix","Exit")
local function participant(player)
    return running and running.players[player.UserId] ~= nil
end
local function leave(player)
    for _,list in pairs(queued) do
        for i=#list,1,-1 do if list[i]==player.UserId then table.remove(list,i) end end
    end
    if participant(player) then
        local role=running.players[player.UserId]
        running.players[player.UserId]=nil
        if role=="Seeker" or role=="It" then running.ended=true end
    end
    local c=player.Character
    local root=c and c:FindFirstChild("HumanoidRootPart")
    if root then root.Anchored=false end
    event:FireClient(player,"Exited")
end
exitPrompt.Triggered:Connect(function(player)
    leave(player)
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root then root.CFrame=CFrame.new(0,7,12) end
end)
local function near(player)
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    return root and (root.Position-CENTER).Magnitude<80
end
local function alivePlayer(id)
    local p=Players:GetPlayerByUserId(id)
    local h=p and p.Character and p.Character:FindFirstChildOfClass("Humanoid")
    return p and h and h.Health>0 and near(p) and p or nil
end
local function send(s,message)
    for id in pairs(s.players) do
        local p=Players:GetPlayerByUserId(id)
        if p then event:FireClient(p,"Status",{mode=s.mode,phase=s.phase,
            message=message or "",remaining=math.max(0,math.ceil(s.untilTime-os.clock())),
            role=s.players[id],captures=s.captures[id] or 0}) end
    end
end
local function finish(s,who)
    if running~=s then return end
    for id,role in pairs(s.players) do
        local p=Players:GetPlayerByUserId(id)
        if p then
            local h=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if h then h.Anchored=false end
            if s.mode=="Hide" and role=="Hidden" then
                Rewards.awardOnce(p,"play_hide_survivor",10)
            elseif s.mode=="Tag" and (s.captures[id] or 0)>0 then
                Rewards.awardOnce(p,"play_first_tag",10)
            end
            event:FireClient(p,"End",who or "Round completed")
        end
    end
    running=nil
end
local function start(mode)
    if running then return end
    local minimum=mode=="Hide" and 3 or 2
    local queue=queued[mode]
    if #queue<minimum then return end
    local selected={}
    local maxPlayers=math.min(#queue,10)
    while #selected<maxPlayers do
        local id=table.remove(queue,1)
        if alivePlayer(id) then table.insert(selected,id) end
    end
    if #selected<minimum then return end
    local state={mode=mode,players={},captures={},phase=mode=="Hide" and "Hiding" or "Playing",
        untilTime=os.clock()+(mode=="Hide" and 15 or 65),ended=false,lastTouch=0}
    running=state
    local seeker=selected[math.random(1,#selected)]
    state.leader=seeker
    for i,id in ipairs(selected) do
        state.players[id]=id==seeker and (mode=="Hide" and "Seeker" or "It") or
            (mode=="Hide" and "Hidden" or "Runner")
        local player=Players:GetPlayerByUserId(id)
        if player then
            local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame=CFrame.new(CENTER+Vector3.new((i%5)*7-14,5,-30))
                root.Anchored=mode=="Hide" and id==seeker
            end
        end
    end
    send(state,mode=="Hide" and "Hide while the seeker waits." or "Tag the runner!")
end
local function join(player,mode)
    if not near(player) or player:GetAttribute("InChessMatch") or running then return end
    for _,queue in pairs(queued) do if table.find(queue,player.UserId) then return end end
    table.insert(queued[mode],player.UserId)
    event:FireClient(player,"Queued",mode,#queued[mode])
    start(mode)
end
tagPrompt.Triggered:Connect(function(p) join(p,"Tag") end)
hidePrompt.Triggered:Connect(function(p) join(p,"Hide") end)
event.OnServerEvent:Connect(function(p,action)
    if action~="Leave" then return end
    local t=os.clock()
    if t-(cooldown[p] or -100)<1 then return end
    cooldown[p]=t
    leave(p)
end)
local accum=0
RunService.Heartbeat:Connect(function(dt)
    accum+=dt
    if accum<.25 then return end
    accum=0
    local s=running
    if not s then return end
    local now=os.clock()
    if s.ended then finish(s,"Round stopped") return end
    if s.mode=="Hide" and s.phase=="Hiding" and now>=s.untilTime then
        s.phase="Seeking"
        s.untilTime=now+75
        local p=alivePlayer(s.leader)
        local root=p and p.Character:FindFirstChild("HumanoidRootPart")
        if root then root.Anchored=false end
    end
    if now>=s.untilTime then
        finish(s,s.mode=="Hide" and "Hiders survived" or "Tag time finished")
        return
    end
    if now-s.lastTouch<1.4 then return end
    local leader=alivePlayer(s.leader)
    local leadRoot=leader and leader.Character:FindFirstChild("HumanoidRootPart")
    if leadRoot and s.phase~="Hiding" then
        local survivors=0
        for id,role in pairs(s.players) do
            if id~=s.leader and (role=="Runner" or role=="Hidden") then
                local p=alivePlayer(id)
                if p then
                    survivors+=1
                    local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                    if root and (root.Position-leadRoot.Position).Magnitude<5.5 then
                        -- Prevent tagging through solid obstacles.
                        local params=RaycastParams.new()
                        params.FilterType=Enum.RaycastFilterType.Exclude
                        params.FilterDescendantsInstances={leader.Character}
                        local ray=workspace:Raycast(leadRoot.Position,root.Position-leadRoot.Position,params)
                        if not ray or ray.Instance:IsDescendantOf(p.Character) then
                            if s.mode=="Tag" then
                                s.players[s.leader]="Runner"
                                s.players[id]="It"
                                s.captures[s.leader]=(s.captures[s.leader] or 0)+1
                                s.leader=id
                            else
                                s.players[id]="Caught"
                            end
                            s.lastTouch=now
                            break
                        end
                    end
                end
            end
        end
        if s.mode=="Hide" and survivors==0 then finish(s,"Seeker found everybody") return end
    end
    send(s)
end)
Players.PlayerRemoving:Connect(function(player) leave(player) cooldown[player]=nil end)
print("[YUGATNEO] Optional no-damage tag and hide/seek play yard ready.")
