--!strict
-- Read-only, responsive mission guide. Players interact through ProximityPrompt.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Content = require(ReplicatedStorage:WaitForChild("SymbiontShared"):WaitForChild("AcademyContent"))
local remoteFolder = ReplicatedStorage:WaitForChild("SymbiontAcademyRemotes")
local stateEvent = remoteFolder:WaitForChild("StateChanged")
local getState = remoteFolder:WaitForChild("GetState")

local gui = Instance.new("ScreenGui")
gui.Name = "SymbiontAcademyHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 8
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "MissionPanel"
panel.BackgroundColor3 = Color3.fromRGB(20, 27, 45)
panel.BackgroundTransparency = 0.06
panel.BorderSizePixel = 0
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -12, 0, 12)
panel.Parent = gui
local rounded = Instance.new("UICorner")
rounded.CornerRadius = UDim.new(0, 13)
rounded.Parent = panel
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(76, 96, 127)
stroke.Thickness = 1
stroke.Parent = panel

local function textLabel(name, y, h, size, color, initial)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Position = UDim2.new(0, 16, 0, y)
    label.Size = UDim2.new(1, -32, 0, h)
    label.BackgroundTransparency = 1
    label.TextColor3 = color
    label.Text = initial
    label.TextSize = size
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Font = Enum.Font.Gotham
    label.Parent = panel
    return label
end

local title = textLabel("Title", 14, 31, 20, Color3.fromRGB(245, 246, 251), "СИМБИОНТ · АКАДЕМИЯ")
title.Font = Enum.Font.GothamBold
title.Size = UDim2.new(1, -126, 0, 29)
local subtitle = textLabel("Guide", 49, 33, 13, Color3.fromRGB(174, 195, 216),
    "Подойди к стендам и нажми E (на телефоне — кнопку действия).")
local tabs = Instance.new("Frame")
tabs.Name = "Levels"
tabs.BackgroundTransparency = 1
tabs.Position = UDim2.new(0, 12, 0, 91)
tabs.Size = UDim2.new(1, -24, 0, 36)
tabs.Parent = panel
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.Padding = UDim.new(0, 5)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = tabs

local levelTitle = textLabel("LevelTitle", 140, 25, 17, Color3.fromRGB(235, 244, 251), "")
levelTitle.Font = Enum.Font.GothamBold
local description = textLabel("Description", 170, 51, 13, Color3.fromRGB(203, 215, 231), "")
local checklist = textLabel("Checklist", 225, 137, 14, Color3.fromRGB(228, 231, 239), "")
local reflection = textLabel("Reflection", 362, 45, 12, Color3.fromRGB(162, 202, 235), "")
local message = textLabel("Feedback", 413, 50, 12, Color3.fromRGB(154, 230, 203), "Начни с любой зоны. Работать можно совместно.")

local fold = Instance.new("TextButton")
fold.Name = "Fold"
fold.Size = UDim2.fromOffset(90, 31)
fold.Position = UDim2.new(1, -101, 0, 11)
fold.Text = "Свернуть"
fold.TextSize = 13
fold.Font = Enum.Font.GothamBold
fold.TextColor3 = Color3.fromRGB(250, 252, 255)
fold.BackgroundColor3 = Color3.fromRGB(64, 88, 128)
fold.Parent = panel
local foldRound = Instance.new("UICorner")
foldRound.CornerRadius = UDim.new(0, 8)
foldRound.Parent = fold

local selectedLevel = Content.order[1]
local latest = {serverSeq = -1, roomId = 0, revision = 0, levels = {}, members = 0, maxMembers = 4, isLeader = false}
local feedback = "Начни с любой зоны. Работать можно совместно."
local collapsed = false
local tabButtons = {}

local function updateSize()
    local camera = Workspace.CurrentCamera
    local viewport = if camera then camera.ViewportSize else Vector2.new(900, 700)
    local width = math.clamp(viewport.X - 24, 220, 440)
    local height = math.clamp(viewport.Y - 95, 275, 472)
    panel.Size = UDim2.fromOffset(width, if collapsed then 52 else height)
    local compact = not collapsed and height < 420
    description.Visible = not compact
    reflection.Visible = not compact
    checklist.Position = UDim2.new(0, 16, 0, if compact then 166 else 225)
    checklist.Size = UDim2.new(1, -32, 0, if compact then math.max(52, height - 222) else 137)
    checklist.TextSize = if compact then 12 else 14
    message.Position = UDim2.new(0, 16, 0, if compact then height - 51 else 413)
    message.Size = UDim2.new(1, -32, 0, if compact then 46 else 50)
end

local function draw()
    local level = Content.levels[selectedLevel]
    if not level then return end
    local progress = latest.levels[selectedLevel] or {done = {}, completed = false, contributors = 0}
    local rows = {}
    local count = 0
    for _, actionId in ipairs(level.order) do
        local action = level.actions[actionId]
        local done = progress.done[actionId] == true
        if done then count += 1 end
        local mark = if done then "[✓]" else "[ ]"
        table.insert(rows, mark .. "  " .. action.label)
    end
    if level.winGroup and progress.completed then
        count = 4
        rows = {"[✓] Проверены три источника",
            "[✓] Выбран мирный путь решения",
            "Выбор не единственный: у разных решений есть ограничения."}
    end
    levelTitle.Text = if latest.roomId == 0 then "Выбери команду 1–4"
        else level.title .. " · " .. level.ageHint .. (if progress.completed then " · ПРОЙДЕНО" else "")
    local hint = "Подойди к одному из игровых стендов и нажми E или экранную кнопку."
    if progress.completed then
        hint = "Задание выполнено. Можно перейти к другой зоне."
    else
        for _, actionId in ipairs(level.order) do
            local action = level.actions[actionId]
            if not progress.done[actionId] and not (action.group and progress.selected) then
                local ready = true
                for _, dependency in ipairs(action.requires) do
                    if not progress.done[dependency] then
                        ready = false
                        break
                    end
                end
                if ready then
                    hint = action.hint
                    break
                end
            end
        end
    end
    if latest.roomId == 0 then
        subtitle.Text = "Подойди к одному из четырёх стендов в общем холле."
        description.Text = "Выбери свободную команду. С ней можно пройти три игры."
        checklist.Text = "Сначала вступи в команду.\nЗатем выбирай задания внутри её игрового мира."
        reflection.Text = "Совместная работа не требует одинаковых мнений."
        message.Text = feedback
    else
        subtitle.Text = hint
        description.Text = level.description
        if panel.AbsoluteSize.Y > 0 and panel.AbsoluteSize.Y < 420 and not collapsed then
            local nextStep = "Задания выполнены!"
            for _, actionId in ipairs(level.order) do
                if not progress.done[actionId] then
                    nextStep = level.actions[actionId].label
                    break
                end
            end
            checklist.Text = "Готово: " .. tostring(count) .. "/" .. tostring(#level.order) ..
                "\nСледующая задача: " .. nextStep
        else
            checklist.Text = table.concat(rows, "\n")
        end
        reflection.Text = "Подумай: " .. level.reflection
        local role = if latest.isLeader then " · организатор" else ""
        message.Text = "Команда " .. tostring(latest.roomId) .. role .. " · " ..
            tostring(latest.members) .. "/" .. tostring(latest.maxMembers) ..
            "\n" .. feedback
    end

    for levelId, button in pairs(tabButtons) do
        local selected = levelId == selectedLevel
        button.BackgroundColor3 = if selected then Content.levels[levelId].color else Color3.fromRGB(52, 63, 87)
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
end

for index, levelId in ipairs(Content.order) do
    local level = Content.levels[levelId]
    local button = Instance.new("TextButton")
    button.Name = "Tab_" .. levelId
    button.LayoutOrder = index
    button.Size = UDim2.new(1 / #Content.order, -5, 1, 0)
    button.BackgroundColor3 = Color3.fromRGB(52, 63, 87)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 12
    button.TextWrapped = true
    button.Font = Enum.Font.GothamBold
    button.Text = level.shortTitle
    button.Parent = tabs
    local radius = Instance.new("UICorner")
    radius.CornerRadius = UDim.new(0, 8)
    radius.Parent = button
    tabButtons[levelId] = button
    button.MouseButton1Click:Connect(function()
        selectedLevel = levelId
        draw()
    end)
end

local function setCollapsed(nextValue)
    collapsed = nextValue
    fold.Text = if collapsed then "Развернуть" else "Свернуть"
    tabs.Visible = not collapsed
    subtitle.Visible = not collapsed
    levelTitle.Visible = not collapsed
    description.Visible = not collapsed
    checklist.Visible = not collapsed
    reflection.Visible = not collapsed
    message.Visible = not collapsed
    updateSize()
end

fold.MouseButton1Click:Connect(function()
    setCollapsed(not collapsed)
end)

local function applySnapshot(snapshot, newMessage)
    if typeof(snapshot) ~= "table" or typeof(snapshot.serverSeq) ~= "number"
        or typeof(snapshot.roomId) ~= "number" or typeof(snapshot.levels) ~= "table" then
        return
    end
    -- A global monotonically growing sequence also handles room changes and resets.
    if snapshot.serverSeq < latest.serverSeq then
        return
    end
    latest = snapshot
    if typeof(newMessage) == "string" and #newMessage < 600 then
        feedback = newMessage
    end
    draw()
end

stateEvent.OnClientEvent:Connect(applySnapshot)
task.spawn(function()
    local ok, snapshot = pcall(function()
        return getState:InvokeServer()
    end)
    if ok then
        applySnapshot(snapshot, nil)
    else
        feedback = "Нет связи с сервером заданий. Попробуй перезайти в игру."
        draw()
    end
end)

local camera = Workspace.CurrentCamera
if camera then
    camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateSize)
end
draw()
updateSize()
