# YUGATNEO Roblox Chess — playable core

Branch: **`feature/playable-chess-core`**

Server-authoritative chess on one shared board: full legal moves via `ChessEngine`, ClickDetector input on every piece part and square, bot practice mode, promotion, check/mate/stalemate, claimable draws.

## Features

| Feature | Status |
|---------|--------|
| All piece moves + captures | Yes (server engine) |
| Check / checkmate / stalemate | Yes |
| Castling, en passant, promotion (Q/R/B/N) | Yes |
| Threefold / fifty-move claims; fivefold / 75 auto | Yes |
| Insufficient material | Yes |
| PLAY VS BOT (legal moves only) | Yes |
| Two human seats (White / Black fields) | Yes |
| Green legal-move highlights | Yes |

## Run with Rojo

```bash
git fetch origin
git switch feature/playable-chess-core
git pull
rojo serve default.project.json
```

Connect the Rojo plugin in Roblox Studio → **Play**.

### Manual paste (no Rojo)

1. Baseplate experience.
2. **ServerScriptService**: ModuleScript `ChessEngine` ← `src/server/ChessEngine.lua`
3. **ServerScriptService**: Script `ChessArena` ← `src/server/ChessArena.server.lua`
4. **StarterPlayerScripts**: LocalScript `ChessControls` ← `src/client/ChessControls.client.lua`
5. Play.

### How to play

1. Stand on the green **White** or blue **Black** field (ProximityPrompt), or press **JOIN WHITE / BLACK**, or **PLAY VS BOT**.
2. Left-click your piece (any part of the model).
3. Green squares = legal moves — click one.
4. Captures: click the enemy piece or its square.
5. Same piece again = deselect.

## Project map

| Path | Role |
|------|------|
| `src/server/ChessEngine.lua` | Pure rules (no Instances) |
| `src/server/ChessArena.server.lua` | Board, seats, bot, ClickDetectors |
| `src/client/ChessControls.client.lua` | HUD, highlights, promotion |
| `tests/ChessEngineSmokeTest.lua` | Studio smoke / perft harness |
| `docs/ENGINE_VERIFICATION.md` | Attack-detection fix + perft |
| `docs/TEST_RESULTS.md` | Automated test log |

## Verification

Independent Python port of the engine rules (same algorithms):

- perft(1) = **20**, perft(2) = **400**, perft(3) = **8902** — PASS
- Castling through check blocked, promotion ×4, fool’s mate, clone isolation — PASS

**Roblox Studio Play is not run in CI automation.** Confirm clicks and bot in Studio before publishing.

## Not on this branch

Story-X spiral world, galleries, defense arenas, and other stacked feature branches are separate. This branch focuses on a **working chess match** only.
