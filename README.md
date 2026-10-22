# YUGATNEO MATRIX — Story X Roblox

## New: интеллектуальная спираль, библиотека и ретро-аркада (October 2026)

> **Рабочая версия кода** в feature-ветке, не готовый публичный Roblox-релиз. Для всех новых механик требуются проверка Rojo build, Roblox Studio, многопользовательские и мобильные тесты.

- **Библиотека «Сюжета Икс»**: четыре оригинальных русско-английских рассказа, читальный экран с прокруткой, поиск абзаца на время, вопрос на понимание, персональные заметки с фильтрацией Roblox TextService, таблица лучших времен текущего сервера.
- **5 познавательных мини-игр**: последовательности для памяти, поиск отличающегося символа, числовая логика, переключение правила и пространственные маршруты.
- **Тир Duck Gallery**: 45-секундная игра с движущимися голографическими утками, серверный подсчет попаданий и запрет на урон игрокам.
- **Легальная ретро-аркада**: собственная пиксельная змейка (8-bit-inspired), дружеский двухпользовательский файтинг (16-bit-inspired), без сторонних ROM и коммерческих персонажей.
- **Детская площадка**: прототип догонялок (от двух игроков) и пряток (от трёх), ожидание участников, бесконтактная механика без урона, добровольный выход.
- **Косметические награды**: только внутриигровые монеты за проверенные сервером достижения; очки, нимб, корона и фиолетовая расцветка автомобиля. Ничего не выдаётся в Roblox Avatar Shop.
- **Оригинальная пиксельная галерея**: три учебных цветовых изображения в библиотеке. Подлинные репродукции художников добавляются позднее, по проверенной лицензии.

### Полная документация для других разработчиков

- [Библия мира и карта](docs/WORLD_BIBLE_RU.md) — атмосфера, законы мира, спираль, навигация, комнаты и ступени развития.
- [Все игровые режимы и дорожная карта](docs/GAME_MODES_AND_ROADMAP.md) — мини-игры, шашки, экономическая настолка, «казаки-разбойники», стратегия обороны сада.
- [Ручная сборка и архитектура](docs/DEVELOPER_HANDOFF.md) — все скрипты, подключение в Studio и кодовые контракты.
- [Права на игры/книги/живопись](docs/CONTENT_RIGHTS.md) — проверка лицензий для ретро, переводов и репродукций.
- [Критерии приемочных тестов](docs/ACCEPTANCE_TESTS.md) и [ручной тест движков](tests/ArcadeRetroSmokeTest.lua).
- [Текущий статус](docs/IMPLEMENTATION_STATUS.md).

Дополнительно доступны старые README и чек-лист шахмат `docs/MATRIX_TEST_PLAN.md`. **Все условия приёмки остаются открытыми до реальных тестов.**


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
