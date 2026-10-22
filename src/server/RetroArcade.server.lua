-- An original retro cabinet hub: 8-bit-style Snake and 16-bit-inspired friendly duel.
-- Do not load ROMs or commercial assets. Both modes run inside Roblox.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Retro=require(script.Parent:WaitForChild("RetroEngine"))
local Rewards=require(script.Parent:WaitForChild("RewardService"))
local event=RS:FindFirstChild("RetroEvent") or Instance.new("RemoteEvent")
event.Name="RetroEvent"
event.Parent=RS

local world=Instance.new("Folder")
world.Name="YUGATNEO_RETRO_ARCADE"
world.Parent=workspace
local cabinets={
    Snake=Vector3.new(77,4,53),
    Duel=Vector3.new(120,4,53),
}
local snakes, duelQueue, duel, lastAction, duck={}, {}, nil, {}, {}
local rng=Random.new()
local function closeTo(p,point,distance)
    if p:GetAttribute("InChessMatch") then return false end
    local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
    return root and (root.Position-point).Magnitude<distance
end
local function makeCabinet(name,at,color)
    local model=Instance.new("Part")
    model.Name=name.."Cabinet"
    model.Size=Vector3.new(8,8,5)
    model.Position=at
    model.Color=color
    model.Anchored=true
    model.Material=Enum.Material.Metal
    model.Parent=world
    local panel=Instance.new("SurfaceGui")
    panel.Face=Enum.NormalId.Front
    panel.PixelsPerStud=45
    panel.Parent=model
    local text=Instance.new("TextLabel")
    text.Size=UDim2.fromScale(1,1)
    text.BackgroundTransparency=1
    text.TextScaled=true
    text.TextWrapped=true
    text.Font=Enum.Font.Arcade
    text.TextColor3=Color3.fromRGB(208,255,211)
    text.Text=name=="Snake" and "8-BIT\nPIXEL SERPENT\nPRESS E TO PLAY" or
        "16-BIT\nFRIENDLY DUEL\nPRESS E TO JOIN"
    text.Parent=panel
    local prompt=Instance.new("ProximityPrompt")
    prompt.ActionText=name=="Snake" and "Play 8-bit" or "Join duel"
    prompt.ObjectText=name=="Snake" and "Pixel Serpent" or "Friendly Duel"
    prompt.HoldDuration=.3
    prompt.MaxActivationDistance=12
    prompt.Parent=model
    return prompt
end
local snakePrompt=makeCabinet("Snake",cabinets.Snake,Color3.fromRGB(39,125,75))
local duelPrompt=makeCabinet("Duel",cabinets.Duel,Color3.fromRGB(125,55,140))

local function beginSnake(player)
    if not closeTo(player,cabinets.Snake,23) or snakes[player] then return end
    snakes[player]={state=Retro.newSnake(rng),lastMove=0,lastTurn=-100,at=os.clock()}
    event:FireClient(player,"SnakeStart",snakes[player].state)
end
snakePrompt.Triggered:Connect(beginSnake)

local function duelFor(player)
    if not duel then return nil end
    if duel.players[1]==player.UserId then return 1 end
    if duel.players[2]==player.UserId then return 2 end
    return nil
end
local function publishDuel()
    if not duel then return end
    local state=Retro.publicDuel(duel)
    for _,uid in ipairs(duel.players) do
        local p=Players:GetPlayerByUserId(uid)
        if p then event:FireClient(p,"DuelState",state) end
    end
end
local function tryDuel()
    if duel or #duelQueue<2 then return end
    local a,b=table.remove(duelQueue,1),table.remove(duelQueue,1)
    local p1,p2=Players:GetPlayerByUserId(a),Players:GetPlayerByUserId(b)
    if not p1 or not p2 then return end
    if not closeTo(p1,cabinets.Duel,70) or not closeTo(p2,cabinets.Duel,70) then return end
    duel=Retro.newDuel(a,b,false)
    event:FireClient(p1,"DuelStart",1,Retro.publicDuel(duel))
    event:FireClient(p2,"DuelStart",2,Retro.publicDuel(duel))
    publishDuel()
end
duelPrompt.Triggered:Connect(function(player)
    if not closeTo(player,cabinets.Duel,23) or snakes[player] then return end
    if duelFor(player) then return end
    if not table.find(duelQueue,player.UserId) then
        table.insert(duelQueue,player.UserId)
        event:FireClient(player,"Notice","Waiting for another player at the duel cabinet")
    end
    tryDuel()
end)

event.OnServerEvent:Connect(function(player,action,arg)
    if type(action)~="string" then return end
    local now=os.clock()
    if now-(lastAction[player] or -100)<.075 then return end
    lastAction[player]=now
    if action=="SnakeTurn" then
        local session=snakes[player]
        if session and now-session.lastTurn>.11 then
            session.lastTurn=now
            Retro.turnSnake(session.state,arg)
        end
    elseif action=="SnakeExit" then
        snakes[player]=nil
    elseif action=="DuelMove" then
        local index=duelFor(player)
        if index and closeTo(player,cabinets.Duel,100) then
            if Retro.actDuel(duel,index,arg,now) then
                publishDuel()
            end
        end
    elseif action=="DuelExit" then
        for i=#duelQueue,1,-1 do
            if duelQueue[i]==player.UserId then table.remove(duelQueue,i) end
        end
        if duelFor(player) then
            duel.ended=true
            local winner=3-duelFor(player)
            duel.victor=winner
            publishDuel()
            duel=nil
        end
    end
end)

local tickAccum=0
RunService.Heartbeat:Connect(function(dt)
    tickAccum+=dt
    if tickAccum<.18 then return end
    tickAccum=0
    for player,session in pairs(snakes) do
        if not closeTo(player,cabinets.Snake,70) then snakes[player]=nil continue end
        Retro.stepSnake(session.state,rng)
        event:FireClient(player,"SnakeState",session.state)
        if not session.state.alive then
            if session.state.score>=30 then
                Rewards.awardOnce(player,"retro_snake_30",20)
            end
            snakes[player]=nil
        end
    end
    if duel then
        Retro.timeoutDuel(duel,os.clock())
        if duel.ended then
            publishDuel()
            local winner=duel.victor and Players:GetPlayerByUserId(duel.players[duel.victor])
            if winner then Rewards.awardOnce(winner,"retro_duel_first_win",20) end
            duel=nil
        end
    end
end)
Players.PlayerRemoving:Connect(function(p)
    snakes[p]=nil
    for i=#duelQueue,1,-1 do if duelQueue[i]==p.UserId then table.remove(duelQueue,i) end end
    if duelFor(p) then duel=nil end
    lastAction[p]=nil
end)
print("[YUGATNEO] Original Snake and friendly 2-player retro duel available.")
