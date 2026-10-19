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
local lastBoardRequestAt = {}

local teamMembers = { White = {}, Black = {} }
local pendingTeamQuiz = nil
local teamQuizSerial = 0
local TEAM_QUIZ_QUESTIONS = {
	{ question = "How many squares are on a chessboard?", options = { "32", "64", "81", "100" }, answer = 2 },
	{ question = "Which piece moves in an L-shape?", options = { "Bishop", "Rook", "Knight", "Pawn" }, answer = 3 },
	{ question = "What is the main goal of chess?", options = { "Capture every piece", "Checkmate the king", "Reach the last rank", "Keep the queen alive" }, answer = 2 },
	{ question = "How many kings does each player start with?", options = { "One", "Two", "Three", "Four" }, answer = 1 },
	{ question = "Which piece can jump over other pieces?", options = { "Rook", "Queen", "Knight", "King" }, answer = 3 },
	{ question = "A pawn normally captures how?", options = { "Straight ahead", "Diagonally", "Like a knight", "Any direction" }, answer = 2 },
}
local function sideMembers(side)
	local result = {}
	for userId in pairs(teamMembers[side]) do
		local player = Players:GetPlayerByUserId(userId)
		if player then table.insert(result, player) end
	end
	return result
end
local function memberCount(side)
	return #sideMembers(side)
end
local function startTeamQuiz(side, row, col, pieceType)
	if gameOver then return true end
	if pendingTeamQuiz then return true end
	local members = sideMembers(side)
	if #members < 2 then return false end
	teamQuizSerial += 1
	local q = TEAM_QUIZ_QUESTIONS[math.random(1, #TEAM_QUIZ_QUESTIONS)]
	pendingTeamQuiz = {
		id = teamQuizSerial, side = side, row = row, col = col,
		pieceType = pieceType, answer = q.answer, expiresAt = os.clock() + 20,
		answered = {},
	}
	for _, teammate in ipairs(members) do
		controlEvent:FireClient(teammate, "TeamQuiz", {
			id = teamQuizSerial, side = side, question = q.question,
			options = q.options, seconds = 20,
		})
	end
	setStatus(side .. " team quiz: first correct answer earns the move")
	task.delay(20, function()
		if pendingTeamQuiz and pendingTeamQuiz.id == teamQuizSerial then
			pendingTeamQuiz = nil
			controlEvent:FireAllClients("TeamQuizHide")
			setStatus(side .. " team quiz timed out; click a friendly piece to try again")
		end
	end)
	return true
end

local function assignPlayer(player)
	if playerSides[player.UserId] then return end
	if not seatPlayers.White then
		seatPlayers.White = player.UserId
		playerSides[player.UserId] = "White"
		teamMembers.White[player.UserId] = true
	elseif not seatPlayers.Black then
		seatPlayers.Black = player.UserId
		playerSides[player.UserId] = "Black"
		teamMembers.Black[player.UserId] = true
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
	if side then
		teamMembers[side][player.UserId] = nil
		if seatPlayers[side] == player.UserId then
			seatPlayers[side] = next(teamMembers[side])
		end
		if seatPlayers[side] == nil then
			gameOver = true
			pendingPromotion = nil
			pendingPromotionUserId = nil
			selectedPiece = nil
			selectedByUserId = nil
			setStatus(player.Name .. " left; one side has no players.")
		end
	end
	if pendingTeamQuiz then
		pendingTeamQuiz.answered[player.UserId] = true
	end
	playerSides[player.UserId] = nil
	lastBoardRequestAt[player.UserId] = nil
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


	-- Mouse selection is handled by the client raycast and validated by the server.
	-- Avoid overlapping ClickDetectors on the many decorative parts of each piece.

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

		-- The client sends a square coordinate; server-side rules validate every requested move.
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
	-- Validate the destination before asking for promotion; otherwise any last-rank square
	-- could open a promotion dialog even when the pawn cannot legally move there.
	if pieceType == "Pawn" and (toRow == 1 or toRow == 8) and not isValidMove(piece, toRow, toCol) then
		setStatus(currentTurn .. " to move | Illegal move")
		return
	end
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
	selectedTile = nil
	selectedByUserId = nil
	pendingPromotion = nil
	controlEvent:FireAllClients("ClearHighlights")
	currentTurn = engineState.turn
	local status = ChessEngine.status(engineState)
	gameOver = status.gameOver
	setStatus(status.text)
	if botEnabled and currentTurn == "Black" and not gameOver then
		task.delay(0.65, function()
			if botMove and botEnabled and currentTurn == "Black" and not gameOver then botMove() end
		end)
	end
end

botMove = function()
	if botThinking or not botEnabled or gameOver or currentTurn ~= "Black" then return end
	botThinking = true
	local candidates = ChessEngine.allLegalMoves(engineState, "Black")
	if #candidates == 0 then
		botThinking = false
		return
	end
	local bestScore = -math.huge
	local best = {}
	for _, candidate in ipairs(candidates) do
		local copy = ChessEngine.copy(engineState)
		local moving = copy.board[candidate.fromRow][candidate.fromCol]
		local target = copy.board[candidate.row][candidate.col]
		local score = math.random() * 0.4
		if target then
			local values = { Pawn = 1, Knight = 3, Bishop = 3.2, Rook = 5, Queen = 9, King = 100 }
			score += 2 + (values[target.type] or 0) * 0.8 - (values[moving.type] or 1) * 0.05
		end
		if moving.type == "Pawn" and (candidate.row == 1 or candidate.row == 8) then score += 8 end
		ChessEngine.move(copy, candidate.fromRow, candidate.fromCol, candidate.row, candidate.col, "Queen")
		if ChessEngine.inCheck(copy, "White") then score += 1.4 end
		if ChessEngine.inCheck(copy, "Black") then score -= 1.2 end
		if score > bestScore then bestScore = score; best = { candidate }
		elseif score >= bestScore - 0.35 then table.insert(best, candidate) end
	end
	local chosen = best[math.random(1, #best)]
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
	pendingTeamQuiz = nil
	controlEvent:FireAllClients("TeamQuizHide")
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
	if action == "BoardClick" then
		if typeof(choice) ~= "table" then return end
		local now = os.clock()
		if now - (lastBoardRequestAt[player.UserId] or 0) < 0.04 then return end
		lastBoardRequestAt[player.UserId] = now

		local row, col = tonumber(choice.row), tonumber(choice.col)
		if not row or not col or row % 1 ~= 0 or col % 1 ~= 0 or not inside(row, col) then
			controlEvent:FireClient(player, "Status", "Invalid board square. Click a visible square.")
			return
		end
		if gameOver then
			controlEvent:FireClient(player, "Status", "This game has ended. Start a new game to continue.")
			return
		end
		if pendingPromotion then
			controlEvent:FireClient(player, "Status", "Choose a promotion piece first.")
			return
		end
		if playerSides[player.UserId] ~= currentTurn then
			controlEvent:FireClient(player, "Status", "It is " .. currentTurn .. "'s turn. You are " .. tostring(playerSides[player.UserId] or "a spectator") .. ".")
			return
		end
		local targetPiece = occupancy[key(row, col)]
		if targetPiece and targetPiece:GetAttribute("Side") == currentTurn then
			if selectedPiece == targetPiece and selectedByUserId == player.UserId then
				selectedPiece = nil
				selectedTile = nil
				selectedByUserId = nil
				controlEvent:FireAllClients("ClearHighlights")
				setStatus(currentTurn .. " to move")
				return
			end
			local pieceType = targetPiece:GetAttribute("PieceType")
			if startTeamQuiz(currentTurn, row, col, pieceType) then return end
			selectedPiece = targetPiece
			selectedTile = { row = row, col = col }
			selectedByUserId = player.UserId
			local legal = ChessEngine.legalMoves(engineState, row, col)
			controlEvent:FireAllClients("LegalMoves", legal, row, col)
			setStatus(currentTurn .. " to move | Selected: " .. pieceType)
		elseif selectedPiece and selectedByUserId == player.UserId then
			tryMove(row, col, nil, player)
		else
			controlEvent:FireClient(player, "Status", "Select one of your " .. currentTurn .. " pieces first.")
		end
	elseif action == "JoinTeam" then
		local side = choice
		if side ~= "White" and side ~= "Black" then return end
		if botEnabled and side == "Black" then
			controlEvent:FireClient(player, "Status", "Black is controlled by the bot in this practice game.")
			return
		end
		if playerSides[player.UserId] then
			controlEvent:FireClient(player, "Status", "You are already on the " .. playerSides[player.UserId] .. " team.")
			return
		end
		if memberCount(side) >= 3 then
			controlEvent:FireClient(player, "Status", side .. " team is full (maximum 3 players).")
			return
		end
		playerSides[player.UserId] = side
		teamMembers[side][player.UserId] = true
		if not seatPlayers[side] then seatPlayers[side] = player.UserId end
		controlEvent:FireClient(player, "SeatAssigned", side)
		for _, teammate in ipairs(sideMembers(side)) do
			controlEvent:FireClient(teammate, "Status", side .. " team: " .. memberCount(side) .. "/3 players")
		end
	elseif action == "TeamAnswer" then
		local quiz = pendingTeamQuiz
		if not quiz or choice == nil or playerSides[player.UserId] ~= quiz.side then return end
		if quiz.answered[player.UserId] then return end
		quiz.answered[player.UserId] = true
		if os.clock() > quiz.expiresAt then return end
		local answerIndex = tonumber(choice)
		if answerIndex ~= quiz.answer then
			controlEvent:FireClient(player, "TeamQuizFeedback", false, "Not quite. Another teammate can still answer.")
			return
		end
		pendingTeamQuiz = nil
		selectedPiece = occupancy[key(quiz.row, quiz.col)]
		selectedTile = { row = quiz.row, col = quiz.col }
		selectedByUserId = player.UserId
		controlEvent:FireAllClients("TeamQuizHide")
		if selectedPiece and selectedPiece.Parent then
			local legal = ChessEngine.legalMoves(engineState, quiz.row, quiz.col)
			controlEvent:FireAllClients("LegalMoves", legal, quiz.row, quiz.col)
			setStatus(player.Name .. " won the " .. quiz.side .. " team quiz and controls " .. quiz.pieceType .. ". Choose a highlighted square.")
			controlEvent:FireClient(player, "TeamQuizFeedback", true, "Correct! You decide this move.")
		end
	elseif action == "PlayBot" then
		if playerSides[player.UserId] == "White" or not seatPlayers.White or seatPlayers.White == player.UserId then
			botEnabled = true
			playerSides[-1] = "Black"
			seatPlayers.White = player.UserId
			seatPlayers.Black = -1
			playerSides[player.UserId] = "White"
			hostUserId = player.UserId
			resetGame()
			controlEvent:FireClient(player, "Status", "Practice vs Bot — you are White. Select a piece, then a green square.")
		else
			controlEvent:FireClient(player, "Status", "This shared board is in use. Wait for a seat to open.")
		end
	elseif action == "Promote" then
		if pendingPromotion and selectedPiece and pendingPromotionUserId == player.UserId and selectedByUserId == player.UserId then
			local pending = pendingPromotion
			pendingPromotion = nil
			pendingPromotionUserId = nil
			tryMove(pending.row, pending.col, choice, player)
		end
	elseif action == "ClaimDraw" then
		if gameOver then return end
		if playerSides[player.UserId] ~= currentTurn then
			controlEvent:FireClient(player, "Status", "Only the player whose turn it is can claim a draw.")
			return
		end
		local status = ChessEngine.status(engineState)
		if status.canClaimThreefold then
			gameOver = true
			selectedPiece = nil
			selectedTile = nil
			selectedByUserId = nil
			controlEvent:FireAllClients("ClearHighlights")
			setStatus("Draw claimed — threefold repetition")
		elseif status.canClaimFiftyMove then
			gameOver = true
			selectedPiece = nil
			selectedTile = nil
			selectedByUserId = nil
			controlEvent:FireAllClients("ClearHighlights")
			setStatus("Draw claimed — fifty-move rule")
		else
			controlEvent:FireClient(player, "Status", "A draw cannot be claimed in the current position.")
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
		selectedTile = nil
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
floor.Size = Vector3.new(190, 1, 190)
floor.Position = Vector3.new(0, -0.2, 0)
floor.Material = Enum.Material.Slate
floor.Color = Color3.fromRGB(28, 32, 42)
floor.Parent = arena

-- Expand the arena into a walkable observatory courtyard.
local worldFolder = Instance.new("Folder")
worldFolder.Name = "World"
worldFolder.Parent = arena

local function worldPart(name, size, position, color, material, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Anchored = true
	p.Material = material or Enum.Material.Metal
	p.Color = color
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent or worldFolder
	return p
end


-- Small study table with a desktop computer, placed beside (not over) the chessboard.
local studyDesk = worldPart("StudyComputerDesk", Vector3.new(9, 0.7, 4.5), Vector3.new(31, 2.1, 13), Color3.fromRGB(94, 65, 45), Enum.Material.Wood)
for _, legOffset in ipairs({Vector3.new(-3.7, -1.1, -1.6), Vector3.new(3.7, -1.1, -1.6), Vector3.new(-3.7, -1.1, 1.6), Vector3.new(3.7, -1.1, 1.6)}) do
	worldPart("StudyDeskLeg", Vector3.new(0.45, 2.2, 0.45), studyDesk.Position + legOffset, Color3.fromRGB(56, 43, 35), Enum.Material.Wood)
end
local computerBase = worldPart("ComputerStand", Vector3.new(1.4, 0.25, 1), Vector3.new(31, 2.65, 12.4), Color3.fromRGB(35, 40, 48), Enum.Material.Metal)
local computerMonitor = worldPart("ComputerMonitor", Vector3.new(3.4, 2.3, 0.3), Vector3.new(31, 3.8, 12.9), Color3.fromRGB(24, 29, 38), Enum.Material.Metal)
local monitorScreen = worldPart("ComputerScreen", Vector3.new(3.05, 1.92, 0.08), Vector3.new(31, 3.83, 12.69), Color3.fromRGB(65, 196, 151), Enum.Material.Neon)
monitorScreen.CanCollide = false
local screenGui = Instance.new("SurfaceGui")
screenGui.Name = "StudyComputerDisplay"
screenGui.Face = Enum.NormalId.Front
screenGui.PixelsPerStud = 45
screenGui.Parent = monitorScreen
local screenText = Instance.new("TextLabel")
screenText.Size = UDim2.fromScale(1, 1)
screenText.BackgroundColor3 = Color3.fromRGB(12, 24, 29)
screenText.BackgroundTransparency = 0.05
screenText.TextColor3 = Color3.fromRGB(120, 255, 190)
screenText.Font = Enum.Font.Code
screenText.TextScaled = true
screenText.Text = "YUGATNEO\nSTUDY TERMINAL\n\nLEARN • PLAY • GROW"
screenText.Parent = screenGui
worldPart("ComputerKeyboard", Vector3.new(2.8, 0.12, 0.85), Vector3.new(31, 2.55, 10.8), Color3.fromRGB(37, 43, 53), Enum.Material.SmoothPlastic)
local computerPrompt = Instance.new("ProximityPrompt")
computerPrompt.ActionText = "Use computer"
computerPrompt.ObjectText = "Study terminal"
computerPrompt.HoldDuration = 0.3
computerPrompt.MaxActivationDistance = 9
computerPrompt.Parent = computerMonitor
computerPrompt.Triggered:Connect(function(player)
	controlEvent:FireClient(player, "Status", "Study terminal: chess practice and learning tools will be available here.")
end)

-- A small walk-in phone booth with a visible handset and keypad.
local boothX, boothZ = -31, 13
local boothFrame = Color3.fromRGB(139, 42, 39)
local boothGlass = Color3.fromRGB(115, 194, 203)
for _, offset in ipairs({Vector3.new(-3, 5, -3), Vector3.new(3, 5, -3), Vector3.new(-3, 5, 3), Vector3.new(3, 5, 3)}) do
	local post = worldPart("PhoneBoothPost", Vector3.new(0.45, 10, 0.45), Vector3.new(boothX, 0, boothZ) + offset, boothFrame, Enum.Material.Metal)
	post.CanCollide = true
end
worldPart("PhoneBoothRoof", Vector3.new(6.8, 0.55, 6.8), Vector3.new(boothX, 10.2, boothZ), boothFrame, Enum.Material.Metal)
worldPart("PhoneBoothBack", Vector3.new(6.2, 9.2, 0.25), Vector3.new(boothX, 5, boothZ - 3), boothGlass, Enum.Material.Glass).Transparency = 0.35
worldPart("PhoneBoothLeftGlass", Vector3.new(0.2, 9.2, 5.8), Vector3.new(boothX - 3, 5, boothZ), boothGlass, Enum.Material.Glass).Transparency = 0.45
worldPart("PhoneBoothRightGlass", Vector3.new(0.2, 9.2, 5.8), Vector3.new(boothX + 3, 5, boothZ), boothGlass, Enum.Material.Glass).Transparency = 0.45
worldPart("PhoneBoothSign", Vector3.new(5.2, 0.8, 0.3), Vector3.new(boothX, 9.3, boothZ + 3.05), Color3.fromRGB(220, 198, 117), Enum.Material.SmoothPlastic)
local phoneSign = worldPart("PhoneBoothSignText", Vector3.new(4.8, 0.55, 0.12), Vector3.new(boothX, 9.3, boothZ + 2.84), Color3.fromRGB(48, 38, 31), Enum.Material.SmoothPlastic)
phoneSign.CanCollide = false
local signGui = Instance.new("SurfaceGui")
signGui.Face = Enum.NormalId.Front
signGui.Parent = phoneSign
local signText = Instance.new("TextLabel")
signText.Size = UDim2.fromScale(1, 1)
signText.BackgroundTransparency = 1
signText.Text = "PHONE"
signText.TextColor3 = Color3.fromRGB(255, 233, 171)
signText.Font = Enum.Font.GothamBlack
signText.TextScaled = true
signText.Parent = signGui
local phoneBody = worldPart("PublicTelephone", Vector3.new(1.4, 2.3, 0.55), Vector3.new(boothX, 5.4, boothZ - 2.55), Color3.fromRGB(40, 45, 52), Enum.Material.Metal)
local phoneDisplay = worldPart("PhoneDisplay", Vector3.new(0.85, 0.4, 0.08), Vector3.new(boothX, 6, boothZ - 2.84), Color3.fromRGB(75, 211, 157), Enum.Material.Neon)
phoneDisplay.CanCollide = false
for index = 1, 3 do
	for col = 1, 3 do
		local keyPart = worldPart("PhoneKey", Vector3.new(0.16, 0.16, 0.08), Vector3.new(boothX - 0.28 + (col - 1) * 0.28, 5.35 - (index - 1) * 0.28, boothZ - 2.86), Color3.fromRGB(225, 224, 215), Enum.Material.SmoothPlastic)
		keyPart.CanCollide = false
	end
end
local handset = worldPart("TelephoneHandset", Vector3.new(0.3, 1.2, 0.3), Vector3.new(boothX + 0.7, 6.3, boothZ - 2.55), Color3.fromRGB(20, 24, 29), Enum.Material.SmoothPlastic)
handset.Shape = Enum.PartType.Cylinder
handset.CFrame = CFrame.new(handset.Position) * CFrame.Angles(0, 0, math.rad(90))
local phonePrompt = Instance.new("ProximityPrompt")
phonePrompt.ActionText = "Use telephone"
phonePrompt.ObjectText = "Public phone booth"
phonePrompt.HoldDuration = 0.35
phonePrompt.MaxActivationDistance = 8
phonePrompt.Parent = phoneBody
phonePrompt.Triggered:Connect(function(player)
	controlEvent:FireClient(player, "Status", "Telephone booth: the public line is ready. More destinations can be connected later.")
end)

local fenceColor = Color3.fromRGB(42, 50, 63)
local trimColor = Color3.fromRGB(226, 177, 73)
local fenceY, fenceRadius = 8, 72
for _, z in ipairs({-fenceRadius, fenceRadius}) do
	worldPart("PerimeterFence", Vector3.new(144, fenceY, 1.2), Vector3.new(0, fenceY/2, z), fenceColor)
	worldPart("FenceGoldRail", Vector3.new(144, 0.35, 1.5), Vector3.new(0, fenceY-0.5, z), trimColor)
end
for _, x in ipairs({-fenceRadius, fenceRadius}) do
	worldPart("PerimeterFence", Vector3.new(1.2, fenceY, 144), Vector3.new(x, fenceY/2, 0), fenceColor)
	worldPart("FenceGoldRail", Vector3.new(1.5, 0.35, 144), Vector3.new(x, fenceY-0.5, 0), trimColor)
end
-- Slender fence bars make the perimeter read as a secure arena enclosure.
for i = -68, 68, 4 do
	for _, z in ipairs({-fenceRadius, fenceRadius}) do worldPart("FenceBar", Vector3.new(0.35, 7.4, 0.5), Vector3.new(i, 3.9, z), trimColor) end
	for _, x in ipairs({-fenceRadius, fenceRadius}) do worldPart("FenceBar", Vector3.new(0.5, 7.4, 0.35), Vector3.new(x, 3.9, i), trimColor) end
end

-- Four watchtowers with walkable platforms, ladder rungs and telescope prompts.
for _, corner in ipairs({Vector2.new(-62,-62), Vector2.new(62,-62), Vector2.new(-62,62), Vector2.new(62,62)}) do
	local x, z = corner.X, corner.Y
	worldPart("WatchtowerLeg", Vector3.new(2, 18, 2), Vector3.new(x-4, 9, z-4), fenceColor)
	worldPart("WatchtowerLeg", Vector3.new(2, 18, 2), Vector3.new(x+4, 9, z-4), fenceColor)
	worldPart("WatchtowerLeg", Vector3.new(2, 18, 2), Vector3.new(x-4, 9, z+4), fenceColor)
	worldPart("WatchtowerLeg", Vector3.new(2, 18, 2), Vector3.new(x+4, 9, z+4), fenceColor)
	worldPart("WatchtowerPlatform", Vector3.new(12, 1.5, 12), Vector3.new(x, 18, z), trimColor)
	worldPart("TowerRail", Vector3.new(12, 1, 0.5), Vector3.new(x, 21, z-5.5), fenceColor)
	worldPart("TowerRail", Vector3.new(12, 1, 0.5), Vector3.new(x, 21, z+5.5), fenceColor)
	worldPart("TowerRail", Vector3.new(0.5, 1, 12), Vector3.new(x-5.5, 21, z), fenceColor)
	worldPart("TowerRail", Vector3.new(0.5, 1, 12), Vector3.new(x+5.5, 21, z), fenceColor)
	for y = 1, 17, 1.5 do
		worldPart("LadderRung", Vector3.new(2.2, 0.25, 0.35), Vector3.new(x-4, y, z-5.2), trimColor)
	end
	local telescope = worldPart("ObservatoryTelescope", Vector3.new(1.2, 1.2, 5), Vector3.new(x, 20, z), Color3.fromRGB(25, 31, 42))
	telescope.CFrame = CFrame.new(telescope.Position, Vector3.new(0, 3, 0))
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Look through telescope"
	prompt.ObjectText = "Arena Observatory"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 10
	prompt.Parent = telescope
	prompt.Triggered:Connect(function(player)
		controlEvent:FireClient(player, "Telescope", telescope.Position)
	end)
end

-- Target range: targets can be clicked to train aim; each player gets a hit counter.
local targetFolder = Instance.new("Folder")
targetFolder.Name = "TargetRange"
targetFolder.Parent = worldFolder
local targetHits = {}
for lane = 1, 3 do
	for targetIndex = 1, 5 do
		local x = 28 + (targetIndex-1)*4
		local z = -24 + (lane-1)*8
		local target = worldPart("Target_"..lane.."_"..targetIndex, Vector3.new(2.5, 3.5, 0.7), Vector3.new(x, 2.5, z), Color3.fromRGB(185, 58, 55), Enum.Material.Neon, targetFolder)
		target.Shape = Enum.PartType.Cylinder
		target.Orientation = Vector3.new(0, 0, 90)
		local click = Instance.new("ClickDetector")
		click.MaxActivationDistance = 90
		click.Parent = target
		click.MouseClick:Connect(function(player)
			targetHits[player.UserId] = (targetHits[player.UserId] or 0) + 1
			controlEvent:FireClient(player, "Status", "Target practice: "..targetHits[player.UserId].." hits. Click another target.")
			target.Color = Color3.fromRGB(75, 190, 130)
			task.delay(0.45, function() if target.Parent then target.Color = Color3.fromRGB(185,58,55) end end)
		end)
	end
end

-- Reaction test pad: wait for green, then click as quickly as possible.
local reactionPad = worldPart("ReactionTestPad", Vector3.new(8, 0.7, 8), Vector3.new(35, 0.2, 32), Color3.fromRGB(170, 65, 65), Enum.Material.Neon)
local reactionClick = Instance.new("ClickDetector")
reactionClick.MaxActivationDistance = 90
reactionClick.Parent = reactionPad
local reactionReadyAt = nil
local reactionArmed = false
local reactionPrompt = Instance.new("ProximityPrompt")
reactionPrompt.ActionText = "Start reaction test"
reactionPrompt.ObjectText = "Reflex Lab"
reactionPrompt.HoldDuration = 0
reactionPrompt.MaxActivationDistance = 12
reactionPrompt.Parent = reactionPad
reactionPrompt.Triggered:Connect(function(player)
	reactionArmed = false
	reactionReadyAt = nil
	reactionPad.Color = Color3.fromRGB(170,65,65)
	controlEvent:FireClient(player, "Status", "Reaction test: wait for GREEN, then click the red pad.")
	task.delay(math.random(2,5), function()
		reactionArmed = true
		reactionReadyAt = os.clock()
		reactionPad.Color = Color3.fromRGB(70, 220, 125)
	end)
end)
reactionClick.MouseClick:Connect(function(player)
	if not reactionArmed or not reactionReadyAt then
		controlEvent:FireClient(player, "Status", "Too early! Start again and wait for green.")
		return
	end
	local elapsed = math.max(0, os.clock() - reactionReadyAt)
	reactionArmed = false
	reactionReadyAt = nil
	reactionPad.Color = Color3.fromRGB(170,65,65)
	controlEvent:FireClient(player, "Status", string.format("Reaction time: %.0f ms", elapsed*1000))
end)

-- Memory challenge: remember a short sequence of lit pads, then click in order.
local memoryPads = {}
local memoryColors = {
	Color3.fromRGB(235,190,92), Color3.fromRGB(65,160,235),
	Color3.fromRGB(180,95,225), Color3.fromRGB(75,190,130)
}
for i = 1, 4 do
	local pad = worldPart("MemoryPad_"..i, Vector3.new(4,0.7,4), Vector3.new(-32+(i-1)*5,0.2,34), memoryColors[i], Enum.Material.Neon)
	pad:SetAttribute("PadIndex", i)
	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 90
	click.Parent = pad
	memoryPads[i] = pad
end
local memorySequence, memoryStep, memoryPlayer = {}, 0, nil
local memoryStart = worldPart("MemoryStart", Vector3.new(6,1,5), Vector3.new(-32,0.2,27), trimColor, Enum.Material.Neon)
local memoryPrompt = Instance.new("ProximityPrompt")
memoryPrompt.ActionText = "Start memory challenge"
memoryPrompt.ObjectText = "Memory Lab"
memoryPrompt.HoldDuration = 0
memoryPrompt.MaxActivationDistance = 12
memoryPrompt.Parent = memoryStart
memoryPrompt.Triggered:Connect(function(player)
	memoryPlayer = player.UserId
	memorySequence, memoryStep = {}, 0
	for i = 1, 4 do memorySequence[i] = math.random(1,4) end
	controlEvent:FireClient(player, "Status", "Memorize the 4-pad sequence. Watch the pads light up.")
	task.spawn(function()
		for _, index in ipairs(memorySequence) do
			local pad = memoryPads[index]
			local oldColor = pad.Color
			pad.Color = Color3.new(1,1,1)
			task.wait(0.45)
			pad.Color = oldColor
			task.wait(0.2)
		end
		controlEvent:FireClient(player, "Status", "Repeat the sequence by clicking pads 1–4 in order.")
	end)
end)
for i, pad in ipairs(memoryPads) do
	pad:FindFirstChildOfClass("ClickDetector").MouseClick:Connect(function(player)
		if memoryPlayer ~= player.UserId or #memorySequence == 0 then return end
		memoryStep += 1
		if i ~= memorySequence[memoryStep] then
			controlEvent:FireClient(player, "Status", "Memory challenge failed. Start again to retry.")
			memorySequence, memoryStep, memoryPlayer = {}, 0, nil
		elseif memoryStep == #memorySequence then
			controlEvent:FireClient(player, "Status", "Memory challenge complete! Perfect recall.")
			memorySequence, memoryStep, memoryPlayer = {}, 0, nil
		else
			controlEvent:FireClient(player, "Status", "Correct: "..memoryStep.."/"..#memorySequence)
		end
	end)
end

-- Give every avatar round sunglasses and a simple beard accessory built from welded parts.
local function styleCharacter(character)
	local head = character:WaitForChild("Head", 5)
	if not head or head:FindFirstChild("YUGATNEO_Sunglasses") then return end
	local glasses = Instance.new("Model")
	glasses.Name = "YUGATNEO_Sunglasses"
	glasses.Parent = character
	local function lens(name, x)
		local part = Instance.new("Part")
		part.Name = name
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(0.12, 0.62, 0.62)
		part.Color = Color3.fromRGB(8,10,14)
		part.Material = Enum.Material.Glass
		part.Transparency = 0.08
		part.CanCollide = false
		part.Massless = true
		part.CFrame = head.CFrame * CFrame.new(x,0.03,-0.53) * CFrame.Angles(0,0,math.rad(90))
		part.Parent = glasses
		local weld = Instance.new("WeldConstraint")
		weld.Part0, weld.Part1 = head, part
		weld.Parent = part
	end
	lens("LeftRoundLens", -0.28)
	lens("RightRoundLens", 0.28)
	local bridge = Instance.new("Part")
	bridge.Name = "GlassesBridge"
	bridge.Size = Vector3.new(0.24,0.07,0.08)
	bridge.Color = Color3.fromRGB(222,175,65)
	bridge.CanCollide = false
	bridge.Massless = true
	bridge.CFrame = head.CFrame * CFrame.new(0,0.03,-0.59)
	bridge.Parent = glasses
	local bridgeWeld = Instance.new("WeldConstraint")
	bridgeWeld.Part0, bridgeWeld.Part1 = head, bridge
	bridgeWeld.Parent = bridge
	local beard = Instance.new("Part")
	beard.Name = "YUGATNEO_Beard"
	beard.Shape = Enum.PartType.Ball
	beard.Size = Vector3.new(0.65,0.45,0.34)
	beard.Color = Color3.fromRGB(35,27,23)
	beard.CanCollide = false
	beard.Massless = true
	beard.CFrame = head.CFrame * CFrame.new(0,-0.48,-0.38)
	beard.Parent = character
	local beardWeld = Instance.new("WeldConstraint")
	beardWeld.Part0, beardWeld.Part1 = head, beard
	beardWeld.Parent = beard
end
local function stylePlayer(player)
	player.CharacterAdded:Connect(function(character) task.spawn(styleCharacter, character) end)
	if player.Character then task.spawn(styleCharacter, player.Character) end
end
for _, player in ipairs(Players:GetPlayers()) do stylePlayer(player) end
Players.PlayerAdded:Connect(stylePlayer)

setStatus("White to move | Walk to the board and choose Practice vs Bot in the HUD")
print("YUGATNEO Chess Arena loaded: board, labelled pieces, and game controls created.")


-- Dedicated walk-on pad for a true top-down chess-board view.
-- The pad is adjacent to the board; stepping onto it switches only that player's camera.
local chessViewPad = Instance.new("Part")
chessViewPad.Name = "ChessTopDownViewPad"
chessViewPad.Anchored = true
chessViewPad.CanCollide = true
chessViewPad.Size = Vector3.new(10, 0.6, 10)
chessViewPad.Position = Vector3.new(24, 0.35, 0)
chessViewPad.Material = Enum.Material.Neon
chessViewPad.Color = Color3.fromRGB(64, 170, 125)
chessViewPad.Parent = worldFolder

local chessViewSign = Instance.new("BillboardGui")
chessViewSign.Name = "ChessViewSign"
chessViewSign.Size = UDim2.fromOffset(220, 54)
chessViewSign.StudsOffset = Vector3.new(0, 3.5, 0)
chessViewSign.AlwaysOnTop = true
chessViewSign.Parent = chessViewPad
local chessViewText = Instance.new("TextLabel")
chessViewText.Size = UDim2.fromScale(1, 1)
chessViewText.BackgroundColor3 = Color3.fromRGB(17, 22, 32)
chessViewText.BackgroundTransparency = 0.1
chessViewText.TextColor3 = Color3.fromRGB(245, 245, 245)
chessViewText.Font = Enum.Font.GothamBold
chessViewText.TextScaled = true
chessViewText.Text = "STEP HERE • CHESS VIEW"
chessViewText.Parent = chessViewSign
local signCorner = Instance.new("UICorner")
signCorner.CornerRadius = UDim.new(0, 10)
signCorner.Parent = chessViewText

local viewCooldown = {}
chessViewPad.Touched:Connect(function(hit)
	local character = hit and hit:FindFirstAncestorOfClass("Model")
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player or viewCooldown[player.UserId] then return end
	viewCooldown[player.UserId] = true
	controlEvent:FireClient(player, "ChessView", Vector3.new(0, 1, 0))
	task.delay(2, function()
		viewCooldown[player.UserId] = nil
	end)
end)
