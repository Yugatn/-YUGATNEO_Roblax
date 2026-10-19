-- YUGATNEO Chess Engine — pure Luau rules (no Roblox Instances).
-- Board rows 1..8: White home rank to Black home rank.

local ChessEngine = {}

local FILES = 8
local PROMOTIONS = { Queen = true, Rook = true, Bishop = true, Knight = true }

local function inside(row, col)
	return row >= 1 and row <= FILES and col >= 1 and col <= FILES
end

local function other(side)
	return side == "White" and "Black" or "White"
end

local function cloneState(state)
	local copy = {
		board = {},
		turn = state.turn,
		enPassant = state.enPassant and { row = state.enPassant.row, col = state.enPassant.col } or nil,
		castling = {
			White = { kingSide = state.castling.White.kingSide, queenSide = state.castling.White.queenSide },
			Black = { kingSide = state.castling.Black.kingSide, queenSide = state.castling.Black.queenSide },
		},
		halfMove = state.halfMove or 0,
		fullMove = state.fullMove or 1,
	}
	for row = 1, 8 do
		copy.board[row] = {}
		for col = 1, 8 do
			local p = state.board[row][col]
			copy.board[row][col] = p and { type = p.type, side = p.side, moved = p.moved } or nil
		end
	end
	return copy
end

local function addMove(moves, row, col, extra)
	local move = { row = row, col = col }
	if extra then
		for k, v in pairs(extra) do
			move[k] = v
		end
	end
	table.insert(moves, move)
end

local function rayMoves(state, row, col, piece, directions, moves)
	for _, direction in ipairs(directions) do
		local r, c = row + direction[1], col + direction[2]
		while inside(r, c) do
			local target = state.board[r][c]
			if not target then
				addMove(moves, r, c)
			else
				if target.side ~= piece.side and target.type ~= "King" then
					addMove(moves, r, c)
				end
				break
			end
			r += direction[1]
			c += direction[2]
		end
	end
end

function ChessEngine.newGame()
	local state = {
		board = {},
		turn = "White",
		enPassant = nil,
		castling = {
			White = { kingSide = true, queenSide = true },
			Black = { kingSide = true, queenSide = true },
		},
		halfMove = 0,
		fullMove = 1,
	}
	for row = 1, 8 do
		state.board[row] = {}
	end
	local back = { "Rook", "Knight", "Bishop", "Queen", "King", "Bishop", "Knight", "Rook" }
	for col = 1, 8 do
		state.board[1][col] = { type = back[col], side = "White", moved = false }
		state.board[2][col] = { type = "Pawn", side = "White", moved = false }
		state.board[7][col] = { type = "Pawn", side = "Black", moved = false }
		state.board[8][col] = { type = back[col], side = "Black", moved = false }
	end
	return state
end

function ChessEngine.findKing(state, side)
	for row = 1, 8 do
		for col = 1, 8 do
			local p = state.board[row][col]
			if p and p.side == side and p.type == "King" then
				return row, col
			end
		end
	end
	return nil, nil
end

function ChessEngine.isSquareAttacked(state, row, col, bySide)
	local pawnDirection = bySide == "White" and 1 or -1
	local pawnRow = row - pawnDirection
	for _, dc in ipairs({ -1, 1 }) do
		local c = col + dc
		if inside(pawnRow, c) then
			local p = state.board[pawnRow][c]
			if p and p.side == bySide and p.type == "Pawn" then
				return true
			end
		end
	end

	for _, delta in ipairs({ { 2, 1 }, { 2, -1 }, { -2, 1 }, { -2, -1 }, { 1, 2 }, { 1, -2 }, { -1, 2 }, { -1, -2 } }) do
		local r, c = row + delta[1], col + delta[2]
		if inside(r, c) then
			local p = state.board[r][c]
			if p and p.side == bySide and p.type == "Knight" then
				return true
			end
		end
	end

	for dr = -1, 1 do
		for dc = -1, 1 do
			if dr ~= 0 or dc ~= 0 then
				local r, c = row + dr, col + dc
				if inside(r, c) then
					local p = state.board[r][c]
					if p and p.side == bySide and p.type == "King" then
						return true
					end
				end
			end
		end
	end

	for _, direction in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
		local r, c = row + direction[1], col + direction[2]
		while inside(r, c) do
			local p = state.board[r][c]
			if p then
				if p.side == bySide and (p.type == "Rook" or p.type == "Queen") then
					return true
				end
				break
			end
			r += direction[1]
			c += direction[2]
		end
	end

	for _, direction in ipairs({ { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }) do
		local r, c = row + direction[1], col + direction[2]
		while inside(r, c) do
			local p = state.board[r][c]
			if p then
				if p.side == bySide and (p.type == "Bishop" or p.type == "Queen") then
					return true
				end
				break
			end
			r += direction[1]
			c += direction[2]
		end
	end

	return false
end

function ChessEngine.inCheck(state, side)
	local row, col = ChessEngine.findKing(state, side)
	if not row then
		return true
	end
	return ChessEngine.isSquareAttacked(state, row, col, other(side))
end

local function pseudoMoves(state, row, col)
	local piece = state.board[row][col]
	local moves = {}
	if not piece then
		return moves
	end
	local side = piece.side
	local forward = side == "White" and 1 or -1

	if piece.type == "Pawn" then
		local one = row + forward
		if inside(one, col) and not state.board[one][col] then
			addMove(moves, one, col)
			local two = row + 2 * forward
			local start = side == "White" and 2 or 7
			if row == start and inside(two, col) and not state.board[two][col] then
				addMove(moves, two, col, { doublePawn = true })
			end
		end
		for _, dc in ipairs({ -1, 1 }) do
			local r, c = row + forward, col + dc
			if inside(r, c) then
				local target = state.board[r][c]
				if target and target.side ~= side and target.type ~= "King" then
					addMove(moves, r, c)
				end
				if state.enPassant and state.enPassant.row == r and state.enPassant.col == c then
					addMove(moves, r, c, { enPassant = true })
				end
			end
		end
	elseif piece.type == "Knight" then
		for _, d in ipairs({ { 2, 1 }, { 2, -1 }, { -2, 1 }, { -2, -1 }, { 1, 2 }, { 1, -2 }, { -1, 2 }, { -1, -2 } }) do
			local r, c = row + d[1], col + d[2]
			if inside(r, c) then
				local target = state.board[r][c]
				if not target or (target.side ~= side and target.type ~= "King") then
					addMove(moves, r, c)
				end
			end
		end
	elseif piece.type == "Bishop" then
		rayMoves(state, row, col, piece, { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }, moves)
	elseif piece.type == "Rook" then
		rayMoves(state, row, col, piece, { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }, moves)
	elseif piece.type == "Queen" then
		rayMoves(state, row, col, piece, {
			{ 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 },
			{ 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
		}, moves)
	elseif piece.type == "King" then
		for dr = -1, 1 do
			for dc = -1, 1 do
				if dr ~= 0 or dc ~= 0 then
					local r, c = row + dr, col + dc
					if inside(r, c) then
						local target = state.board[r][c]
						if not target or (target.side ~= side and target.type ~= "King") then
							addMove(moves, r, c)
						end
					end
				end
			end
		end
		local home = side == "White" and 1 or 8
		if row == home and col == 5 and not piece.moved and not ChessEngine.inCheck(state, side) then
			local rights = state.castling[side]
			local rookK, rookQ = state.board[home][8], state.board[home][1]
			if rights.kingSide and rookK and rookK.type == "Rook" and rookK.side == side and not rookK.moved
				and not state.board[home][6] and not state.board[home][7]
				and not ChessEngine.isSquareAttacked(state, home, 6, other(side))
				and not ChessEngine.isSquareAttacked(state, home, 7, other(side)) then
				addMove(moves, home, 7, { castle = "kingSide" })
			end
			if rights.queenSide and rookQ and rookQ.type == "Rook" and rookQ.side == side and not rookQ.moved
				and not state.board[home][2] and not state.board[home][3] and not state.board[home][4]
				and not ChessEngine.isSquareAttacked(state, home, 4, other(side))
				and not ChessEngine.isSquareAttacked(state, home, 3, other(side)) then
				addMove(moves, home, 3, { castle = "queenSide" })
			end
		end
	end
	return moves
end

local function applyMoveUnchecked(state, fromRow, fromCol, move, promotion)
	local board = state.board
	local piece = board[fromRow][fromCol]
	local captured = board[move.row][move.col]
	if move.enPassant then
		local capturedRow = move.row + (piece.side == "White" and -1 or 1)
		captured = board[capturedRow][move.col]
		board[capturedRow][move.col] = nil
	end
	board[fromRow][fromCol] = nil
	board[move.row][move.col] = piece

	if move.castle then
		local home = piece.side == "White" and 1 or 8
		local rookFrom = move.castle == "kingSide" and 8 or 1
		local rookTo = move.castle == "kingSide" and 6 or 4
		board[home][rookTo] = board[home][rookFrom]
		board[home][rookFrom] = nil
		board[home][rookTo].moved = true
	end

	piece.moved = true
	if piece.type == "Pawn" and (move.row == 8 or move.row == 1) then
		piece.type = PROMOTIONS[promotion] and promotion or "Queen"
	end
	state.enPassant = nil
	if piece.type == "Pawn" and math.abs(move.row - fromRow) == 2 then
		state.enPassant = { row = (move.row + fromRow) / 2, col = fromCol }
	end
	if piece.type == "King" then
		state.castling[piece.side].kingSide = false
		state.castling[piece.side].queenSide = false
	elseif piece.type == "Rook" then
		local home = piece.side == "White" and 1 or 8
		if fromRow == home and fromCol == 1 then
			state.castling[piece.side].queenSide = false
		end
		if fromRow == home and fromCol == 8 then
			state.castling[piece.side].kingSide = false
		end
	end
	if captured and captured.type == "Rook" then
		local home = captured.side == "White" and 1 or 8
		if move.row == home and move.col == 1 then
			state.castling[captured.side].queenSide = false
		end
		if move.row == home and move.col == 8 then
			state.castling[captured.side].kingSide = false
		end
	end
	if captured or piece.type == "Pawn" then
		state.halfMove = 0
	else
		state.halfMove += 1
	end
	if piece.side == "Black" then
		state.fullMove += 1
	end
	state.turn = other(piece.side)
	return captured
end

function ChessEngine.legalMoves(state, row, col)
	local piece = state.board[row] and state.board[row][col]
	if not piece then
		return {}
	end
	local legal = {}
	for _, move in ipairs(pseudoMoves(state, row, col)) do
		local copy = cloneState(state)
		applyMoveUnchecked(copy, row, col, move, "Queen")
		if not ChessEngine.inCheck(copy, piece.side) then
			table.insert(legal, move)
		end
	end
	return legal
end

function ChessEngine.move(state, fromRow, fromCol, toRow, toCol, promotion)
	if not inside(fromRow, fromCol) or not inside(toRow, toCol) then
		return false, "Invalid square"
	end
	local piece = state.board[fromRow][fromCol]
	if not piece then
		return false, "No piece on that square"
	end
	if piece.side ~= state.turn then
		return false, "It is " .. state.turn .. "'s turn"
	end
	local chosen
	for _, move in ipairs(ChessEngine.legalMoves(state, fromRow, fromCol)) do
		if move.row == toRow and move.col == toCol then
			chosen = move
			break
		end
	end
	if not chosen then
		return false, "Illegal move"
	end
	if piece.type == "Pawn" and (toRow == 1 or toRow == 8) and not PROMOTIONS[promotion] then
		return false, "Choose Queen, Rook, Bishop, or Knight for promotion"
	end
	local captured = applyMoveUnchecked(state, fromRow, fromCol, chosen, promotion)
	return true, ChessEngine.status(state), captured, chosen
end

function ChessEngine.allLegalMoves(state, side)
	local moves = {}
	side = side or state.turn
	for row = 1, 8 do
		for col = 1, 8 do
			local piece = state.board[row][col]
			if piece and piece.side == side then
				for _, move in ipairs(ChessEngine.legalMoves(state, row, col)) do
					table.insert(moves, {
						fromRow = row,
						fromCol = col,
						row = move.row,
						col = move.col,
						castle = move.castle,
						enPassant = move.enPassant,
					})
				end
			end
		end
	end
	return moves
end

function ChessEngine.status(state)
	local side = state.turn
	local check = ChessEngine.inCheck(state, side)
	local moves = ChessEngine.allLegalMoves(state, side)
	if #moves == 0 then
		if check then
			return {
				text = "Checkmate — " .. other(side) .. " wins",
				check = true,
				checkmate = true,
				stalemate = false,
				winner = other(side),
				gameOver = true,
			}
		end
		return {
			text = "Stalemate — draw",
			check = false,
			checkmate = false,
			stalemate = true,
			gameOver = true,
		}
	end
	if check then
		return {
			text = side .. " is in check",
			check = true,
			checkmate = false,
			stalemate = false,
			gameOver = false,
		}
	end
	return {
		text = side .. " to move",
		check = false,
		checkmate = false,
		stalemate = false,
		gameOver = false,
	}
end

function ChessEngine.copy(state)
	return cloneState(state)
end

return ChessEngine
