# Chess verification plan

This checklist is required before treating the prototype as tournament-ready. The current Roblox Studio project has not been automatically executed by these repository changes.

## Camera and input
- [ ] Step onto `WhiteChessViewPad`; camera frames all 64 White-board squares and pieces.
- [ ] Step onto `BlackChessViewPad`; camera frames all 64 Black-board squares and pieces.
- [ ] Camera remains stable while the avatar moves and while the character respawns.
- [ ] `EXIT` restores the prior camera type, subject, field of view, and controls.
- [ ] Mouse selection works from the oblique camera angle; clicking a legal destination moves the selected piece.
- [ ] Clicking an illegal destination does not change the board state.
- [ ] The green move highlights clear after a move, deselection, reset, and game end.

## Rules engine scenarios
- [ ] Pawn one-square move, initial two-square move, blocked pawn, and diagonal capture.
- [ ] Knight jump over occupied squares; bishop, rook, and queen path blocking.
- [ ] A move that exposes the moving side's king to check is rejected.
- [ ] King cannot move to an attacked square.
- [ ] Castling on both sides; reject castling through check, out of check, or after king/rook moved.
- [ ] En passant is available only immediately after the opponent's two-square pawn move; discovered check remains illegal.
- [ ] Promotion choices Queen, Rook, Bishop, and Knight are reflected in both engine state and rendered piece.
- [ ] Checkmate and stalemate positions end the game correctly.
- [ ] Reject a client move when it is not that player's turn or the player is not assigned to that side.

## Bot practice
- [ ] Pressing `PLAY VS BOT` starts a fresh game, reserves Black for the bot, and automatically enters White board view.
- [ ] The human can make a legal White move and the bot makes one legal Black reply.
- [ ] The bot never moves twice, never moves after game over, and never acts on behalf of a human seat.
- [ ] Reset starts a fresh position and clears selection, promotion UI, and highlights.

## Known scope gaps
- Two physical boards show one shared match. Independent table IDs, separate match state, queue/matchmaking, reconnect/requeue, and persistent ratings are not implemented.
- Run these tests with two Roblox Studio clients (Start Server + 2 Players) as well as a single client before publishing.


## Cooperative team quiz
- [ ] Start Studio server with at least three clients. Confirm first two are assigned to opposite sides and third can join White or Black.
- [ ] Add a second human to White. Clicking a White piece opens the quiz for all White teammates and does not yet select/highlight the piece.
- [ ] Submit a wrong answer: that player receives feedback and cannot answer again in the same quiz; other teammates can still answer.
- [ ] The first correct answer closes the quiz and grants only that player control of the pending piece selection.
- [ ] The quiz winner can select a legal destination; teammates who did not win cannot move the selected piece.
- [ ] If nobody answers correctly within 20 seconds, the quiz closes and the team can retry by clicking a friendly piece.
- [ ] When only one human is on a side, piece selection works without a quiz.
- [ ] Joining a full team (3 players) is rejected; players cannot join both teams or switch teams during the match.
- [ ] Resetting during a quiz clears the quiz and leaves no stale selection.
- [ ] Test White team and Black team independently, including after check, captures, promotion, and game end.


## Dual-board synchronization
- [ ] Confirm exactly one board spawns with 32 pieces in the correct starting position.
- [ ] Confirm green White and blue Black player fields spawn on opposite sides of the same board.
- [ ] Approach White field and press E; verify player is assigned White.
- [ ] With a second client, approach Black field and press E; verify player is assigned Black and the match begins.
- [ ] Verify a third client cannot claim an occupied side.
- [ ] Verify the HUD does not claim both seats are occupied while both fields are empty.
- [ ] On the single board, select a piece and move it; verify the same board updates correctly.
- [ ] Repeat a capture, castling move, en-passant capture, and promotion; verify the single board remains consistent with the chess engine.
- [ ] Reset the game; verify the single board returns to the starting position.
- [ ] With two Studio clients, verify each must claim an opposite field, and each can play only on their own turn.
- [ ] Confirm White and Black fields point the camera at the same board from opposite sides.

## Mouse input regression
- [ ] In either board-view mode, click the visible body of a piece; the correct logical square is selected and both boards show matching highlights.
- [ ] Click a green destination square; the piece moves and turn/status updates.
- [ ] Click the same piece twice to cancel selection.
- [ ] Click an enemy piece on a legal capture square to capture it.
- [ ] Click a piece while too far away to trigger any ClickDetector; selection still works from the top-down board view.
- [ ] Click outside both boards; no chess selection or move occurs.
- [ ] Send malformed row/column values through a client test; server rejects them without changing state.

## Automated engine smoke test
- [ ] Copy `tests/ChessEngineSmokeTest.lua` into a temporary Script under ServerScriptService.
- [ ] Run Play and confirm Output reports perft depth 1 = 20, depth 2 = 400, and depth 3 = 8902.
- [ ] Confirm the state-copy test leaves the original turn unchanged.
- [ ] Remove the temporary test Script after the run.

## Raycast interaction
- [ ] Enter either Chess Board view, click a piece, and verify the origin square turns gold and legal destinations turn green on both boards.
- [ ] Click a green square; verify the piece moves, turn changes, and the bot replies in bot mode.
- [ ] Click the board while it is the opponent's turn; the player receives a clear status message rather than a silent failure.
- [ ] Click the avatar and empty world; neither should be treated as a chess square.
- [ ] Test on wide and narrow viewports to check ray-plane square mapping.


## Draw rules regression
- [ ] Run `tests/ChessEngineSmokeTest.lua` in Studio and confirm perft depth 1–3 = 20, 400, 8902.
- [ ] Repeat the knight shuffle until the starting position has occurred three times; verify the game remains active and **CLAIM DRAW** succeeds for the side to move.
- [ ] Repeat the knight shuffle until the starting position has occurred five times; verify automatic draw.
- [ ] Set a legal test position to 100 half-moves without pawn moves or captures; verify draw is claimable but not automatic.
- [ ] Set a legal test position to 150 half-moves; verify automatic draw.
- [ ] Test king versus king and king+bishop versus king; verify insufficient-material draw.
- [ ] Verify checkmate and stalemate take precedence over move-count draw thresholds.
- [ ] Verify a player cannot claim a draw when it is not their side's turn or no claim condition is met.


## Clean arena regression
- [ ] Confirm the four watchtowers, fence rails, telescopes, target range, reaction pad, memory pads, computer desk, and phone booth no longer spawn.
- [ ] Confirm one chessboard, status panel, compact floor, and both player fields remain; no second board is created.
- [ ] Step onto the chess-view pad and use EXIT; confirm the original camera is restored.
- [ ] Confirm no telescope-specific camera UI or actions remain.
