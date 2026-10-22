-- YUGATNEO ChessEngine smoke test
-- Manual use: copy this script into a temporary Script under ServerScriptService,
-- run Play once, verify the assertions in Output, then remove the temporary Script.
local ServerScriptService = game:GetService("ServerScriptService")
local ChessEngine = require(ServerScriptService:WaitForChild("ChessEngine"))

local function assertEqual(actual, expected, label)
	assert(actual == expected, string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)))
	print("[ChessEngine PASS]", label, actual)
end

local function perft(state, depth)
	if depth == 0 then return 1 end
	local nodes = 0
	for _, move in ipairs(ChessEngine.allLegalMoves(state, state.turn)) do
		local child = ChessEngine.copy(state)
		local ok, reason = ChessEngine.move(child, move.fromRow, move.fromCol, move.row, move.col, "Queen")
		assert(ok, "Generated legal move rejected by ChessEngine.move: " .. tostring(reason))
		nodes += perft(child, depth - 1)
	end
	return nodes
end

local initial = ChessEngine.newGame()
assertEqual(#ChessEngine.allLegalMoves(initial, "White"), 20, "starting position has 20 legal White moves")
assertEqual(perft(initial, 1), 20, "perft depth 1")
assertEqual(perft(initial, 2), 400, "perft depth 2")
assertEqual(perft(initial, 3), 8902, "perft depth 3")

local copy = ChessEngine.copy(initial)
local ok = ChessEngine.move(copy, 2, 5, 4, 5, "Queen")
assertEqual(ok, true, "White e-pawn double move is accepted")
assertEqual(copy.turn, "Black", "turn changes after a legal move")
assertEqual(initial.turn, "White", "copying state leaves original unchanged")


local repetition = ChessEngine.newGame()
local sequence = {
	{1,2,3,3}, {8,2,6,3}, {3,3,1,2}, {6,3,8,2},
	{1,2,3,3}, {8,2,6,3}, {3,3,1,2}, {6,3,8,2},
}
for index, move in ipairs(sequence) do
	local moved, reason = ChessEngine.move(repetition, move[1], move[2], move[3], move[4], "Queen")
	assert(moved, "Knight repetition move " .. index .. " rejected: " .. tostring(reason))
end
local repetitionStatus = ChessEngine.status(repetition)
assertEqual(repetitionStatus.gameOver, false, "threefold repetition is claimable, not automatic")
assertEqual(repetitionStatus.canClaimThreefold, true, "threefold repetition exposes a draw claim")

local fivefold = ChessEngine.newGame()
for index, move in ipairs({
	{1,2,3,3}, {8,2,6,3}, {3,3,1,2}, {6,3,8,2},
	{1,2,3,3}, {8,2,6,3}, {3,3,1,2}, {6,3,8,2},
	{1,2,3,3}, {8,2,6,3}, {3,3,1,2}, {6,3,8,2},
	{1,2,3,3}, {8,2,6,3}, {3,3,1,2}, {6,3,8,2},
}) do
	local moved, reason = ChessEngine.move(fivefold, move[1], move[2], move[3], move[4], "Queen")
	assert(moved, "Fivefold repetition move " .. index .. " rejected: " .. tostring(reason))
end
local fivefoldStatus = ChessEngine.status(fivefold)
assertEqual(fivefoldStatus.gameOver, true, "fivefold repetition ends the game automatically")
assertEqual(fivefoldStatus.drawReason, "fivefold repetition", "fivefold repetition reason")

local fiftyMove = ChessEngine.newGame()
for row = 1, 8 do for col = 1, 8 do fiftyMove.board[row][col] = nil end end
fiftyMove.board[1][5] = { type = "King", side = "White", moved = true }
fiftyMove.board[8][5] = { type = "King", side = "Black", moved = true }
fiftyMove.board[1][1] = { type = "Rook", side = "White", moved = true }
fiftyMove.castling.White.kingSide = false
fiftyMove.castling.White.queenSide = false
fiftyMove.castling.Black.kingSide = false
fiftyMove.castling.Black.queenSide = false
fiftyMove.halfMove = 100
local fiftyStatus = ChessEngine.status(fiftyMove)
assertEqual(fiftyStatus.gameOver, false, "fifty-move draw is claimable, not automatic")
assertEqual(fiftyStatus.canClaimFiftyMove, true, "100 half-moves enable a draw claim")
fiftyMove.halfMove = 150
local seventyFiveStatus = ChessEngine.status(fiftyMove)
assertEqual(seventyFiveStatus.drawReason, "seventy-five-move rule", "150 half-moves trigger automatic draw")

local insufficient = ChessEngine.newGame()
for row = 1, 8 do for col = 1, 8 do insufficient.board[row][col] = nil end end
insufficient.board[1][5] = { type = "King", side = "White", moved = true }
insufficient.board[8][5] = { type = "King", side = "Black", moved = true }
insufficient.board[2][3] = { type = "Bishop", side = "White", moved = true }
insufficient.castling.White.kingSide = false
insufficient.castling.White.queenSide = false
insufficient.castling.Black.kingSide = false
insufficient.castling.Black.queenSide = false
insufficient.halfMove = 0
local insufficientStatus = ChessEngine.status(insufficient)
assertEqual(insufficientStatus.drawReason, "insufficient material", "king and bishop versus king is drawn")

print("[ChessEngine PASS] All smoke tests passed.")
