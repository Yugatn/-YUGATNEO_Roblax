# YUGATNEO MATRIX — Story X Roblox

A development prototype that combines the world of **Сюжет Икс** with multiplayer chess, an explorable spiral highway, hover-kart driving, puzzle missions, and non-PvP target practice. **This branch has not yet been verified in Roblox Studio.**

## Play loop

1. Join the Matrix world at the central spawn. Explore the Memory Garden, Signal Maze, Observation Tower, and drone-training range.
2. Use the green **Chess Dimension** portal on the spawn island. A long bridge connects the old city to the three-turn serpentine around the central chess hall.
3. Choose **CASUAL** in the top-right HUD, or **TOURNEY** for a four-player knockout: two semifinals (tables 1/2) and a final (table 1).
4. The server pairs players, assigns White/Black, positions them near the board, starts the game, and validates every move. On completion, spectators see the winner and the board resets after 12 seconds.
5. Other visitors can **WATCH 1/2/3** from the HUD, explore the map, or join the waiting queue.
6. Enter one of two **Serpentine Karts** near the access bridge and use W/S to accelerate/reverse and A/D to steer. The physical spiral has guardrails and an observation platform at its summit.
7. Practice with **Pulse / Rapid / Charged** emitters against training drones. They cannot harm player characters. The earlier PvP WeaponSystem remains in the repository but is **not enabled** in the active Rojo mapping.

## Chess features

- Three independent server-authoritative boards.
- Turn order, king safety, check/checkmate, stalemate, castling, en passant, and promotion choice.
- Additional draw handling in the imported rules engine: repetition, halfmove limits, insufficient material; claim via server-side action (HUD claim control still needs UX testing).
- Resignations, consensual draw, and disconnect outcomes.
- FIFO casual matchmaking, tournament registration, semifinals, final, and replay on drawn elimination games.
- Session scoreboard and persistent **total wins** (not Elo): global top 10 uses Roblox OrderedDataStore. If Roblox API services are unavailable in Studio, session results still display. No virtual money, betting or paid stakes.
- All match state, registration, and win awards are processed on the server.

**Tournament scope:** 4 participants, one bracket per game server, no tournament resumption after server restart, no cross-server matchmaking. Competitive tournament clocks, anti-stalling, appeals, formal ratings, audit logs, and persistence of tournament brackets are future work.

## Matrix world

The procedural matrix city includes six Story X memory fragments and three reasoning terminals. Its themes are observation versus interpretation, the Other, Mira, the Right of Exit, and the unknown X. Shooting is harmless drone-target training; no player damage is enabled. The spiral is a geometry and physics prototype, not a production racing controller.

## Run the feature branch

Mac / Roblox Studio, assuming Rojo and the Rojo Studio plugin are installed:

```sh
git fetch origin
git switch feature/story-x-spiral-chess-tournaments
git pull
rojo serve default.project.json
```

Connect the Rojo plugin in Roblox Studio and press **Play**. If another Rojo server is already using the default port, stop it first. `main` still contains the old chess prototype until this feature is tested and merged.

Run **Test > Start** with at least **4 players** to verify the bracket. Test the chess board, promotion and draw scenarios separately; see `docs/MATRIX_TEST_PLAN.md`. For saved rankings, Roblox API services and a published test universe are required. Roblox recommends a separate testing universe rather than enabling Studio data store access for your live production game.

## Important engineering notes

- `default.project.json` activates only StoryXMatrixWorld, SpiralWorld, SpiralVehicles, ChessEngine, MatchTable, TournamentHub, Rankings, ChessArena, ChessControls, ChessCommunity and StoryXMatrixHUD.
- The original standalone ChessArena and old standalone SpiralChessArena are **not** simultaneously active. The chess match engine and the Story X world were brought together from earlier GitHub feature branches.
- The chess engine regression harness `tests/ChessEngineSmokeTest.lua` checks opening perft 20/400/8902 and draw-related cases. **Presence of a test is not a passed test**; Roblox Studio and multi-client verification remain outstanding.
- `.github/workflows/roblox-ci.yml` builds a Roblox place for PRs targeting `main`. Publication remains a manual, separate workflow.
- RemoteEvent inputs and seating are validated on the server; no client-supplied victory or leaderboard score is accepted.
- Avoid taking third-party Roblox Toolbox models of unclear licensing or with embedded scripts into this project.

## Files

- `src/server/SpiralWorld.server.lua` – procedural helix, guardrails, chess dimension portals.
- `src/server/SpiralVehicles.server.lua` – two controllable recoverable hover-karts.
- `src/server/ChessEngine.lua` – legal chess and terminal-state rules.
- `src/server/MatchTable.lua` – per-table chess FSM and 3D rendering.
- `src/server/TournamentHub.lua` – queue pairing and knockout bracket.
- `src/server/Rankings.lua` – session wins and ordered persistent wins.
- `src/server/ChessArena.server.lua` – server coordinator, registration pads, status board.
- `src/server/StoryXMatrixWorld.server.lua` – puzzles, exploration, safe drones.
- `src/client/ChessControls.client.lua`, `ChessCommunity.client.lua`, `StoryXMatrixHUD.client.lua` – game HUD.

### Reference architecture
- Roblox Creator Hub: https://create.roblox.com/docs/scripting/security/client-server-boundary
- Data stores: https://create.roblox.com/docs/cloud-services/data-stores
- OrderedDataStore: https://create.roblox.com/docs/reference/engine/classes/OrderedDataStore
- RemoteEvents: https://create.roblox.com/docs/scripting/events/remote
- AlignOrientation: https://create.roblox.com/docs/reference/engine/classes/AlignOrientation


## New: library, cognitive arcade, 8-bit cabinet and cultural districts

Branch `feature/story-x-library-recreation` extends the previous spiral/chess world without modifying `main` directly. It adds a procedural reading library with four original short Russian-language stories, paragraph-level search and comprehension races, a personal **session-only** notebook, pixel art in the gallery, and server-earned **in-experience** cosmetic rewards. The Library X has a walkable bridge from the Matrix district and can also be reached by a high-level portal on the spiral.

The cognitive arcade is mapped into the live Rojo project: Memory, Attention, Logic, Rule Switching, Spatial Routes, and a holographic duck shooting gallery (no player damage). A separate retro cabinet provides an original Snake game in 8-bit style, including touch/keyboard controls. The 16-bit duel rules engine exists as a module, but its cabinet UI is not yet playable. Retro ROM emulation and unlicensed commercial games are **not** included. Additional planned dimensions are labeled `PLANNED` in the spiral world.

The reading race server determines the shared book challenge and validates correct **book + paragraph + comprehension answer**, then rewards finishers. Shop currently offers original in-experience neon glasses, crown and trail; the future kart paint is disabled until actually integrated with driving.

**Important:** all new scripts are committed, but this branch still needs Roblox Studio playtesting; these descriptions indicate code presence, not a confirmed bug-free build. The notes TextBox is ephemeral and not synced to Roblox DataStore. Testing of persistent reward balances, concurrency and moderation behavior is required before release.

### The handoff documents

- [World design bible (Russian)](docs/STORY_X_WORLD_BIBLE_RU.md): long-term spiral geography, eight development levels, hide-and-seek, chase/tag, checkers, original strategy games, museum, retro rights and reward design.
- [Manual Studio implementation and handoff (Russian)](docs/MANUAL_BUILD_AND_HANDOFF_RU.md): per-file module mapping, geography, exact feature contracts and testing steps for other developers.
- [Library content, licensing and reading pedagogy](docs/LIBRARY_CONTENT.md): starter catalog, public-domain candidate verification and content review.
- [Library & arcade smoke-test source](tests/StoryXLibrarySmokeTest.lua): copy into a temporary Script under `ServerScriptService`; running requires Studio. **Not yet executed.**

### How to test this branch

```sh
git fetch origin
git switch feature/story-x-library-recreation
git pull
rojo serve default.project.json
```

Join with at least four multiplayer Studio clients to test the reading races and existing chess tournament separately. Studio API data access must use a **separate test universe**, not a live datastore. The build workflow verifies place generation but does not substitute for multiplayer physics, UI and latency tests.


## New: persistent virtual pet / «Тамагочи»

Branch `feature/story-x-tamagotchi` adds a standalone **original virtual pet**, discoverable through interactive capsules near Matrix spawn and spiral step 64. The pet selection includes **Люми / Мико / Росток**. Returning players see a small collapsible pixel HUD showing hunger, happiness, energy, health and growth level. Four server-validated controls: feed, play, rest and care.

- One free pet per player; no premium advantage, pressure-based streaks or push notifications.
- No pet death, no loss of earned XP or irreversible penalty during offline absence; limited needs decay during the first simulated two hours only.
- Roblox DataStore saves species, needs and XP between sessions where API services are available. When unavailable the game runs session-only and displays a warning.
- Rojo modules: `src/server/PetRules.lua`, `src/server/PetWorld.server.lua`, `src/client/VirtualPet.client.lua`.
- **Manual instructions and QA:** [VIRTUAL_PET_IMPLEMENTATION_RU.md](docs/VIRTUAL_PET_IMPLEMENTATION_RU.md); [smoke-test harness](tests/PetRulesSmokeTest.lua).
- This branch is a **source-code implementation, not a validated published game.** Roblox Studio multiplayer/UI and real DataStore tests are still required.

To test: switch to `feature/story-x-tamagotchi`, run `rojo serve default.project.json`, connect Studio and press Play. Use a separate test universe for DataStore tests.


## New dimensions: light-cycle racing, cooperative waves and zombie tag

This branch adds **LUMEN CIRCUIT**, an original cyber-neon grid racing game with interactive laser entry on spiral step 82, 1–6 server-controlled lightbikes, persistent tracks within each round, server-validated 90° turns and wall/trail collisions. HUD supports keyboard and phone controls. See `src/server/LightCycleEngine.lua`, `src/server/NeonGridWorld.server.lua`, `src/client/LightCycleHUD.client.lua`.

Two tactical cooperative dimensions now have first-source-code implementations:
- **METAL SENTINELS** (spiral step 107): 1–3 players versus waves of original non-human machine targets, choosing defender, engineer or support roles, repairing a central base, supplying energy and surviving 10 or 20 rounds.
- **SHADOW SWARM** (spiral step 123): the same original co-op mechanics applied to fantasy shadow creatures, without graphic violence or player-versus-player attacks.

**ZOMBIE TAG** (spiral step 140) is a separate non-damaging, hide-and-seek/chase world. One randomly assigned catcher can convert others only after three continuous seconds nearby with unobstructed line-of-sight; newly tagged players join the catchers. There are climbable trees, multi-level hide houses and static cars to hide in. Published rounds can last 30 or 60 minutes, with a shorter Studio-only test duration; when one/two final runners remain, a short final escape determines survival.

Server scripts are Rojo-mapped and use `WorldRewards` for in-experience progress. Competitive bots use simplified movement toward the core: they **do not yet** implement full PathfindingService tactics. All scripts remain **untested in Roblox Studio**, with device/multiplayer/physics checks required before release.

- **[Manual assembly, exact game rules, and test plan](docs/TEAM_DIMENSIONS_RU.md)**
- **[Module-only test harness](tests/TeamGamesSmokeTest.lua)** — not executed yet.
- All new dimensions have original names and assets; they do not distribute the copyrighted contents of *TRON*, *Terminator*, *Dune*, *Assassin's Creed*, or commercial retro games.


## Co-op defense: voting, salvage crafting and navigation

The `feature/story-x-defense-tactics-crafting` branch extends both wave-defense dimensions with **team-selected tactical plans** (`Fortify`, `Scout`, `Resupply`), a shared salvage resource, four fixed construction pads per arena, repairable/upgradable barricades, and a bounded asynchronous Roblox PathfindingService adapter for bot routing.

- Salvage starts at 15, increases by 3 per defeated target and 8 per cleared wave (maximum 250).
- Build / Repair / Upgrade costs 9 / 4 / 15 salvage. Engineer gains a 2-salvage discount and stronger repair.
- Robots target the core or an intact barrier along their approach. Destroyed barriers can be repaired. Core health and construction resources are always changed by the server.
- Voting occurs in the lobby and sets the plan once per match; ties default to Balanced.
- The existing team HUD shows the selected plan, common materials, number of intact barricades and a dynamic cooperation objective.

**Status:** source code implemented; Studio navigation, mobile interaction, balancing and multiplayer validation pending. The module smoke test has been authored but not run in Roblox Studio. See [full manual build and test guide](docs/DEFENSE_TACTICS_IMPLEMENTATION_RU.md) and [tactics smoke tests](tests/DefenseTacticsSmokeTest.lua).

Use `git switch feature/story-x-defense-tactics-crafting`, `rojo serve default.project.json` and connect Roblox Studio Rojo plugin. Feature-branch builds are now included in GitHub Actions triggers, with publication still manual.


## Interactive Story X Art Gallery / Галерея Сюжета Икс

**Branch:** `feature/story-x-spiral-gallery`. Adds the first explorable **Story X Gallery** dimension, accessible by a ProximityPrompt on spiral step 58. The museum is a walkable 153×128-stud room with a central observer sculpture and **10 independent interactive art exhibits** adapted from author **Югатн**'s literary universe `Yugatn/story-x`.

Visitors can view original procedural holographic pixel mosaics, read chapter interpretations, answer optional server-checked questions, and return to the Matrix, chess hall, library, cognitive arcade or spiral. Correct answers are **educational discovery flags**, not psychological grades or real-world money. `DataStoreService` attempts to save visited and completed exhibits; if unavailable, the experience works for the session without promising persistence.

**Illustrations:** No uploaded Story X Library images have been imported into Roblox yet. Each gallery card defaults to an original procedural mosaic. To substitute licensed author art, upload the file in Roblox Creator Dashboard and set a real `imageAsset` ID in `src/server/StoryXGalleryCatalog.lua`. Do **not** invent an asset ID or import film stills without rights.

- Server: `StoryXGalleryCatalog.lua`, `StoryXGallery.server.lua`.
- Client: `StoryXGallery.client.lua`.
- Manual Studio test: `tests/StoryXGallerySmokeTest.lua`.
- [Architecture, source-art installation, safety and acceptance plan](docs/STORY_X_GALLERY_RU.md).

**Status:** source implementation only; no published Roblox Studio gameplay proof. Run `rojo serve default.project.json`, then test with multiple players and a separate DataStore-enabled test universe before merging.
