-- YUGATNEO Chess Arena: on-screen controls
-- Place this LocalScript in StarterPlayer > StarterPlayerScripts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local controlEvent = ReplicatedStorage:WaitForChild("SpiralChessControlEvent")

local gui = Instance.new("ScreenGui")
gui.Name = "YUGATNEOSpiralChessControls"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "ControlPanel"
panel.AnchorPoint = Vector2.new(0, 0)
panel.Position = UDim2.new(0, 18, 0, 18)
panel.Size = UDim2.new(0, 250, 0, 178)
panel.BackgroundColor3 = Color3.fromRGB(22, 27, 38)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Position = UDim2.new(0, 12, 0, 7)
title.Size = UDim2.new(1, -24, 0, 30)
title.BackgroundTransparency = 1
title.Text = "SPIRAL CHESS // YUGATNEO MATRIX"
title.TextColor3 = Color3.fromRGB(255, 218, 125)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBlack
title.TextSize = 18
title.Parent = panel

local function makeButton(name, text, y, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = UDim2.new(0, 12, 0, y)
	button.Size = UDim2.new(1, -24, 0, 34)
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Font = Enum.Font.GothamBold
	button.TextSize = 14
	button.AutoButtonColor = true
	button.Parent = panel
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = button
	return button
end

local helpButton = makeButton("HelpButton", "How to play", 42, Color3.fromRGB(52, 89, 130))
local deselectButton = makeButton("DeselectButton", "Cancel selection", 82, Color3.fromRGB(80, 86, 99))
local resetButton = makeButton("ResetButton", "Start a new game", 122, Color3.fromRGB(153, 78, 53))

local helpPanel = Instance.new("TextLabel")
helpPanel.Name = "HelpText"
helpPanel.Position = UDim2.new(0, 18, 0, 205)
helpPanel.Size = UDim2.new(0, 310, 0, 148)
helpPanel.BackgroundColor3 = Color3.fromRGB(22, 27, 38)
helpPanel.BackgroundTransparency = 0.04
helpPanel.BorderSizePixel = 0
helpPanel.TextColor3 = Color3.fromRGB(245, 245, 245)
helpPanel.TextWrapped = true
helpPanel.TextXAlignment = Enum.TextXAlignment.Left
helpPanel.TextYAlignment = Enum.TextYAlignment.Top
helpPanel.Font = Enum.Font.Gotham
helpPanel.TextSize = 14
helpPanel.Text = "HOW TO PLAY\n1. Click one of your pieces.\n2. Click the destination square.\n3. White moves first, then Black.\n\nP pawn | R rook | N knight | B bishop | Q queen | K king\n\nPrototype note: check/checkmate and special moves are not implemented yet."
helpPanel.Visible = false
helpPanel.Parent = gui
local helpCorner = Instance.new("UICorner")
helpCorner.CornerRadius = UDim.new(0, 10)
helpCorner.Parent = helpPanel

helpButton.Activated:Connect(function()
	helpPanel.Visible = not helpPanel.Visible
	helpButton.Text = helpPanel.Visible and "Hide instructions" or "How to play"
end)

deselectButton.Activated:Connect(function()
	controlEvent:FireServer("Deselect")
end)

resetButton.Activated:Connect(function()
	controlEvent:FireServer("Reset")
end)
