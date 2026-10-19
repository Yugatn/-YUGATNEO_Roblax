# GitHub and Roblox Studio: setup and publishing

This repository uses Rojo to map the Lua scripts in GitHub into Roblox services.

## Important distinction

- GitHub stores the source files.
- Rojo's local server syncs files from your computer to a connected Roblox Studio session.
- GitHub Actions can build a .rbxlx place file in the cloud.
- Publishing that built place to Roblox is a separate, explicit workflow and requires an Open Cloud API key plus the experience's Universe ID and Place ID.

GitHub alone cannot push changes into an already-open Studio session. For live editing, a computer must have the repository checked out, Rojo installed, and the Rojo Studio plugin connected.

## A. Live sync with Studio (recommended for development)

1. Install Git and VS Code if they are not already installed.
2. Install Rojo using the current instructions at https://rojo.space/docs/.
3. Install the Rojo plugin in Roblox Studio. The official Roblox guide is https://create.roblox.com/docs/projects/external-tools.
4. Clone this repository to your computer and open its folder in VS Code.
5. In a terminal in the repository folder, run: rojo serve
6. In Roblox Studio, open a place and click the Rojo plugin, then connect to the local server.
7. Edit/pull the files in the local repository. Rojo will sync supported changes into Studio while the server and plugin remain connected.

The project mapping in default.project.json maps:
- src/server/ChessArena.server.lua → ServerScriptService/ChessArena
- src/client/ChessControls.client.lua → StarterPlayer/StarterPlayerScripts/ChessControls

GitHub-to-Studio flow: first pull the latest commit to your local checkout (for example, git pull), then Rojo syncs those local files into the connected Studio session. A GitHub commit by itself does not connect to your computer.

## B. Build check on GitHub

The workflow .github/workflows/roblox-ci.yml runs when changes are pushed to main or a pull request targets main. It builds the project with Rojo and uploads build.rbxlx as a workflow artifact. This checks that the Rojo project can be built; it does not run Roblox gameplay tests.

## C. Optional manual publishing to Roblox

The same workflow supports a manual publish. It is deliberately not set to publish every commit automatically, so a test or accidental commit cannot immediately replace the live game.

### 1. Configure secrets

In GitHub, open Settings → Secrets and variables → Actions and add:

- ROBLOX_API_KEY — an Open Cloud API key with universe-places access and Write permission for the intended experience.
- ROBLOX_UNIVERSE_ID — the experience's Universe ID.
- ROBLOX_PLACE_ID — the exact place to update.

Keep the key in GitHub Secrets; never commit it into source files, README, or workflow YAML. Restrict the key to the intended experience and only the permissions needed. Roblox's official guide: https://create.roblox.com/docs/cloud/guides/usage-place-publishing.

### 2. Publish

1. Push the desired source files to main.
2. Open the repository's Actions tab.
3. Select Validate and publish Roblox place.
4. Click Run workflow and select branch main.
5. Set Publish the built place to Roblox to true only when you intend to update the live place.
6. Run the workflow and inspect the job result. Confirm the new version in Creator Dashboard or Roblox Studio.

The publish job sends the Rojo-built .rbxlx file to Roblox's Place Publishing API. It does not publish merely by committing to GitHub. Publishing requires an existing experience/place, correct IDs, a valid API key, and appropriate permissions. Keep the API key private.

## D. Chess controls

The existing client panel already sends Reset and Deselect actions to the server. Reset starts a new game on the shared board for everyone in that server; it is not a separate private match per player. The current chess implementation is a prototype and does not yet implement check/checkmate, castling, en passant, or pawn promotion.

## Troubleshooting

- If Rojo cannot connect, make sure rojo serve is still running and the Studio plugin is connected to that same local session.
- If rojo build fails in GitHub Actions, open the failed workflow and inspect the build step.
- If publishing fails, verify all three secrets, the Place ID/Universe ID pairing, the API key's universe-places Write permission, and that the place is publishable.
- Never paste your Roblox API key or account security cookie into chat or commit it to GitHub.
