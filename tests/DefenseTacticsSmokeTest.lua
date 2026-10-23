-- Run as a temporary ServerScript in Roblox Studio to smoke-test pure defense logic.
-- This file in GitHub is NOT proof of a successful Studio run.
local T = require(script.Parent:WaitForChild("DefenseTactics"))
local Rules = require(script.Parent:WaitForChild("DefenseRules"))
local function check(ok,label)
 assert(ok,"[TACTICS FAIL] "..label)
 print("[TACTICS PASS]",label)
end
local site={level=0,health=0,maxHealth=0,position=Vector3.new(0,0,10)}
check(T.cost("Build","Engineer")==7,"engineer building discount")
check(T.cost("Build","Defender")==9,"ordinary building cost")
local built,coins=T.apply("Build","Engineer",site,15)
check(built and coins==8 and site.health==75 and site.level==1,"initial barricade crafted")
local duplicate,newCoins=T.apply("Build","Defender",site,coins)
check(not duplicate and newCoins==coins,"duplicate build cannot spend resources")
local upgradeBroke=T.apply("Upgrade","Defender",site,coins)
check(not upgradeBroke and site.level==1,"insufficient funds reject upgrade")
local salvage=T.awardSalvage(coins,"wave")
check(salvage==16,"wave completion shares salvage")
local upgraded,left=T.apply("Upgrade","Defender",site,salvage)
check(upgraded and left==1 and site.level==2 and site.maxHealth==130,"team upgrade")
site.health=15
local insufficient=T.apply("Repair","Engineer",site,left)
check(not insufficient and site.health==15,"repair refuses insufficient materials")
local repaired=T.apply("Repair","Engineer",site,5)
check(repaired and site.health==60,"engineer repair provides significant cover")
check(T.awardSalvage(249,"wave")==250,"shared inventory is capped")
local votes={}
check(T.vote(votes,101,"Scout"),"first voter selects scout")
check(T.vote(votes,202,"Fortify"),"second voter selects fortify")
local tie=T.teamPlan(votes,{101,202})
check(tie=="Balanced","tie produces neutral team plan")
T.vote(votes,303,"Scout")
local majority=T.teamPlan(votes,{101,202,303})
check(majority=="Scout","three players resolve majority")
check(not T.vote(votes,777,"Cheat"),"unknown tactical vote rejected")
check(T.coreAttackDamage(8,"Fortify")==6,"fortified core reduces incoming damage")
check(T.hitDamage(20,"Scout")==24,"scout plan increases permitted hit damage")
check(T.supplyBonus("Resupply")==8,"supply-focused team receives more charges")
local barriers={
 {position=Vector3.new(0,0,10),health=40,level=1},
 {position=Vector3.new(30,0,0),health=70,level=1}
}
check(T.intercept(Vector3.new(0,0,40),Vector3.zero,barriers)==1,
 "barrier intercepts approaching enemy")
barriers[1].health=0
check(T.intercept(Vector3.new(0,0,40),Vector3.zero,barriers)==nil,
 "destroyed barrier no longer intercepts")
check(Rules.count(Rules.config("Robots10",3),5)>0,
 "cooperative wave configuration still loads")
check(string.find(T.objective(65,{},{{ammo=60}},20),"инженер")~=nil,
 "urgent base damage takes priority")
check(string.find(T.objective(150,{},{{ammo=60}},20),"укрепления")~=nil,
 "team builder objective is displayed")
check(string.find(T.objective(150,{
 {health=75,level=1},{health=75,level=1}},{{ammo=3}},0),"Снабженец")~=nil,
 "low charges request team supplies")
print("[TACTICS] Pure rules smoke test completed. Live navigation and multiplayer remain unverified.")
