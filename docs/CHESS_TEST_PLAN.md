# Chess verification checklist

This checklist is for Roblox Studio. A successful Rojo build proves the project can be assembled; it does not prove chess rules or network behavior are correct.

## Basic interaction
- [ ] Start a local server with one player.
- [ ] Click **PLAY VS BOT**. Confirm the status says the player is White and the bot is Black.
- [ ] Click a White piece. Confirm legal destinations turn green.
- [ ] Click a green destination. Confirm the piece moves and Black replies after a short delay.
- [ ] Click an illegal destination. Confirm the position and turn do not change.
- [ ] Click CANCEL after selecting a piece. Confirm selection highlights clear.
- [ ] Press NEW GAME. Confirm all 32 pieces return to their initial squares.

## Rules scenarios
- [ ] White pawn moves one square from its starting rank.
- [ ] White pawn can move two squares from its starting rank only if both squares are clear.
- [ ] Pawn captures diagonally only when an enemy piece is present (or en passant applies).
- [ ] Knight can jump over pieces; rook, bishop and queen cannot jump.
- [ ] A move that leaves the moving side's king in check is rejected.
- [ ] Check is announced; checkmate ends the game; stalemate ends as a draw.
- [ ] Castling is allowed only when all conditions are met; it is rejected through check or while in check.
- [ ] En passant is available only immediately after the opponent's two-square pawn move.
- [ ] Promotion offers queen, rook, bishop and knight, and the rendered piece matches the choice.
- [ ] Bot's move is always legal and the game does not freeze after checkmate/stalemate.

## Multiplayer and permissions
- [ ] With two human players, first is White and second is Black.
- [ ] A third player cannot move either side.
- [ ] Only the host can reset the shared board.
- [ ] A player cannot move when it is the other side's turn.
- [ ] If a human opponent leaves, the game stops cleanly; the remaining White player can start bot practice if the Black seat is free.

## Known gaps before tournaments
- The server currently supports one shared board, not independent tables.
- No tournament registration, bracket/Swiss pairing, round clock, results persistence, player rating, or anti-abuse moderation exists yet.
- Threefold repetition, the fifty-move rule, and insufficient-material draws are not implemented.
- The bot is a basic legal-move opponent and should not be advertised as a strong chess AI.
- Verify all scenarios in Studio with both **Play** and **Start Server / Start Player**. Do not publish as tournament-ready until these checks pass.
