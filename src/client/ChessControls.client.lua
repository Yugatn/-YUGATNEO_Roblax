-- YUGATNEO Chess: polished controls, move hints, and live status.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local controlEvent = ReplicatedStorage:WaitForChild("ChessControlEvent")

local COLORS = {
	panel = Color3.fromRGB(17, 22, 32),
	panel2 = Color3.fromRGB(27, 34, 47),
	gold = Color3.fromRGB(235, 190, 92),
	text = Color3.fromRGB(242, 244, 248),
	muted = Color3.fromRGB(166, 176, 193),
	blue = Color3.fromRGB(62, 105, 156),
	green = Color3.fromRGB(58, 143, 106),
	red = Color3.fromRGB(151, 75, 64),
}

local gui = Instance.new("ScreenGui")
gui.Name = "YUGATNEOChessControls"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 20
gui.Parent = player:WaitForChild("PlayerGui")

local function round(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
	return corner
end

local function stroke(instance, color, transparency)
	local edge = Instance.new("UIStroke")
	edge.Color = color
	edge.Transparency = transparency or 0
	edge.Thickness = 1
	edge.Parent = instance
	return edge
end

local panel = Instance.new("Frame")
panel.Name = "ControlPanel"
panel.Position = UDim2.new(0, 20, 0, 20)
panel.Size = UDim2.new(0, 300, 0, 248)
panel.BackgroundColor3 = COLORS.panel
panel.BackgroundTransparency = 0.04
panel.BorderSizePixel = 0
panel.Parent = gui
round(panel, 16)
stroke(panel, Color3.fromRGB(90, 104, 128), 0.35)

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 58)
header.BackgroundColor3 = COLORS.panel2
header.BorderSizePixel = 0
header.Parent = panel
round(header, 16)

local headerMask = Instance.new("Frame")
headerMask.Position = UDim2.new(0, 0, 1, -15)
headerMask.Size = UDim2.new(1, 0, 0, 15)
headerMask.BackgroundColor3 = COLORS.panel2
headerMask.BorderSizePixel = 0
headerMask.Parent = header

local logo = Instance.new("TextLabel")
logo.Name = "Brand"
logo.Position = UDim2.new(0, 16, 0, 7)
logo.Size = UDim2.new(1, -32, 0, 25)
logo.BackgroundTransparency = 1
logo.Text = "♔  YUGATNEO CHESS"
logo.TextColor3 = COLORS.gold
logo.Font = Enum.Font.GothamBlack
logo.TextSize = 18
logo.TextXAlignment = Enum.TextXAlignment.Left
logo.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Position = UDim2.new(0, 17, 0, 32)
subtitle.Size = UDim2.new(1, -34, 0, 16)
subtitle.BackgroundTransparency = 1
subtitle.Text = "CLASSIC CHESS • TWO SIDES • ONE BOARD"
subtitle.TextColor3 = COLORS.muted
subtitle.Font = Enum.Font.GothamMedium
subtitle.TextSize = 9
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = header

local statusCard = Instance.new("Frame")
statusCard.Name = "StatusCard"
statusCard.Position = UDim2.new(0, 12, 0, 70)
statusCard.Size = UDim2.new(1, -24, 0, 48)
statusCard.BackgroundColor3 = Color3.fromRGB(34, 43, 58)
statusCard.BorderSizePixel = 0
statusCard.Parent = panel
round(statusCard, 10)

local statusDot = Instance.new("Frame")
statusDot.Position = UDim2.new(0, 12, 0.5, -5)
statusDot.Size = UDim2.new(0, 10, 0, 10)
statusDot.BackgroundColor3 = COLORS.gold
statusDot.BorderSizePixel = 0
statusDot.Parent = statusCard
round(statusDot, 5)

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.Position = UDim2.new(0, 30, 0, 0)
statusLabel.Size = UDim2.new(1, -40, 1, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "White to move"
statusLabel.TextColor3 = COLORS.text
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 14
statusLabel.TextWrapped = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = statusCard

local function makeButton(name, label, x, y, width, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = UDim2.new(0, x, 0, y)
	button.Size = UDim2.new(0, width, 0, 36)
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Text = label
	button.TextColor3 = COLORS.text
	button.Font = Enum.Font.GothamBold
	button.TextSize = 12
	button.AutoButtonColor = true
	button.Parent = panel
	round(button, 9)
	return button
end

local helpButton = makeButton("HelpButton", "♟  RULES", 12, 130, 86, COLORS.blue)
local deselectButton = makeButton("DeselectButton", "CANCEL", 106, 130, 82, Color3.fromRGB(69, 79, 96))
local resetButton = makeButton("ResetButton", "NEW GAME", 196, 130, 92, COLORS.red)

local tip = Instance.new("TextLabel")
tip.Name = "Tip"
tip.Position = UDim2.new(0, 14, 0, 176)
tip.Size = UDim2.new(1, -28, 0, 42)
tip.BackgroundTransparency = 1
tip.Text = "Select a piece to reveal legal moves.\nClick a highlighted square to move."
tip.TextColor3 = COLORS.muted
tip.Font = Enum.Font.Gotham
tip.TextSize = 11
tip.TextWrapped = true
tip.TextXAlignment = Enum.TextXAlignment.Left
tip.TextYAlignment = Enum.TextYAlignment.Top
tip.Parent = panel

local helpPanel = Instance.new("Frame")
helpPanel.Name = "RulesPanel"
helpPanel.Position = UDim2.new(0, 20, 0, 280)
helpPanel.Size = UDim2.new(0, 300, 0, 224)
helpPanel.BackgroundColor3 = COLORS.panel
helpPanel.BorderSizePixel = 0
helpPanel.Visible = false
helpPanel.Parent = gui
round(helpPanel, 14)
stroke(helpPanel, COLORS.gold, 0.3)

local helpTitle = Instance.new("TextLabel")
helpTitle.Position = UDim2.new(0, 14, 0, 10)
helpTitle.Size = UDim2.new(1, -28, 0, 28)
helpTitle.BackgroundTransparency = 1
helpTitle.Text = "HOW TO PLAY"
helpTitle.TextColor3 = COLORS.gold
helpTitle.Font = Enum.Font.GothamBlack
helpTitle.TextSize = 17
helpTitle.TextXAlignment = Enum.TextXAlignment.Left
helpTitle.Parent = helpPanel

local helpText = Instance.new("TextLabel")
helpText.Position = UDim2.new(0, 14, 0, 44)
helpText.Size = UDim2.new(1, -28, 1, -92)
helpText.BackgroundTransparency = 1
helpText.Text = "1. Click one of your pieces.\n2. Green squares show legal destinations.\n3. Click a destination to complete the move.\n\nIncludes check, checkmate, stalemate, castling, en passant and automatic queen promotion.\n\nWhite moves first. Capturing the king is never a legal move."
helpText.TextColor3 = COLORS.text
helpText.Font = Enum.Font.Gotham
helpText.TextSize = 12
helpText.TextWrapped = true
helpText.TextXAlignment = Enum.TextXAlignment.Left
helpText.TextYAlignment = Enum.TextYAlignment.Top
helpText.Parent = helpPanel

local closeHelp = makeButton("CloseHelp", "CLOSE", 14, 184, 272, COLORS.blue)
closeHelp.Parent = helpPanel
closeHelp.Position = UDim2.new(0, 14, 1, -44)
closeHelp.Size = UDim2.new(1, -28, 0, 32)

helpButton.Activated:Connect(function()
	helpPanel.Visible = not helpPanel.Visible
end)
closeHelp.Activated:Connect(function()
	helpPanel.Visible = false
end)
deselectButton.Activated:Connect(function()
	controlEvent:FireServer("Deselect")
end)
resetButton.Activated:Connect(function()
	controlEvent:FireServer("Reset")
end)

local highlighted = {}
local function restoreHighlights()
	for tile, original in pairs(highlighted) do
		if tile and tile.Parent then tile.Color = original end
	end
	table.clear(highlighted)
end

local function getTileColor(row, col)
	return ((row + col) % 2 == 0) and Color3.fromRGB(238, 232, 218) or Color3.fromRGB(65, 75, 91)
end

controlEvent.OnClientEvent:Connect(function(action, payload, fromRow, fromCol)
	if action == "Status" then
		statusLabel.Text = tostring(payload)
		if string.find(string.lower(tostring(payload)), "checkmate") or string.find(string.lower(tostring(payload)), "stalemate") then
			statusDot.BackgroundColor3 = COLORS.red
		elseif string.find(string.lower(tostring(payload)), "check") then
			statusDot.BackgroundColor3 = COLORS.gold
		else
			statusDot.BackgroundColor3 = COLORS.green
		end
	elseif action == "ClearHighlights" then
		restoreHighlights()
	elseif action == "LegalMoves" then
		restoreHighlights()
		local arena = workspace:FindFirstChild("YUGATNEO_ChessArena")
		local board = arena and arena:FindFirstChild("Board")
		if not board then return end
		if fromRow and fromCol then
			local origin = board:FindFirstChild("Square_" .. fromRow .. "_" .. fromCol)
			if origin then
				highlighted[origin] = getTileColor(fromRow, fromCol)
				origin.Color = COLORS.gold
			end
		end
		for _, move in ipairs(payload or {}) do
			local tile = board:FindFirstChild("Square_" .. move.row .. "_" .. move.col)
			if tile then
				highlighted[tile] = getTileColor(move.row, move.col)
				tile.Color = COLORS.green
			end
		end
	end
end)
