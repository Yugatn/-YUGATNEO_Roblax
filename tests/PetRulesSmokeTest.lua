-- Temporary Roblox Studio test harness for the PURE virtual pet rules.
-- Copy to ServerScriptService as Script, run Play, inspect Output, then remove.
-- This is not a substitute for live DataStore and two-client verification.
local PetRules = require(script.Parent:WaitForChild("PetRules"))
local function check(condition, message)
    assert(condition, "[Pet Test FAIL] " .. message)
    print("[Pet Test PASS] " .. message)
end
local base = 1800000000
local p = PetRules.create("Lumi", base)
check(p.level == 1 and p.hunger == 85 and p.health == 100, "new pet stats")
check(PetRules.public(p).species == "Lumi", "public projection")
local ok = PetRules.act(p, "Feed", base + 5)
check(ok and p.hunger == 100 and p.xp == 5, "feeding and XP")
local blocked = PetRules.act(p, "Feed", base + 6)
check(not blocked and p.xp == 5, "cooldown prevents spam")
check(not PetRules.act(p, "Teleport", base + 30), "unknown action refused")

local month = 31 * 24 * 3600
PetRules.advance(p, base + month, true)
check(p.health == 100 and p.xp == 5, "absence never damages health or accumulated XP")
check(p.hunger >= 76, "offline needs are capped to two hours")
check(p.lastUpdated == base + month, "offline clock consumes downtime once")
local h = p.hunger
PetRules.advance(p, base + month, true)
check(p.hunger == h, "rejoining twice does not double-count absence")

local saved = PetRules.restore({
    species = p.species, hunger = p.hunger, joy = p.joy,
    energy = p.energy, health = p.health, xp = p.xp,
    careCount = p.careCount, createdAt = p.createdAt,
    lastUpdated = p.lastUpdated,
}, base + month + 100)
check(saved and saved.xp == 5 and saved.hunger == p.hunger, "profile restored")
check(PetRules.restore({species="Invalid"}, base)==nil, "unknown type rejected")
saved.energy = 10
local played = PetRules.act(saved, "Play", base+month+110)
check(not played and saved.lastAction.Play == nil, "low-energy action does not consume cooldown")
check(PetRules.act(saved, "Rest", base+month+120), "rest restores energy")
check(PetRules.act(saved, "Play", base+month+140), "play allowed after rest")
for i=1,24 do
    PetRules.act(saved, "Care", base+month+200+i*30)
end
check(saved.level >= 2, "growth through positive care")
check(PetRules.stage(saved) == "Малыш" or PetRules.stage(saved) == "Юный исследователь",
    "growth stage stable")
print("[YUGATNEO PET] Pure tests finished; Studio persistence and UI tests still required.")
