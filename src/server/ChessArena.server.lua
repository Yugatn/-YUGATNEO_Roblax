-- YUGATNEO Roblox Chess Arena
-- Server-authoritative chess rules powered by ChessEngine.

local Players = game:GetService("Players")
local ChessEngine = require(script.Parent:WaitForChild("ChessEngine"))

local TILE = 4
local BOARD_Y = 1
local PIECE_Y = BOARD_Y + 0.18
local ORIGIN = Vector3.new(-16, BOARD_Y, -16)
local BOARD_NAME = "YUGATNEO_ChessArena"

local old = workspace:FindFirstChild(BOARD_NAME)
if old then
	old:Destroy()
end

local arena = Instance.new("Folder")
arena.Name = BOARD_NAME
arena.Parent = workspace

local boardFolder = Instance.new("Folder")
boardFolder.Name = "Board"
boardFolder.Parent = arena

local piecesFolder = Instance.new("Folder")
piecesFolder.Name = "Pieces"
piecesFolder.Parent = arena

local controlEvent = Instance.new("RemoteEvent")
controlEvent.Name = "ChessControlEvent"
controlEvent.Parent = game:GetService("ReplicatedStorage")

local statusPart = Instance.new("Part")
statusPart.Name = "GameStatusBoard"
statusPart.Anchored = true
statusPart.CanCollide = false
statusPart.Size = Vector3.new(18, 5, 0.5)
statusPart.Position = Vector3.new(0, 8, -22)
statusPart.Material = Enum.Material.SmoothPlastic
statusPart.Color = Color3.fromRGB(20, 24, 32)
statusPart.Parent = arena

local surfaceGui = Instance.new("SurfaceGui")
surfaceGui.Face = Enum.NormalId.Front
surfaceGui.PixelsPerStud = 45
surfaceGui.Parent = statusPart

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.fromScale(1, 1)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
statusLabel.TextScaled = true
statusLabel.Font = Enum.Font.GothamBold
statusLabel.Text = "YUGATNEO CHESS | White to move"
statusLabel.Parent = surfaceGui

local function setStatus(text)
	statusLabel.Text = "YUGATNEO CHESS\n" .. text
	controlEvent:FireAllClients("Status", text)
end

local tiles = {}
local occupancy = {}
local currentTurn = "White"
local engineState = ChessEngine.newGame()
local selectedPiece = nil
local selectedTile = nil
local pendingPromotion = nil
local pendingPromotionUserId = nil
local selectedByUserId = nil
local gameOver = false
local botEnabled = false
local botThinking = false
local botMove
local tryMove

-- This prototype has one shared board. Only the two seated players may move:
-- the first player is White, the second is Black; additional players spectate.
local playerSides = {}
local seatPlayers = { White = nil, Black = nil }
local hostUserId = nil

local function assignPlayer(player)
	if playerSides[player.UserId] then return end
	if not seatPlayers.White then
		seatPlayers.White = player.UserId
		playerSides[player.UserId] = "White"
	elseif not seatPlayers.Black then
		seatPlayers.Black = player.UserId
	end
	if playerSides[player.UserId] == "Black" then
		seatPlayers.Black = player.UserId
		playerSides[player.UserId] = "Black"
	end
	if not hostUserId then hostUserId = player.UserId end
	controlEvent:FireClient(player, "SeatAssigned", playerSides[player.UserId] or "Spectator")
end

for _, player in ipairs(Players:GetPlayers()) do
	assignPlayer(player)
end
Players.PlayerAdded:Connect(assignPlayer)
Players.PlayerRemoving:Connect(function(player)
	local side = playerSides[player.UserId]
	if side and seatPlayers[side] == player.UserId then
		seatPlayers[side] = nil
		gameOver = true
		pendingPromotion = nil
		pendingPromotionUserId = nil
		selectedPiece = nil
		selectedByUserId = nil
		setStatus(player.Name .. " left; match stopped. A new game requires two seated players.")
	end
	playerSides[player.UserId] = nil
	if hostUserId == player.UserId then
		hostUserId = seatPlayers.White or seatPlayers.Black
	end
end)

local WHITE = Color3.fromRGB(238, 232, 218)
local BLACK = Color3.fromRGB(65, 75, 91)
local SELECTED = Color3.fromRGB(75, 190, 130)
local WHITE_PIECE = Color3.fromRGB(245, 245, 240)
local BLACK_PIECE = Color3.fromRGB(35, 40, 50)
local GOLD = Color3.fromRGB(222, 175, 65)

local function key(row, col)
	return tostring(row) .. "," .. tostring(col)
end

local function inside(row, col)
	return row >= 1 and row <= 8 and col >= 1 and col <= 8
end

local function squarePosition(row, col, y)
	return Vector3.new((col - 4.5) * TILE, y or PIECE_Y, (row - 4.5) * TILE)
end

local function addPart(model, name, size, offset, color, shape, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		part.Shape = shape
	end
	part.CFrame = model:GetPivot() * CFrame.new(offset)
	part.Parent = model
	return part
end

local function makePiece(pieceType, side, row, col)
	local model = Instance.new("Model")
	model.Name = side .. "_" .. pieceType .. "_" .. row .. "_" .. col
	model:SetAttribute("PieceType", pieceType)
	model:SetAttribute("Side", side)
	model:SetAttribute("Row", row)
	model:SetAttribute("Col", col)

	local color = side == "White" and WHITE_PIECE or BLACK_PIECE
	local accent = side == "White" and Color3.fromRGB(185, 190, 195) or GOLD
	local base = Instance.new("Part")
	base.Name = "ClickableBase"
	base.Shape = Enum.PartType.Cylinder
	base.Size = Vector3.new(0.42, 1.35, 1.35)
	base.Anchored = true
	base.CanCollide = false
	base.Material = Enum.Material.Metal
	base.Color = color
	base.CFrame = CFrame.new(squarePosition(row, col, PIECE_Y)) * CFrame.Angles(0, 0, math.rad(90))
	base.Parent = model
	model.PrimaryPart = base

	local function cylinder(name, diameter, height, y, partColor)
		local p = Instance.new("Part")
		p.Name = name
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(height, diameter, diameter)
		p.Anchored = true
		p.CanCollide = false
		p.Material = Enum.Material.SmoothPlastic
		p.Color = partColor
		p.CFrame = CFrame.new(squarePosition(row, col, PIECE_Y + y)) * CFrame.Angles(0, 0, math.rad(90))
		p.Parent = model
		return p
	end

	local function ball(name, diameter, y, partColor)
		local p = Instance.new("Part")
		p.Name = name
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.new(diameter, diameter, diameter)
		p.Anchored = true
		p.CanCollide = false
		p.Material = Enum.Material.SmoothPlastic
		p.Color = partColor
		p.Position = squarePosition(row, col, PIECE_Y + y)
		p.Parent = model
		return p
	end

	-- Stronger silhouettes: a broad foot, tapered-looking body, and type-specific top.
	cylinder("Collar", 1.02, 0.25, 0.82, accent)
	cylinder("Body", 0.72, 0.82, 1.25, color)

	if pieceType == "Pawn" then
		cylinder("Neck", 0.48, 0.28, 1.72, color)
		ball("Head", 0.62, 1.98, color)
	elseif pieceType == "Rook" then
		cylinder("Tower", 0.95, 0.55, 1.82, color)
		for i = 1, 4 do
			local crenel = Instance.new("Part")
			crenel.Name = "Crenellation"
			crenel.Size = Vector3.new(0.22, 0.3, 0.22)
			crenel.Anchored = true
			crenel.CanCollide = false
			crenel.Color = accent
			local angle = (i - 1) * math.pi / 2
			crenel.Position = squarePosition(row, col, PIECE_Y + 2.2) + Vector3.new(math.cos(angle) * 0.31, 0, math.sin(angle) * 0.31)
			crenel.Parent = model
		end
	elseif pieceType == "Knight" then
		local head = Instance.new("Part")
		head.Name = "HorseHead"
		head.Size = Vector3.new(0.48, 0.92, 0.42)
		head.Anchored = true
		head.CanCollide = false
		head.Color = color
		head.CFrame = CFrame.new(squarePosition(row, col, PIECE_Y + 1.9)) * CFrame.Angles(math.rad(-12), 0, math.rad(-10))
		head.Parent = model
		local ear = Instance.new("Part")
		ear.Name = "Ear"
		ear.Size = Vector3.new(0.18, 0.36, 0.18)
		ear.Anchored = true
		ear.CanCollide = false
		ear.Color = accent
		ear.Position = squarePosition(row, col, PIECE_Y + 2.48)
		ear.Parent = model
	elseif pieceType == "Bishop" then
		cylinder("MitreBase", 0.72, 0.24, 1.78, color)
		local mitre = Instance.new("Part")
		mitre.Name = "PointedMitre"
		mitre.Shape = Enum.PartType.Ball
		mitre.Size = Vector3.new(0.54, 0.72, 0.54)
		mitre.Anchored = true
		mitre.CanCollide = false
		mitre.Color = color
		mitre.Position = squarePosition(row, col, PIECE_Y + 2.05)
		mitre.Parent = model
		ball("MitreTip", 0.18, 2.42, accent)
	elseif pieceType == "Queen" then
		cylinder("Crown", 1.02, 0.28, 1.88, color)
		for i = 1, 5 do
			local angle = (i - 1) * (2 * math.pi / 5)
			local point = Instance.new("Part")
			point.Name = "CrownPoint"
			point.Shape = Enum.PartType.Ball
			point.Size = Vector3.new(0.24, 0.24, 0.24)
			point.Anchored = true
			point.CanCollide = false
			point.Color = accent
			point.Position = squarePosition(row, col, PIECE_Y + 2.12) + Vector3.new(math.cos(angle) * 0.36, 0, math.sin(angle) * 0.36)
			point.Parent = model
		end
	elseif pieceType == "King" then
		cylinder("RoyalCrown", 0.9, 0.3, 1.88, color)
		addPart(model, "CrossVertical", Vector3.new(0.18, 0.72, 0.18), Vector3.new(0, 2.42, 0), accent)
		addPart(model, "CrossHorizontal", Vector3.new(0.5, 0.16, 0.16), Vector3.new(0, 2.47, 0), accent)
	end

	-- A readable letter badge makes the piece type obvious from the camera.
	local badge = Instance.new("BillboardGui")
	badge.Name = "PieceBadge"
	badge.Size = UDim2.fromOffset(38, 38)
	badge.StudsOffset = Vector3.new(0, 3.0, 0)
	badge.AlwaysOnTop = true
	badge.MaxDistance = 120
	badge.Parent = base
	local badgeText = Instance.new("TextLabel")
	badgeText.Size = UDim2.fromScale(1, 1)
	badgeText.BackgroundColor3 = side == "White" and Color3.fromRGB(30, 35, 45) or Color3.fromRGB(245, 240, 225)
	badgeText.BackgroundTransparency = 0.1
	badgeText.TextColor3 = side == "White" and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(20, 25, 35)
	badgeText.Font = Enum.Font.GothamBlack
	badgeText.TextScaled = true
	badgeText.Text = ({Pawn="P", Rook="R", Knight="N", Bishop="B", Queen="Q", King="K"})[pieceType]
	badgeText.Parent = badge
	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0.5, 0)
	badgeCorner.Parent = badgeText

	model.Parent = piecesFolder
	occupancy[key(row, col)] = model

	local function onPieceClicked(player)
		if gameOver or pendingPromotion then return end
		if playerSides[player.UserId] ~= currentTurn then return end
		local currentRow = model:GetAttribute("Row")
		local currentCol = model:GetAttribute("Col")
		if model.Parent and occupancy[key(currentRow, currentCol)] == model then
			if model:GetAttribute("Side") == currentTurn then
				if selectedPiece == model then
					selectedPiece = nil
					selectedByUserId = nil
					controlEvent:FireAllClients("ClearHighlights")
					setStatus(currentTurn .. " to move")
				else
					selectedPiece = model
					selectedByUserId = player.UserId
					local legal = ChessEngine.legalMoves(engineState, currentRow, currentCol)
					controlEvent:FireAllClients("LegalMoves", legal, currentRow, currentCol)
					setStatus(currentTurn .. " to move | Selected: " .. pieceType)
				end
			elseif selectedPiece then
				-- Clicking an opposing piece attempts to capture it on its square.
				tryMove(currentRow, currentCol, nil, player)
			end
		end
	end

	-- Attach a detector to every visible part so the upper shape is clickable too.
	for _, descendant in ipairs(model:GetChildren()) do
		if descendant:IsA("BasePart") then
			local click = Instance.new("ClickDetector")
			click.MaxActivationDistance = 80
			click.Parent = descendant
			click.MouseClick:Connect(onPieceClicked)
		end
	end

	return model
end

-- Build the board and wire square clicks.
for row = 1, 8 do
	tiles[row] = {}
	for col = 1, 8 do
		local tile = Instance.new("Part")
		tile.Name = "Square_" .. row .. "_" .. col
		tile.Anchored = true
		tile.Size = Vector3.new(TILE, 0.35, TILE)
		tile.Position = Vector3.new((col - 4.5) * TILE, BOARD_Y, (row - 4.5) * TILE)
		tile.Material = Enum.Material.SmoothPlastic
		tile.Color = ((row + col) % 2 == 0) and WHITE or BLACK
		tile.Parent = boardFolder
		tile:SetAttribute("Row", row)
		tile:SetAttribute("Col", col)
		tiles[row][col] = tile

		local click = Instance.new("ClickDetector")
		click.MaxActivationDistance = 100
		click.Parent = tile
		click.MouseClick:Connect(function(player)
			if selectedPiece then
				tryMove(row, col, nil, player)
			end
		end)
	end
end

local function pathIsClear(fromRow, fromCol, toRow, toCol)
	local rowStep = toRow == fromRow and 0 or (toRow > fromRow and 1 or -1)
	local colStep = toCol == fromCol and 0 or (toCol > fromCol and 1 or -1)
	local row = fromRow + rowStep
	local col = fromCol + colStep
	while row ~= toRow or col ~= toCol do
		if occupancy[key(row, col)] then
			return false
		end
		row += rowStep
		col += colStep
	end
	return true
end

local function isValidMove(piece, toRow, toCol)
	if not piece or not piece.Parent then return false end
	local row, col = piece:GetAttribute("Row"), piece:GetAttribute("Col")
	for _, move in ipairs(ChessEngine.legalMoves(engineState, row, col)) do
		if move.row == toRow and move.col == toCol then return true end
	end
	return false
end

tryMove = function(toRow, toCol, promotionChoice, player)
	if gameOver then return end
	if not player or playerSides[player.UserId] ~= currentTurn then return end
	if selectedByUserId ~= player.UserId then return end
	if pendingPromotion and not promotionChoice then return end
	if not selectedPiece or not selectedPiece.Parent then
		selectedPiece = nil
		return
	end
	local piece = selectedPiece
	if piece:GetAttribute("Side") ~= currentTurn then
		selectedPiece = nil
		return
	end

	local fromRow, fromCol = piece:GetAttribute("Row"), piece:GetAttribute("Col")
	local side = piece:GetAttribute("Side")
	local pieceType = piece:GetAttribute("PieceType")
	if pieceType == "Pawn" and (toRow == 1 or toRow == 8) and not promotionChoice then
		pendingPromotion = { row = toRow, col = toCol }
		pendingPromotionUserId = player.UserId
		controlEvent:FireClient(player, "PromotionRequired")
		setStatus("Choose a piece for pawn promotion")
		return
	end
	local success, result, captured, move = ChessEngine.move(engineState, fromRow, fromCol, toRow, toCol, promotionChoice or "Queen")
	if not success then
		setStatus(currentTurn .. " to move | " .. tostring(result))
		return
	end

	local captureRow = move.enPassant and (toRow + (side == "White" and -1 or 1)) or toRow
	local capturedModel = occupancy[key(captureRow, toCol)]
	if capturedModel and capturedModel ~= piece then
		occupancy[key(captureRow, toCol)] = nil
		capturedModel:Destroy()
	end

	occupancy[key(fromRow, fromCol)] = nil
	occupancy[key(toRow, toCol)] = piece
	piece:SetAttribute("Row", toRow)
	piece:SetAttribute("Col", toCol)

	if move.castle then
		local home = side == "White" and 1 or 8
		local rookFromCol = move.castle == "kingSide" and 8 or 1
		local rookToCol = move.castle == "kingSide" and 6 or 4
		local rook = occupancy[key(home, rookFromCol)]
		if rook then
			occupancy[key(home, rookFromCol)] = nil
			occupancy[key(home, rookToCol)] = rook
			rook:SetAttribute("Row", home)
			rook:SetAttribute("Col", rookToCol)
			rook:PivotTo(CFrame.new(squarePosition(home, rookToCol, PIECE_Y)) * CFrame.Angles(0, 0, math.rad(90)))
		end
	end

	piece:PivotTo(CFrame.new(squarePosition(toRow, toCol, PIECE_Y)) * CFrame.Angles(0, 0, math.rad(90)))
	local promoted = pieceType == "Pawn" and (toRow == 1 or toRow == 8)
	if promoted then
		local promotedType = (promotionChoice == "Queen" or promotionChoice == "Rook" or promotionChoice == "Bishop" or promotionChoice == "Knight") and promotionChoice or "Queen"
		piece:Destroy()
		occupancy[key(toRow, toCol)] = nil
		piece = makePiece(promotedType, side, toRow, toCol)
	end

	selectedPiece = nil
	selectedByUserId = nil
	pendingPromotion = nil
	controlEvent:FireAllClients("ClearHighlights")
	currentTurn = engineState.turn
	local status = ChessEngine.status(engineState)
	gameOver = status.gameOver
	setStatus(status.text)
	if botEnabled and currentTurn == "Black" and not gameOver then
		task.delay(0.6, function()
			if botMove and botEnabled and currentTurn == "Black" and not gameOver then
				botMove()
			end
		end)
	end
end

botMove = function()
	if botThinking or not botEnabled or gameOver or currentTurn ~= "Black" then return end
	botThinking = true
	local candidates = ChessEngine.allLegalMoves(engineState, "Black")
	if #candidates == 0 then botThinking = false; return end
	local bestScore = -math.huge
	local bestMoves = {}
	local values = { Pawn = 1, Knight = 3, Bishop = 3.2, Rook = 5, Queen = 9, King = 100 }
	for _, candidate in ipairs(candidates) do
		local moving = engineState.board[candidate.fromRow][candidate.fromCol]
		local target = engineState.board[candidate.row][candidate.col]
		local score = math.random() * 0.3
		if target then score += 1.5 + (values[target.type] or 0) * 0.9 - (values[moving.type] or 1) * 0.04 end
		if moving.type == "Pawn" and (candidate.row == 1 or candidate.row == 8) then score += 8 end
		local simulated = ChessEngine.copy(engineState)
		ChessEngine.move(simulated, candidate.fromRow, candidate.fromCol, candidate.row, candidate.col, "Queen")
		if ChessEngine.inCheck(simulated, "White") then score += 1.25 end
		if ChessEngine.inCheck(simulated, "Black") then score -= 1.5 end
		if score > bestScore then bestScore = score; bestMoves = { candidate }
		elseif score >= bestScore - 0.25 then table.insert(bestMoves, candidate) end
	end
	local chosen = bestMoves[math.random(1, #bestMoves)]
	local model = occupancy[key(chosen.fromRow, chosen.fromCol)]
	if model then
		selectedPiece = model
		selectedByUserId = -1
		tryMove(chosen.row, chosen.col, "Queen", { UserId = -1 })
	end
	botThinking = false
end

local backRank = {"Rook", "Knight", "Bishop", "Queen", "King", "Bishop", "Knight", "Rook"}

local function resetGame()
	botThinking = false
	piecesFolder:ClearAllChildren()
	table.clear(occupancy)
	selectedPiece = nil
	selectedByUserId = nil
	pendingPromotion = nil
	pendingPromotionUserId = nil
	gameOver = false
	currentTurn = "White"
	engineState = ChessEngine.newGame()
	for col = 1, 8 do
		makePiece(backRank[col], "White", 1, col)
		makePiece("Pawn", "White", 2, col)
		makePiece(backRank[col], "Black", 8, col)
		makePiece("Pawn", "Black", 7, col)
	end
	setStatus("White to move | New game")
end

controlEvent.OnServerEvent:Connect(function(player, action, choice)
	if action == "PlayBot" then
		if seatPlayers.White ~= player.UserId or (seatPlayers.Black ~= nil and seatPlayers.Black ~= -1) then
			controlEvent:FireClient(player, "Status", "Practice mode is available when you have the White seat and no human opponent is seated.")
			return
		end
		botEnabled = true
		playerSides[-1] = "Black"
		seatPlayers.Black = -1
		hostUserId = player.UserId
		resetGame()
		controlEvent:FireClient(player, "Status", "Practice vs Bot — you are White. Select a piece, then a green square.")
	elseif action == "Promote" then
		if pendingPromotion and selectedPiece and pendingPromotionUserId == player.UserId and selectedByUserId == player.UserId then
			local pending = pendingPromotion
			pendingPromotion = nil
			pendingPromotionUserId = nil
			tryMove(pending.row, pending.col, choice, player)
		end
	elseif action == "Reset" then
		if player.UserId == hostUserId and seatPlayers.White and seatPlayers.Black then
			resetGame()
		else
			controlEvent:FireClient(player, "Status", "Only the table host can reset, and two players must be seated.")
		end
	elseif action == "Deselect" then
		if selectedByUserId ~= player.UserId then return end
		selectedPiece = nil
		selectedByUserId = nil
		pendingPromotion = nil
		pendingPromotionUserId = nil
		controlEvent:FireAllClients("PromotionHide")
		controlEvent:FireAllClients("ClearHighlights")
		setStatus(currentTurn .. " to move")
	end
end)

resetGame()

-- Spawn a simple floor under the board.
local floor = Instance.new("Part")
floor.Name = "ArenaFloor"
floor.Anchored = true
floor.Size = Vector3.new(50, 1, 50)
floor.Position = Vector3.new(0, -0.2, 0)
floor.Material = Enum.Material.Slate
floor.Color = Color3.fromRGB(28, 32, 42)
floor.Parent = arena

setStatus("White to move | Press PLAY VS BOT to practise alone")
print("YUGATNEO Chess Arena loaded: board, labelled pieces, and game controls created.")
