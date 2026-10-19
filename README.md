# YUGATNEO Roblox — Chess Arena

A Roblox Studio chess prototype for the YUGATNEO world.

## Included
- Automatically generated 8×8 chessboard and 32 starting pieces.
- Click a piece, then click a destination square to move it.
- Turn-based play for White and Black.
- Captures and basic movement rules for all six piece types.
- Server-side move validation, so clients cannot directly move pieces by changing their positions.
- Simple status display for the current turn and selected piece.

## Important prototype limitations
This is a playable movement prototype, not yet a complete tournament chess implementation. Check/checkmate validation, castling, en passant, pawn promotion, matchmaking, persistent ratings, and spectator tools are not implemented yet.

## Run in Roblox Studio
1. Open Roblox Studio and create a **Baseplate** experience.
2. In **Explorer**, open **ServerScriptService**.
3. Insert a **Script** named `ChessArena`.
4. Copy the contents of `src/server/ChessArena.server.lua` into that Script.
5. Press **Play**. The board and pieces are generated automatically.

## Project files
- `src/server/ChessArena.server.lua` — server-side board, piece generation, turn handling, captures, and basic move validation.
- `default.project.json` — Rojo project mapping, for users who use the Rojo workflow.

The source file is a normal Roblox Luau server script. The JSON project file is optional if you are editing directly in Roblox Studio.
