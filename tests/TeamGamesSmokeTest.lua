-- Manual Studio ServerScriptService smoke tests for story X co-op / light trails / zombie tag.
-- Copy as temporary Script; inspect Roblox Output; remove before publishing.
local Wave=require(script.Parent:WaitForChild("DefenseRules"))
local Tag=require(script.Parent:WaitForChild("InfectionRules"))
local Light=require(script.Parent:WaitForChild("LightCycleEngine"))
local function ok(condition,label)
    assert(condition,"[Team games] FAIL: "..label)
    print("[Team games] PASS: "..label)
end
for _,mode in ipairs({"Robots10","Robots20","Shadows10","Shadows20"}) do
    for group=1,3 do
        local cfg=Wave.config(mode,group)
        ok(cfg~=nil and cfg.people==group,"valid co-op config "..mode..":"..group)
        ok(Wave.count(cfg,1)>0,"bots spawn on first wave")
        ok(Wave.count(cfg,cfg.rounds)<=cfg.limit,"wave population capped")
        ok(Wave.resistance(cfg,cfg.rounds)>Wave.resistance(cfg,1),"increasing AI resistance")
    end
end
ok(Wave.restore("Engineer",5)>Wave.restore("Defender",5),"engineer better at repairs")
ok(Wave.replenish("Support",0)>Wave.replenish("Defender",0),"support role better at supply")
ok(Tag.timeLimit(30,false)==1800 and Tag.timeLimit(60,false)==3600,"30m and 60m modes")
ok(Tag.timeLimit(60,true)==180,"short Studio smoke mode")
ok(not Tag.captured(5,7.9,true,4),"2.9 sec cannot infect")
ok(Tag.captured(5,8.1,true,4),"3.1 sec within range can infect")
ok(not Tag.captured(5,9,false,4),"blocked line-of-sight cannot infect")
ok(not Tag.captured(5,9,true,6),"distant target cannot infect")
ok(Tag.finalists(6)==2 and Tag.finalists(3)==1,"final survivor thresholds")
ok(Tag.finalEscapeAllowed(6,2) and not Tag.finalEscapeAllowed(6,4),"escape phase threshold")

local m=Light.newMatch({101,202},20,16)
ok(m.riders[101]~=nil and m.riders[202]~=nil,"light grid creates two bikes")
ok(not Light.turn(m,101,"Left"),"cannot reverse into light trail")
ok(Light.turn(m,101,"Down"),"first 90-degree turn accepted")
ok(not Light.turn(m,101,"Up"),"second turn in same tick rejected")
Light.step(m)
ok(m.roundTicks==1,"light engine tick advances")
local checkWinner=Light.newMatch({333,444},16,12)
for i=1,25 do
    if checkWinner.over then break end
    Light.step(checkWinner)
end
ok(checkWinner.over,"unsteered lightcycles hit walls and match ends")
ok(Light.public(checkWinner).over,"public game state matches server")
print("[YUGATNEO] Module-only tests passed; multiplayer physics, saving and UI are NOT tested by this script.")
