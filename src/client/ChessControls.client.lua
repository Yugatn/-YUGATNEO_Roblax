-- YUGATNEO Chess client: lobby, HUD, Scriptable camera locked to table.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("ChessControlEvent")

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

local myTableId = nil
local mySide = nil
local cameraConn = nil
local highlighted = {}

local function round(inst, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = inst
end

local gui = Instance.new("ScreenGui")
gui.Name = "YUGATNEOChessControls"
gui.ResetOnSpawn = false
gui.DisplayOrder = 25
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "HUD"
panel.Position = UDim2.new(0, 16, 0, 16)
panel.Size = UDim2.new(0, 300, 0, 220)
panel.BackgroundColor3 = COLORS.panel
panel.BorderSizePixel = 0
panel.Parent = gui
round(panel, 14)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -24, 0, 28)
title.Position = UDim2.new(0, 12, 0, 8)
title.BackgroundTransparency = 1
title.Text = "♔  YUGATNEO CHESS"
title.TextColor3 = COLORS.gold
title.Font = Enum.Font.GothamBlack
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.Position = UDim2.new(0, 12, 0, 42)
statusLabel.Size = UDim2.new(1, -24, 0, 48)
statusLabel.BackgroundColor3 = COLORS.panel2
statusLabel.TextColor3 = COLORS.text
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 13
statusLabel.TextWrapped = true
statusLabel.Text = "Walk to a blue Join Pad and hold E to sit at a table."
statusLabel.Parent = panel
round(statusLabel, 8)

local function makeBtn(name, text, y, color)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Position = UDim2.new(0, 12, 0, y)
	b.Size = UDim2.new(1, -24, 0, 32)
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = COLORS.text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.Parent = panel
	round(b, 8)
	return b
end

local readyBtn = makeBtn("Ready", "I'M READY", 100, COLORS.green)
local cancelBtn = makeBtn("Cancel", "LEAVE TABLE", 138, Color3.fromRGB(69, 79, 96))
local resignBtn = makeBtn("Resign", "RESIGN", 176, COLORS.red)
resignBtn.Visible = false

local promotionPanel = Instance.new("Frame")
promotionPanel.AnchorPoint = Vector2.new(0.5, 0.5)
promotionPanel.Position = UDim2.fromScale(0.5, 0.5)
promotionPanel.Size = UDim2.new(0, 320, 0, 110)
promotionPanel.BackgroundColor3 = COLORS.panel
promotionPanel.Visible = false
promotionPanel.Parent = gui
round(promotionPanel, 12)
local promoTitle = Instance.new("TextLabel")
promoTitle.Size = UDim2.new(1, -20, 0, 28)
promoTitle.Position = UDim2.new(0, 10, 0, 6)
promoTitle.BackgroundTransparency = 1
promoTitle.Text = "PROMOTE PAWN"
promoTitle.TextColor3 = COLORS.gold
promoTitle.Font = Enum.Font.GothamBlack
promoTitle.TextSize = 15
promoTitle.Parent = promotionPanel
for i, choice in ipairs({ "Queen", "Rook", "Bishop", "Knight" }) do
	local b = Instance.new("TextButton")
	b.Position = UDim2.new(0, 12 + (i - 1) * 76, 0, 44)
	b.Size = UDim2.new(0, 70, 0, 48)
	b.BackgroundColor3 = COLORS.panel2
	b.Text = choice
	b.TextColor3 = COLORS.text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 11
	b.Parent = promotionPanel
	round(b, 8)
	b.Activated:Connect(function()
		promotionPanel.Visible = false
		event:FireServer("Promote", choice)
	end)
end

local function restoreHighlights()
	for tile, color in pairs(highlighted) do
		if tile and tile.Parent then tile.Color = color end
	end
	table.clear(highlighted)
end

local function lockCamera(origin)
	local cam = workspace.CurrentCamera
	if not cam or not origin then return end
	cam.CameraType = Enum.CameraType.Scriptable
	local focus = Vector3.new(origin.x, origin.y + 1, origin.z)
	local pos = focus + Vector3.new(0, 28, 32)
	if cameraConn then cameraConn:Disconnect() end
	cameraConn = RunService.RenderStepped:Connect(function()
		if cam.CameraType ~= Enum.CameraType.Scriptable then return end
		cam.CFrame = CFrame.new(pos, focus)
	end)
end

local function unlockCamera()
	if cameraConn then cameraConn:Disconnect() cameraConn = nil end
	local cam = workspace.CurrentCamera
	if cam then cam.CameraType = Enum.CameraType.Custom end
end

readyBtn.Activated:Connect(function()
	event:FireServer("Ready", true)
end)

cancelBtn.Activated:Connect(function()
	if cancelBtn.Text == "CLEAR TABLE" then
		event:FireServer("ClearFinished")
	else
		event:FireServer("Cancel")
	end
end)

resignBtn.Activated:Connect(function()
	event:FireServer("Resign")
end)

event.OnClientEvent:Connect(function(action, tableId, payload, extra)
	if action == "Joined" then
		myTableId = tableId
		mySide = payload and payload.side
		local st = payload and payload.state
		statusLabel.Text = string.format("Table %s · You are %s\n%s", tostring(tableId), tostring(mySide), st and st.statusText or "Waiting")
		if st and st.origin then lockCamera(st.origin) end
		resignBtn.Visible = false
		readyBtn.Visible = true
		cancelBtn.Visible = true
		cancelBtn.Text = "LEAVE TABLE"
	elseif action == "Lobby" or action == "TableState" then
		if tableId and myTableId and tableId ~= myTableId then return end
		local st = payload
		if st then
			statusLabel.Text = string.format(
				"Table %s · %s\n%s vs %s\n%s",
				st.tableId, st.state, st.whiteName, st.blackName, st.statusText or ""
			)
			if st.origin then lockCamera(st.origin) end
			local playing = st.state == "Playing"
			resignBtn.Visible = playing
			readyBtn.Visible = st.state == "Ready" or st.state == "Waiting"
			if st.state == "Finished" then
				cancelBtn.Text = "CLEAR TABLE"
				cancelBtn.Visible = true
				readyBtn.Visible = false
			elseif st.state == "Ready" or st.state == "Waiting" then
				cancelBtn.Text = "LEAVE TABLE"
				cancelBtn.Visible = true
			else
				cancelBtn.Visible = false
			end
		end
	elseif action == "MatchStarted" then
		statusLabel.Text = "Match started — " .. (payload and payload.statusText or "White to move")
		resignBtn.Visible = true
		readyBtn.Visible = false
		cancelBtn.Visible = false
		if payload and payload.origin then lockCamera(payload.origin) end
	elseif action == "MatchEnded" then
		local st = payload or {}
		statusLabel.Text = string.format("Finished: %s\n%s", tostring(st.endReason), st.statusText or "")
		resignBtn.Visible = false
		readyBtn.Visible = false
		cancelBtn.Text = "CLEAR TABLE"
		cancelBtn.Visible = true
	elseif action == "LeftTable" then
		myTableId = nil
		mySide = nil
		restoreHighlights()
		unlockCamera()
		statusLabel.Text = "Left table. Walk to a Join Pad to play again."
		readyBtn.Visible = true
		cancelBtn.Visible = true
		cancelBtn.Text = "LEAVE TABLE"
		resignBtn.Visible = false
	elseif action == "Status" then
		if type(payload) == "string" then
			statusLabel.Text = payload
		end
	elseif action == "LegalMoves" then
		restoreHighlights()
		local folder = workspace:FindFirstChild("Table_" .. tostring(tableId or myTableId))
		local board = folder and folder:FindFirstChild("Board")
		if not board then return end
		local fromRow = extra and extra.fromRow
		local fromCol = extra and extra.fromCol
		if fromRow and fromCol then
			local originTile = board:FindFirstChild("Square_" .. fromRow .. "_" .. fromCol)
			if originTile then
				highlighted[originTile] = originTile.Color
				originTile.Color = COLORS.gold
			end
		end
		for _, move in ipairs(payload or {}) do
			local tile = board:FindFirstChild("Square_" .. move.row .. "_" .. move.col)
			if tile then
				highlighted[tile] = tile.Color
				tile.Color = COLORS.green
			end
		end
	elseif action == "ClearHighlights" then
		restoreHighlights()
	elseif action == "PromotionRequired" then
		promotionPanel.Visible = true
	elseif action == "PromotionHide" then
		promotionPanel.Visible = false
	elseif action == "Error" then
		statusLabel.Text = "Error: " .. tostring(payload)
	end
end)

print("[YUGATNEO] Chess client ready — use Join Pad ProximityPrompt.")
