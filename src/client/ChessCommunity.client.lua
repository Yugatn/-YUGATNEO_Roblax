local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("ChessControlEvent")
local gui = Instance.new("ScreenGui")
gui.Name = "YUGATNEO_Tournaments"
gui.ResetOnSpawn = false
gui.DisplayOrder = 19
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "CommunityPanel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -15, 0, 18)
panel.Size = UDim2.fromOffset(280, 420)
panel.BackgroundColor3 = Color3.fromRGB(8, 17, 31)
panel.BackgroundTransparency = 0.04
panel.BorderSizePixel = 0
panel.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel

local function label(text, y, height, size, color)
    local obj = Instance.new("TextLabel")
    obj.Position = UDim2.fromOffset(10, y)
    obj.Size = UDim2.new(1, -20, 0, height)
    obj.BackgroundTransparency = 1
    obj.Font = Enum.Font.GothamBold
    obj.TextSize = size or 13
    obj.TextColor3 = color or Color3.fromRGB(224, 244, 250)
    obj.TextWrapped = true
    obj.TextXAlignment = Enum.TextXAlignment.Left
    obj.TextYAlignment = Enum.TextYAlignment.Top
    obj.Text = text
    obj.Parent = panel
    return obj
end
local title = label("♔ YUGATNEO / CHESS HUB", 10, 26, 17, Color3.fromRGB(70, 255, 210))
local stateText = label("Queue for a match or watch a live game.", 43, 48, 13)
local bracket = label("4-player knockout: semifinals and final", 177, 95, 12, Color3.fromRGB(170, 224, 240))
local scores = label("GLOBAL WINS: loading...", 295, 90, 12, Color3.fromRGB(230, 196, 115))

local function button(text, x, y, w, callback)
    local b = Instance.new("TextButton")
    b.Position = UDim2.fromOffset(x, y)
    b.Size = UDim2.fromOffset(w, 30)
    b.BackgroundColor3 = Color3.fromRGB(30, 90, 120)
    b.BorderSizePixel = 0
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Text = text
    b.Parent = panel
    local round = Instance.new("UICorner")
    round.CornerRadius = UDim.new(0, 7)
    round.Parent = b
    b.Activated:Connect(callback)
end

button("CASUAL", 10, 98, 82, function() event:FireServer("QueueCasual") end)
button("TOURNEY", 99, 98, 90, function() event:FireServer("QueueTournament") end)
button("LEAVE", 196, 98, 74, function() event:FireServer("LeaveQueue") end)

local spectator = nil
local cameraConnection
local function release()
    spectator = nil
    if cameraConnection then cameraConnection:Disconnect() cameraConnection = nil end
    local camera = workspace.CurrentCamera
    if camera then camera.CameraType = Enum.CameraType.Custom end
end
local function view(origin, id)
    if player:GetAttribute("InChessMatch") then return end
    release()
    spectator = id
    cameraConnection = RunService.RenderStepped:Connect(function()
        if not spectator or player:GetAttribute("InChessMatch") then release() return end
        local camera = workspace.CurrentCamera
        if not camera then return end
        camera.CameraType = Enum.CameraType.Scriptable
        local focus = Vector3.new(origin.x, origin.y, origin.z)
        camera.CFrame = CFrame.new(focus + Vector3.new(0, 32, 41), focus)
    end)
    stateText.Text = "Watching table " .. tostring(id) .. " | EXIT VIEW to explore."
end
for i=1,3 do
    local id = tostring(i)
    button("WATCH " .. id, 10 + (i-1)*88, 135, 80,
        function() event:FireServer("Spectate", id) end)
end
button("EXIT VIEW", 10, 384, 120, release)
button("REFRESH", 141, 384, 129, function() event:FireServer("ListTables") end)

player:GetAttributeChangedSignal("InChessMatch"):Connect(function()
    if player:GetAttribute("InChessMatch") then release() end
end)

event.OnClientEvent:Connect(function(action, id, payload)
    if action == "Community" then
        local data = payload or {}
        stateText.Text = string.format("Casual waiting: %d | Tournament waiting: %d",
            data.casual or 0, data.waitingTournament or 0)
        local t = data.bracket or {}
        local lines = {"BRACKET: " .. tostring(t.stage or "Registration")}
        if t.first then
            table.insert(lines, t.first .. " → " .. tostring(t.winner1))
            table.insert(lines, t.second .. " → " .. tostring(t.winner2))
        else
            table.insert(lines, "Four queued players start a bracket.")
        end
        if t.champion then table.insert(lines, "Champion: " .. t.champion) end
        bracket.Text = table.concat(lines, "\n")
        local rankings = {"GLOBAL VICTORIES"}
        for i, v in ipairs(data.global or {}) do
            if i > 5 then break end
            table.insert(rankings, i .. ". " .. tostring(v.name) .. " — " .. tostring(v.wins))
        end
        if #rankings == 1 then table.insert(rankings, "Unavailable or no results yet") end
        scores.Text = table.concat(rankings, "\n")
    elseif action == "SpectateTable" then
        if payload and payload.origin then view(payload.origin, id) end
    elseif action == "TournamentNotice" then
        if type(payload) == "string" then stateText.Text = payload end
    end
end)
event:FireServer("ListTables")
