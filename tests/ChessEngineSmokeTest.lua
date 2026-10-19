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

print("[ChessEngine PASS] All smoke tests passed.")
