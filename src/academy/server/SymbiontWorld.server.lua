--!strict
-- Symbiont Academy: four physically separated, server-authoritative team worlds.
-- Independent scenes avoid mixing progress when unrelated parties play together.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Content = require(ReplicatedStorage:WaitForChild("SymbiontShared"):WaitForChild("AcademyContent"))
local Rules = require(script.Parent:WaitForChild("SymbiontRules"))
local Rooms = require(script.Parent:WaitForChild("SymbiontRooms"))

local MAX_ROOMS = 4
local MAX_TEAM = 4
local registry = Rooms.new(MAX_ROOMS, MAX_TEAM)
local lastPromptAt = {}
local confirmations = {}
local scenes = {}

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

getState.OnServerInvoke = function(player)
    return Rooms.snapshot(registry, player.UserId)
end

local ground = Color3.fromRGB(20, 28, 49)
local trim = Color3.fromRGB(57, 75, 110)

local function originFor(roomId)
    -- Room islands are separated by 600 studs, with a common lobby at the origin.
    return Vector3.new(500 + (roomId - 1) * 600, 0, 420)
end

local function makePart(name, size, position, color, material, parent)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Position = position
    part.Anchored = true
    part.CanCollide = true
    part.Color = color
    part.Material = material or Enum.Material.SmoothPlastic
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent or folder
    return part
end

local function labelOn(part, caption, backgroundColor, offset, width)
    local gui = Instance.new("BillboardGui")
    gui.Name = "Sign"
    gui.Adornee = part
    gui.Size = UDim2.fromOffset(width or 280, 74)
    gui.StudsOffsetWorldSpace = offset or Vector3.new(0, 6, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 105
    gui.Parent = part
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundColor3 = backgroundColor
    label.BackgroundTransparency = 0.08
    label.TextColor3 = Color3.fromRGB(246, 248, 255)
    label.TextScaled = true
    label.TextWrapped = true
    label.Font = Enum.Font.GothamBold
    label.Text = caption
    label.Parent = gui
    local rounded = Instance.new("UICorner")
    rounded.CornerRadius = UDim.new(0, 10)
    rounded.Parent = label
end

local function makePrompt(part, action, objectText, holdTime)
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "AcademyAction"
    prompt.ActionText = action
    prompt.ObjectText = objectText
    prompt.HoldDuration = holdTime or 0.35
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
    return root ~= nil and humanoid ~= nil and humanoid.Health > 0
        and (root.Position - part.Position).Magnitude <= maxDistance
end

local function canPrompt(player, prompt)
    local part = prompt.Parent
    if not prompt.Enabled or not part or not part:IsA("BasePart") then
        return false
    end
    if not near(player, part, prompt.MaxActivationDistance + 3) then
        return false
    end
    local now = os.clock()
    local last = lastPromptAt[player.UserId] or -1e6
    if now - last < 0.3 then
        return false
    end
    lastPromptAt[player.UserId] = now
    return true
end

local function movePlayer(player, position)
    local character = player.Character
    if not character then
        return
    end
    character:PivotTo(CFrame.new(position))
end

local function notify(player, message)
    stateEvent:FireClient(player, Rooms.snapshot(registry, player.UserId), message)
end

local function notifyRoom(roomId, message)
    local room = Rooms.getRoom(registry, roomId)
    if not room then
        return
    end
    for _, userId in ipairs(room.members) do
        local member = Players:GetPlayerByUserId(userId)
        if member then
            notify(member, message)
        end
    end
end

local function renderRoom(roomId)
    local scene = scenes[roomId]
    if not scene then
        return
    end
    local room = Rooms.getRoom(registry, roomId)
    local state = if room then room.state else Rules.newState()
    for _, levelId in ipairs(Content.order) do
        local progress = state.levels[levelId]
        for actionId, record in pairs(scene.boards[levelId]) do
            local completed = progress.done[actionId] == true
            record.part.Color = if completed then Color3.fromRGB(37, 160, 130)
                else Color3.fromRGB(42, 51, 75)
            record.part.Material = if completed then Enum.Material.Neon
                else Enum.Material.SmoothPlastic
            local action = Content.levels[levelId].actions[actionId]
            record.prompt.Enabled = not completed and not (action.group and progress.selected ~= nil)
        end
        for actionId, objects in pairs(scene.effects[levelId]) do
            for _, object in ipairs(objects) do
                local completed = progress.done[actionId] == true
                object.Transparency = if completed then 0.04 else 0.76
                object.Material = if completed then Enum.Material.Neon
                    else Enum.Material.SmoothPlastic
                object.CanCollide = false
            end
        end
    end
end

local function interact(player, prompt, roomId, levelId, actionId)
    if Rooms.roomOf(registry, player.UserId) ~= roomId or not canPrompt(player, prompt) then
        return
    end
    local ok, message = Rooms.apply(registry, player.UserId, roomId, levelId, actionId)
    if not ok then
        notify(player, message)
        return
    end
    renderRoom(roomId)
    local levelProgress = Rooms.getRoom(registry, roomId).state.levels[levelId]
    local suffix = if levelProgress.completed then
        " Эпизод завершён! Обсудите вопрос для размышления."
        else ""
    notifyRoom(roomId, message .. suffix)
end

local function leaveRoom(player)
    local roomId = Rooms.roomOf(registry, player.UserId)
    if not roomId then
        notify(player, "Ты уже в общем холле.")
        return
    end
    local ok, message = Rooms.leave(registry, player.UserId)
    if not ok then
        notify(player, message)
        return
    end
    confirmations[player.UserId] = nil
    movePlayer(player, Vector3.new(0, 5, -88))
    renderRoom(roomId)
    notify(player, message)
    notifyRoom(roomId, "Состав команды изменился.")
end

-- Global lobby: select one of four rooms; never place players into other teams by a client remote.
makePart("CommonLobby", Vector3.new(130, 2, 85), Vector3.new(0, -1, -70), ground, Enum.Material.Slate, folder)
local spawn = Instance.new("SpawnLocation")
spawn.Name = "AcademySpawn"
spawn.Size = Vector3.new(14, 1, 14)
spawn.Anchored = true
spawn.Neutral = true
spawn.Position = Vector3.new(0, 1, -95)
spawn.Color = Color3.fromRGB(224, 179, 91)
spawn.Material = Enum.Material.Neon
spawn.Parent = folder
labelOn(spawn, "СИМБИОНТ · АКАДЕМИЯ\nВыбери команду 1–4", ground, Vector3.new(0, 7, 0), 420)

for roomId = 1, MAX_ROOMS do
    local thisRoomId = roomId
    local roomOrigin = originFor(thisRoomId)
    local roomFolder = Instance.new("Folder")
    roomFolder.Name = "Team_" .. tostring(thisRoomId)
    roomFolder.Parent = folder
    local scene = {boards = {}, effects = {}}
    scenes[thisRoomId] = scene

    -- Players enter one of four teams only from the common lobby.
    local joinPad = makePart("JoinTeam_" .. tostring(thisRoomId), Vector3.new(22, 1, 16),
        Vector3.new((thisRoomId - 2.5) * 30, 0.8, -61),
        Color3.fromRGB(80, 157, 196), Enum.Material.Neon, folder)
    labelOn(joinPad, "Команда " .. tostring(thisRoomId) .. "\n1–4 участника", ground, Vector3.new(0, 5, 0), 185)
    local joinPrompt = makePrompt(joinPad, "Присоединиться", "Комната " .. tostring(thisRoomId), 0.2)
    joinPrompt.Triggered:Connect(function(player)
        if Rooms.roomOf(registry, player.UserId) or not canPrompt(player, joinPrompt) then
            return
        end
        local ok, message = Rooms.join(registry, player.UserId, thisRoomId)
        if not ok then
            notify(player, message)
            return
        end
        confirmations[player.UserId] = nil
        renderRoom(thisRoomId)
        movePlayer(player, roomOrigin + Vector3.new(0, 5, -83))
        notifyRoom(thisRoomId, message)
    end)

    -- Each team receives its own physical island. No other team's 3D state is reused.
    makePart("RoomPlaza", Vector3.new(112, 2, 63),
        roomOrigin + Vector3.new(0, -1, -70), ground, Enum.Material.Slate, roomFolder)
    local welcome = makePart("TeamMonument", Vector3.new(11, 8, 3),
        roomOrigin + Vector3.new(0, 4, -101), Color3.fromRGB(99, 170, 201),
        Enum.Material.Metal, roomFolder)
    labelOn(welcome, "Команда " .. tostring(thisRoomId) .. "\nВыбери одну из трёх игр",
        ground, Vector3.new(0, 9, 0), 350)

    local leavePad = makePart("LeaveRoom", Vector3.new(16, 1, 12),
        roomOrigin + Vector3.new(-40, 0.8, -81), Color3.fromRGB(215, 153, 85),
        Enum.Material.Neon, roomFolder)
    labelOn(leavePad, "Выйти из команды", ground, Vector3.new(0, 5, 0), 210)
    local leavePrompt = makePrompt(leavePad, "Выйти", "Общий холл", 0.2)
    leavePrompt.Triggered:Connect(function(player)
        if Rooms.roomOf(registry, player.UserId) ~= thisRoomId or not canPrompt(player, leavePrompt) then
            return
        end
        leaveRoom(player)
    end)

    local restartPad = makePart("RestartTeam", Vector3.new(16, 1, 12),
        roomOrigin + Vector3.new(40, 0.8, -81), Color3.fromRGB(173, 98, 106),
        Enum.Material.Neon, roomFolder)
    labelOn(restartPad, "Начать заново\nТолько организатор", ground, Vector3.new(0, 5, 0), 220)
    local restartPrompt = makePrompt(restartPad, "Сбросить задания", "Подтвердить дважды", 0.3)
    restartPrompt.Triggered:Connect(function(player)
        if Rooms.roomOf(registry, player.UserId) ~= thisRoomId or not canPrompt(player, restartPrompt) then
            return
        end
        local room = Rooms.getRoom(registry, thisRoomId)
        if not room or room.leader ~= player.UserId then
            notify(player, "Перезапуск доступен только организатору команды.")
            return
        end
        local previous = confirmations[player.UserId]
        if not previous or previous.roomId ~= thisRoomId or previous.expiresAt < os.clock() then
            confirmations[player.UserId] = {roomId = thisRoomId, expiresAt = os.clock() + 8}
            notify(player, "Нажми «Сбросить задания» ещё раз в течение 8 секунд.")
            return
        end
        confirmations[player.UserId] = nil
        local ok, message = Rooms.reset(registry, player.UserId)
        if ok then
            renderRoom(thisRoomId)
            notifyRoom(thisRoomId, message)
        else
            notify(player, message)
        end
    end)

    for index, levelId in ipairs(Content.order) do
        local thisLevelId = levelId
        local level = Content.levels[thisLevelId]
        local center = roomOrigin + level.center
        local zone = Instance.new("Folder")
        zone.Name = thisLevelId
        zone.Parent = roomFolder

        local travelPad = makePart("Travel_" .. thisLevelId, Vector3.new(18, 1, 13),
            roomOrigin + Vector3.new((index - 2) * 25, 0.8, -57),
            level.color, Enum.Material.Neon, roomFolder)
        labelOn(travelPad, level.shortTitle, ground, Vector3.new(0, 5, 0), 210)
        local travelPrompt = makePrompt(travelPad, "Начать", level.title, 0.1)
        travelPrompt.Triggered:Connect(function(player)
            if Rooms.roomOf(registry, player.UserId) == thisRoomId
                and canPrompt(player, travelPrompt) then
                movePlayer(player, center + Vector3.new(0, 5, -34))
                notify(player, "Задание: " .. level.title)
            end
        end)

        makePart("Square", Vector3.new(118, 2, 104), center + Vector3.new(0, -1, 0),
            ground, Enum.Material.Slate, zone)
        makePart("CenterPath", Vector3.new(13, 0.15, 76), center + Vector3.new(0, 0.08, -7),
            trim, Enum.Material.SmoothPlastic, zone)
        makePart("SceneStage", Vector3.new(82, 0.7, 34), center + Vector3.new(0, 0.1, 18),
            level.color, Enum.Material.SmoothPlastic, zone)
        local monument = makePart("MissionMonument", Vector3.new(14, 9, 3),
            center + Vector3.new(0, 4.5, -39), level.color, Enum.Material.Metal, zone)
        labelOn(monument, level.title .. " · " .. level.ageHint, ground, Vector3.new(0, 10, 0), 380)

        scene.effects[thisLevelId] = {}
        if thisLevelId == "water" then
            local tank = makePart("WaterTank", Vector3.new(12, 12, 12),
                center + Vector3.new(-37, 7, -10), level.color, Enum.Material.Glass, zone)
            tank.Shape = Enum.PartType.Ball
            scene.effects[thisLevelId].activate = {tank}
            local districts = {"clinic", "school", "homes"}
            for pipeIndex, dx in ipairs({-19, 0, 19}) do
                local pipe = makePart("Pipe_" .. districts[pipeIndex], Vector3.new(3, 2, 24),
                    center + Vector3.new(dx, 1, 27), Color3.fromRGB(77, 168, 205),
                    Enum.Material.Metal, zone)
                scene.effects[thisLevelId][districts[pipeIndex]] = {pipe}
            end
        elseif thisLevelId == "bridge" then
            local river = makePart("River", Vector3.new(70, 0.3, 12),
                center + Vector3.new(0, 0.3, -21), Color3.fromRGB(48, 120, 205),
                Enum.Material.Glass, zone)
            river.CanCollide = false
            local deck = makePart("BridgeModel", Vector3.new(18, 1.2, 16),
                center + Vector3.new(0, 2, -21), Color3.fromRGB(210, 162, 98),
                Enum.Material.WoodPlanks, zone)
            scene.effects[thisLevelId].open = {deck}
            local supports = {"beamLeft", "beamRight"}
            for beamIndex, dx in ipairs({-10, 10}) do
                local beam = makePart("Railing_" .. supports[beamIndex], Vector3.new(1, 3, 18),
                    center + Vector3.new(dx, 3.5, -21), Color3.fromRGB(226, 205, 162),
                    Enum.Material.Wood, zone)
                scene.effects[thisLevelId][supports[beamIndex]] = {beam}
            end
        else
            local sources = {"budget", "residents", "engineers"}
            for sourceIndex, dx in ipairs({-25, 0, 25}) do
                local column = makePart("ForumColumn_" .. sources[sourceIndex],
                    Vector3.new(4, 12, 4), center + Vector3.new(dx, 6, -15),
                    level.color, Enum.Material.Marble, zone)
                scene.effects[thisLevelId][sources[sourceIndex]] = {column}
            end
            makePart("MeetingTable", Vector3.new(28, 2, 8),
                center + Vector3.new(0, 3, -12), Color3.fromRGB(98, 79, 141),
                Enum.Material.Wood, zone)
        end

        local backPad = makePart("ReturnToTeam", Vector3.new(13, 1, 10),
            center + Vector3.new(38, 0.8, -36), Color3.fromRGB(225, 176, 95),
            Enum.Material.Neon, zone)
        labelOn(backPad, "Вернуться в команду", ground, Vector3.new(0, 5, 0), 230)
        local backPrompt = makePrompt(backPad, "Вернуться", "Площадь команды", 0.1)
        backPrompt.Triggered:Connect(function(player)
            if Rooms.roomOf(registry, player.UserId) == thisRoomId
                and canPrompt(player, backPrompt) then
                movePlayer(player, roomOrigin + Vector3.new(0, 5, -83))
                notify(player, "Ты вернулся на площадь команды.")
            end
        end)

        scene.boards[thisLevelId] = {}
        for actionIndex, actionId in ipairs(level.order) do
            local thisActionId = actionId
            local action = level.actions[thisActionId]
            local col = (actionIndex - 1) % 3
            local row = math.floor((actionIndex - 1) / 3)
            local board = makePart("Action_" .. thisActionId, Vector3.new(20, 7, 1.5),
                center + Vector3.new((col - 1) * 27, 3.5, 8 + row * 26),
                Color3.fromRGB(42, 51, 75), Enum.Material.SmoothPlastic, zone)
            labelOn(board, action.label, ground, Vector3.new(0, 5, 0), 250)
            local prompt = makePrompt(board, "Выполнить", level.title, 0.3)
            scene.boards[thisLevelId][thisActionId] = {part = board, prompt = prompt}
            prompt.Triggered:Connect(function(player)
                interact(player, prompt, thisRoomId, thisLevelId, thisActionId)
            end)
        end
    end

    renderRoom(thisRoomId)
end

local function bindPlayer(player)
    player.CharacterAdded:Connect(function(character)
        task.spawn(function()
            local root = character:WaitForChild("HumanoidRootPart", 10)
            if not root or player.Character ~= character then
                return
            end
            local roomId = Rooms.roomOf(registry, player.UserId)
            if roomId then
                character:PivotTo(CFrame.new(originFor(roomId) + Vector3.new(0, 5, -83)))
            end
        end)
    end)
end

Players.PlayerAdded:Connect(bindPlayer)
for _, player in ipairs(Players:GetPlayers()) do
    bindPlayer(player)
end

Players.PlayerRemoving:Connect(function(player)
    lastPromptAt[player.UserId] = nil
    confirmations[player.UserId] = nil
    local roomId = Rooms.roomOf(registry, player.UserId)
    if roomId then
        Rooms.leave(registry, player.UserId)
        renderRoom(roomId)
        notifyRoom(roomId, "Состав команды изменился. Организатор назначается автоматически.")
    end
end)

print("Symbiont Academy: four independent team worlds with 3 cooperative games each.")
