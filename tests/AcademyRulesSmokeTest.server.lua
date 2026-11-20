-- Functional smoke test. Copy as Script into ServerScriptService in a throwaway Studio test Place.
-- Not mapped into the production Rojo project.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rules = require(game:GetService("ServerScriptService"):WaitForChild("SymbiontRules"))

local state = Rules.newState()
assert(not select(1, Rules.apply(state, "water", "activate", 101)), "Must check prerequisites")
for _, actionId in ipairs({"inspect", "prepare", "school", "clinic", "homes", "activate"}) do
    local ok, why = Rules.apply(state, "water", actionId, if actionId == "clinic" then 202 else 101)
    assert(ok, "Water failed: " .. actionId .. " " .. tostring(why))
end
assert(state.levels.water.completed)
assert(Rules.snapshot(state).levels.water.contributors == 2)
assert(not select(1, Rules.apply(state, "water", "activate", 101)), "Replay must be blocked")

for _, actionId in ipairs({"survey", "plan", "beamRight", "beamLeft", "test", "open"}) do
    assert(select(1, Rules.apply(state, "bridge", actionId, 101)), "Bridge failed: " .. actionId)
end
assert(state.levels.bridge.completed)

assert(not select(1, Rules.apply(state, "council", "meeting", 101)))
for _, id in ipairs({"budget", "residents", "engineers"}) do
    assert(select(1, Rules.apply(state, "council", id, 101)))
end
assert(select(1, Rules.apply(state, "council", "audit", 101)))
assert(state.levels.council.completed)
assert(state.levels.council.selected == "audit")
assert(not select(1, Rules.apply(state, "council", "petition", 101)))
assert(not select(1, Rules.apply(state, "invalid", "unknown", 101)))
assert(Rules.snapshot(state).revision == 16)
print("PASS: Symbiont Academy Rules")
