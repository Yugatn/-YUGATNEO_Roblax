# YUGATNEO Roblox — Chess Arena

A Roblox Studio chess game prototype for the YUGATNEO world. This branch adds a top-down board-view camera to the server-side chess rules engine and in-game HUD. Changes still require live verification in Roblox Studio.

## Included in this development branch

- Generated 8×8 board and 32 starting pieces.
- Distinct 3D piece silhouettes and readable piece badges.
- Click a piece to highlight legal destination squares, then click a destination to move.
- Server-authoritative legal move validation.
- Turn order, captures, king-safety checks, check, checkmate, and stalemate.
- Castling, en passant, and pawn promotion with a queen, rook, bishop, or knight choice dialog.
- Modern dark HUD with gold accents, live status, move hints, rules panel, cancel selection, and host-only new-game control.
- Basic server-side seating for the current shared board: first player is White, second player is Black, additional players spectate.
- Move requests are restricted to the seated player whose side is on move; promotion choice is accepted only from the player who initiated that promotion.

## Important implementation notes

- The current server still creates one shared board for everyone in the server; independent tables and matchmaking are not implemented yet.
- Seating is a security baseline, not a full lobby: seats are not yet re-queued automatically when a player leaves, and the host is the first player who joined the current server.
- The rules engine is a first implementation and still needs scenario-based testing in Roblox Studio before it can be treated as tournament-ready.
- Draw handling for threefold repetition, the fifty-move rule, and insufficient material is not implemented yet.
- Automated tests and live Roblox Studio verification are still required before treating the rules engine as tournament-ready.

## Top-down chess interaction
- A green walk-on pad is placed beside the chessboard. Stepping onto it switches the local camera to a stable oblique overhead view, calculated from the board center and viewport. Use the on-screen **EXIT** control to restore the previous camera state.
- Select a piece and click a highlighted green square. The server validates legal moves through `ChessEngine`, including check restrictions and special chess moves supported by the engine.
- This is still a shared-board prototype. Independent table IDs and simultaneous separate matches are not implemented. See [`docs/CHESS_TEST_PLAN.md`](docs/CHESS_TEST_PLAN.md) for the camera, move legality, special-rule, and bot test checklist; these tests have not been run automatically in Roblox Studio.

## Cooperative teams and quiz captain

- Up to three human players can be assigned to each side using **JOIN WHITE TEAM** and **JOIN BLACK TEAM**. The first two players on a fresh server are assigned White and Black automatically; additional players can join a team if it has room.
- When a side has multiple human teammates, clicking one of that side's pieces starts a short multiple-choice chess/general chess-knowledge quiz for that team. The first teammate to answer correctly becomes the move captain for that selection and chooses the legal destination.
- The quiz is time-limited to 20 seconds. Each teammate gets one answer attempt per quiz. If no one answers correctly before time runs out, the team can click a friendly piece to try again.
- The server decides the correct answer, controls quiz state, assigns the move captain, and still validates the chess move through `ChessEngine`.
- This is an initial prototype: questions are a small fixed set, team membership is limited to three per side, and no persistent team/turn statistics or separate match tables exist. Test with multiple Studio clients before publishing.

## Reliable board input and world props

- Piece and square selection now uses a client mouse raycast and sends only the target row/column through `ChessControlEvent`; the server checks side-to-move, player assignment, selection ownership, and legal moves in `ChessEngine`.
- Removed overlapping `ClickDetector` listeners from the chessboard and piece decorations to avoid input priority and character-distance issues. The client raycast is only an input mechanism, not an authority for legal moves.
- Added a study desk with a computer terminal and an interactive public telephone booth beside the board.
- The computer and phone prompts currently show informational status messages; they are visual world props, not yet connected to a real browser, telephony, or navigation system.
- Reference used: Roblox Creator Hub documentation for [ClickDetector](https://create.roblox.com/docs/reference/engine/classes/ClickDetector) and [RemoteEvents](https://create.roblox.com/docs/scripting/events/remote). This implementation uses original project code rather than copying a third-party chess engine with unclear or restrictive licensing.

## Input reliability and engine checks

- Board input uses `UserInputService` plus a camera raycast filtered to the chess arena, then sends only row/column coordinates to the server. This avoids relying on overlapping `ClickDetector` instances and ignores characters and unrelated scenery.
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

This work is isolated on `feature/reliable-chess-input-world-props`; `main` remains unchanged while the changes are reviewed. To test this branch locally:

```bash
git fetch origin
git switch feature/reliable-chess-input-world-props
git pull
```

Then reconnect Rojo if needed. GitHub changes do not appear in Studio until the local checkout has been updated.

## Files

- `src/server/ChessEngine.lua` — chess movement, attack detection, legal move filtering, check/checkmate/stalemate, castling, en passant, promotion.
- `src/server/ChessArena.server.lua` — board and piece rendering, server-side interaction, simple player seats, promotion rendering, status, host-authorized reset.
- `src/client/ChessControls.client.lua` — in-game HUD, rules panel, status, legal-move highlighting.
- `default.project.json` — Rojo mapping.
- `docs/ROBLOX_GITHUB_SYNC.md` — synchronization and publishing guide.
