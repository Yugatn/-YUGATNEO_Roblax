# Chess verification plan

This checklist is required before treating the prototype as tournament-ready. The current Roblox Studio project has not been automatically executed by these repository changes.

## Camera and input
- [ ] Step onto `ChessTopDownViewPad`; camera frames all 64 squares and all pieces.
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
- [ ] Pressing `PLAY VS BOT` starts a fresh game and visibly confirms White is the human side.
- [ ] The human can make a legal White move and the bot makes one legal Black reply.
- [ ] The bot never moves twice, never moves after game over, and never acts on behalf of a human seat.
- [ ] Reset starts a fresh position and clears selection, promotion UI, and highlights.

## Known scope gaps
- One shared board is still used by everyone in a server. Independent table IDs, separate match state, queue/matchmaking, reconnect/requeue, persistent ratings, repetition draws, the fifty-move rule, and insufficient-material draws are not implemented.
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
