# YUGATNEO Roblox — Chess Arena

A Roblox Studio chess prototype for the YUGATNEO world.

## Included
- Automatically generated 8×8 chessboard and 32 starting pieces.
- Distinct piece silhouettes plus a letter badge: P (pawn), R (rook), N (knight), B (bishop), Q (queen), K (king).
- Click a piece, then click a destination square to move it.
- Turn-based play for White and Black.
- Captures and basic movement rules for all six piece types.
- On-screen controls: instructions, cancel selection, and reset/new game.
- Server-side move validation for basic piece movement.

## Prototype limitations
This is not yet a complete tournament chess implementation. Check/checkmate validation, castling, en passant, pawn promotion, separate simultaneous matches, matchmaking, persistent ratings, and spectator tools are not implemented yet. The reset button restarts the shared board for everyone in the server.

## Run in Roblox Studio (manual setup)
1. Open Roblox Studio and create a **Baseplate** experience.
2. In **ServerScriptService**, create a **Script** named `ChessArena`; paste in `src/server/ChessArena.server.lua`.
3. In **StarterPlayer > StarterPlayerScripts**, create a **LocalScript** named `ChessControls`; paste in `src/client/ChessControls.client.lua`.
4. Press **Play**. The server generates the board and pieces, and the client script adds the control panel.

Both scripts are required for the on-screen controls. If you only install the server script, the board and pieces will appear but the control panel will not.

## GitHub, Rojo, and publishing
The `default.project.json` maps both scripts into Roblox services. For live sync, install Rojo and its Studio plugin, clone this repository locally, then run `rojo serve` and connect the plugin in Studio. GitHub changes reach Studio after you pull them into the local checkout; GitHub does not directly connect to your running Studio session.

The GitHub Actions workflow `.github/workflows/roblox-ci.yml` builds the place on pushes and pull requests. It can also publish manually to Roblox when you run the workflow with publishing enabled and configure `ROBLOX_API_KEY`, `ROBLOX_UNIVERSE_ID`, and `ROBLOX_PLACE_ID` in GitHub Actions secrets. Publishing is intentionally manual by default. See [the full setup guide](docs/ROBLOX_GITHUB_SYNC.md).

## Project files
- `src/server/ChessArena.server.lua` — server-side board, piece generation, turn handling, captures, and basic move validation.
- `src/client/ChessControls.client.lua` — on-screen buttons and player instructions.
- `default.project.json` — Rojo project mapping.
