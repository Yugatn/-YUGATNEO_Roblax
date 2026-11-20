-- Functional Studio smoke tests for room isolation, authority, leadership and resets.
-- Add to ServerScriptService manually alongside the Academy Rojo modules in a TEST place.
local Rooms = require(game:GetService("ServerScriptService"):WaitForChild("SymbiontRooms"))

local registry = Rooms.new(4, 4)
local function must(ok, message)
    assert(ok, tostring(message))
end
must(not select(1, Rooms.join(registry, 101, 0)), "Room 0 must be rejected")
must(not select(1, Rooms.join(registry, 101, 5)), "Room 5 must be rejected")
must(select(1, Rooms.join(registry, 101, 1)))
must(select(1, Rooms.join(registry, 202, 1)))
must(select(1, Rooms.join(registry, 303, 2)))
must(not select(1, Rooms.join(registry, 101, 2)), "Must leave before switching teams")
must(not select(1, Rooms.apply(registry, 101, 2, "water", "inspect")),
    "Other-room actions must fail")
must(Rooms.roomOf(registry, 202) == 1)
must(Rooms.roomOf(registry, 303) == 2)
must(Rooms.snapshot(registry, 101).isLeader)
must(not Rooms.snapshot(registry, 202).isLeader)

must(select(1, Rooms.apply(registry, 101, 1, "water", "inspect")))
must(select(1, Rooms.apply(registry, 303, 2, "water", "inspect")))
must(select(1, Rooms.apply(registry, 202, 1, "water", "prepare")))
must(select(1, Rooms.apply(registry, 303, 2, "water", "prepare")))
must(select(1, Rooms.apply(registry, 303, 2, "bridge", "survey")))
must(Rooms.snapshot(registry, 202).levels.water.done.prepare)
must(Rooms.snapshot(registry, 303).levels.bridge.done.survey)
must(not Rooms.snapshot(registry, 202).levels.bridge.done.survey,
    "Room 2 progress leaked into room 1")

must(not select(1, Rooms.reset(registry, 202)), "Non-leader reset must fail")
local before = Rooms.snapshot(registry, 202).serverSeq
must(select(1, Rooms.reset(registry, 101)))
local after = Rooms.snapshot(registry, 202)
must(after.serverSeq > before, "Reset must advance ordered client packet sequence")
must(not after.levels.water.done.inspect)
must(Rooms.snapshot(registry, 303).levels.water.done.prepare,
    "Reset in room 1 must not affect room 2")

must(select(1, Rooms.join(registry, 404, 1)))
must(select(1, Rooms.join(registry, 505, 1)))
must(not select(1, Rooms.join(registry, 606, 1)), "Over-capacity join must fail")
must(select(1, Rooms.leave(registry, 101)))
must(Rooms.snapshot(registry, 202).isLeader, "Oldest remaining player becomes leader")
must(select(1, Rooms.reset(registry, 202)))
must(select(1, Rooms.leave(registry, 202)))
must(select(1, Rooms.leave(registry, 404)))
must(select(1, Rooms.leave(registry, 505)))
must(Rooms.getRoom(registry, 1) == nil, "Empty room must be deleted")
must(select(1, Rooms.join(registry, 606, 1)))
local fresh = Rooms.snapshot(registry, 606)
must(fresh.isLeader and fresh.members == 1)
must(not fresh.levels.water.done.inspect, "New session must start clean")
assert(fresh.roomId == 1)
print("PASS: Symbiont Academy team isolation and reset smoke tests")
