-- Manual Studio test: copy this Lua code into ServerScriptService as a temporary
-- Script, press Play, inspect Output and delete the temporary Script afterward.
local Catalog=require(script.Parent:WaitForChild("StoryXGalleryCatalog"))
local function check(condition,message)
 assert(condition,"[Gallery FAIL] "..message)
 print("[Gallery PASS] "..message)
end
check(#Catalog.exhibits==10,"all ten authored exhibition chapters included")
local seen={}
for _,entry in ipairs(Catalog.exhibits) do
 check(not seen[entry.id],"unique identifier "..entry.id)
 seen[entry.id]=true
 check(Catalog.find(entry.id)==entry,"lookup for "..entry.id)
 check(Catalog.routes[entry.route]~=nil,"connected route "..entry.id)
 check(type(entry.title)=="string" and #entry.title>3,"title "..entry.id)
 check(type(entry.story)=="string" and #entry.story>80,"readable story "..entry.id)
 check(type(entry.caption)=="string" and #entry.caption>45,"caption "..entry.id)
 check(type(entry.answer)=="number" and entry.options[entry.answer]~=nil,"quiz options "..entry.id)
 check(Catalog.check(entry.id,entry.answer),"correct answer "..entry.id)
 check(not Catalog.check(entry.id,entry.answer%3+1),"wrong answer rejected "..entry.id)
 local public=Catalog.public(entry)
 check(public.answer==nil,"answer not leaked to visitor for "..entry.id)
 check(public.id==entry.id and public.title==entry.title,"public data "..entry.id)
end
check(Catalog.find("unauthorized")==nil,"unknown gallery scene denied")
check(not Catalog.check("other",999),"invalid answer rejected")

local world=workspace:WaitForChild("STORY_X_GALLERY",15)
check(world~=nil,"procedural world created")
if world then
 check(world:FindFirstChild("MuseumFloor")~=nil,"safe walking floor")
 check(world:FindFirstChild("SpiralGalleryPortal")~=nil,"spiral entry kiosk")
 check(world:FindFirstChild("ToSpiral")~=nil,"return from exhibit to spiral")
 for _,entry in ipairs(Catalog.exhibits) do
  local art=world:FindFirstChild("Artwork_"..entry.id)
  local kiosk=world:FindFirstChild("Kiosk_"..entry.id)
  check(art~=nil,"canvas "..entry.id)
  check(art and art:FindFirstChildOfClass("SurfaceGui")~=nil,
   "renderable art "..entry.id)
  check(kiosk and kiosk:FindFirstChildOfClass("ProximityPrompt")~=nil,
   "interactive art kiosk "..entry.id)
 end
end
print("[STORY X] Test source prepared. Real multiplayer and device checks still necessary.")
