# YUGATNEO Roblox Chess

Branch: **`feature/playable-chess-core`** (based on `feature/two-board-playable-chess` + engine attack fix).

## Run in Studio

```bash
git fetch origin
git switch feature/playable-chess-core
git pull
rojo serve default.project.json
```

Connect the Rojo plugin → **Play**.

### How to play

1. Stand on the **White** or **Black** field (or press **Join White / Join Black** / **PLAY VS BOT**).
2. **Left-click** one of your pieces (any part of the 3D model).
3. **Green squares** = legal destinations (server-computed).
4. **Left-click** a green square to move.
5. Capture by clicking the enemy piece or its square.
6. Click the same piece again to deselect.

One shared board. Scriptable top-down camera is optional via the walk-on pad if present in this branch.

### Rules implemented

- All standard moves, captures, check, checkmate, stalemate
- Castling (both sides), en passant, promotion (Q/R/B/N)
- Claimable threefold + fifty-move; automatic fivefold + 75-move
- Insufficient material draws
- Server-authoritative validation

### Bot

**PLAY VS BOT** — human plays White; simple Black minimax-style responder using legal moves only (see arena bot path).

## Verification status

| Check | Result |
|-------|--------|
| perft depth 1 = 20 | **PASS** (Python port of fixed engine) |
| perft depth 2 = 400 | **PASS** |
| perft depth 3 = 8902 | **PASS** |
| Studio Play end-to-end | **Not run** in this environment |
| Multi-client Studio | **Not run** here |

See `docs/ENGINE_VERIFICATION.md`.

## Project map

| Path | Role |
|------|------|
| `src/server/ChessEngine.lua` | Rules only |
| `src/server/ChessArena.server.lua` | Board, seats, ClickDetectors, bot |
| `src/client/ChessControls.client.lua` | HUD, highlights, promotion |
| `tests/ChessEngineSmokeTest.lua` | Studio smoke / perft harness |
| `default.project.json` | Rojo |

## Known limits

- Studio runtime not executed from CI automation
- Team quiz / multi-captain mode exists in older branches; focus this branch on 1v1 + bot
- Piece meshes are procedural Parts, not MeshId assets
