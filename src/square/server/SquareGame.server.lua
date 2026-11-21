--!strict
-- Four-square football. Server-authoritative arcade bounce simulation.
-- Stand-alone Roblox Place: square.project.json.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("SquareShared"):WaitForChild("SquareConfig"))
local Rules = require(script.Parent:WaitForChild("SquareRules"))
local state = Rules.new()
local groundY = Config.ballRadius + 0.12

local arena = Instance.new("Folder")
arena.Name = "FourSquareFootball"
arena.Parent = Workspace

local remoteFolder = Instance.new("Folder")
remoteFolder.Name = "SquareRemotes"
remoteFolder.Parent = ReplicatedStorage

local actionRemote = Instance.new("RemoteEvent")
actionRemote.Name = "Strike"
actionRemote.Parent = remoteFolder

local updateRemote = Instance.new("RemoteEvent")
updateRemote.Name = "Scoreboard"
updateRemote.Parent = remoteFolder

local getState = Instance.new("RemoteFunction")
getState.Name = "GetState"
getState.Parent = remoteFolder

local function makePart(name, size, position, color, material, canCollide)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Anchored = true
    p.CanCollide = canCollide ~= false
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Position = position
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.Parent = arena
    return p
end

local function sign(part, text, offset, size)
    local gui = Instance.new("BillboardGui")
    gui.Name = "Notice"
    gui.Size = size or UDim2.fromOffset(230, 66)
    gui.StudsOffsetWorldSpace = offset or Vector3.new(0, 4, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 110
    gui.Adornee = part
    gui.Parent = part
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.BackgroundColor3 = Color3.fromRGB(27, 31, 41)
    label.BackgroundTransparency = 0.08
    label.TextScaled = true
    label.TextWrapped = true
    label.Font = Enum.Font.GothamBold
    label.Parent = gui
    local radius = Instance.new("UICorner")
    radius.CornerRadius = UDim.new(0, 10)
    radius.Parent = label
end

-- A single flat asphalt field with visually distinct four square zones.
makePart("Asphalt", Vector3.new(82, 1, 82), Vector3.new(0, -0.5, 0),
    Color3.fromRGB(45, 47, 53), Enum.Material.Asphalt, true)
makePart("SafeWalkway", Vector3.new(112, 1, 112), Vector3.new(0, -1.2, 0),
    Color3.fromRGB(30, 36, 43), Enum.Material.Concrete, true)

for seat=1,4 do
    local center = Config.squareCenters[seat]
    local tint = makePart("Zone_" .. seat, Vector3.new(39.5, 0.08, 39.5),
        Vector3.new(center.X, 0.065, center.Z), Config.colors[seat],
        Enum.Material.SmoothPlastic, false)
    tint.Transparency = 0.78
    local marker = makePart("Number_" .. seat, Vector3.new(5, 0.12, 5),
        Vector3.new(center.X + (if center.X<0 then -11 else 11), 0.13, center.Z +
            (if center.Z<0 then -11 else 11)), Config.colors[seat], Enum.Material.Neon, false)
    sign(marker, "Игрок " .. seat, Vector3.new(0, 3.2, 0), UDim2.fromOffset(150, 48))
end

local function stripe(name, size, x, z, color)
    return makePart(name, size, Vector3.new(x, 0.15, z), color, Enum.Material.SmoothPlastic, false)
end
local white = Color3.fromRGB(247, 248, 252)
stripe("NorthLine", Vector3.new(82, 0.2, 0.55), 0, -40, white)
stripe("SouthLine", Vector3.new(82, 0.2, 0.55), 0, 40, white)
stripe("WestLine", Vector3.new(0.55, 0.2, 82), -40, 0, white)
stripe("EastLine", Vector3.new(0.55, 0.2, 82), 40, 0, white)
stripe("Divider_NS", Vector3.new(0.55, 0.2, 80), 0, 0, white)
stripe("Divider_EW", Vector3.new(80, 0.2, 0.55), 0, 0, white)
stripe("PenaltyCenter", Vector3.new(8, 0.23, 8), 0, 0, Color3.fromRGB(204, 52, 60))

local ball = makePart("Football", Vector3.new(Config.ballRadius * 2,
    Config.ballRadius * 2, Config.ballRadius * 2),
    Vector3.new(0, groundY, 0), Color3.fromRGB(248, 248, 245),
    Enum.Material.SmoothPlastic, false)
ball.Shape = Enum.PartType.Ball
ball:SetAttribute("GameBall", true)
-- Black patches welded to the server-controlled, anchored soccer ball.
for patchIndex, axis in ipairs({
    Vector3.new(1,0,0), Vector3.new(-1,0,0),
    Vector3.new(0,1,0), Vector3.new(0,-1,0),
    Vector3.new(0,0,1), Vector3.new(0,0,-1),
}) do
    local patch = Instance.new("Part")
    patch.Name = "BlackPatch_" .. patchIndex
    patch.Size = Vector3.new(0.68,0.68,0.68)
    patch.Shape = Enum.PartType.Ball
    patch.CanCollide = false
    patch.CanTouch = false
    patch.Massless = true
    patch.Color = Color3.fromRGB(24, 29, 34)
    patch.Material = Enum.Material.SmoothPlastic
    patch.Position = ball.Position + axis * 1.17
    patch.Parent = arena
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = ball
    weld.Part1 = patch
    weld.Parent = patch
end

local spectatorSpawn = Instance.new("SpawnLocation")
spectatorSpawn.Name = "StagingSpawn"
spectatorSpawn.Anchored = true
spectatorSpawn.Neutral = true
spectatorSpawn.Size = Vector3.new(13,1,13)
spectatorSpawn.Position = Vector3.new(0, 1, -51)
spectatorSpawn.Color = Color3.fromRGB(127, 134, 147)
spectatorSpawn.Parent = arena
local guide = makePart("RulesSign", Vector3.new(16, 10, 2),
    Vector3.new(0, 5, -60), Color3.fromRGB(38, 57, 76), Enum.Material.Metal, true)
sign(guide, "КВАДРАТ · ФУТБОЛ\n4 игрока · до 5 голов", Vector3.new(0, 8, 0), UDim2.fromOffset(400, 86))

local lastActionAt = {}
local motion = {t=0, start=ball.Position, finish=ball.Position, height=9, goalZone=0}
local pauseToken = 0
local restartToken = 0
local syncStarted = false

local function seatPosition(seat)
    local center = Config.squareCenters[seat]
    return Vector3.new(center.X, 3.5, center.Z)
end

local function moveAvatar(player)
    local character = player.Character
    if not character then return end
    local seat = Rules.seatOf(state, player.UserId)
    character:PivotTo(CFrame.new(if seat > 0 then seatPosition(seat)
        else Vector3.new(0, 4, -50)))
end

local function broadcast()
    for _, player in ipairs(Players:GetPlayers()) do
        updateRemote:FireClient(player, Rules.status(state, player.UserId))
    end
end

getState.OnServerInvoke = function(player)
    return Rules.status(state, player.UserId)
end

local function setBall(position)
    ball.CFrame = CFrame.new(position)
end

local function placeForServe()
    if state.phase ~= "serve" or state.server == 0 then return end
    local home = Config.squareCenters[state.server]
    setBall(Vector3.new(home.X + 3, groundY, home.Z))
end

local function launch(target)
    local destination = if target == 0 then Vector3.new(0, groundY, 0)
        else Config.squareCenters[target] + Vector3.new(3, groundY, 3)
    motion.t = 0
    motion.start = ball.Position
    motion.finish = destination
    motion.height = if state.lastHit == "head" then 12 else 8.5
    motion.goalZone = target
    broadcast()
end

local function startMatch()
    if Rules.start(state) then
        placeForServe()
        broadcast()
        return true
    end
    broadcast()
    return false
end

local function scheduleAfterFinished()
    restartToken += 1
    local token = restartToken
    task.delay(9, function()
        if token ~= restartToken or state.phase ~= "finished" then return end
        local full = true
        for i=1,4 do if state.players[i]==nil then full = false end end
        if full then
            startMatch()
        else
            state.phase = "waiting"
            state.message = "Нужны четыре игрока для новой партии."
            state.revision += 1
            broadcast()
        end
    end)
end

local function scheduleAfterPenalty(offender)
    broadcast()
    if state.phase == "finished" then
        scheduleAfterFinished()
        return
    end
    pauseToken += 1
    local token = pauseToken
    task.delay(2.2, function()
        if token ~= pauseToken or state.phase ~= "pause" then return end
        -- Conceder serves next, unless eliminated; then rotate to another live player.
        local preferred = if Rules.nextSeat(state, offender) == offender then offender
            else Rules.nextSeat(state, offender + 1)
        if Rules.beginServe(state, preferred) then placeForServe() end
        broadcast()
    end)
end

local function contact(pointZone)
    local result = Rules.bounce(state, pointZone)
    if result == "fault" or result == "goal" then
        scheduleAfterPenalty(state.receiver)
    elseif result == "continue" then
        motion.t = 0
        motion.start = Vector3.new(ball.Position.X, groundY, ball.Position.Z)
        motion.finish = motion.start
        broadcast()
    end
end

local function inPlayZone(playerSeat, point)
    local zone = Config.zone(point.X, point.Z)
    if zone == playerSeat then return true end
    -- Chasing is permitted outside the board only after this player's own bounce.
    if zone == 0 and state.lastBounceZone == playerSeat then
        local own = Config.squareCenters[playerSeat]
        return math.abs(point.X - own.X) <= 55 and math.abs(point.Z - own.Z) <= 55
    end
    return false
end

local function eligibleContact(player, seat, kind)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then return false end
    local ownZone = Config.zone(root.Position.X, root.Position.Z)
    if not inPlayZone(seat, root.Position) then return false end
    local distance = (root.Position - ball.Position).Magnitude
    if distance > Config.hitRadius then return false end
    if kind == "head" then
        local head = character:FindFirstChild("Head")
        if not head or (head.Position-ball.Position).Magnitude > 10
            or ball.Position.Y < Config.headHeight then return false end
    elseif kind == "foot" then
        if ball.Position.Y > Config.ballRadius + 5 then return false end
    elseif kind == "serve" then
        if ownZone ~= seat then return false end
    end
    -- A kick/head is legal only if the ball is currently in the defender's court,
    -- or the ball bounced there and is being chased outside the court.
    if kind ~= "serve" then
        local ballZone = Config.zone(ball.Position.X, ball.Position.Z)
        if ballZone ~= seat and not (ballZone == 0 and state.lastBounceZone == seat) then
            return false
        end
    end
    return true
end

actionRemote.OnServerEvent:Connect(function(player, kind, target)
    if type(kind) ~= "string" or not ({serve=true, foot=true, head=true})[kind]
        or type(target) ~= "number" or target ~= math.floor(target)
        or target < 0 or target > 4 then return end
    local now = os.clock()
    if now-(lastActionAt[player.UserId] or -999) < Config.cooldown then return end
    lastActionAt[player.UserId] = now
    local seat = Rules.seatOf(state, player.UserId)
    if seat == 0 or not eligibleContact(player, seat, kind) then return end
    local ok, reason = Rules.hit(state, seat, kind, target)
    if not ok then
        if reason == "early_foot" then
            Rules.penalty(state, seat, "Удар ногой до необходимого отскока", true)
            scheduleAfterPenalty(seat)
        end
        return
    end
    launch(state.receiver)
end)

RunService.Heartbeat:Connect(function(dt)
    if state.phase ~= "flight" and state.phase ~= "bounce" then return end
    local duration = if state.phase == "flight" then Config.flightDuration
        else Config.bounceDuration
    motion.t = math.min(1, motion.t + math.min(dt, 0.08) / duration)
    local a = motion.t
    local ground = Vector3.new(
        motion.start.X + (motion.finish.X-motion.start.X)*a,
        groundY,
        motion.start.Z + (motion.finish.Z-motion.start.Z)*a)
    local yBase = motion.start.Y*(1-a) + groundY*a
    local height = if state.phase=="flight" then motion.height
        else math.max(2.6, 6.0 - state.bounceCount*1.3)
    setBall(Vector3.new(ground.X,
        yBase + math.sin(math.pi*a)*height, ground.Z))
    if a >= 1 then
        setBall(Vector3.new(ground.X, groundY, ground.Z))
        contact(Config.zone(ground.X, ground.Z))
    end
end)

local function bindPlayer(player)
    local seat = Rules.join(state, player.UserId)
    if seat > 0 then
        state.message = "Игрок " .. seat .. " занял квадрат. " .. state.message
    end
    player.CharacterAdded:Connect(function(character)
        local root = character:WaitForChild("HumanoidRootPart", 10)
        if root and player.Character == character then
            task.defer(moveAvatar, player)
        end
    end)
    if player.Character then task.defer(moveAvatar, player) end
    if state.phase == "waiting" then
        local full = true
        for i=1,4 do if state.players[i]==nil then full=false end end
        if full then startMatch() else broadcast() end
    else
        broadcast()
    end
end

Players.PlayerAdded:Connect(bindPlayer)
for _, player in ipairs(Players:GetPlayers()) do bindPlayer(player) end

Players.PlayerRemoving:Connect(function(player)
    lastActionAt[player.UserId] = nil
    local seat = Rules.leave(state, player.UserId)
    if seat == 0 then return end
    local active, winner = Rules.activeCount(state)
    if state.phase ~= "waiting" and state.phase ~= "finished" and active <= 1 then
        state.phase = "finished"
        state.winner = winner
        state.message = "Игрок покинул матч." ..
            (if winner > 0 then " Победил игрок " .. winner .. "!" else "")
        state.revision += 1
        scheduleAfterFinished()
    elseif state.phase == "flight" or state.phase == "bounce" or state.phase == "serve" then
        if state.receiver == seat or state.server == seat or state.lastHitter == seat then
            pauseToken += 1
            state.phase = "pause"
            state.message = "Игрок покинул матч. Подготавливается новая подача."
            state.revision += 1
            scheduleAfterPenalty(Rules.nextSeat(state, seat+1))
        end
    end
    broadcast()
end)

print("FOUR SQUARE: server-controlled football court and referee initialized.")
