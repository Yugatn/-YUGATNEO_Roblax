-- YUGATNEO Chess Arena (streamlined, server-authoritative)
-- Single board, ClickDetectors on all piece parts + squares, optional bot.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ChessEngine = require(script.Parent:WaitForChild("ChessEngine"))

local TILE, BOARD_Y = 4, 1
local PIECE_Y = BOARD_Y + 0.18
local BOARD_NAME = "YUGATNEO_ChessArena"

local old = workspace:FindFirstChild(BOARD_NAME)
if old then old:Destroy() end

local arena = Instance.new("Folder")
arena.Name = BOARD_NAME
arena.Parent = workspace
local boardFolder = Instance.new("Folder")
boardFolder.Name = "Board"
boardFolder.Parent = arena
local piecesFolder = Instance.new("Folder")
piecesFolder.Name = "Pieces"
piecesFolder.Parent = arena

local controlEvent = ReplicatedStorage:FindFirstChild("ChessControlEvent")
if not controlEvent then
	controlEvent = Instance.new("RemoteEvent")
	controlEvent.Name = "ChessControlEvent"
	controlEvent.Parent = ReplicatedStorage
end

local statusPart = Instance.new("Part")
statusPart.Name = "GameStatusBoard"
statusPart.Anchored = true
statusPart.CanCollide = false
statusPart.Size = Vector3.new(18, 5, 0.5)
statusPart.Position = Vector3.new(0, 8, -22)
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

local tiles, occupancy = {}, {}
local currentTurn = "White"
local engineState = ChessEngine.newGame()
local selectedPiece, selectedByUserId = nil, nil
local pendingPromotion, pendingPromotionUserId = nil, nil
local gameOver, matchStarted, botEnabled, botThinking = false, false, false, false
local playerSides, seatPlayers = {}, { White = nil, Black = nil }
local handleBoardClick, tryMove, botMove

local WHITE = Color3.fromRGB(238, 232, 218)
local BLACK = Color3.fromRGB(65, 75, 91)
local WHITE_PIECE = Color3.fromRGB(245, 245, 240)
local BLACK_PIECE = Color3.fromRGB(35, 40, 50)
local GOLD = Color3.fromRGB(222, 175, 65)

local function key(r, c) return r .. "," .. c end
local function squarePosition(row, col, y)
	return Vector3.new((col - 4.5) * TILE, y or PIECE_Y, (row - 4.5) * TILE)
end

local function makePiece(pieceType, side, row, col)
	local model = Instance.new("Model")
	model.Name = side .. "_" .. pieceType .. "_" .. row .. "_" .. col
	model:SetAttribute("PieceType", pieceType)
	model:SetAttribute("Side", side)
	model:SetAttribute("Row", row)
	model:SetAttribute("Col", col)
	local color = side == "White" and WHITE_PIECE or BLACK_PIECE
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
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Cylinder
	body.Size = Vector3.new(0.9, 0.75, 0.75)
	body.Anchored = true
	body.CanCollide = false
	body.Color = color
	body.CFrame = CFrame.new(squarePosition(row, col, PIECE_Y + 1.1)) * CFrame.Angles(0, 0, math.rad(90))
	body.Parent = model
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(0.7, 0.7, 0.7)
	head.Anchored = true
	head.CanCollide = false
	head.Color = side == "White" and color or GOLD
	head.Position = squarePosition(row, col, PIECE_Y + 1.85)
	head.Parent = model
	local badge = Instance.new("BillboardGui")
	badge.Size = UDim2.fromOffset(36, 36)
	badge.StudsOffset = Vector3.new(0, 2.8, 0)
	badge.AlwaysOnTop = true
	badge.MaxDistance = 120
	badge.Parent = base
	local bt = Instance.new("TextLabel")
	bt.Size = UDim2.fromScale(1, 1)
	bt.BackgroundColor3 = side == "White" and Color3.fromRGB(30, 35, 45) or Color3.fromRGB(245, 240, 225)
	bt.TextColor3 = side == "White" and Color3.new(1, 1, 1) or Color3.fromRGB(20, 25, 35)
	bt.Font = Enum.Font.GothamBlack
	bt.TextScaled = true
	bt.Text = ({ Pawn = "P", Rook = "R", Knight = "N", Bishop = "B", Queen = "Q", King = "K" })[pieceType]
	bt.Parent = badge
	Instance.new("UICorner", bt).CornerRadius = UDim.new(0.5, 0)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			local cd = Instance.new("ClickDetector")
			cd.MaxActivationDistance = 128
			cd.Parent = d
			cd.MouseClick:Connect(function(player)
				if handleBoardClick then
					handleBoardClick(player, { row = model:GetAttribute("Row"), col = model:GetAttribute("Col") })
				end
			end)
		end
	end
	model.Parent = piecesFolder
	occupancy[key(row, col)] = model
	return model
end

local function spawnAll()
	piecesFolder:ClearAllChildren()
	table.clear(occupancy)
	local back = { "Rook", "Knight", "Bishop", "Queen", "King", "Bishop", "Knight", "Rook" }
	for col = 1, 8 do
		makePiece(back[col], "White", 1, col)
		makePiece("Pawn", "White", 2, col)
		makePiece(back[col], "Black", 8, col)
		makePiece("Pawn", "Black", 7, col)
	end
end

for row = 1, 8 do
	tiles[row] = {}
	for col = 1, 8 do
		local tile = Instance.new("Part")
		tile.Name = "Square_" .. row .. "_" .. col
		tile.Anchored = true
		tile.Size = Vector3.new(TILE, 0.35, TILE)
		tile.Position = squarePosition(row, col, BOARD_Y)
		tile.Material = Enum.Material.SmoothPlastic
		tile.Color = ((row + col) % 2 == 0) and WHITE or BLACK
		tile.Parent = boardFolder
		tile:SetAttribute("Row", row)
		tile:SetAttribute("Col", col)
		local cd = Instance.new("ClickDetector")
		cd.MaxActivationDistance = 128
		cd.Parent = tile
		cd.MouseClick:Connect(function(player)
			if handleBoardClick then handleBoardClick(player, { row = row, col = col }) end
		end)
		tiles[row][col] = tile
	end
end

local function isValidMove(piece, toRow, toCol)
	if not piece or not piece.Parent then return false end
	local r, c = piece:GetAttribute("Row"), piece:GetAttribute("Col")
	for _, m in ipairs(ChessEngine.legalMoves(engineState, r, c)) do
		if m.row == toRow and m.col == toCol then return true end
	end
	return false
end

tryMove = function(toRow, toCol, promotionChoice, player)
	if not matchStarted or gameOver or not player then return end
	local isBot = botEnabled and player.UserId == -1 and currentTurn == "Black"
	if not isBot then
		if playerSides[player.UserId] ~= currentTurn then return end
	end
	if selectedByUserId ~= player.UserId then return end
	if pendingPromotion and not promotionChoice then return end
	if not selectedPiece or not selectedPiece.Parent then selectedPiece = nil return end
	local piece = selectedPiece
	if piece:GetAttribute("Side") ~= currentTurn then selectedPiece = nil return end
	local fromRow, fromCol = piece:GetAttribute("Row"), piece:GetAttribute("Col")
	local side = piece:GetAttribute("Side")
	local pieceType = piece:GetAttribute("PieceType")
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
	local success, result, _, move = ChessEngine.move(engineState, fromRow, fromCol, toRow, toCol, promotionChoice or "Queen")
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
		local rf = move.castle == "kingSide" and 8 or 1
		local rt = move.castle == "kingSide" and 6 or 4
		local rook = occupancy[key(home, rf)]
		if rook then
			occupancy[key(home, rf)] = nil
			occupancy[key(home, rt)] = rook
			rook:SetAttribute("Row", home)
			rook:SetAttribute("Col", rt)
			rook:PivotTo(CFrame.new(squarePosition(home, rt, PIECE_Y)) * CFrame.Angles(0, 0, math.rad(90)))
		end
	end
	piece:PivotTo(CFrame.new(squarePosition(toRow, toCol, PIECE_Y)) * CFrame.Angles(0, 0, math.rad(90)))
	local promoted = engineState.board[toRow][toCol]
	if pieceType == "Pawn" and (toRow == 1 or toRow == 8) and promoted then
		piece:Destroy()
		occupancy[key(toRow, toCol)] = nil
		makePiece(promoted.type, side, toRow, toCol)
	end
	selectedPiece, selectedByUserId = nil, nil
	pendingPromotion, pendingPromotionUserId = nil, nil
	controlEvent:FireAllClients("ClearHighlights")
	currentTurn = engineState.turn
	local status = type(result) == "table" and result or ChessEngine.status(engineState)
	if status.gameOver then
		gameOver = true
		setStatus(status.text)
	else
		setStatus(status.text)
	end
	if botEnabled and currentTurn == "Black" and not gameOver then
		task.delay(0.45, function()
			if botMove then botMove() end
		end)
	end
end

botMove = function()
	if botThinking or not matchStarted or not botEnabled or gameOver or currentTurn ~= "Black" then return end
	botThinking = true
	local candidates = ChessEngine.allLegalMoves(engineState, "Black")
	if #candidates == 0 then botThinking = false return end
	local bestScore, best = -math.huge, {}
	for _, candidate in ipairs(candidates) do
		local copy = ChessEngine.copy(engineState)
		local moving = copy.board[candidate.fromRow][candidate.fromCol]
		local target = copy.board[candidate.row][candidate.col]
		local score = math.random() * 0.4
		if target then
			local values = { Pawn = 1, Knight = 3, Bishop = 3.2, Rook = 5, Queen = 9, King = 100 }
			score += 2 + (values[target.type] or 0) * 0.8
		end
		ChessEngine.move(copy, candidate.fromRow, candidate.fromCol, candidate.row, candidate.col, "Queen")
		if ChessEngine.inCheck(copy, "White") then score += 1.4 end
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

local function resetGame()
	botThinking = false
	spawnAll()
	selectedPiece, selectedByUserId = nil, nil
	pendingPromotion, pendingPromotionUserId = nil, nil
	engineState = ChessEngine.newGame()
	currentTurn = "White"
	gameOver = false
	matchStarted = seatPlayers.White ~= nil and seatPlayers.Black ~= nil
	controlEvent:FireAllClients("ClearHighlights")
	if matchStarted then
		setStatus("White to move")
	else
		setStatus("Stand on White or Black field, or press PLAY VS BOT")
	end
end

handleBoardClick = function(player, choice)
	if type(choice) ~= "table" then return end
	local row, col = choice.row, choice.col
	if type(row) ~= "number" or type(col) ~= "number" then return end
	if row < 1 or row > 8 or col < 1 or col > 8 then return end
	if not matchStarted then
		controlEvent:FireClient(player, "Status", "Join a side field or PLAY VS BOT first.")
		return
	end
	if gameOver then
		controlEvent:FireClient(player, "Status", "Game over. Press New Game.")
		return
	end
	if pendingPromotion and pendingPromotionUserId == player.UserId then
		controlEvent:FireClient(player, "Status", "Choose promotion piece first.")
		return
	end
	if playerSides[player.UserId] ~= currentTurn then
		controlEvent:FireClient(player, "Status", "It is " .. currentTurn .. "'s turn.")
		return
	end
	local targetPiece = occupancy[key(row, col)]
	if targetPiece and targetPiece:GetAttribute("Side") == currentTurn then
		if selectedPiece == targetPiece and selectedByUserId == player.UserId then
			selectedPiece, selectedByUserId = nil, nil
			controlEvent:FireAllClients("ClearHighlights")
			return
		end
		selectedPiece = targetPiece
		selectedByUserId = player.UserId
		local legal = ChessEngine.legalMoves(engineState, row, col)
		controlEvent:FireAllClients("LegalMoves", legal, row, col)
	elseif selectedPiece and selectedByUserId == player.UserId then
		tryMove(row, col, nil, player)
	else
		controlEvent:FireClient(player, "Status", "Select one of your " .. currentTurn .. " pieces first.")
	end
end

local function claimSide(player, side)
	if playerSides[player.UserId] then
		controlEvent:FireClient(player, "Status", "Already joined " .. playerSides[player.UserId])
		return
	end
	if botEnabled and side == "Black" then
		controlEvent:FireClient(player, "Status", "Black is the bot.")
		return
	end
	if seatPlayers[side] and seatPlayers[side] ~= player.UserId then
		controlEvent:FireClient(player, "Status", side .. " seat taken.")
		return
	end
	playerSides[player.UserId] = side
	seatPlayers[side] = player.UserId
	controlEvent:FireClient(player, "SeatAssigned", side)
	if seatPlayers.White and seatPlayers.Black then
		botEnabled = false
		resetGame()
		setStatus("Both players ready — White to move")
	else
		setStatus(side .. " joined. Waiting for opponent.")
	end
end

controlEvent.OnServerEvent:Connect(function(player, action, choice)
	if action == "BoardClick" then
		if type(choice) ~= "table" then return end
		local r, c = choice.row, choice.col
		if type(r) ~= "number" or type(c) ~= "number" then return end
		if r < 1 or r > 8 or c < 1 or c > 8 then return end
		if r ~= math.floor(r) or c ~= math.floor(c) then return end
		handleBoardClick(player, { row = r, col = c })
	elseif action == "JoinField" then
		if choice == "White" or choice == "Black" then claimSide(player, choice) end
	elseif action == "PlayBot" then
		playerSides[player.UserId] = "White"
		seatPlayers.White = player.UserId
		seatPlayers.Black = -1
		botEnabled = true
		controlEvent:FireClient(player, "SeatAssigned", "White")
		resetGame()
		setStatus("Playing vs bot — White to move")
	elseif action == "Promote" then
		if pendingPromotion and pendingPromotionUserId == player.UserId and selectedByUserId == player.UserId then
			local pending = pendingPromotion
			tryMove(pending.row, pending.col, choice, player)
		end
	elseif action == "Deselect" then
		if selectedByUserId == player.UserId then
			selectedPiece, selectedByUserId = nil, nil
			controlEvent:FireAllClients("ClearHighlights")
		end
	elseif action == "Reset" then
		if playerSides[player.UserId] then resetGame() end
	elseif action == "ClaimDraw" then
		local st = ChessEngine.status(engineState)
		if st.canClaimThreefold or st.canClaimFiftyMove then
			gameOver = true
			setStatus("Draw claimed")
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local side = playerSides[player.UserId]
	if side then
		playerSides[player.UserId] = nil
		if seatPlayers[side] == player.UserId then
			seatPlayers[side] = nil
			matchStarted = false
			gameOver = true
			setStatus(player.Name .. " left.")
		end
	end
end)

local floor = Instance.new("Part")
floor.Name = "ArenaFloor"
floor.Anchored = true
floor.Size = Vector3.new(48, 1, 52)
floor.Position = Vector3.new(0, -0.2, 2)
floor.Material = Enum.Material.Slate
floor.Color = Color3.fromRGB(28, 32, 42)
floor.Parent = arena

local function makeField(name, side, pos, color)
	local field = Instance.new("Part")
	field.Name = name
	field.Anchored = true
	field.Size = Vector3.new(10, 0.6, 7)
	field.Position = pos
	field.Color = color
	field.Material = Enum.Material.Neon
	field.Parent = arena
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Join " .. side
	prompt.ObjectText = side .. " seat"
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = field
	prompt.Triggered:Connect(function(player) claimSide(player, side) end)
	return field
end
makeField("WhitePlayerField", "White", Vector3.new(0, 0.35, -24), Color3.fromRGB(64, 170, 125))
makeField("BlackPlayerField", "Black", Vector3.new(0, 0.35, 24), Color3.fromRGB(70, 125, 190))

spawnAll()
setStatus("Stand on a field or PLAY VS BOT")
print("[YUGATNEO] ChessArena ready (streamlined single board)")
