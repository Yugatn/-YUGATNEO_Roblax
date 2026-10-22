-- YUGATNEO integrated chess server. MatchTable validates moves; queues never trust client claims.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MatchTable = require(script.Parent:WaitForChild("MatchTable"))
local TournamentHub = require(script.Parent:WaitForChild("TournamentHub"))
local Rankings = require(script.Parent:WaitForChild("Rankings"))

for _, item in ipairs(workspace:GetChildren()) do
    if item.Name:match("^Table_") then item:Destroy() end
end
local event = ReplicatedStorage:FindFirstChild("ChessControlEvent") or Instance.new("RemoteEvent")
event.Name = "ChessControlEvent"
event.Parent = ReplicatedStorage
local games, membership, limit = {}, {}, {}
local hub
local global = {}

local board = Instance.new("Part")
board.Name = "YUGATNEO_TournamentScreen"
board.Anchored = true
board.CanCollide = false
board.Material = Enum.Material.Metal
board.Color = Color3.fromRGB(7, 16, 31)
board.Position = Vector3.new(500, 12, -53)
board.Size = Vector3.new(32, 17, 0.5)
board.Parent = workspace
local surface = Instance.new("SurfaceGui")
surface.Face = Enum.NormalId.Front
surface.PixelsPerStud = 45
surface.Parent = board
local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(70, 245, 218)
label.Font = Enum.Font.GothamBold
label.TextSize = 25
label.TextWrapped = true
label.TextYAlignment = Enum.TextYAlignment.Top
label.Parent = surface

local function publish()
    if not hub then return end
    local s = hub:snapshot()
    local lines = {
        "YUGATNEO / CHESS DIMENSION",
        "CASUAL WAITING: " .. s.casual .. "   TOURNEY WAITING: " .. s.signedUp,
        "Stage: " .. s.stage
    }
    if s.first then
        table.insert(lines, s.first .. "  /  " .. s.winner1)
        table.insert(lines, s.second .. "  /  " .. s.winner2)
    else
        table.insert(lines, "4 players = 2 semifinals + final")
    end
    if s.champion then table.insert(lines, "CHAMPION: " .. s.champion) end
    table.insert(lines, "SERVER VICTORIES")
    local session = Rankings.session()
    for i, entry in ipairs(session) do
        if i > 5 then break end
        table.insert(lines, tostring(i) .. ". " .. entry.name .. ": " .. entry.wins)
    end
    label.Text = table.concat(lines, "\n")
    event:FireAllClients("Community", nil, {
        casual = s.casual,
        waitingTournament = s.signedUp,
        bracket = s,
        session = session,
        global = global,
    })
end

local function assign(player, tableId)
    membership[player.UserId] = tableId
    player:SetAttribute("InChessMatch", tableId ~= nil)
end
for _, conf in ipairs({
    {id = "1", position = Vector3.new(447, 1, 0)},
    {id = "2", position = Vector3.new(500, 1, 0)},
    {id = "3", position = Vector3.new(553, 1, 0)},
}) do
    games[conf.id] = MatchTable.new({
        tableId = conf.id,
        origin = conf.position,
        event = event,
        queueOnly = true,
        onJoin = function(p, id) assign(p, id) end,
        onLeave = function(p) assign(p, nil) end,
        onFinish = function(result)
            task.defer(function()
                if hub then Rankings.awardWinner(hub:finished(result)) end
                publish()
            end)
        end,
    })
end
hub = TournamentHub.new(games, membership, event, publish)

local function queuePad(name, x, message, tournament, tint)
    local pad = Instance.new("Part")
    pad.Name = name
    pad.Size = Vector3.new(9, 0.5, 9)
    pad.Position = Vector3.new(x, 0.55, 55)
    pad.Color = tint
    pad.Material = Enum.Material.Neon
    pad.Anchored = true
    pad.Parent = workspace
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = message
    prompt.ObjectText = "Chess Dimension"
    prompt.HoldDuration = 0.2
    prompt.RequiresLineOfSight = false
    prompt.Parent = pad
    prompt.Triggered:Connect(function(player) hub:join(player, tournament) end)
end
queuePad("CasualQueue", 480, "Join casual queue", false, Color3.fromRGB(30, 155, 200))
queuePad("TournamentQueue", 520, "Join tournament", true, Color3.fromRGB(125, 65, 215))

event.OnServerEvent:Connect(function(player, action, ...)
    if type(action) ~= "string" then return end
    local now, uid = os.clock(), player.UserId
    if now - (limit[uid] or -100) < 0.12 then return end
    limit[uid] = now
    local args = {...}
    if action == "QueueCasual" or action == "QueueTournament" then
        hub:join(player, action == "QueueTournament")
    elseif action == "LeaveQueue" then
        hub:leave(uid)
    elseif action == "ListTables" then
        local list = {}
        for i = 1, 3 do table.insert(list, games[tostring(i)]:getPublicState()) end
        event:FireClient(player, "Tables", nil, list)
        publish()
    elseif action == "Spectate" and not membership[uid] then
        local gameTable = games[tostring(args[1])]
        if gameTable then event:FireClient(player, "SpectateTable", gameTable.tableId, gameTable:getPublicState()) end
    else
        local t = membership[uid] and games[membership[uid]]
        if not t then return end
        if action == "Cancel" then t:cancelWaiting(player)
        elseif action == "Ready" then t:setReady(player, args[1] ~= false)
        elseif action == "Resign" then t:resign(player)
        elseif action == "Draw" then t:offerDraw(player)
        elseif action == "ClaimDraw" then t:claimDraw(player)
        elseif action == "ClearFinished" then t:clearFinished(player)
        elseif action == "Deselect" then t:deselect(player)
        elseif action == "Promote" then
            local choice = args[1]
            if choice == "Queen" or choice == "Rook" or choice == "Bishop" or choice == "Knight" then
                t:promote(player, choice)
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    hub:leave(player.UserId)
    local gameTable = membership[player.UserId] and games[membership[player.UserId]]
    if gameTable then gameTable:handleDisconnect(player.UserId) end
    membership[player.UserId] = nil
    limit[player.UserId] = nil
    task.defer(publish)
end)

task.spawn(function()
    while true do
        global = Rankings.globalTop()
        publish()
        task.wait(120)
    end
end)
task.defer(publish)
print("[YUGATNEO] Three chess tables, tournament pairing, queues and rankings initialized.")
