# ChessEngine verification

## Critical bug fixed (2026-10-19)

`ChessEngine.isSquareAttacked` previously looped directions incorrectly:

```lua
-- BROKEN: line[1] is only the first vector {1,0}, not the direction list
for _, direction in ipairs(line[1]) do
```

Sliding attacks (rook, bishop, queen) were effectively wrong. That broke:
- filtering moves that leave the king in check
- castling-through-check detection
- accurate mate/stalemate

Fixed by iterating explicit direction arrays for orthogonal and diagonal rays.

## Perft results (independent Python port of the fixed rules)

Command (local sandbox):

```text
python3 chess_engine.py
```

Output:

```text
legal white moves: 20
perft1: 20
perft2: 400
perft3: 8902
ALL PERFT PASSED
```

These match the standard starting-position perft suite.

## Studio smoke test

`tests/ChessEngineSmokeTest.lua` is still intended for Roblox Studio Play:

1. Map it temporarily under ServerScriptService (or require from SSS)
2. Press Play once
3. Confirm `[ChessEngine PASS]` lines in Output
4. Remove the temporary runner

**Roblox Studio was not available in the automation environment.** Engine perft was verified outside Studio via the Python port of the same algorithms.

## Input path (feature/two-board-playable-chess base)

1. Server builds 8×8 tiles + pieces with `ClickDetector` on every `BasePart` of each piece and on every square
2. `MouseClick` → `handleBoardClick(player, {row, col})`
3. Server checks seat/side/turn/gameOver
4. Own piece → `ChessEngine.legalMoves` → `FireAllClients("LegalMoves", ...)`
5. Target square → `ChessEngine.move` → update 3D occupancy → status broadcast
6. Client only draws highlights; it does not decide legality
