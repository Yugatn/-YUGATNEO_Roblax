# YUGATNEO MATRIX — Roblox Studio test protocol

**Status:** CHECKLIST ONLY. This document does not claim that any Roblox Studio tests have passed.

## Build / smoke
1. Switch to `feature/story-x-spiral-chess-tournaments`; run Rojo and connect Studio.
2. Check Output for errors and confirm all 8 mapped server scripts/modules and 3 LocalScripts exist.
3. Check one hologram titled **YUGATNEO MATRIX** at spawn and one over the chess dimension.
4. Activate the Chess Dimension portal, verify the chess hall contains 3 different 8×8 boards, and return to Matrix.
5. Walk the complete three-turn serpentine. There must be no invisible holes, blocked turns, or dangerous gaps. Test climbing and descending.
6. Enter both hover-karts using W/S and A/D. Test steering, uphill traction, braking, falling, and the recovery ProximityPrompt; inspect humanoid/seat stability.

## Chess rules
- Copy `tests/ChessEngineSmokeTest.lua` to a temporary server script and run Play. Opening legal-move perft must produce 20, 400, 8902. Inspect each assertion, then remove the temporary script.
- Use multiplayer clients to verify turn ownership, valid/invalid moves, legal highlights, captures, check, checkmate and stalemate.
- Castle kingside and queenside with moved/blocked rook restrictions.
- En passant immediately after a two-square opposing pawn advance, but not a move later.
- Promote to queen, rook, bishop and knight.
- Try moving into or out of check illegally; it must be rejected.
- Verify threefold/50-move claims work only in eligible positions. Fivefold/75-move automatic results and insufficient material must be tested.
- Verify two players cannot control the same colour through click spamming or malicious client RemoteEvents.

## Matchmaking and knockout bracket (4 Studio clients minimum)
1. Players A/B join the casual queue and play on board 3.
2. Players C/D sign up for the tournament. Add A/B only once they are no longer in their casual game, or test with 6 clients.
3. With four free tournament entrants, verify semifinal pairings on boards 1 and 2.
4. Let one player on each board win or resign. Verify the results appear on the physical board and top-right HUD.
5. After each game, verify the table resets after 12 seconds; when both semifinal winners exist, their final starts on board 1.
6. End the final and verify champion name, ratings, and ability to register for the next tournament.
7. Verify a drawn semifinal causes a rematch, not a randomly selected winner.
8. Test disconnect during a match (opponent wins), disconnect while queued, and spectators cycling WATCH 1/2/3 / EXIT VIEW.
9. Test spammed Queue, Draw, Resign and Promote requests from the client. Ensure no arbitrary player can inject wins or make moves for another player.
10. Restart a server: tournament state resets (expected), while global *wins* are restored if DataStore API access is enabled.

## Story X and no-PvP tools
- Collect all six memory fragments and answer the three reasoning terminals.
- Select Pulse, Rapid, Charged with buttons and numeric keys; hold F for pulse to training drones. Verify rates and damage differ.
- Verify emitted rays cannot injure another player or damage chess players; while seated at chess, F does nothing.
- Verify the Quiet Room is accessible without requiring any weapon training (the route is optional).
- Check phone/tablet layouts: three HUDs must not obstruct puzzle entry, promotion, action buttons or the exit controls.

## Known gaps before public release
- No robust simulation, published-server load tests or GitHub CI results verified at authoring time.
- Four-player bracket exists only within one server. There are no cross-server bracket reservations, clock limits, season ratings, spectator chat moderation, or long-running tournament recovery.
- Vehicle handling is a small physics prototype; wheel suspension, mobile driving UX, stuck detection, collision tuning and motion-sickness accessibility require further work.
- Content-maturity disclosure, player reporting, accessibility and Roblox moderation review must be checked separately.
- DataStores require a separate test universe if enabling Studio API services (do not use your live production data for testing).
