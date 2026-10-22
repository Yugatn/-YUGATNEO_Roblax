-- Story X: original virtual-pet simulation, deliberately gentle for younger players.
-- Pure-ish data rules: no Roblox services and no network calls.
local PetRules = {}
PetRules.species = {
    Lumi = {label = "Люми", shape = "star", description = "Светящийся исследователь"},
    Miko = {label = "Мико", shape = "cat", description = "Любознательный котик"},
    Sprout = {label = "Росток", shape = "plant", description = "Зелёный друг"},
}
PetRules.actions = {Feed = true, Play = true, Rest = true, Care = true}
local function limit(x) return math.clamp(math.floor(x + 0.5), 0, 100) end
local function int(x, fallback, low, high)
    if type(x) ~= "number" or x ~= x or x == math.huge or x == -math.huge then return fallback end
    return math.clamp(math.floor(x), low, high)
end

function PetRules.create(species, now)
    assert(PetRules.species[species], "Unsupported virtual pet")
    return {
        species = species, hunger = 85, joy = 85, energy = 80, health = 100,
        xp = 0, level = 1, createdAt = now, lastUpdated = now, lastAction = {},
        careCount = 0, totalDays = 0,
    }
end

function PetRules.restore(value, now)
    if type(value) ~= "table" or not PetRules.species[value.species] then return nil end
    local p = PetRules.create(value.species, now)
    for _, name in ipairs({"hunger", "joy", "energy", "health"}) do
        p[name] = int(value[name], p[name], 0, 100)
    end
    p.xp = int(value.xp, 0, 0, 500000)
    p.level = math.clamp(1 + math.floor(p.xp / 100), 1, 10)
    p.careCount = int(value.careCount, 0, 0, 999999)
    p.createdAt = int(value.createdAt, now, 0, now)
    p.lastUpdated = int(value.lastUpdated, now, 0, now)
    return p
end

-- No death and no negative XP. At most two hours of neglect are simulated
-- across an offline absence; long breaks are a normal, healthy choice.
function PetRules.advance(p, now, offline)
    now = math.max(p.lastUpdated, math.floor(now))
    local elapsed = now - p.lastUpdated
    local effective = offline and math.min(elapsed, 7200) or math.min(elapsed, 3600)
    local blocks = math.floor(effective / 600)
    if blocks > 0 then
        p.hunger = limit(p.hunger - blocks * (offline and 2 or 1))
        p.joy = limit(p.joy - blocks)
        p.energy = limit(p.energy + blocks * (offline and 2 or 0))
        -- Health never falls due solely to player absence.
        p.lastUpdated = offline and now or (p.lastUpdated + blocks * 600)
    elseif offline then
        p.lastUpdated = now
    end
    return p
end

function PetRules.stage(p)
    if p.level >= 7 then return "Мудрый спутник" end
    if p.level >= 4 then return "Юный исследователь" end
    return "Малыш"
end

-- The server enforces real-time cooldown and validates all actions.
function PetRules.act(p, action, now)
    if not PetRules.actions[action] then return false, "Unknown action" end
    now = math.floor(now)
    local elapsed = now - (p.lastAction[action] or -10000)
    local cooldown = action == "Play" and 25 or 15
    if elapsed < cooldown then return false, "Подожди немного: питомец отдыхает", cooldown - elapsed end
    if action == "Play" and p.energy < 12 then
        return false, "Сначала дай питомцу отдохнуть", 0
    end
    p.lastAction[action] = now
    if action == "Feed" then
        p.hunger = limit(p.hunger + 22)
        p.joy = limit(p.joy + 2)
    elseif action == "Play" then
        p.joy = limit(p.joy + 19)
        p.energy = limit(p.energy - 10)
        p.hunger = limit(p.hunger - 4)
        if p.hunger < 20 then p.health = math.max(60, p.health - 2) end
    elseif action == "Rest" then
        p.energy = limit(p.energy + 25)
        p.joy = limit(p.joy + 2)
    elseif action == "Care" then
        p.health = limit(p.health + 15)
        p.joy = limit(p.joy + 6)
    end
    p.xp = math.min(500000, p.xp + 5)
    p.careCount = math.min(999999, p.careCount + 1)
    p.level = math.clamp(1 + math.floor(p.xp / 100), 1, 10)
    return true, "Питомец благодарен за заботу", cooldown
end

function PetRules.public(p)
    if not p then return nil end
    return {
        species = p.species, label = PetRules.species[p.species].label,
        stage = PetRules.stage(p),
        hunger = p.hunger, joy = p.joy, energy = p.energy, health = p.health,
        level = p.level, xp = p.xp, careCount = p.careCount,
    }
end
return PetRules
