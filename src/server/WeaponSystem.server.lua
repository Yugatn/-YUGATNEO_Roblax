-- YUGATNEO Weapon System — server-authoritative loadout + raycast fire.
-- Disabled while the player is seated at a chess table (Playing/Waiting/Ready).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local WEAPONS = {
	Pistol = { damage = 18, range = 180, cooldown = 0.35, name = "Pistol" },
	Rifle = { damage = 28, range = 320, cooldown = 0.55, name = "Rifle" },
	SMG = { damage = 12, range = 140, cooldown = 0.12, name = "SMG" },
}

local event = ReplicatedStorage:FindFirstChild("WeaponEvent")
if not event then
	event = Instance.new("RemoteEvent")
	event.Name = "WeaponEvent"
	event.Parent = ReplicatedStorage
end

local equipped = {} -- userId -> weapon key
local lastShot = {} -- userId -> tick()

-- Optional hook: ChessArena can set this attribute on the player
local function isInChessMatch(player)
	return player:GetAttribute("InChessMatch") == true
end

local function equip(player, weaponKey)
	if not WEAPONS[weaponKey] then
		return false, "Unknown weapon"
	end
if isInChessMatch(player) then
		return false, "Cannot equip weapons during a chess match"
	end
	equipped[player.UserId] = weaponKey
	event:FireClient(player, "Equipped", weaponKey, WEAPONS[weaponKey])
	return true
end

local function fire(player, origin, direction)
	if isInChessMatch(player) then
		return false, "No shooting during chess"
	end
	local key = equipped[player.UserId]
	if not key then
		return false, "No weapon equipped"
	end
	local def = WEAPONS[key]
	local now = tick()
	if lastShot[player.UserId] and (now - lastShot[player.UserId]) < def.cooldown then
		return false, "Cooldown"
	end
	if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then
		return false, "Bad aim data"
	end
	if direction.Magnitude < 0.01 then
		return false, "Bad direction"
	end
	direction = direction.Unit

	-- Sanity: origin should be near the character
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false, "No character"
	end
	if (origin - hrp.Position).Magnitude > 12 then
		origin = hrp.Position + Vector3.new(0, 1.5, 0)
	end

	lastShot[player.UserId] = now

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }
	local result = Workspace:Raycast(origin, direction * def.range, params)

	local hitPos = origin + direction * def.range
	local hitPlayerName = nil
	if result then
		hitPos = result.Position
		local model = result.Instance:FindFirstAncestorOfClass("Model")
		if model then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			local victim = Players:GetPlayerFromCharacter(model)
			if humanoid and humanoid.Health > 0 then
				-- Do not damage players in chess matches
				if not (victim and isInChessMatch(victim)) then
					humanoid:TakeDamage(def.damage)
					hitPlayerName = victim and victim.DisplayName or model.Name
				end
			end
		end
	end

	-- Visual tracer for nearby clients
	event:FireAllClients("Tracer", origin, hitPos, key)
	if hitPlayerName then
		event:FireClient(player, "Hit", hitPlayerName, def.damage)
	end
	return true
end

event.OnServerEvent:Connect(function(player, action, a, b)
	if action == "Equip" then
		equip(player, a)
	elseif action == "Fire" then
		fire(player, a, b)
	end
end)

Players.PlayerAdded:Connect(function(player)
	equipped[player.UserId] = "Pistol"
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		event:FireClient(player, "Equipped", "Pistol", WEAPONS.Pistol)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	equipped[player.UserId] = nil
	lastShot[player.UserId] = nil
end)

print("[YUGATNEO] WeaponSystem ready — Pistol / Rifle / SMG")
