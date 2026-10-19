# YUGATNEO Roblox — Chess Arena

A Roblox Studio chess game prototype for the YUGATNEO world. The active development branch `feature/full-chess-game` adds a server-side rules engine and a redesigned in-game HUD.

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

## Run in Roblox Studio

1. Open this repository folder on your Mac.
2. In Terminal, run `rojo serve default.project.json`.
3. Open Roblox Studio and connect the Rojo plugin to `localhost:34872`.
4. Press **Play**.
5. In Explorer, check `ServerScriptService/ChessEngine`, `ServerScriptService/ChessArena`, and `StarterPlayer/StarterPlayerScripts/ChessControls`.

If Rojo is already running on port 34872, do not launch a second server. Use the existing Terminal window or stop the old process deliberately before restarting.

## GitHub and branches

The feature is being developed on `feature/full-chess-game`; `main` remains unchanged while the new rules and UI are reviewed. To test this branch locally:

```bash
git fetch origin
git switch feature/full-chess-game
git pull
```

Then reconnect Rojo if needed. GitHub changes do not appear in Studio until the local checkout has been updated.

## Files

- `src/server/ChessEngine.lua` — chess movement, attack detection, legal move filtering, check/checkmate/stalemate, castling, en passant, promotion.
- `src/server/ChessArena.server.lua` — board and piece rendering, server-side interaction, simple player seats, promotion rendering, status, host-authorized reset.
- `src/client/ChessControls.client.lua` — in-game HUD, rules panel, status, legal-move highlighting.
- `default.project.json` — Rojo mapping.
- `docs/ROBLOX_GITHUB_SYNC.md` — synchronization and publishing guide.
