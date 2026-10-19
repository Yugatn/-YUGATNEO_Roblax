# YUGATNEO Roblox — Chess Arena + Weapons

Branch: `feature/full-chess-game`

## Chess

1. `git switch feature/full-chess-game && git pull`
2. `rojo serve default.project.json`
3. Play in Studio → walk to **blue Join Pad** → hold **E**
4. Second player joins → both press **I'M READY**
5. Click piece → green legal squares → click destination

Three tables at X = 0, +55, −55. Camera locks (Scriptable) during the match.

### Rules
- Legal moves, check / checkmate / stalemate
- Castling, en passant, promotion choice
- **Fifty-move rule** (auto-draw at 100 half-moves without capture/pawn move)
- **Threefold repetition** (auto-draw)
- Resign, mutual draw offer, disconnect = technical loss

## Weapons (outside chess matches)

| Key | Weapon | Damage | Range |
|-----|--------|--------|-------|
| 1 | Pistol | 18 | 180 |
| 2 | Rifle | 28 | 320 |
| 3 | SMG | 12 | 140 |

Left mouse button fires. Shooting is **blocked** while `InChessMatch` is true (seated at a table).

## Files

- `src/server/ChessEngine.lua` — rules + draws
- `src/server/MatchTable.lua` — one table
- `src/server/ChessArena.server.lua` — 3 tables, membership
- `src/server/WeaponSystem.server.lua` — loadout + raycast
- `src/client/ChessControls.client.lua` — chess HUD + camera
- `src/client/WeaponControls.client.lua` — weapon HUD

## Known limits

- Piece models are procedural (improved silhouettes, not MeshId assets)
- No wager / challenge modes yet
- Not play-tested inside Studio from this environment
