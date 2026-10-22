--!strict
-- STORY X: YUGATNEO MATRIX
-- Generated neon exploration world. All rewards and puzzle checks are server-authoritative.
-- Fictional, non-violent pulse blaster: only training drones can be hit; players take no damage.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local WORLD_NAME = "YUGATNEO_MATRIX_WORLD"
local oldWorld = workspace:FindFirstChild(WORLD_NAME)
if oldWorld then oldWorld:Destroy() end

local world = Instance.new("Folder")
world.Name = WORLD_NAME
world.Parent = workspace

local function getRemote(name: string): RemoteEvent
	local existing = ReplicatedStorage:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then return existing end
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = ReplicatedStorage
	return event
end

local noticeEvent = getRemote("StoryXNotice")
local puzzleEvent = getRemote("StoryXPuzzle")
local answerEvent = getRemote("StoryXAnswer")
local pulseEvent = getRemote("StoryXPulse")
local modeEvent = getRemote("StoryXPulseMode")
local progressEvent = getRemote("StoryXProgress")

local CYAN = Color3.fromRGB(0, 255, 210)
local GREEN = Color3.fromRGB(80, 255, 125)
local BLUE = Color3.fromRGB(40, 140, 255)
local PURPLE = Color3.fromRGB(155, 75, 255)
local PINK = Color3.fromRGB(255, 55, 190)
local DARK = Color3.fromRGB(5, 9, 24)
local WHITE = Color3.fromRGB(235, 255, 255)

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, transparency: number?, collide: boolean?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.Color = color
	p.Material = material or Enum.Material.Neon
	p.Transparency = transparency or 0
	p.CanCollide = collide == true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function label(adornee: BasePart, text: string, width: number, height: number, offset: Vector3, color: Color3, maxDistance: number?)
	local gui = Instance.new("BillboardGui")
	gui.Name = "HologramLabel"
	gui.Adornee = adornee
	gui.Size = UDim2.fromOffset(width, height)
	gui.StudsOffsetWorldSpace = offset
	gui.AlwaysOnTop = true
	gui.MaxDistance = maxDistance or 500
	gui.Parent = adornee
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextColor3 = color
	textLabel.TextStrokeColor3 = Color3.fromRGB(0, 20, 30)
	textLabel.TextStrokeTransparency = 0.15
	textLabel.TextScaled = true
	textLabel.Font = Enum.Font.GothamBlack
	textLabel.Parent = gui
	return gui
end

local function neonLine(name: string, a: Vector3, b: Vector3, thickness: number, color: Color3)
	local delta = b - a
	local p = part(world, name, Vector3.new(thickness, thickness, delta.Magnitude), CFrame.lookAt((a + b) / 2, b), color, Enum.Material.Neon, 0.12, false)
	return p
end

-- Dark platform, cyan grid, and a glowing title suspended above the spawn.
part(world, "InfiniteBase", Vector3.new(420, 4, 420), CFrame.new(0, -3, 0), DARK, Enum.Material.Slate, 0, true)
for n = -200, 200, 20 do
	neonLine("Grid_X_" .. n, Vector3.new(n, -0.94, -200), Vector3.new(n, -0.94, 200), 0.12, Color3.fromRGB(0, 70, 90))
	neonLine("Grid_Z_" .. n, Vector3.new(-200, -0.94, n), Vector3.new(200, -0.94, n), 0.12, Color3.fromRGB(0, 70, 90))
end

local titleAnchor = part(world, "YUGATNEO_MATRIX_HologramAnchor", Vector3.new(1, 1, 1), CFrame.new(0, 66, -25), CYAN, Enum.Material.Neon, 1, false)
label(titleAnchor, "YUGATNEO MATRIX", 1000, 130, Vector3.new(0, 0, 0), CYAN, 1200)
local subtitleAnchor = part(world, "WorldSubtitleAnchor", Vector3.new(1, 1, 1), CFrame.new(0, 58, -25), GREEN, Enum.Material.Neon, 1, false)
label(subtitleAnchor, "A STORY X EXPERIENCE  •  OBSERVE / QUESTION / CHOOSE", 900, 48, Vector3.new(0, 0, 0), WHITE, 1000)

-- Spawn island.
part(world, "SpawnIsland", Vector3.new(66, 2, 56), CFrame.new(0, 0, 0), Color3.fromRGB(9, 22, 38), Enum.Material.Metal, 0, true)
for x = -30, 30, 10 do
	part(world, "SpawnEdge_" .. x, Vector3.new(0.45, 0.3, 54), CFrame.new(x, 1.2, 0), CYAN, Enum.Material.Neon, 0.1, false)
end
local spawn = Instance.new("SpawnLocation")
spawn.Name = "MatrixSpawn"
spawn.Size = Vector3.new(8, 1, 8)
spawn.Position = Vector3.new(0, 2, 12)
spawn.Anchored = true
spawn.Neutral = true
spawn.Material = Enum.Material.Neon
spawn.Color = GREEN
spawn.Parent = world

local welcome = part(world, "WelcomeConsole", Vector3.new(8, 6, 1), CFrame.new(0, 4, -18), Color3.fromRGB(5, 20, 35), Enum.Material.Metal, 0, true)
label(welcome, "WELCOME, OBSERVER\nYour map is a model. The world is more than the map.", 330, 115, Vector3.new(0, 5, 0), WHITE, 250)

local function makePlatform(name: string, position: Vector3, size: Vector3, color: Color3)
	local p = part(world, name, size, CFrame.new(position), Color3.fromRGB(8, 20, 35), Enum.Material.Metal, 0, true)
	part(world, name .. "_Edge", Vector3.new(size.X, 0.3, size.Z), CFrame.new(position.X, position.Y + size.Y/2 + 0.12, position.Z), color, Enum.Material.Neon, 0.1, false)
	return p
end

-- Raised districts joined by wide, walkable neon bridges.
makePlatform("MemoryGarden", Vector3.new(-78, 8, -45), Vector3.new(58, 3, 54), Color3.fromRGB(30, 220, 255))
makePlatform("SignalMaze", Vector3.new(78, 11, -45), Vector3.new(58, 3, 54), PURPLE)
makePlatform("DroneRange", Vector3.new(0, 6, 95), Vector3.new(78, 3, 56), PINK)
makePlatform("ObservationTowerBase", Vector3.new(0, 14, -125), Vector3.new(48, 3, 48), GREEN)

local function bridge(name: string, startPos: Vector3, endPos: Vector3, width: number, color: Color3)
	local delta = endPos - startPos
	local center = (startPos + endPos) / 2
	local p = part(world, name, Vector3.new(width, 1.5, delta.Magnitude), CFrame.lookAt(center, endPos), Color3.fromRGB(10, 27, 43), Enum.Material.Metal, 0, true)
	local edgeA = startPos + Vector3.new(width/2, 0.8, 0)
	local edgeB = endPos + Vector3.new(width/2, 0.8, 0)
	neonLine(name .. "_RailA", edgeA, edgeB, 0.25, color)
	neonLine(name .. "_RailB", startPos - Vector3.new(width/2, -0.8, 0), endPos - Vector3.new(width/2, -0.8, 0), 0.25, color)
	return p
end
bridge("Bridge_ToMemory", Vector3.new(-22, 1, -6), Vector3.new(-60, 8, -45), 12, CYAN)
bridge("Bridge_ToSignals", Vector3.new(22, 1, -6), Vector3.new(60, 11, -45), 12, PURPLE)
bridge("Bridge_ToRange", Vector3.new(0, 1, 28), Vector3.new(0, 6, 66), 14, PINK)
bridge("Bridge_ToTower", Vector3.new(0, 1, -26), Vector3.new(0, 14, -100), 12, GREEN)

-- Tall abstract city towers: geometry only, no external assets.
for i = 1, 26 do
	local angle = (math.pi * 2) * i / 26
	local radius = 145 + (i % 4) * 12
	local x, z = math.cos(angle) * radius, math.sin(angle) * radius
	local h = 18 + (i % 7) * 8
	local tower = part(world, "DataSpire_" .. i, Vector3.new(10 + (i%3)*3, h, 10 + (i%4)*2), CFrame.new(x, h/2 - 1, z), Color3.fromRGB(7, 20, 35), Enum.Material.Metal, 0, true)
	part(world, "SpireSignal_" .. i, Vector3.new(10 + (i%3)*3, 0.45, 10 + (i%4)*2), CFrame.new(x, h - 0.7, z), i%2==0 and CYAN or GREEN, Enum.Material.Neon, 0.05, false)
	if i % 2 == 0 then label(tower, "DATA / " .. string.format("%02d", i), 120, 30, Vector3.new(0, h/2 + 2, 0), CYAN, 400) end
end

-- Collectible evidence: story lore is presented as fragments, not absolute answers.
local playerState: {[Player]: {fragments: number, solved: {[string]: boolean}, drones: number}} = {}
local fragmentTexts = {
	{title="FRAGMENT 01 — THE OTHER", body="A model of a person is not the person. Ask what you observed, what you inferred, and what remains unknown."},
	{title="FRAGMENT 02 — MIRA", body="Mira observes Eugene too. The observer is part of the system being observed."},
	{title="FRAGMENT 03 — THE TRACE", body="A pattern can be meaningful, accidental, or incomplete. Check more than one explanation."},
	{title="FRAGMENT 04 — THE EMPTY", body="The Empties erase inconvenient differences. Restore the details that the system tried to discard."},
	{title="FRAGMENT 05 — THE RIGHT TO EXIT", body="A safe system lets a subject pause, refuse, or leave an experiment."},
	{title="FRAGMENT 06 — X", body="Reality is more than any one map. Leave room for the part you do not yet understand."},
}

local function giveFragment(player: Player, id: number)
	local state = playerState[player]
	if not state then return end
	local key = "Fragment" .. id
	if state.solved[key] then
		noticeEvent:FireClient(player, "Already recovered", "You have this memory fragment. Explore another district.")
		return
	end
	state.solved[key] = true
	state.fragments += 1
	local f = fragmentTexts[id]
	progressEvent:FireClient(player, state.fragments, state.drones)
	noticeEvent:FireClient(player, f.title, f.body)
end

for i, f in ipairs(fragmentTexts) do
	local positions = {
		Vector3.new(-78, 12, -45), Vector3.new(-94, 12, -54), Vector3.new(-63, 12, -31),
		Vector3.new(78, 15, -45), Vector3.new(92, 15, -31), Vector3.new(0, 18, -125),
	}
	local pos = positions[i]
	local orb = part(world, "MemoryFragment_" .. i, Vector3.new(2.5, 2.5, 2.5), CFrame.new(pos), i%2==0 and GREEN or CYAN, Enum.Material.Neon, 0.05, false)
	orb.Shape = Enum.PartType.Ball
	local light = Instance.new("PointLight")
	light.Color = orb.Color
	light.Range = 14
	light.Brightness = 1.4
	light.Parent = orb
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Recover memory"
	prompt.ObjectText = f.title
	prompt.HoldDuration = 0.35
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = orb
	prompt.Triggered:Connect(function(player) giveFragment(player, i) end)
end

-- Three short reasoning puzzles. Correct answers are checked by the server.
local puzzles = {
	Trace = {title="THE TRACE TERMINAL", question="A light flashes twice. Is that enough to prove a message was sent?", hint="Think about evidence versus explanation.", answers={"no", "not enough", "cannot know", "can't know"}, success="Correct. Two flashes are an observation; their cause remains open."},
	Other = {title="MIRA'S QUESTION", question="Can a profile, score, or memory file fully describe another person?", hint="Remember the rule: model is not subject.", answers={"no", "never", "not completely"}, success="Correct. A model can help, but it cannot replace the other subject."},
	Exit = {title="THE QUIET ROOM", question="What should a safe experiment allow a participant to do?", hint="Think about consent and the right to stop.", answers={"stop", "leave", "refuse", "pause", "stop or leave"}, success="Correct. A subject must be able to pause, refuse, or leave."},
}

local function addPuzzle(id: string, pos: Vector3, color: Color3)
	local console = part(world, "PuzzleTerminal_" .. id, Vector3.new(5, 5, 2), CFrame.new(pos), Color3.fromRGB(9, 18, 34), Enum.Material.Metal, 0, true)
	part(world, "TerminalScreen_" .. id, Vector3.new(4.1, 2.6, 0.25), CFrame.new(pos + Vector3.new(0, 0.55, -1.12)), color, Enum.Material.Neon, 0.12, false)
	label(console, puzzles[id].title, 220, 40, Vector3.new(0, 3.7, 0), color, 220)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Inspect / answer"
	prompt.ObjectText = puzzles[id].title
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = console
	prompt.Triggered:Connect(function(player)
		local state = playerState[player]
		if not state then return end
		if state.solved["Puzzle_" .. id] then
			noticeEvent:FireClient(player, "TERMINAL COMPLETE", "You already solved this terminal. Keep exploring.")
		else
			puzzleEvent:FireClient(player, id, puzzles[id].title, puzzles[id].question, puzzles[id].hint)
		end
	end)
end

addPuzzle("Trace", Vector3.new(-80, 12, -25), CYAN)
addPuzzle("Other", Vector3.new(94, 15, -55), PURPLE)
addPuzzle("Exit", Vector3.new(0, 9, 112), PINK)

answerEvent.OnServerEvent:Connect(function(player: Player, id: any, rawAnswer: any)
	if typeof(id) ~= "string" or typeof(rawAnswer) ~= "string" or #rawAnswer > 100 then return end
	local puzzle = puzzles[id]
	local state = playerState[player]
	if not puzzle or not state then return end
	if state.solved["Puzzle_" .. id] then return end
	local answer = string.lower(string.gsub(rawAnswer, "^%s*(.-)%s*$", "%1"))
	local ok = false
	for _, candidate in ipairs(puzzle.answers) do
		if answer == candidate then ok = true end
	end
	if ok then
		state.solved["Puzzle_" .. id] = true
		state.fragments += 1
		progressEvent:FireClient(player, state.fragments, state.drones)
		noticeEvent:FireClient(player, "REASONING VERIFIED", puzzle.success .. " +1 memory shard.")
	else
		noticeEvent:FireClient(player, "NOT QUITE", "Try again. " .. puzzle.hint)
	end
end)

-- Non-player-damaging training drones. Pulse shots can only score against these targets.
local droneFolder = Instance.new("Folder")
droneFolder.Name = "TrainingDrones"
droneFolder.Parent = world
local droneModels: {Model} = {}
for i = 1, 6 do
	local x = -27 + ((i-1)%3)*27
	local z = 87 + math.floor((i-1)/3)*20
	local model = Instance.new("Model")
	model.Name = "TrainingDrone_" .. i
	model:SetAttribute("DroneHealth", 3)
	model.Parent = droneFolder
	local core = part(model, "Core", Vector3.new(4, 4, 4), CFrame.new(x, 12, z), i%2==0 and PURPLE or PINK, Enum.Material.Neon, 0, false)
	core.Shape = Enum.PartType.Ball
	model.PrimaryPart = core
	for arm = 1, 4 do
		local a = (math.pi/2)*(arm-1)
		local wing = part(model, "Wing_" .. arm, Vector3.new(2.6, 0.45, 0.8), CFrame.new(x + math.cos(a)*2.7, 12, z + math.sin(a)*2.7), CYAN, Enum.Material.Neon, 0.1, false)
	end
	label(core, "TRAINING DRONE", 160, 28, Vector3.new(0, 3.2, 0), WHITE, 180)
	table.insert(droneModels, model)
end

local lastShot: {[Player]: number} = {}
local pulseMode = {}
local modes = {
    Pulse = {damage = 1, cooldown = 0.35, range = 180},
    Rapid = {damage = 1, cooldown = 0.17, range = 145},
    Charged = {damage = 3, cooldown = 1.1, range = 220},
}
modeEvent.OnServerEvent:Connect(function(player, selected)
    if typeof(selected) == "string" and modes[selected] then pulseMode[player] = selected end
end)
pulseEvent.OnServerEvent:Connect(function(player: Player, direction: any)
	if typeof(direction) ~= "Vector3" or direction.Magnitude < 0.8 or direction.Magnitude > 1.2 then return end
	if player:GetAttribute("InChessMatch") then return end
	local now = os.clock()
	local config = modes[pulseMode[player] or "Pulse"]
	if now - (lastShot[player] or -100) < config.cooldown then return end
	lastShot[player] = now
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then return end
	local origin = root.Position + Vector3.new(0, 1.5, 0)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {character}
	rayParams.IgnoreWater = true
	local result = workspace:Raycast(origin, direction.Unit * config.range, rayParams)
	local endpoint = result and result.Position or (origin + direction.Unit * config.range)
	local beam = part(world, "PulseBeam", Vector3.new(0.16, 0.16, (endpoint-origin).Magnitude), CFrame.lookAt((origin+endpoint)/2, endpoint), CYAN, Enum.Material.Neon, 0.05, false)
	Debris:AddItem(beam, 0.12)
	if result then
		local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
		if hitModel and hitModel.Parent == droneFolder then
			local health = (hitModel:GetAttribute("DroneHealth") or 3) - config.damage
			hitModel:SetAttribute("DroneHealth", health)
			local core = hitModel.PrimaryPart
			if core then
				core.Color = health <= 1 and GREEN or CYAN
				local flash = TweenService:Create(core, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {Size = Vector3.new(5,5,5)})
				flash:Play()
			end
			if health <= 0 then
				for _, desc in ipairs(hitModel:GetDescendants()) do
					if desc:IsA("BasePart") then desc.Transparency = 1; desc.CanQuery = false end
				end
				local state = playerState[player]
				if state then
					state.drones += 1
					progressEvent:FireClient(player, state.fragments, state.drones)
					noticeEvent:FireClient(player, "DRONE DISABLED", "Training target safely disabled. No one was harmed.")
				end
				task.delay(8, function()
					if hitModel.Parent then
						hitModel:SetAttribute("DroneHealth", 3)
						for _, desc in ipairs(hitModel:GetDescendants()) do
							if desc:IsA("BasePart") then desc.Transparency = 0; desc.CanQuery = true end
						end
						if hitModel.PrimaryPart then hitModel.PrimaryPart.Color = PINK end
					end
				end)
			end
		end
	end
end)

-- A simple observation tower marker at the top of the map.
local tower = part(world, "ObservationBeacon", Vector3.new(4, 20, 4), CFrame.new(0, 27, -125), GREEN, Enum.Material.Neon, 0.18, false)
label(tower, "THE OBSERVER IS ALSO OBSERVED", 420, 70, Vector3.new(0, 12, 0), GREEN, 500)

Players.PlayerAdded:Connect(function(player)
	playerState[player] = {fragments = 0, solved = {}, drones = 0}
	task.defer(function()
		progressEvent:FireClient(player, 0, 0)
		noticeEvent:FireClient(player, "WELCOME TO YUGATNEO MATRIX", "Recover six memory fragments, solve three reasoning terminals, and disable training drones with your harmless pulse tool. Observe carefully: a clue is not always a conclusion.")
	end)
end)
Players.PlayerRemoving:Connect(function(player)
	playerState[player] = nil
	lastShot[player] = nil
	pulseMode[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	playerState[player] = playerState[player] or {fragments = 0, solved = {}, drones = 0}
end

print("[STORY X] YUGATNEO MATRIX world generated. Explore, reason, and leave room for X.")
