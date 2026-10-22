-- YUGATNEO MatchTable: independent chess table (engine, players, FSM, 3D).
local Players = game:GetService("Players")
local ChessEngine = require(script.Parent:WaitForChild("ChessEngine"))

local MatchTable = {}
MatchTable.__index = MatchTable

local TILE, BOARD_Y = 4, 1
local PIECE_Y = BOARD_Y + 0.2
local WHITE = Color3.fromRGB(238, 232, 218)
local BLACK = Color3.fromRGB(65, 75, 91)
local WHITE_PIECE = Color3.fromRGB(248, 246, 240)
local BLACK_PIECE = Color3.fromRGB(32, 36, 44)
local GOLD = Color3.fromRGB(222, 175, 65)

local VALID = {
	Idle = { Waiting = true },
	Waiting = { Ready = true, Idle = true },
	Ready = { Playing = true, Waiting = true, Idle = true },
	Playing = { Finished = true },
	Finished = { Idle = true },
}
local MODES = { Classic = true }

local function key(r, c)
	return r .. "," .. c
end

local function sq(origin, row, col, y)
	return Vector3.new(origin.X + (col - 4.5) * TILE, y or PIECE_Y, origin.Z + (row - 4.5) * TILE)
end

function MatchTable.new(config)
	local self = setmetatable({}, MatchTable)
	self.tableId = config.tableId
	self.origin = config.origin or Vector3.new(0, BOARD_Y, 0)
	self.event = config.event
	self.onJoin = config.onJoin
	self.onLeave = config.onLeave
	self.onFinish = config.onFinish
	self.queueOnly = config.queueOnly == true
	self.state = "Idle"
	self.mode = "Classic"
	self.stakeAmount = 0
	self.challengeType = nil
	self.whitePlayerUserId = nil
	self.blackPlayerUserId = nil
	self.whiteReady = false
	self.blackReady = false
	self.startedAt = nil
	self.endReason = nil
	self.winnerSide = nil
	self.drawOfferFrom = nil
	self.engineState = ChessEngine.newGame()
	self.selected = {}
	self.pendingPromotion = {}
	self.occupancy = {}
	self.tiles = {}
	self:_buildWorld()
	self:_spawnPieces()
	self:_updateStatus()
	return self
end

function MatchTable:_transition(to)
	if not (VALID[self.state] and VALID[self.state][to]) then
		return false
	end
	self.state = to
	self:_updateStatus()
	self:_notifyBoth("TableState", self:getPublicState())
	return true
end

function MatchTable:_side(uid)
	if self.whitePlayerUserId == uid then return "White" end
	if self.blackPlayerUserId == uid then return "Black" end
	return nil
end

function MatchTable:_notifyBoth(action, payload, extra)
	for _, uid in ipairs({ self.whitePlayerUserId, self.blackPlayerUserId }) do
		if uid then
			local p = Players:GetPlayerByUserId(uid)
			if p then self.event:FireClient(p, action, self.tableId, payload, extra) end
		end
	end
end

function MatchTable:_notifyOne(uid, action, payload, extra)
	local p = Players:GetPlayerByUserId(uid)
	if p then self.event:FireClient(p, action, self.tableId, payload, extra) end
end

function MatchTable:_callJoin(player)
	if self.onJoin then self.onJoin(player, self.tableId) end
end

function MatchTable:_callLeave(player)
	if self.onLeave and typeof(player) == "Instance" then self.onLeave(player) end
end

function MatchTable:getPublicState()
	local function name(uid)
		if not uid then return "—" end
		local p = Players:GetPlayerByUserId(uid)
		return p and p.DisplayName or ("User " .. uid)
	end
	local st = ChessEngine.status(self.engineState)
	return {
		tableId = self.tableId,
		state = self.state,
		mode = self.mode,
		stakeAmount = self.stakeAmount,
		challengeType = self.challengeType,
		whitePlayerUserId = self.whitePlayerUserId,
		blackPlayerUserId = self.blackPlayerUserId,
		whiteName = name(self.whitePlayerUserId),
		blackName = name(self.blackPlayerUserId),
		whiteReady = self.whiteReady,
		blackReady = self.blackReady,
		turn = self.engineState.turn,
		statusText = st.text,
		check = st.check,
		gameOver = st.gameOver,
		winnerSide = self.winnerSide or st.winner,
		endReason = self.endReason,
		origin = { x = self.origin.X, y = self.origin.Y, z = self.origin.Z },
	}
end

function MatchTable:_setPrompt(on)
	if self.joinPrompt then self.joinPrompt.Enabled = on and not self.queueOnly end
end

function MatchTable:_updateStatus()
	local s = self:getPublicState()
	local lines = {
		"TABLE " .. self.tableId,
		s.state:upper(),
		"Mode: " .. s.mode,
		"White: " .. s.whiteName,
		"Black: " .. s.blackName,
	}
	if self.state == "Playing" or self.state == "Finished" then
		table.insert(lines, s.statusText)
	end
	if self.statusLabel then self.statusLabel.Text = table.concat(lines, "\n") end
end

function MatchTable:_buildWorld()
	local folder = Instance.new("Folder")
	folder.Name = "Table_" .. self.tableId
	folder.Parent = workspace
	self.folder = folder

	local boardFolder = Instance.new("Folder")
	boardFolder.Name = "Board"
	boardFolder.Parent = folder
	self.boardFolder = boardFolder

	local piecesFolder = Instance.new("Folder")
	piecesFolder.Name = "Pieces"
	piecesFolder.Parent = folder
	self.piecesFolder = piecesFolder

	local floor = Instance.new("Part")
	floor.Name = "TableFloor"
	floor.Anchored = true
	floor.Size = Vector3.new(42, 1, 42)
	floor.Position = self.origin + Vector3.new(0, -1.15, 0)
	floor.Material = Enum.Material.Slate
	floor.Color = Color3.fromRGB(28, 32, 42)
	floor.Parent = folder

	local statusPart = Instance.new("Part")
	statusPart.Name = "StatusBoard"
	statusPart.Anchored = true
	statusPart.CanCollide = false
	statusPart.Size = Vector3.new(14, 6, 0.4)
	statusPart.Position = self.origin + Vector3.new(0, 7, -20)
	statusPart.Color = Color3.fromRGB(20, 24, 32)
	statusPart.Parent = folder
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.PixelsPerStud = 40
	sg.Parent = statusPart
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.fromRGB(245, 245, 245)
	lbl.TextScaled = true
	lbl.Font = Enum.Font.GothamBold
	lbl.Text = "TABLE " .. self.tableId
	lbl.Parent = sg
	self.statusLabel = lbl

	local joinPad = Instance.new("Part")
	joinPad.Name = "JoinPad"
	joinPad.Anchored = true
	joinPad.Size = Vector3.new(8, 0.4, 8)
	joinPad.Position = self.origin + Vector3.new(0, 0.3, 22)
	joinPad.Material = Enum.Material.Neon
	joinPad.Color = Color3.fromRGB(60, 120, 180)
	joinPad.Parent = folder
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Join Table"
	prompt.ObjectText = "Chess Table " .. self.tableId
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = joinPad
	prompt.Enabled = not self.queueOnly
	self.joinPrompt = prompt
	prompt.Triggered:Connect(function(player)
		if not self.queueOnly then self:requestJoin(player) end
	end)

	for row = 1, 8 do
		self.tiles[row] = {}
		for col = 1, 8 do
			local tile = Instance.new("Part")
			tile.Name = "Square_" .. row .. "_" .. col
			tile.Anchored = true
			tile.Size = Vector3.new(TILE, 0.35, TILE)
			tile.Position = sq(self.origin, row, col, BOARD_Y)
			tile.Material = Enum.Material.SmoothPlastic
			tile.Color = ((row + col) % 2 == 0) and WHITE or BLACK
			tile.Parent = boardFolder
			tile:SetAttribute("Row", row)
			tile:SetAttribute("Col", col)
			tile:SetAttribute("TableId", self.tableId)
			self.tiles[row][col] = tile
			local click = Instance.new("ClickDetector")
			click.MaxActivationDistance = 90
			click.Parent = tile
			click.MouseClick:Connect(function(player)
				self:onSquareClicked(player, row, col)
			end)
		end
	end
end

local function addPart(model, name, size, offset, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.CFrame = model:GetPivot() * CFrame.new(offset)
	p.Parent = model
	return p
end

function MatchTable:_makePiece(pieceType, side, row, col)
	local model = Instance.new("Model")
	model.Name = side .. "_" .. pieceType .. "_" .. row .. "_" .. col
	model:SetAttribute("PieceType", pieceType)
	model:SetAttribute("Side", side)
	model:SetAttribute("Row", row)
	model:SetAttribute("Col", col)
	model:SetAttribute("TableId", self.tableId)

	local color = side == "White" and WHITE_PIECE or BLACK_PIECE
	local accent = side == "White" and Color3.fromRGB(200, 205, 210) or GOLD
	local mat = Enum.Material.Marble

	local base = Instance.new("Part")
	base.Name = "ClickableBase"
	base.Shape = Enum.PartType.Cylinder
	base.Size = Vector3.new(0.35, 1.55, 1.55)
	base.Anchored = true
	base.CanCollide = false
	base.Material = mat
	base.Color = color
	base.CFrame = CFrame.new(sq(self.origin, row, col, PIECE_Y)) * CFrame.Angles(0, 0, math.rad(90))
	base.Parent = model
	model.PrimaryPart = base

	local function cyl(name, diameter, height, y, partColor)
		local p = Instance.new("Part")
		p.Name = name
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(height, diameter, diameter)
		p.Anchored = true
		p.CanCollide = false
		p.Material = mat
		p.Color = partColor or color
		p.CFrame = CFrame.new(sq(self.origin, row, col, PIECE_Y + y)) * CFrame.Angles(0, 0, math.rad(90))
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
		p.Material = mat
		p.Color = partColor or color
		p.Position = sq(self.origin, row, col, PIECE_Y + y)
		p.Parent = model
	end

	-- Classic silhouette: wide foot → waist → stem → head
	cyl("Foot", 1.45, 0.28, 0.55, color)
	cyl("Waist", 1.05, 0.22, 0.95, accent)
	cyl("Stem", 0.55, 0.9, 1.45, color)

	if pieceType == "Pawn" then
		cyl("Collar", 0.7, 0.2, 1.95, accent)
		ball("Head", 0.72, 2.25, color)
	elseif pieceType == "Rook" then
		cyl("Tower", 1.05, 0.7, 2.05, color)
		for i = 1, 4 do
			local a = (i - 1) * math.pi / 2
			local merlon = Instance.new("Part")
			merlon.Name = "Merlon"
			merlon.Size = Vector3.new(0.28, 0.35, 0.28)
			merlon.Anchored = true
			merlon.CanCollide = false
			merlon.Material = mat
			merlon.Color = accent
			merlon.Position = sq(self.origin, row, col, PIECE_Y + 2.5)
				+ Vector3.new(math.cos(a) * 0.35, 0, math.sin(a) * 0.35)
			merlon.Parent = model
		end
	elseif pieceType == "Knight" then
		local neck = Instance.new("Part")
		neck.Name = "Neck"
		neck.Size = Vector3.new(0.4, 0.7, 0.45)
		neck.Anchored = true
		neck.CanCollide = false
		neck.Material = mat
		neck.Color = color
		neck.CFrame = CFrame.new(sq(self.origin, row, col, PIECE_Y + 1.95)) * CFrame.Angles(math.rad(-20), 0, 0)
		neck.Parent = model
		local head = Instance.new("Part")
		head.Name = "HorseHead"
		head.Size = Vector3.new(0.55, 0.85, 0.5)
		head.Anchored = true
		head.CanCollide = false
		head.Material = mat
		head.Color = color
		head.CFrame = CFrame.new(sq(self.origin, row, col, PIECE_Y + 2.35) + Vector3.new(0.15, 0, 0))
			* CFrame.Angles(math.rad(-25), math.rad(15), 0)
		head.Parent = model
		ball("Snout", 0.28, 2.15, accent)
	elseif pieceType == "Bishop" then
		cyl("Mitre", 0.85, 0.55, 2.05, color)
		ball("MitreBall", 0.55, 2.35, color)
		ball("Tip", 0.22, 2.7, accent)
	elseif pieceType == "Queen" then
		cyl("CrownBase", 1.15, 0.35, 2.05, color)
		for i = 1, 5 do
			local a = (i - 1) * (2 * math.pi / 5)
			ball("Jewel" .. i, 0.28, 2.35, accent)
			-- offset jewels around crown
			local jewel = model:FindFirstChild("Jewel" .. i)
			if jewel then
				jewel.Position = sq(self.origin, row, col, PIECE_Y + 2.35)
					+ Vector3.new(math.cos(a) * 0.38, 0, math.sin(a) * 0.38)
			end
		end
		ball("CrownTop", 0.35, 2.55, accent)
	elseif pieceType == "King" then
		cyl("Crown", 1.0, 0.4, 2.05, color)
		addPart(model, "CrossV", Vector3.new(0.18, 0.85, 0.18), Vector3.new(0, 2.65, 0), accent, mat)
		addPart(model, "CrossH", Vector3.new(0.55, 0.18, 0.18), Vector3.new(0, 2.75, 0), accent, mat)
	end

	local badge = Instance.new("BillboardGui")
	badge.Size = UDim2.fromOffset(34, 34)
	badge.StudsOffset = Vector3.new(0, 3.4, 0)
	badge.AlwaysOnTop = true
	badge.MaxDistance = 90
	badge.Parent = base
	local bt = Instance.new("TextLabel")
	bt.Size = UDim2.fromScale(1, 1)
	bt.BackgroundColor3 = side == "White" and Color3.fromRGB(30, 35, 45) or Color3.fromRGB(245, 240, 225)
	bt.BackgroundTransparency = 0.15
	bt.TextColor3 = side == "White" and Color3.new(1, 1, 1) or Color3.fromRGB(20, 25, 35)
	bt.Font = Enum.Font.GothamBlack
	bt.TextScaled = true
	bt.Text = ({ Pawn = "P", Rook = "R", Knight = "N", Bishop = "B", Queen = "Q", King = "K" })[pieceType]
	bt.Parent = badge
	Instance.new("UICorner", bt).CornerRadius = UDim.new(0.5, 0)

	model.Parent = self.piecesFolder
	self.occupancy[key(row, col)] = model

	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			local cd = Instance.new("ClickDetector")
			cd.MaxActivationDistance = 80
			cd.Parent = d
			cd.MouseClick:Connect(function(player)
				self:onPieceClicked(player, model)
			end)
		end
	end
	return model
end

function MatchTable:_spawnPieces()
	self.piecesFolder:ClearAllChildren()
	table.clear(self.occupancy)
	local back = { "Rook", "Knight", "Bishop", "Queen", "King", "Bishop", "Knight", "Rook" }
	for col = 1, 8 do
		self:_makePiece(back[col], "White", 1, col)
		self:_makePiece("Pawn", "White", 2, col)
		self:_makePiece(back[col], "Black", 8, col)
		self:_makePiece("Pawn", "Black", 7, col)
	end
end

function MatchTable:_clearSel(uid)
	self.selected[uid] = nil
	self.pendingPromotion[uid] = nil
	self:_notifyOne(uid, "ClearHighlights", nil)
	self:_notifyOne(uid, "PromotionHide", nil)
end

function MatchTable:requestJoin(player, options)
	options = options or {}
	local uid = player.UserId
	if self:_side(uid) then
		self:_notifyOne(uid, "Lobby", self:getPublicState())
		return true, "Already seated"
	end
	if self.state == "Playing" or self.state == "Finished" then
		return false, "Table is busy"
	end
	if self.whitePlayerUserId and self.blackPlayerUserId then
		return false, "Table is full"
	end

	local mode = options.mode or "Classic"
	if not MODES[mode] then mode = "Classic" end
	if not self.whitePlayerUserId and not self.blackPlayerUserId then
		self.mode = mode
		self.stakeAmount = 0
		self.challengeType = nil
	end

	local side
	if not self.whitePlayerUserId then
		self.whitePlayerUserId = uid
		side = "White"
	else
		self.blackPlayerUserId = uid
		side = "Black"
	end

	if self.state == "Idle" then self:_transition("Waiting") end
	if self.whitePlayerUserId and self.blackPlayerUserId and self.state == "Waiting" then
		self:_transition("Ready")
	end
	self:_setPrompt(self.state == "Idle" or self.state == "Waiting")
	self:_updateStatus()
	self:_callJoin(player)
	self:_notifyBoth("Lobby", self:getPublicState())
	self:_notifyOne(uid, "Joined", { side = side, state = self:getPublicState() })
	return true, side
end

function MatchTable:cancelWaiting(player)
	local uid = player.UserId
	if not self:_side(uid) then return false, "Not at table" end
	if self.state ~= "Waiting" and self.state ~= "Ready" then return false, "Cannot leave" end
	if self.whitePlayerUserId == uid then self.whitePlayerUserId = nil self.whiteReady = false end
	if self.blackPlayerUserId == uid then self.blackPlayerUserId = nil self.blackReady = false end
	self:_clearSel(uid)
	self:_notifyOne(uid, "LeftTable", self.tableId)
	self:_callLeave(player)
	if not self.whitePlayerUserId and not self.blackPlayerUserId then
		self.mode = "Classic"
		self.stakeAmount = 0
		self.challengeType = nil
		if self.state == "Ready" or self.state == "Waiting" then self:_transition("Idle") end
	else
		self.whiteReady = false
		self.blackReady = false
		if self.state == "Ready" then self:_transition("Waiting") end
		self:_notifyBoth("Lobby", self:getPublicState())
	end
	self:_setPrompt(true)
	self:_updateStatus()
	return true
end

function MatchTable:setReady(player, ready)
	local uid = player.UserId
	local side = self:_side(uid)
	if not side then return false, "Not seated" end
	if self.state ~= "Ready" and self.state ~= "Waiting" then return false, "Not in lobby" end
	if side == "White" then self.whiteReady = ready and true or false
	else self.blackReady = ready and true or false end
	if self.whitePlayerUserId and self.blackPlayerUserId and self.whiteReady and self.blackReady then
		if self.state == "Waiting" then self:_transition("Ready") end
		return self:startMatch()
	end
	self:_notifyBoth("Lobby", self:getPublicState())
	return true
end

function MatchTable:startMatch()
	if not self.whitePlayerUserId or not self.blackPlayerUserId then return false, "Need two players" end
	if not self.whiteReady or not self.blackReady then return false, "Both must confirm" end
	self.engineState = ChessEngine.newGame()
	self.selected = {}
	self.pendingPromotion = {}
	self.startedAt = os.time()
	self.endReason = nil
	self.winnerSide = nil
	self:_spawnPieces()
	if self.state == "Waiting" then self:_transition("Ready") end
	if not self:_transition("Playing") then return false, "Transition failed" end
	self:_setPrompt(false)
	self:_notifyBoth("MatchStarted", self:getPublicState())
	return true
end

function MatchTable:_finish(reason, winner)
	if self.state ~= "Playing" then return false end
	self.endReason = reason
	self.winnerSide = winner
	self:_transition("Finished")
	self:_setPrompt(false)
	self:_notifyBoth("MatchEnded", self:getPublicState())
	if self.onFinish then
		self.onFinish({tableId = self.tableId, white = self.whitePlayerUserId, black = self.blackPlayerUserId, winner = winner, reason = reason})
	end
	return true
end

function MatchTable:resign(player)
	local side = self:_side(player.UserId)
	if not side or self.state ~= "Playing" then return false end
	return self:_finish("resign", side == "White" and "Black" or "White")
end

function MatchTable:offerDraw(player)
	local uid = player.UserId
	if not self:_side(uid) or self.state ~= "Playing" then return false end
	if self.drawOfferFrom and self.drawOfferFrom ~= uid then
		self.drawOfferFrom = nil
		return self:_finish("draw_agreement", nil)
	end
	self.drawOfferFrom = uid
	self:_notifyBoth("DrawOffered", { fromUserId = uid })
	return true
end

function MatchTable:handleDisconnect(uid)
	if not self:_side(uid) then return end
	local player = Players:GetPlayerByUserId(uid)
	if self.state == "Waiting" or self.state == "Ready" then
		self:cancelWaiting({ UserId = uid })
	elseif self.state == "Playing" then
		local side = self:_side(uid)
		self:_finish("disconnect", side == "White" and "Black" or "White")
		if player then self:_callLeave(player) end
	elseif self.state == "Finished" then
		if self.whitePlayerUserId == uid then self.whitePlayerUserId = nil end
		if self.blackPlayerUserId == uid then self.blackPlayerUserId = nil end
		if player then self:_callLeave(player) end
	end
end

function MatchTable:clearFinished(player)
	if self.state ~= "Finished" then return false, "Not finished" end
	local uid = player and player.UserId
	if uid and not self:_side(uid) then return false, "Not authorized" end
	local white, black = self.whitePlayerUserId, self.blackPlayerUserId
	self.whitePlayerUserId = nil
	self.blackPlayerUserId = nil
	self.whiteReady = false
	self.blackReady = false
	self.mode = "Classic"
	self.stakeAmount = 0
	self.challengeType = nil
	self.drawOfferFrom = nil
	self.selected = {}
	self.pendingPromotion = {}
	self.engineState = ChessEngine.newGame()
	self:_spawnPieces()
	self:_transition("Idle")
	self:_setPrompt(true)
	if white then
		self:_notifyOne(white, "LeftTable", self.tableId)
		local p = Players:GetPlayerByUserId(white)
		if p then self:_callLeave(p) end
	end
	if black then
		self:_notifyOne(black, "LeftTable", self.tableId)
		local p = Players:GetPlayerByUserId(black)
		if p then self:_callLeave(p) end
	end
	return true
end

function MatchTable:onPieceClicked(player, model)
	local uid = player.UserId
	local side = self:_side(uid)
	if not side or self.state ~= "Playing" or self.pendingPromotion[uid] then return end
	local row, col = model:GetAttribute("Row"), model:GetAttribute("Col")
	if model:GetAttribute("Side") == side and side == self.engineState.turn then
		local sel = self.selected[uid]
		if sel and sel.row == row and sel.col == col then
			self:_clearSel(uid)
			return
		end
		self.selected[uid] = { row = row, col = col }
		self:_notifyOne(uid, "LegalMoves", ChessEngine.legalMoves(self.engineState, row, col), {
			fromRow = row, fromCol = col,
		})
		return
	end
	if self.selected[uid] then self:tryMove(player, row, col) end
end

function MatchTable:onSquareClicked(player, row, col)
	if self.selected[player.UserId] then self:tryMove(player, row, col) end
end

function MatchTable:tryMove(player, toRow, toCol, promotion)
	local uid = player.UserId
	local side = self:_side(uid)
	if not side then return false, "Not a participant" end
	if self.state ~= "Playing" then return false, "Not playing" end
	if side ~= self.engineState.turn then return false, "Not your turn" end
	local sel = self.selected[uid]
	if not sel then return false, "No selection" end
	local fromRow, fromCol = sel.row, sel.col
	local piece = self.engineState.board[fromRow] and self.engineState.board[fromRow][fromCol]
	if not piece then self:_clearSel(uid) return false, "No piece" end
	if piece.type == "Pawn" and (toRow == 1 or toRow == 8) and not promotion then
		self.pendingPromotion[uid] = { row = toRow, col = toCol }
		self:_notifyOne(uid, "PromotionRequired", { row = toRow, col = toCol })
		return true
	end
	local ok, result, _, move = ChessEngine.move(self.engineState, fromRow, fromCol, toRow, toCol, promotion or "Queen")
	if not ok then
		self:_notifyOne(uid, "Status", tostring(result))
		return false, result
	end

	local captureRow = move.enPassant and (toRow + (side == "White" and -1 or 1)) or toRow
	local cap = self.occupancy[key(captureRow, toCol)]
	local moving = self.occupancy[key(fromRow, fromCol)]
	if cap and cap ~= moving then
		self.occupancy[key(captureRow, toCol)] = nil
		cap:Destroy()
	end
	if moving then
		self.occupancy[key(fromRow, fromCol)] = nil
		self.occupancy[key(toRow, toCol)] = moving
		moving:SetAttribute("Row", toRow)
		moving:SetAttribute("Col", toCol)
		moving:PivotTo(CFrame.new(sq(self.origin, toRow, toCol, PIECE_Y)) * CFrame.Angles(0, 0, math.rad(90)))
		if move.castle then
			local home = side == "White" and 1 or 8
			local rf = move.castle == "kingSide" and 8 or 1
			local rt = move.castle == "kingSide" and 6 or 4
			local rook = self.occupancy[key(home, rf)]
			if rook then
				self.occupancy[key(home, rf)] = nil
				self.occupancy[key(home, rt)] = rook
				rook:SetAttribute("Row", home)
				rook:SetAttribute("Col", rt)
				rook:PivotTo(CFrame.new(sq(self.origin, home, rt, PIECE_Y)) * CFrame.Angles(0, 0, math.rad(90)))
			end
		end
		local promoted = self.engineState.board[toRow][toCol]
		if piece.type == "Pawn" and (toRow == 1 or toRow == 8) and promoted then
			moving:Destroy()
			self.occupancy[key(toRow, toCol)] = nil
			self:_makePiece(promoted.type, side, toRow, toCol)
		end
	end

	self:_clearSel(uid)
	self.drawOfferFrom = nil
	local status = ChessEngine.status(self.engineState)
	self:_notifyBoth("Status", status.text)
	self:_notifyBoth("TableState", self:getPublicState())
	self:_updateStatus()
	if status.gameOver then
		local reason = status.drawReason or "stalemate"
		if status.checkmate then reason = "checkmate" end
		self:_finish(reason, status.winner)
	end
	return true, status
end

function MatchTable:promote(player, choice)
	local pending = self.pendingPromotion[player.UserId]
	if not pending then return false end
	self.pendingPromotion[player.UserId] = nil
	return self:tryMove(player, pending.row, pending.col, choice)
end

function MatchTable:deselect(player)
	self:_clearSel(player.UserId)
	return true
end

function MatchTable:claimDraw(player)
	local side = self:_side(player.UserId)
	if self.state ~= "Playing" or side ~= self.engineState.turn then return false end
	local status = ChessEngine.status(self.engineState)
	if status.canClaimThreefold then return self:_finish("threefold_claim", nil) end
	if status.canClaimFiftyMove then return self:_finish("fifty_move_claim", nil) end
	return false
end

return MatchTable
