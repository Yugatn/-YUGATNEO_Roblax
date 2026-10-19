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
panel.Size = UDim2.new(0, 300, 0, 286)
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
local botButton = makeButton("PlayBotButton", "PLAY VS BOT", 12, 220, 276, COLORS.green)

local tip = Instance.new("TextLabel")
tip.Name = "Tip"
tip.Position = UDim2.new(0, 14, 0, 176)
tip.Size = UDim2.new(1, -28, 0, 42)
tip.BackgroundTransparency = 1
tip.Text = "1) Click PLAY VS BOT.  2) Select a piece.\n3) Click a green square to move."
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
helpText.Text = "HOW TO START\n1. Press PLAY VS BOT. You play White.\n2. Click one of your light pieces.\n3. Green squares are legal moves. Click one.\n4. The bot replies as Black.\n\nPAWN: forward, captures diagonally.\nROOK: straight lines. BISHOP: diagonals.\nQUEEN: straight + diagonal. KNIGHT: L-shape.\nKING: one square; keep it safe.\n\nGoal: checkmate the enemy king."
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
botButton.Activated:Connect(function()
	controlEvent:FireServer("PlayBot")
end)

local promotionPanel = Instance.new("Frame")
promotionPanel.Name = "PromotionChoice"
promotionPanel.AnchorPoint = Vector2.new(0.5, 0.5)
promotionPanel.Position = UDim2.fromScale(0.5, 0.5)
promotionPanel.Size = UDim2.new(0, 330, 0, 116)
promotionPanel.BackgroundColor3 = COLORS.panel
promotionPanel.BorderSizePixel = 0
promotionPanel.Visible = false
promotionPanel.Parent = gui
round(promotionPanel, 14)
stroke(promotionPanel, COLORS.gold, 0.15)

local promotionTitle = Instance.new("TextLabel")
promotionTitle.Position = UDim2.new(0, 12, 0, 8)
promotionTitle.Size = UDim2.new(1, -24, 0, 25)
promotionTitle.BackgroundTransparency = 1
promotionTitle.Text = "PROMOTE YOUR PAWN"
promotionTitle.TextColor3 = COLORS.gold
promotionTitle.Font = Enum.Font.GothamBlack
promotionTitle.TextSize = 15
promotionTitle.Parent = promotionPanel

for index, choice in ipairs({ { "Queen", "♛  QUEEN" }, { "Rook", "♜  ROOK" }, { "Bishop", "♝  BISHOP" }, { "Knight", "♞  KNIGHT" } }) do
	local button = Instance.new("TextButton")
	button.Name = choice[1] .. "Promotion"
	button.Position = UDim2.new(0, 12 + (index - 1) * 79, 0, 48)
	button.Size = UDim2.new(0, 72, 0, 48)
	button.BackgroundColor3 = COLORS.panel2
	button.BorderSizePixel = 0
	button.Text = choice[2]
	button.TextColor3 = COLORS.text
	button.Font = Enum.Font.GothamBold
	button.TextSize = 10
	button.TextWrapped = true
	button.Parent = promotionPanel
	round(button, 8)
	button.Activated:Connect(function()
		promotionPanel.Visible = false
		controlEvent:FireServer("Promote", choice[1])
	end)
end

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

local camera = workspace.CurrentCamera
local previousCameraType, previousCameraSubject, previousCameraCFrame, previousCameraFOV
local telescopeOverlay = Instance.new("Frame")
telescopeOverlay.Name = "TelescopeOverlay"
telescopeOverlay.AnchorPoint = Vector2.new(0.5, 0)
telescopeOverlay.Position = UDim2.new(0.5, 0, 0, 18)
telescopeOverlay.Size = UDim2.new(0, 280, 0, 54)
telescopeOverlay.BackgroundColor3 = COLORS.panel
telescopeOverlay.Visible = false
telescopeOverlay.Parent = gui
round(telescopeOverlay, 12)
stroke(telescopeOverlay, COLORS.gold, 0.15)
local telescopeLabel = Instance.new("TextLabel")
telescopeLabel.Size = UDim2.new(1, -90, 1, 0)
telescopeLabel.Position = UDim2.new(0, 12, 0, 0)
telescopeLabel.BackgroundTransparency = 1
telescopeLabel.Text = "OBSERVATORY • telescope view"
telescopeLabel.TextColor3 = COLORS.gold
telescopeLabel.Font = Enum.Font.GothamBold
telescopeLabel.TextSize = 11
telescopeLabel.Parent = telescopeOverlay
local exitTelescope = Instance.new("TextButton")
exitTelescope.Size = UDim2.new(0, 76, 0, 32)
exitTelescope.Position = UDim2.new(1, -84, 0.5, -16)
exitTelescope.BackgroundColor3 = COLORS.red
exitTelescope.Text = "EXIT"
exitTelescope.TextColor3 = COLORS.text
exitTelescope.Font = Enum.Font.GothamBold
exitTelescope.TextSize = 12
exitTelescope.Parent = telescopeOverlay
round(exitTelescope, 8)
local RunService = game:GetService("RunService")
local activeChessCameraCFrame = nil
local CAMERA_BIND_NAME = "YUGATNEO_ChessTopDownCamera"

local function releaseCamera()
	RunService:UnbindFromRenderStep(CAMERA_BIND_NAME)
	activeChessCameraCFrame = nil
	camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = previousCameraType or Enum.CameraType.Custom
		camera.CameraSubject = previousCameraSubject or (player.Character and player.Character:FindFirstChildOfClass("Humanoid"))
		if previousCameraCFrame then camera.CFrame = previousCameraCFrame end
		if previousCameraFOV then camera.FieldOfView = previousCameraFOV end
	end
end

local function stopTelescope()
	telescopeOverlay.Visible = false
	releaseCamera()
end
exitTelescope.Activated:Connect(stopTelescope)

controlEvent.OnClientEvent:Connect(function(action, payload, fromRow, fromCol)
	if action == "Telescope" or action == "ChessView" then
		camera = workspace.CurrentCamera
		if camera then
			-- Capture the normal camera state only when entering the view, not on repeated touch events.
			if camera.CameraType ~= Enum.CameraType.Scriptable or not activeChessCameraCFrame then
				previousCameraType = camera.CameraType
				previousCameraSubject = camera.CameraSubject
				previousCameraCFrame = camera.CFrame
				previousCameraFOV = camera.FieldOfView
			end
			camera.CameraType = Enum.CameraType.Scriptable
			if action == "ChessView" then
				telescopeLabel.Text = "CHESS BOARD • BOARD VIEW"
				-- Board spans about 32 studs. An oblique elevated angle avoids the edge-on
				-- appearance of a perfectly vertical camera and keeps the full board in frame.
				-- Use the board center sent by the server so camera and board cannot drift apart.
				local target = typeof(payload) == "Vector3" and payload or Vector3.new(0, 1, 0)
				local viewport = camera.ViewportSize
				local boardSpan = 36
				local verticalFov = math.rad(camera.FieldOfView)
				local aspect = math.max(viewport.X / math.max(viewport.Y, 1), 1)
				local requiredDistance = (boardSpan / 2) / math.tan(verticalFov / 2)
				local height = math.max(34, requiredDistance * 0.78)
				local depth = math.max(18, height * 0.48)
				activeChessCameraCFrame = CFrame.lookAt(target + Vector3.new(0, height, depth), target)
				camera.FieldOfView = 55
				RunService:UnbindFromRenderStep(CAMERA_BIND_NAME)
				RunService:BindToRenderStep(CAMERA_BIND_NAME, Enum.RenderPriority.Camera.Value + 1, function()
					local currentCamera = workspace.CurrentCamera
					if currentCamera then
						currentCamera.CameraType = Enum.CameraType.Scriptable
						currentCamera.CFrame = activeChessCameraCFrame
					end
				end)
			else
				activeChessCameraCFrame = nil
				RunService:UnbindFromRenderStep(CAMERA_BIND_NAME)
				telescopeLabel.Text = "OBSERVATORY • telescope view"
				camera.CFrame = CFrame.lookAt(payload + Vector3.new(0, 2, 1), Vector3.new(0, 2, 0))
			end
			camera.CFrame = activeChessCameraCFrame or camera.CFrame
			telescopeOverlay.Visible = true
		end
	elseif action == "SeatAssigned" then
		local assigned = tostring(payload)
		if assigned == "White" or assigned == "Black" then
			statusLabel.Text = "You are " .. assigned .. " — waiting for both players"
		else
			statusLabel.Text = "Spectator — both seats are occupied"
		end
	elseif action == "PromotionRequired" then
		promotionPanel.Visible = true
	elseif action == "PromotionHide" then
		promotionPanel.Visible = false
	elseif action == "Status" then
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
