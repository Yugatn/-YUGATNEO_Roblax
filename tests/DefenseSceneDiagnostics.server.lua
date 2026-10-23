-- STORY X defense scene diagnostic: temporary Studio Script only.
-- Requires WaveDefense.server.lua to have already initialized in the same place.
local world=workspace:WaitForChild("STORY_X_COOP_DEFENSE",15)
assert(world,"Missing co-op defense world")
local function check(condition,label)
 assert(condition,"[DEFENSE SCENE FAIL] "..label)
 print("[DEFENSE SCENE PASS] "..label)
end
for _,name in ipairs({"METAL_SENTINELS","SHADOW_SWARM"}) do
 local arena=world:WaitForChild(name,15)
 check(arena~=nil,name.." arena generated")
 if arena then
  local core=arena:FindFirstChild("DefenseCore")
  check(core and core:IsA("BasePart"),name.." contains tangible core")
  check(arena:FindFirstChild("SpiralBridge")~=nil,
   name.." attached to spiral by a generated bridge")
  check(arena:FindFirstChild("LobbyJoin")~=nil,
   name.." supports joining another match")
  for i=1,4 do
   local pad=arena:FindFirstChild("CraftPad_"..i)
   local barrier=arena:FindFirstChild("Barricade_"..i)
   check(pad and barrier and not barrier.CanCollide,
    name.." construction pad "..i.." starts without a wall")
   check(pad:FindFirstChildOfClass("ProximityPrompt")~=nil,
    name.." construction pad "..i.." is interactive")
  end
  for _,plan in ipairs({"Fortify","Scout","Resupply"}) do
   check(arena:FindFirstChild("PlanVote_"..plan)~=nil,
    name.." contains tactic voting "..plan)
  end
  check(arena:FindFirstChild("RepairWorkbench")~=nil,name.." core repair available")
  check(arena:FindFirstChild("SupplyDepot")~=nil,name.." supply terminal available")
 end
end
print("[DEFENSE SCENE] Procedural world checks completed; human multi-client testing still needed.")
