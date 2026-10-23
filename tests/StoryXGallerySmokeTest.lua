-- Copy this temporary Script to ServerScriptService in Roblox Studio.
-- Checks pure Story X catalog and asset allowlist, not engine rendering/physics.
local Catalog=require(script.Parent:WaitForChild("StoryXGalleryCatalog"))
local Assets=require(script.Parent:WaitForChild("StoryXGalleryAssets"))
local function check(value,message)
    assert(value,"[GALLERY FAIL] "..message)
    print("[GALLERY PASS]",message)
end
check(#Catalog.entries==8,"eight authored scenes")
local seen={}
for _,e in ipairs(Catalog.entries) do
    check(not seen[e.id],"unique exhibit "..e.id)
    seen[e.id]=true
    check(type(e.scene)=="string" and #e.scene>120,"narrative content "..e.id)
    check(type(e.pattern)=="table" and #e.pattern==9,"pixel composition "..e.id)
    for _,row in ipairs(e.pattern) do
        check(#row==9,"pixel row width: "..e.id)
    end
    local pub=Catalog.public(e)
    check(pub and pub.correct==nil,"server does not leak answer key: "..e.id)
    check(#pub.options==3 and #pub.question>0,"comprehension prompt "..e.id)
    check(Catalog.verify(e.id,e.correct),"correct answer accepted: "..e.id)
    check(not Catalog.verify(e.id,(e.correct%3)+1),"wrong answer rejected: "..e.id)
    check(Assets.get(e.id)==nil,"unreviewed Roblox image cannot load: "..e.id)
end
check(Catalog.get("unknown")==nil,"unknown exhibit rejected")
check(not Catalog.verify("observer","1"),"string answers rejected")
check(not Catalog.verify("observer",math.huge),"nonfinite answer rejected")
print("[GALLERY] Module tests finished; gallery rendering and two-player tests require Studio.")
