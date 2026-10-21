# Сюжет Икс — YUGATNEO MATRIX

A Roblox exploration prototype inspired by the Story-X canon: a neon simulation city where the player explores, collects memory fragments, answers reasoning puzzles, and practices aim against harmless training drones.

## Design principles

- **Model is not subject.** The player learns to distinguish observation, interpretation, and what remains unknown.
- **Mira is another subject.** The story emphasizes mutual observation and respect for the Other.
- **Right to exit.** One terminal asks what a safe experiment must allow.
- **The X remainder.** Not every clue is resolved; uncertainty is part of the experience.
- **Kid-friendly play.** Stylized pulse blaster affects training drones only. No player damage, blood, or realistic weapon content.
- **No external assets required.** The world is assembled from Roblox Parts, neon materials, labels, prompts, and simple UI.

## First playable features

- Floating holographic **YUGATNEO MATRIX** title.
- Neon grid base, abstract data spires, four districts, bridges, spawn island, and observation tower.
- Six collectible Story-X memory fragments.
- Three server-validated reasoning terminals.
- Pulse training range with six respawning drones.
- Mission HUD, feedback toasts, progress counter, keyboard **F** and on-screen **PULSE** button.
- Server-authoritative puzzle checks and drone hit detection.

## Run with Rojo

1. Clone this repository and install Rojo with Rokit.
2. In the project root run `rojo serve`.
3. Connect the Rojo plugin in Roblox Studio.
4. Press Play and explore the world.

The existing Chess Arena prototype is preserved in Git history, but the project mapping on this feature branch is set to the Story-X world. Merge only after testing in Roblox Studio.

## Controls

- **WASD** — move; mouse — look.
- **E** — interact with memory fragments and terminals (Roblox ProximityPrompt).
- **F** or the on-screen **PULSE** button — fire a harmless pulse at training drones.
- At a reasoning terminal, type an answer and submit it.

## Important status

This is an initial playable code implementation, not yet verified by a Roblox Studio runtime test. Please run it in Studio and inspect Output before publishing. The world is procedural; advanced animation, sound, save data, mobile-specific layout tuning, and full playtesting are future work.
