# Test results (feature/playable-chess-core)

## Environment
- Python 3.12 port of fixed ChessEngine move generation (same algorithms as Luau).
- Roblox Studio: **not available** in automation environment.

## Perft (starting position)

| Depth | Expected | Actual | Status |
|-------|----------|--------|--------|
| 1 | 20 | 20 | PASS |
| 2 | 400 | 400 | PASS |
| 3 | 8902 | 8902 | PASS |

## Expanded suite (2026-10-19)

```
PASS - perft depth 1 == 20
PASS - perft depth 2 == 400
PASS - perft depth 3 == 8902
PASS - starting legal moves == 20
PASS - clone isolation
PASS - kingside castle when path clear
PASS - no kingside castle when f1 attacked
PASS - promotion to Queen
PASS - promotion to Rook
PASS - promotion to Bishop
PASS - promotion to Knight
PASS - fool's mate: white in check
PASS - fool's mate: zero white legal moves
PASS - a1 rook cannot jump to a3
14 / 14 passed
ALL PASSED
```

## Defects found by static analysis + fixed in this branch

1. **ChessEngine.isSquareAttacked** (fixed earlier): sliding piece rays broken → king safety wrong.
2. **Bot never moved** (fixed in ChessArena): `tryMove` required `playerSides[userId]==currentTurn`, bot uses `UserId=-1` without a seat → all bot moves rejected. Now allows synthetic bot when `botEnabled` and Black to move.
3. **BoardClick** remote: now rejects non-integer / out-of-range coordinates before handleBoardClick.
4. Dead `pathIsClear` removed (unused; legality only via ChessEngine).

## Not verified in Studio

- ClickDetector interaction end-to-end
- Two-client sync
- Team quiz flow
- Visual promotion / castling animation
