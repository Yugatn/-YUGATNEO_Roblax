# YUGATNEO MATRIX — Spiral World and Chess Summit

This branch adds a distinct elevated chess destination instead of leaving chess on the main exploration floor.

## World layout
- A long neon approach bridge leaves the Matrix island.
- A 4.5-turn collidable spiral rises around a glowing central spine.
- The summit has its own platform, perimeter beacons, holographic title, and chess arena.
- Chess uses separate server/client scripts and a separate RemoteEvent, so the older prototype is not loaded twice.

## Run
1. If no Rokit manifest exists, run `rokit init`, then add Rojo and install tools.
2. From the repository root run `rojo serve`.
3. Connect the Roblox Studio Rojo plugin and press Play.
4. Follow the illuminated bridge and climb the spiral to the Chess Summit.

## Chess status
The prototype supports basic piece movement, captures, and turn switching. It is not a complete chess engine: check/checkmate, castling, en passant, pawn promotion, per-player match isolation, and full server-authoritative turn permissions still need implementation and testing.

## Validation
Committed on a feature branch. Roblox Studio runtime playtesting has not been performed.
