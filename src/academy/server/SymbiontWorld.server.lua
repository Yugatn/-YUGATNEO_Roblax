--!strict
-- Symbiont Academy: stand-alone Roblox Place; original assets built from Roblox Parts.
-- Server owns every completion, interaction, and navigation decision.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Content = require(ReplicatedStorage:WaitForChild("SymbiontShared"):WaitForChild("AcademyContent"))
local Rules = require(script.Parent:WaitForChild("SymbiontRules"))

local folder = Instance.new("Folder")
folder.Name = "SymbiontAcademy"
folder.Parent = Workspace

local remotes = Instance.new("Folder")
remotes.Name = "SymbiontAcademyRemotes"
remotes.Parent = ReplicatedStorage

local stateEvent = Instance.new("RemoteEvent")
stateEvent.Name = "StateChanged"
stateEvent.Parent = remotes

local getState = Instance.new("RemoteFunction")
getState.Name = "GetState"
getState.Parent = remotes

local state = Rules.newState()
local lastPromptAt = {}
local actionBoards = {}

getState.OnServerInvoke = function(_player)
    return Rules.snapshot(state)
end

local function makePart(name, size, position, color, material, parent)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Position = position
    part.Anchored = true
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent or folder
    return part
end

local function labelOn(part, caption, backgroundColor, studsOffset, width)
    local gui = Instance.new("BillboardGui")
    gui.Name = "Sign"
    gui.Adornee = part
    gui.Size = UDim2.fromOffset(width or 280, 74)
    gui.StudsOffsetWorldSpace = studsOffset or Vector3.new(0, 6, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 115
    gui.Parent = part

    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundColor3 = backgroundColor
    text.BackgroundTransparency = 0.08
    text.TextColor3 = Color3.fromRGB(245, 247, 253)
    text.TextScaled = true
    text.TextWrapped = true
    text.Font = Enum.Font.GothamBold
    text.Text = caption
    text.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = text
end

local function makePrompt(part, text, objectText, holdDuration)
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = text
    prompt.ObjectText = objectText
    prompt.HoldDuration = holdDuration or 0.35
    prompt.MaxActivationDistance = 12
    prompt.RequiresLineOfSight = false
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.Parent = part
    return prompt
end

local function near(player, part, maxDistance)
    if not player or not player:IsA("Player") then
        return false
    end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return root ~= nil
        and humanoid ~= nil
        and humanoid.Health > 0
        and (root.Position - part.Position).Magnitude <= maxDistance
end

local function throttled(player)
    local now = os.clock()
    local last = lastPromptAt[player.UserId] or -1e6
    if now - last < 0.3 then
        return true
    end
    lastPromptAt[player.UserId] = now
    return false
end

local function notify(player, message)
    stateEvent:FireClient(player, Rules.snapshot(state), message)
end

local function renderState(levelId)
    local progress = state.levels[levelId]
    for actionId, record in pairs(actionBoards[levelId]) do
        local completed = progress.done[actionId] == true
        record.part.Color = if completed then Color3.fromRGB(37, 160, 130) else Color3.fromRGB(42, 51, 75)
        record.part.Material = if completed then Enum.Material.Neon else Enum.Material.SmoothPlastic
        -- After one civic solution, all other alternatives are intentionally disabled.
        local action = Content.levels[levelId].actions[actionId]
        record.prompt.Enabled = not completed and not (action.group and progress.selected ~= nil)
    end
end

local function interact(player, prompt, levelId, actionId)
    local base = prompt.Parent
    if not base or not base:IsA("BasePart") then
        return
    end
    -- Proximity prompts can be forged by clients; always validate distance server-side.
    if not near(player, base, prompt.MaxActivationDistance + 3) or throttled(player) then
        return
    end
    local ok, feedback = Rules.apply(state, levelId, actionId, player.UserId)
    if not ok then
        notify(player, feedback)
        return
    end
    renderState(levelId)
    local suffix = if state.levels[levelId].completed then
        " Эпизод завершён! Вспомни вопрос для размышления на панели."
        else ""
    stateEvent:FireAllClients(Rules.snapshot(state), feedback .. suffix)
end

local ground = Color3.fromRGB(20, 28, 49)
local trim = Color3.fromRGB(57, 75, 110)

for _, levelId in ipairs(Content.order) do
    local level = Content.levels[levelId]
    local center = level.center
    local zone = Instance.new("Folder")
    zone.Name = levelId
    zone.Parent = folder
    makePart("Square", Vector3.new(118, 2, 104), center + Vector3.new(0, -1, 0), ground, Enum.Material.Slate, zone)
    makePart("CenterPath", Vector3.new(13, 0.15, 76), center + Vector3.new(0, 0.08, -7), trim, Enum.Material.SmoothPlastic, zone)
    makePart("SceneStage", Vector3.new(82, 0.7, 34), center + Vector3.new(0, 0.1, 18), level.color, Enum.Material.SmoothPlastic, zone)
    local monument = makePart("MissionMonument", Vector3.new(14, 9, 3), center + Vector3.new(0, 4.5, -39), level.color, Enum.Material.Metal, zone)
    labelOn(monument, level.title .. "  ·  " .. level.ageHint, ground, Vector3.new(0, 10, 0), 380)

    -- Decorative original geometry with no third-party assets or physics hazards.
    if levelId == "water" then
        local tank = makePart("WaterTank", Vector3.new(12, 12, 12), center + Vector3.new(-37, 7, -10), level.color, Enum.Material.Glass, zone)
        tank.Shape = Enum.PartType.Ball
        for _, dx in ipairs({-19, 0, 19}) do
            makePart("PipeNetwork", Vector3.new(3, 2, 24), center + Vector3.new(dx, 1, 27), Color3.fromRGB(77, 168, 205), Enum.Material.Metal, zone)
        end
    elseif levelId == "bridge" then
        makePart("River", Vector3.new(70, 0.3, 12), center + Vector3.new(0, 0.3, -21), Color3.fromRGB(48, 120, 205), Enum.Material.Glass, zone)
        makePart("BridgeModel", Vector3.new(18, 1.2, 16), center + Vector3.new(0, 2, -21), Color3.fromRGB(210, 162, 98), Enum.Material.WoodPlanks, zone)
        for _, dx in ipairs({-10, 10}) do
            makePart("Railing", Vector3.new(1, 3, 18), center + Vector3.new(dx, 3.5, -21), Color3.fromRGB(226, 205, 162), Enum.Material.Wood, zone)
        end
    else
        for _, dx in ipairs({-25, 0, 25}) do
            makePart("ForumColumn", Vector3.new(4, 12, 4), center + Vector3.new(dx, 6, -15), level.color, Enum.Material.Marble, zone)
        end
        makePart("MeetingTable", Vector3.new(28, 2, 8), center + Vector3.new(0, 3, -12), Color3.fromRGB(98, 79, 141), Enum.Material.Wood, zone)
    end

    actionBoards[levelId] = {}
    for index, actionId in ipairs(level.order) do
        local action = level.actions[actionId]
        local col = (index - 1) % 3
        local row = math.floor((index - 1) / 3)
        local boardPos = center + Vector3.new((col - 1) * 27, 3.5, 8 + row * 26)
        local board = makePart("Action_" .. actionId, Vector3.new(20, 7, 1.5), boardPos,
            Color3.fromRGB(42, 51, 75), Enum.Material.SmoothPlastic, zone)
        labelOn(board, action.label, ground, Vector3.new(0, 5, 0), 250)
        local prompt = makePrompt(board, "Выполнить", level.title, 0.3)
        actionBoards[levelId][actionId] = {part = board, prompt = prompt}
        prompt.Triggered:Connect(function(player)
            interact(player, prompt, levelId, actionId)
        end)
    end
end

local spawn = Instance.new("SpawnLocation")
spawn.Name = "AcademySpawn"
spawn.Size = Vector3.new(14, 1, 14)
spawn.Anchored = true
spawn.Position = Vector3.new(0, 1, -82)
spawn.Neutral = true
spawn.CanCollide = true
spawn.Material = Enum.Material.Neon
spawn.Color = Color3.fromRGB(224, 179, 91)
spawn.Parent = folder
labelOn(spawn, "СИМБИОНТ: АКАДЕМИЯ\nИсследуй, помогай, проверяй", ground, Vector3.new(0, 7, 0), 430)
makePart("LobbyPath", Vector3.new(16, 0.3, 35), Vector3.new(0, 0.25, -61), trim, Enum.Material.SmoothPlastic, folder)

for index, levelId in ipairs(Content.order) do
    local level = Content.levels[levelId]
    local pad = makePart("Travel_" .. levelId, Vector3.new(17, 1, 13),
        Vector3.new((index - 2) * 25, 0.8, -57), level.color, Enum.Material.Neon, folder)
    labelOn(pad, level.shortTitle, ground, Vector3.new(0, 5, 0), 200)
    local prompt = makePrompt(pad, "Отправиться", level.title, 0.1)
    prompt.Triggered:Connect(function(player)
        if not near(player, pad, prompt.MaxActivationDistance + 3) or throttled(player) then
            return
        end
        local character = player.Character
        if character then
            character:PivotTo(CFrame.new(level.center + Vector3.new(0, 4, -34)))
            notify(player, "Ты в эпизоде: " .. level.title)
        end
    end)
end

Players.PlayerRemoving:Connect(function(player)
    lastPromptAt[player.UserId] = nil
end)

print("Symbiont Academy loaded: three shared cooperative episodes.")
