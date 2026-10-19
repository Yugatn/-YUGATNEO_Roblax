# YUGATNEO Roblox — Chess Arena

Playable multiplayer chess for Roblox (YUGATNEO). Development branch: `feature/full-chess-game`.

## How to play (in Studio)

1. `git switch feature/full-chess-game && git pull`
2. `rojo serve default.project.json`
3. Connect Rojo plugin in Roblox Studio → **Play**
4. Walk to a **blue Join Pad** near a table → hold **E** (ProximityPrompt)
5. Second player joins the same pad → both press **I'M READY**
6. Click your piece → green squares show legal moves → click destination
7. Camera locks to the board (Scriptable) for the match; returns to normal when you leave

Three independent tables spawn at X = 0, +55, −55.

## What works now

- Full legal moves, check / checkmate / stalemate, castling, en passant, promotion choice
- Server-authoritative rules (`ChessEngine`)
- Isolated tables (`MatchTable`) with FSM: Idle → Waiting → Ready → Playing → Finished → Idle
- Only seated players can move; only on their turn
- Disconnect during play = technical loss for that player
- Cancel waiting frees the seat
- Scriptable camera fixed on the table (no vertical camera fight)
- Modes field ready: Classic / Wager / Challenge (economy later)

## Not yet

- Virtual currency / stakes
- Friendly challenges (push-ups etc.)
- Fifty-move / threefold / insufficient material draws
- Live verification inside Roblox Studio from CI (use local Play)

## Files

| Path | Role |
|------|------|
| `src/server/ChessEngine.lua` | Pure rules engine |
| `src/server/MatchTable.lua` | One table: board, seats, FSM |
| `src/server/ChessArena.server.lua` | Spawns 3 tables, routes events |
| `src/client/ChessControls.client.lua` | HUD + Scriptable camera |
| `default.project.json` | Rojo map |

## Branch

https://github.com/Yugatn/-YUGATNEO_Roblax/tree/feature/full-chess-game
