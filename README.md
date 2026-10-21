# YUGATNEO Roblox — Сюжет Икс: MATRIX

A Roblox experience prototype for exploring the world of **Сюжет Икс** in a neon, Matrix-inspired city.

## Current experience on this branch

- Giant floating hologram: **YUGATNEO MATRIX**.
- Neon grid, abstract data towers, raised districts, bridges, memory garden, signal maze, drone range, and observation tower.
- Six collectible memory fragments inspired by the Story-X canon: the Other, Mira, the Trace, the Empties, the Right to Exit, and X.
- Three short reasoning terminals about evidence, other-subjects, and consent.
- A stylized, harmless pulse tool for shooting training drones. Players cannot be damaged by it.
- Mission HUD, progress counter, answer interface, and feedback messages.
- Procedural geometry; no external asset dependencies.

## Story-X foundation

The experience adapts the project's central ideas into play:

- **Model is not subject.** A profile, score, or memory is not the person.
- **The observer is part of the system.** Mira observes Eugene too; observation changes what happens next.
- **Observation is not interpretation.** A pattern can be meaningful, accidental, or incomplete.
- **Right to exit.** Safe experiments must allow a participant to stop or leave.
- **X is the remainder.** No single map or explanation exhausts reality.

The game is a fictional experience, not a scientific claim.

## Run in Roblox Studio

1. Clone the repository locally.
2. Install Rokit and Rojo. If the repository has no `rokit.toml`, run `rokit init`, then `rokit add rojo-rbx/rojo` and `rokit install`.
3. In the repository root, run `rojo serve`.
4. Connect the Rojo plugin in Roblox Studio.
5. Press **Play** and inspect the Output panel.

The Rojo mapping in this branch points to `src/server/StoryXMatrixWorld.server.lua` and `src/client/StoryXMatrixHUD.client.lua`. The earlier Chess Arena scripts remain in the repository but are not the active experience mapping on this branch.

## Controls

- **WASD** — move; mouse — look.
- **E** — interact with memory fragments and terminals.
- **F** or on-screen **PULSE** — fire a pulse at training drones.
- Type an answer at a reasoning terminal and submit it.

## Status

This is the first playable implementation of the world code, not a confirmed Roblox Studio test. Run it in Studio before publishing. Saving progress, audio, advanced animation, accessibility/mobile polish, and extended playtesting remain future work.


## Spiral Chess Summit

Branch `feature/chess-spiral-level` adds a 4.5-turn neon spiral, a glowing central spine, an approach bridge, and a dedicated chess summit. See [README_SPIRAL_CHESS.md](README_SPIRAL_CHESS.md) for setup and current chess limitations.
