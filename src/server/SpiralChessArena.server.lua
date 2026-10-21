-- YUGATNEO MATRIX — Spiral Chess Level
-- Prototype: legal piece movement and captures, but no check/checkmate,
-- castling, en passant, or pawn promotion yet.

local Players = game:GetService("Players")

local TILE = 4
local CENTER = Vector3.new(500, 121, 0)
local BOARD_Y = CENTER.Y
local PIECE_Y = BOARD_Y + 0.18
local ORIGIN = CENTER
local BOARD_NAME = "YUGATNEO_SpiralChessArena"

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
controlEvent.Name = "SpiralChessControlEvent"
controlEvent.Parent = game:GetService("ReplicatedStorage")

local statusPart = Instance.new("Part")
statusPart.Name = "GameStatusBoard"
statusPart.Anchored = true
statusPart.CanCollide = false
statusPart.Size = Vector3.new(18, 5, 0.5)
statusPart.Position = CENTER + Vector3.new(0, 8, -22)
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
end

local tiles = {}
local occupancy = {}
local currentTurn = "White"
local selectedPiece = nil
local selectedTile = nil
local tryMove

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
	return CENTER + Vector3.new((col - 4.5) * TILE, (y or PIECE_Y) - CENTER.Y, (row - 4.5) * TILE)
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
		local currentRow = model:GetAttribute("Row")
		local currentCol = model:GetAttribute("Col")
		if model.Parent and occupancy[key(currentRow, currentCol)] == model then
			if model:GetAttribute("Side") == currentTurn then
				if selectedPiece == model then
					selectedPiece = nil
					setStatus(currentTurn .. " to move")
				else
					selectedPiece = model
					setStatus(currentTurn .. " to move | Selected: " .. pieceType)
				end
			elseif selectedPiece then
				-- Clicking an opposing piece attempts to capture it on its square.
				tryMove(currentRow, currentCol)
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
				tryMove(row, col)
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
	if not piece or not piece.Parent or not inside(toRow, toCol) then
		return false
	end
	local fromRow = piece:GetAttribute("Row")
	local fromCol = piece:GetAttribute("Col")
	local pieceType = piece:GetAttribute("PieceType")
	local side = piece:GetAttribute("Side")
	local dr = toRow - fromRow
	local dc = toCol - fromCol
	if dr == 0 and dc == 0 then return false end

	local target = occupancy[key(toRow, toCol)]
	if target and target:GetAttribute("Side") == side then return false end

	if pieceType == "Pawn" then
		local direction = side == "White" and 1 or -1
		local startRow = side == "White" and 2 or 7
		if dc == 0 and dr == direction and not target then return true end
		if dc == 0 and dr == 2 * direction and fromRow == startRow and not target
			and not occupancy[key(fromRow + direction, fromCol)] then return true end
		if math.abs(dc) == 1 and dr == direction and target then return true end
		return false
	elseif pieceType == "Knight" then
		return (math.abs(dr) == 2 and math.abs(dc) == 1) or (math.abs(dr) == 1 and math.abs(dc) == 2)
	elseif pieceType == "King" then
		return math.max(math.abs(dr), math.abs(dc)) == 1
	elseif pieceType == "Bishop" then
		return math.abs(dr) == math.abs(dc) and pathIsClear(fromRow, fromCol, toRow, toCol)
	elseif pieceType == "Rook" then
		return (dr == 0 or dc == 0) and pathIsClear(fromRow, fromCol, toRow, toCol)
	elseif pieceType == "Queen" then
		local straight = dr == 0 or dc == 0
		local diagonal = math.abs(dr) == math.abs(dc)
		return (straight or diagonal) and pathIsClear(fromRow, fromCol, toRow, toCol)
	end
	return false
end

tryMove = function(toRow, toCol)
	if not selectedPiece or not selectedPiece.Parent then
		selectedPiece = nil
		return
	end
	local piece = selectedPiece
	if piece:GetAttribute("Side") ~= currentTurn then
		selectedPiece = nil
		return
	end
	if not isValidMove(piece, toRow, toCol) then
		setStatus(currentTurn .. " to move | Invalid move")
		return
	end

	local fromRow = piece:GetAttribute("Row")
	local fromCol = piece:GetAttribute("Col")
	local target = occupancy[key(toRow, toCol)]
	if target then
		occupancy[key(toRow, toCol)] = nil
		target:Destroy()
	end
	occupancy[key(fromRow, fromCol)] = nil
	occupancy[key(toRow, toCol)] = piece
	piece:SetAttribute("Row", toRow)
	piece:SetAttribute("Col", toCol)
	piece:PivotTo(CFrame.new(squarePosition(toRow, toCol, PIECE_Y)) * CFrame.Angles(0, 0, math.rad(90)))
	selectedPiece = nil
	currentTurn = currentTurn == "White" and "Black" or "White"
	setStatus(currentTurn .. " to move")
end

local backRank = {"Rook", "Knight", "Bishop", "Queen", "King", "Bishop", "Knight", "Rook"}

local function resetGame()
	piecesFolder:ClearAllChildren()
	table.clear(occupancy)
	selectedPiece = nil
	currentTurn = "White"
	for col = 1, 8 do
		makePiece(backRank[col], "White", 1, col)
		makePiece("Pawn", "White", 2, col)
		makePiece(backRank[col], "Black", 8, col)
		makePiece("Pawn", "Black", 7, col)
	end
	setStatus("White to move | New game")
end

controlEvent.OnServerEvent:Connect(function(player, action)
	if action == "Reset" then
		resetGame()
	elseif action == "Deselect" then
		selectedPiece = nil
		setStatus(currentTurn .. " to move")
	end
end)

resetGame()

-- Spawn a simple floor under the board.
local floor = Instance.new("Part")
floor.Name = "ArenaFloor"
floor.Anchored = true
floor.Size = Vector3.new(58, 1, 58)
floor.Position = CENTER + Vector3.new(0, -1.2, 0)
floor.Material = Enum.Material.Slate
floor.Color = Color3.fromRGB(28, 32, 42)
floor.Parent = arena

setStatus("White to move | Spiral Summit")
print("YUGATNEO Spiral Chess loaded at summit. Prototype rules only.")
