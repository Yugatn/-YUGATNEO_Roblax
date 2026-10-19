# YUGATNEO Roblox — Chess Arena

A Roblox Studio chess game prototype for the YUGATNEO world. This branch uses one shared chessboard and two separate player fields on opposite sides. Stepping onto a field claims White or Black automatically. It also includes robust mouse-to-square mapping and automatic overhead view for bot practice. Changes still require live verification in Roblox Studio.

## Included in this development branch

- One generated 8×8 chessboard with 32 starting pieces, plus two player fields on opposite sides.
- Distinct 3D piece silhouettes and readable piece badges.
- Click a piece to highlight legal destination squares, then click a destination to move.
- Server-authoritative legal move validation.
- Turn order, captures, king-safety checks, check, checkmate, and stalemate.
- Castling, en passant, and pawn promotion with a queen, rook, bishop, or knight choice dialog.
- Modern dark HUD with gold accents, live status, move hints, rules panel, cancel selection, and host-only new-game control.
- One server-authoritative match on one board. Players claim White/Black by stepping onto the matching field; the match remains locked until both sides are occupied. Other players can spectate or join a team.
- Move requests are restricted to the seated player whose side is on move; promotion choice is accepted only from the player who initiated that promotion.

## Important implementation notes

- There is only one physical board and one match. The two fields are player join points, not additional boards. Independent table IDs and matchmaking are not implemented yet.
- Joining the server does not automatically claim a side. Board input is blocked until both White and Black fields are occupied. If a side becomes empty, the match is stopped; automatic queueing and reconnect support are not implemented.
- The server reuses the existing `ChessControlEvent` during script reloads to avoid creating separate client/server event instances. HUD team buttons can add teammates to an occupied side up to the three-player limit; entering the physical fields claims only an unoccupied side.
- The rules engine is a first implementation and still needs scenario-based testing in Roblox Studio before it can be treated as tournament-ready.
- Draw handling is present in the current engine branch but still requires runtime regression testing.
- Automated tests and live Roblox Studio verification are still required before treating the rules engine as tournament-ready.

## Top-down chess interaction
- A green White player field and blue Black player field sit on opposite sides of the same board. White is on the board's row-1 side; Black is on the row-8 side. Step onto either field to claim that side; entering a field also switches the local camera to an overhead-oblique view from that side. The board rejects moves until both fields are occupied. Pressing **PLAY VS BOT** also opens White's board view automatically. Use **EXIT** to restore the previous camera state.
- Select a piece and click a highlighted green square. The server validates legal moves through `ChessEngine`, including check restrictions and special chess moves supported by the engine.
- Both players use the same board and match state. Independent table IDs and simultaneous separate matches are not implemented. See [`docs/CHESS_TEST_PLAN.md`](docs/CHESS_TEST_PLAN.md) for the camera, move legality, special-rule, and bot test checklist; these tests have not been run automatically in Roblox Studio.

## Cooperative teams and quiz captain

- The primary White and Black players join by stepping onto their respective fields. Up to three human players can be assigned to each side using the **JOIN WHITE TEAM** and **JOIN BLACK TEAM** controls. Team membership and the quiz captain flow require multi-client verification.
- When a side has multiple human teammates, clicking one of that side's pieces starts a short multiple-choice chess/general chess-knowledge quiz for that team. The first teammate to answer correctly becomes the move captain for that selection and chooses the legal destination.
- The quiz is time-limited to 20 seconds. Each teammate gets one answer attempt per quiz. If no one answers correctly before time runs out, the team can click a friendly piece to try again.
- The server decides the correct answer, controls quiz state, assigns the move captain, and still validates the chess move through `ChessEngine`.
- This is an initial prototype: questions are a small fixed set, team membership is limited to three per side, and no persistent team/turn statistics or separate match tables exist. Test with multiple Studio clients before publishing.

## Focused chess arena

- Removed the four watchtowers, perimeter fence and decorative rails, telescopes, target range, reaction-time pad, memory challenge, computer desk, phone booth, and character sunglasses/beard styling. These features were unrelated to chess and made the play area visually crowded.
- The environment now consists of one chessboard, its pieces, a status panel, a compact floor, and separate White/Black player fields on opposite sides.
- The camera overlay is now chess-only; telescope camera actions and labels were removed.
- The floor is a compact 48×52-stud area sized for one board and two opposing player fields.

## Input reliability and engine checks

- Board selection uses server-created `ClickDetector`s on all 64 squares and each piece's clickable base. This avoids depending on custom screen-ray coordinate calculations; both the piece and empty destination square send the same validated square coordinate into the server move handler. This avoids depending on which tall piece part a raycast hits and sends only row/column coordinates to the server.
- The server rate-limits board-click requests and returns player-specific feedback for invalid squares, ended games, pending promotion, and the wrong side to move. The server remains authoritative for turn ownership and legal moves.
- The engine resets the half-move counter on pawn promotion as required by the 50-move-rule counter semantics.
- A manual engine smoke-test harness is available at [`tests/ChessEngineSmokeTest.lua`](tests/ChessEngineSmokeTest.lua). Copy it into a temporary Script under `ServerScriptService` and run Play; it checks standard starting-position perft counts at depths 1–3 (20, 400, 8902). Remove the temporary Script after testing.
- These changes have not been executed in Roblox Studio in this environment. Treat the smoke-test file as a test harness to run, not as evidence that the tests have passed.

## Draw rules

- Threefold repetition and the fifty-move rule are **claimable** draws, not automatic game endings. The current player can use **CLAIM DRAW** when the current position meets either condition.
- Fivefold repetition and the seventy-five-move rule end the game automatically. Checkmate/stalemate are evaluated before these draw counters.
- The engine also detects clear insufficient-material cases: king versus king, king + one bishop/knight versus king, and bishops-only positions where every bishop is on the same square color.
- These rules have a manual regression harness in `tests/ChessEngineSmokeTest.lua`. They are not yet verified in a live Roblox Studio session. Position-repetition keying still needs dedicated en-passant edge-case tests before tournament use.

## Run in Roblox Studio

1. Open this repository folder on your Mac.
2. In Terminal, run `rojo serve default.project.json`.
3. Open Roblox Studio and connect the Rojo plugin to `localhost:34872`.
4. Press **Play**.
5. In Explorer, check `ServerScriptService/ChessEngine`, `ServerScriptService/ChessArena`, and `StarterPlayer/StarterPlayerScripts/ChessControls`.

If Rojo is already running on port 34872, do not launch a second server. Use the existing Terminal window or stop the old process deliberately before restarting.

## GitHub and branches

This work is isolated on `feature/two-board-playable-chess`; `main` remains unchanged while the changes are reviewed. To test this branch locally:

```bash
git fetch origin
git switch feature/two-board-playable-chess
git pull
```

Then reconnect Rojo if needed. GitHub changes do not appear in Studio until the local checkout has been updated.

## Files

- `src/server/ChessEngine.lua` — chess movement, attack detection, legal move filtering, check/checkmate/stalemate, castling, en passant, promotion.
- `src/server/ChessArena.server.lua` — board and piece rendering, server-side interaction, simple player seats, promotion rendering, status, host-authorized reset.
- `src/client/ChessControls.client.lua` — in-game HUD, rules panel, status, legal-move highlighting.
- `default.project.json` — Rojo mapping.
- `docs/ROBLOX_GITHUB_SYNC.md` — synchronization and publishing guide.
