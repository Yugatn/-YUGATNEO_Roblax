-- Story X / YUGATNEO: cognitive arcade and holographic duck shooting gallery.
-- No player damage; scores and challenge solutions are decided on the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Arcade = require(script.Parent:WaitForChild("ArcadeLibrary"))
local Rewards = require(script.Parent:WaitForChild("RewardService"))

local event = ReplicatedStorage:FindFirstChild("ArcadeEvent") or Instance.new("RemoteEvent")
event.Name = "ArcadeEvent"
event.Parent = ReplicatedStorage
local world = Instance.new("Folder")
world.Name = "YUGATNEO_COGNITIVE_ARCADE"
world.Parent = workspace
local GREEN = Color3.fromRGB(62, 250, 185)
local CYAN = Color3.fromRGB(22, 195, 255)
local GOLD = Color3.fromRGB(245, 200, 90)
local PURPLE = Color3.fromRGB(153, 93, 238)
local NAVY = Color3.fromRGB(10, 23, 42)
local rng = Random.new()
local sessions, playerScores, activeGallery, lastAction = {}, {}, {}, {}
local serial = 0
local plaza = Vector3.new(104, 0, 30)
local duckCenter = Vector3.new(117, 0, 127)

local function part(name, size, position, color, parent)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Position = position
    p.Anchored = true
    p.CanCollide = true
    p.Material = Enum.Material.Metal
    p.Color = color
    p.Parent = parent or world
    return p
end
local function sign(anchor, message)
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.fromOffset(290, 76)
    gui.StudsOffset = Vector3.new(0, 5.5, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 160
    gui.Parent = anchor
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1,1)
    label.BackgroundTransparency = 1
    label.Text = message
    label.TextColor3 = GREEN
    label.Font = Enum.Font.GothamBold
    label.TextWrapped = true
    label.TextScaled = true
    label.Parent = gui
end
local function near(player, center, distance)
    if player:GetAttribute("InChessMatch") then return false end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    return root and humanoid and humanoid.Health > 0
        and (root.Position-center).Magnitude <= distance
end
local function prompt(base, action, caption, fn)
    local p = Instance.new("ProximityPrompt")
    p.ActionText = action
    p.ObjectText = caption
    p.HoldDuration = 0.2
    p.MaxActivationDistance = 12
    p.RequiresLineOfSight = false
    p.Parent = base
    p.Triggered:Connect(function(player)
        if near(player, base.Position, 17) then fn(player) end
    end)
end
-- Main plaza connects physically to Matrix spawn without extra experiences.
part("ArcadePlaza", Vector3.new(99, 1.6, 82), plaza + Vector3.new(0,-1,0), NAVY)
part("ArcadeWalkway", Vector3.new(44, 1.5, 14), Vector3.new(33, -0.65, 12), NAVY)
local header = part("WelcomeArcade", Vector3.new(42, 7, 1), Vector3.new(104, 6, -6), PURPLE)
header.CanCollide = false
sign(header, "YUGATNEO / COGNITIVE ARCADE\nMEMORY · ATTENTION · LOGIC · RETRO")

local catalog = {
    {id = "Memory", label = "MEMORY LAB", color = GREEN},
    {id = "Attention", label = "FOCUS GRID", color = CYAN},
    {id = "Logic", label = "LOGIC PATTERNS", color = GOLD},
    {id = "Switch", label = "FLEXIBLE THINKING", color = PURPLE},
    {id = "Spatial", label = "SPATIAL ROUTES", color = GREEN},
}
local startChallenge
for i, mode in ipairs(catalog) do
    local x = 62 + (i-1)*21
    local terminal = part(mode.id .. "Terminal", Vector3.new(9, 7, 3), Vector3.new(x, 4, 18), mode.color)
    sign(terminal, mode.label)
    prompt(terminal, "PLAY", mode.label, function(player) startChallenge(player, mode.id) end)
end

startChallenge = function(player, mode)
    if not table.find(Arcade.modes, mode) or not near(player, plaza, 86) then return end
    serial += 1
    local id = serial
    local level = math.clamp(math.floor((playerScores[player] or 0)/4)+1, 1, 5)
    local public, secret = Arcade.generate(mode, rng, level)
    local now = os.clock()
    sessions[player] = {
        id = id, secret = secret, mode = mode, start = now,
        earliest = now + (mode == "Memory" and public.visibleSeconds or 0.5),
        expires = now + 65,
    }
    event:FireClient(player, "Challenge", id, public, playerScores[player] or 0)
end

part("GalleryPlatform", Vector3.new(89, 1.5, 102),
    duckCenter + Vector3.new(0, -1, -10), NAVY)
part("GalleryConnector", Vector3.new(14, 1.5, 40), Vector3.new(117, -0.6, 77), NAVY)
local galleryStart = part("DuckGalleryConsole", Vector3.new(10, 6, 4),
    Vector3.new(117, 4, 88), GOLD)
sign(galleryStart, "HOLOGRAPHIC DUCK GALLERY\n45 SEC / TARGET PRACTICE")
prompt(galleryStart, "START", "Duck gallery", function(player)
    if activeGallery[player] and activeGallery[player].expires > os.clock() then return end
    activeGallery[player] = {expires = os.clock()+45, score = 0, lastShot = -100}
    event:FireClient(player, "DuckStart", 45)
    task.delay(45, function()
        local s = activeGallery[player]
        if s and s.expires <= os.clock() then
            activeGallery[player] = nil
            if s.score>=10 then Rewards.awardOnce(player,"first_duck_gallery",10) end
            event:FireClient(player, "DuckEnd", s.score)
        end
    end)
end)

local ducks = {}
for i = 1, 5 do
    local model = Instance.new("Model")
    model.Name = "HolographicDuck_" .. i
    model.Parent = world
    local body = part("DuckBody", Vector3.new(4.5, 3.2, 1), Vector3.new(0,0,0), GOLD, model)
    body.CanCollide = false
    body.Material = Enum.Material.Neon
    body.Shape = Enum.PartType.Ball
    model.PrimaryPart = body
    local head = part("DuckHead", Vector3.new(2.3, 2.3, 1), Vector3.new(1.2,1.7,0), GREEN, model)
    head.CanCollide = false
    head.Shape = Enum.PartType.Ball
    local beak = part("DuckBeak", Vector3.new(1.8, 0.55, 1), Vector3.new(2.9,1.45,0), Color3.fromRGB(255, 110, 58), model)
    beak.CanCollide = false
    local duck = {model = model, phase = i*1.4, speed = 0.5+i*0.1, lastHit = -100}
    ducks[i] = duck
    for _, segment in ipairs({body,head,beak}) do
        local click = Instance.new("ClickDetector")
        click.MaxActivationDistance = 110
        click.Parent = segment
        click.MouseClick:Connect(function(player)
            local s = activeGallery[player]
            local now = os.clock()
            if not s or s.expires <= now then return end
            if now-s.lastShot < 0.3 or now-duck.lastHit < 0.18 then return end
            if not near(player, duckCenter, 82) then return end
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if not root or (root.Position-model.PrimaryPart.Position).Magnitude > 110 then return end
            -- The server owns the moving target. The client never submits a hit or score.
            s.lastShot = now
            duck.lastHit = now
            s.score += 10
            event:FireClient(player, "DuckScore", s.score)
        end)
    end
end
local accumulator = 0
RunService.Heartbeat:Connect(function(dt)
    accumulator += dt
    if accumulator < 0.065 then return end
    accumulator = 0
    local now = os.clock()
    for i, duck in ipairs(ducks) do
        local pos = duckCenter + Vector3.new(
            math.sin(now*duck.speed+duck.phase)*27,
            9 + (i-1)*3.0 + math.sin(now+duck.phase)*0.7,
            29 + (i%2)*6)
        duck.model:PivotTo(CFrame.new(pos))
    end
end)

event.OnServerEvent:Connect(function(player, action, sessionId, response)
    if type(action) ~= "string" then return end
    local now = os.clock()
    if now - (lastAction[player] or -100) < 0.16 then return end
    lastAction[player] = now
    if action == "Close" then
        sessions[player] = nil
        return
    end
    if action == "Next" then
        if type(sessionId) == "string" and table.find(Arcade.modes, sessionId) then
            startChallenge(player, sessionId)
        end
        return
    end
    if action ~= "Answer" or type(sessionId) ~= "number" then return end
    local s = sessions[player]
    if not s or s.id ~= sessionId or now < s.earliest or now > s.expires then return end
    if not near(player, plaza, 86) then sessions[player] = nil return end
    sessions[player] = nil
    local correct = Arcade.check(s.mode, s.secret, response)
    if correct then
        playerScores[player] = (playerScores[player] or 0) + 1
        Rewards.awardOnce(player,"first_"..s.mode,12)
    end
    event:FireClient(player, "Result", correct, s.mode, playerScores[player] or 0)
end)

Players.PlayerRemoving:Connect(function(player)
    sessions[player] = nil
    playerScores[player] = nil
    activeGallery[player] = nil
    lastAction[player] = nil
end)
print("[YUGATNEO] Cognitive arcade: five tasks and non-damaging moving duck targets online.")
