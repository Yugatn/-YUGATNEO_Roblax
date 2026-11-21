--!strict
-- Four-square football: phone and desktop controls, clear scoreboard and shot targets.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local Config = require(ReplicatedStorage:WaitForChild("SquareShared"):WaitForChild("SquareConfig"))
local remotes = ReplicatedStorage:WaitForChild("SquareRemotes")
local strikeRemote = remotes:WaitForChild("Strike")
local stateRemote = remotes:WaitForChild("Scoreboard")
local getState = remotes:WaitForChild("GetState")

local screen = Instance.new("ScreenGui")
screen.Name = "FourSquareHUD"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = false
screen.DisplayOrder = 12
screen.Parent = player:WaitForChild("PlayerGui")

local function makeFrame(name, parent, color)
    local f = Instance.new("Frame")
    f.Name = name
    f.BackgroundColor3 = color
    f.BackgroundTransparency = 0.05
    f.BorderSizePixel = 0
    f.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 11)
    corner.Parent = f
    return f
end

local function makeLabel(name, parent, pos, size, fontSize, text, color)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.Position = pos
    label.Size = size
    label.Font = Enum.Font.Gotham
    label.TextSize = fontSize
    label.TextColor3 = color or Color3.fromRGB(245,247,251)
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Text = text
    label.Parent = parent
    return label
end

local function makeButton(name, parent, text, color)
    local button = Instance.new("TextButton")
    button.Name = name
    button.BackgroundColor3 = color
    button.TextColor3 = Color3.fromRGB(255,255,255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 15
    button.TextWrapped = true
    button.Text = text
    button.AutoButtonColor = true
    button.Parent = parent
    local radius = Instance.new("UICorner")
    radius.CornerRadius = UDim.new(0, 8)
    radius.Parent = button
    return button
end

local scoreboard = makeFrame("Scoreboard", screen, Color3.fromRGB(19, 24, 34))
scoreboard.AnchorPoint = Vector2.new(0,0)
scoreboard.Position = UDim2.fromOffset(11, 10)

local title = makeLabel("Title", scoreboard, UDim2.fromOffset(12,8),
    UDim2.new(1,-24,0,28),20,"КВАДРАТ · ФУТБОЛ")
title.Font = Enum.Font.GothamBold

local seatLabels = {}
for i=1,4 do
    seatLabels[i] = makeLabel("Seat_" .. i,scoreboard,UDim2.fromOffset(13,40+(i-1)*29),
        UDim2.new(1,-22,0,27),15,"Игрок "..i.." · ожидание")
end
local message = makeLabel("Message",scoreboard,UDim2.fromOffset(12,161),
    UDim2.new(1,-24,0,58),13,"Ждём четырёх игроков.")
local help = makeLabel("Hint",scoreboard,UDim2.fromOffset(12,221),
    UDim2.new(1,-24,0,48),12,
    "Ногой — только после отскока. Головой — можно с лёта. Подача: два отскока по диагонали.",
    Color3.fromRGB(188, 210, 232))

local controls = makeFrame("Controls", screen, Color3.fromRGB(19,24,34))
controls.AnchorPoint = Vector2.new(0.5,1)
controls.Position = UDim2.new(0.5,0,1,-13)

local aimLabel = makeLabel("Aim",controls,UDim2.fromOffset(12,7),
    UDim2.new(1,-24,0,27),14,"Куда направить мяч?")
aimLabel.Font = Enum.Font.GothamBold

local targets = Instance.new("Frame")
targets.Name = "Targets"
targets.BackgroundTransparency = 1
targets.Position = UDim2.fromOffset(10,37)
targets.Size = UDim2.new(1,-20,0,40)
targets.Parent = controls
local targetLayout = Instance.new("UIListLayout")
targetLayout.FillDirection = Enum.FillDirection.Horizontal
targetLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
targetLayout.VerticalAlignment = Enum.VerticalAlignment.Center
targetLayout.Padding = UDim.new(0,5)
targetLayout.Parent = targets

local actionFrame = Instance.new("Frame")
actionFrame.Name = "Actions"
actionFrame.BackgroundTransparency = 1
actionFrame.Position = UDim2.fromOffset(10,82)
actionFrame.Size = UDim2.new(1,-20,0,45)
actionFrame.Parent = controls
local actionLayout = Instance.new("UIListLayout")
actionLayout.FillDirection = Enum.FillDirection.Horizontal
actionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
actionLayout.VerticalAlignment = Enum.VerticalAlignment.Center
actionLayout.Padding = UDim.new(0,7)
actionLayout.Parent = actionFrame

local status = {
    revision=-1, seat=0, phase="waiting", message="Ожидание игроков.",
    server=1, receiver=0, bounceCount=0, isServe=false, seats={},
}
local selectedTarget = 4 -- Start with a safe opponent; the red center must be chosen deliberately.
local targetButtons = {}
local targetChoices = {1,2,3,4,0}
for _, choice in ipairs(targetChoices) do
    local color = if choice == 0 then Color3.fromRGB(165, 54, 61) else Config.colors[choice]
    local text = if choice == 0 then "Центр!" else "№"..choice
    local button = makeButton("Target_"..choice,targets,text,color)
    targetButtons[choice] = button
    button.MouseButton1Click:Connect(function()
        if choice ~= 0 then
            local other = status.seats[choice]
            if choice == status.seat or not other or not other.occupied or other.out then return end
        end
        selectedTarget = choice
        aimLabel.Text = if choice == 0 then "Центральный квадрат = штраф бьющему!"
            else "Цель: квадрат игрока " .. choice
        -- Updated again in draw() when scoreboard changes.
    end)
end

local kick = makeButton("Kick",actionFrame,"НОГОЙ · F",Color3.fromRGB(41,131,185))
local head = makeButton("Head",actionFrame,"ГОЛОВОЙ · H",Color3.fromRGB(168,105,192))
local serve = makeButton("Serve",actionFrame,"ПОДАЧА · P",Color3.fromRGB(66,142,91))

local viewButton = makeButton("CameraToggle",scoreboard,"Сверху · V",Color3.fromRGB(55,68,86))
viewButton.TextSize = 12
viewButton.Size = UDim2.fromOffset(105,30)
viewButton.AnchorPoint = Vector2.new(1,0)
viewButton.Position = UDim2.new(1,-8,0,8)

local overhead = false
local function setOverhead(value)
    overhead = value
    viewButton.Text = if overhead then "Обычный вид" else "Сверху · V"
    local camera = Workspace.CurrentCamera
    if camera and not overhead then
        camera.CameraType = Enum.CameraType.Custom
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then camera.CameraSubject = humanoid end
    end
end

viewButton.MouseButton1Click:Connect(function()
    setOverhead(not overhead)
end)
RunService.RenderStepped:Connect(function()
    if not overhead then return end
    local camera = Workspace.CurrentCamera
    if camera then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = CFrame.lookAt(
            Vector3.new(0, 118, 0), Vector3.new(0, 0, 0), Vector3.new(0, 0, -1))
    end
end)

local function send(kind)
    if status.seat == 0 or status.phase == "finished" or status.phase == "waiting"
        or status.phase == "pause" then return end
    strikeRemote:FireServer(kind,selectedTarget)
end
kick.MouseButton1Click:Connect(function() send("foot") end)
head.MouseButton1Click:Connect(function() send("head") end)
serve.MouseButton1Click:Connect(function() send("serve") end)

UserInputService.InputBegan:Connect(function(input,processed)
    if processed or UserInputService:GetFocusedTextBox() then return end
    local k = input.KeyCode
    local numbers = {
        [Enum.KeyCode.One]=1,[Enum.KeyCode.Two]=2,
        [Enum.KeyCode.Three]=3,[Enum.KeyCode.Four]=4,
        [Enum.KeyCode.Zero]=0,
    }
    if numbers[k] ~= nil then
        selectedTarget = numbers[k]
    elseif k == Enum.KeyCode.F then send("foot")
    elseif k == Enum.KeyCode.H then send("head")
    elseif k == Enum.KeyCode.P then send("serve")
    elseif k == Enum.KeyCode.V then setOverhead(not overhead)
    end
end)

local function fit()
    local camera = Workspace.CurrentCamera
    local v = if camera then camera.ViewportSize else Vector2.new(1000,720)
    local small = v.X < 660
    scoreboard.Size = UDim2.fromOffset(math.min(v.X-20,if small then 290 else 355),
        if small then 224 else 277)
    help.Visible = not small
    title.TextSize = if small then 16 else 20
    viewButton.Size = UDim2.fromOffset(if small then 83 else 105,29)
    controls.Size = UDim2.fromOffset(math.min(v.X-16,if small then 360 else 490),141)
    local available = controls.AbsoluteSize.X
    local targetWidth = math.max(39, math.floor((available-45)/5))
    for _, button in pairs(targetButtons) do
        button.Size = UDim2.fromOffset(targetWidth,36)
        button.TextSize = if small then 12 else 15
    end
    local actionWidth = math.max(83,math.floor((available-44)/3))
    for _, button in ipairs({kick,head,serve}) do
        button.Size = UDim2.fromOffset(actionWidth,43)
        button.TextSize = if small then 12 else 14
    end
end

local function draw()
    local seat = status.seat
    title.Text = "КВАДРАТ · " .. (if seat > 0 then "ИГРОК "..seat else "ЗРИТЕЛЬ")
    for i=1,4 do
        local item = status.seats[i] or {}
        local label = seatLabels[i]
        local suffix = if not item.occupied then "место свободно"
            elseif item.out then "ВЫБЫЛ"
            else "в игре"
        label.Text = "■ "..i.."  ·  "..tostring(item.goals or 0).."/5  ·  "..suffix
        label.TextColor3 = if item.out then Color3.fromRGB(169,170,173) else Config.colors[i]
        label.Font = if seat == i then Enum.Font.GothamBold else Enum.Font.Gotham
    end
    message.Text = status.message or "Мяч в игре."
    local targetInfo = if selectedTarget == 0 then "центр — собственный штраф"
        else "квадрат "..selectedTarget
    aimLabel.Text = "Цель: "..targetInfo.." · удары по клавишам 1–4"
    for choice, button in pairs(targetButtons) do
        local item = status.seats[choice]
        local enabled = choice == 0 or (item ~= nil and item.occupied and not item.out and choice ~= seat)
        button.AutoButtonColor = enabled
        button.Active = enabled
        button.TextTransparency = if enabled then 0 else 0.55
        button.BackgroundTransparency = if selectedTarget == choice then 0 else 0.28
    end
    local serving = status.phase == "serve" and status.server == seat
    serve.BackgroundTransparency = if serving then 0 else 0.65
    kick.BackgroundTransparency = if status.receiver == seat and status.phase ~= "serve" then 0 else 0.65
    head.BackgroundTransparency = if status.receiver == seat and status.phase ~= "serve" then 0 else 0.65
    local nextBounce = if status.isServe then "2-й отскок открывает удар ногой"
        else "после 1-го отскока можно бить ногой"
    help.Text = "Подача по диагонали: 2 отскока, гол после 3-го. Остальные: гол после 2-го. " ..
        nextBounce .. ". Головой с лёта разрешено; забитый гол головой = 5 и вылет."
end

local function receive(nextStatus)
    if type(nextStatus) ~= "table" or type(nextStatus.revision) ~= "number" then return end
    if nextStatus.revision < status.revision then return end
    status = nextStatus
    if selectedTarget == status.seat or (selectedTarget ~= 0 and
        (not status.seats[selectedTarget] or status.seats[selectedTarget].out or
            not status.seats[selectedTarget].occupied)) then
        for i=1,4 do
            if i ~= status.seat and status.seats[i] and status.seats[i].occupied
                and not status.seats[i].out then
                selectedTarget = i
                break
            end
        end
    end
    draw()
end
stateRemote.OnClientEvent:Connect(receive)
task.spawn(function()
    local ok,response = pcall(function() return getState:InvokeServer() end)
    if ok then receive(response) end
end)

local camera = Workspace.CurrentCamera
if camera then camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
fit()
draw()
