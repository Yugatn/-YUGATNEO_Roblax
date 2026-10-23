-- Temporary Script for Roblox Studio ServerScriptService; remove after test.
-- Tests generated world objects, not actual player access or full UI rendering.
local world=workspace:WaitForChild("STORY_X_INTERACTIVE_GALLERY",15)
assert(world,"Missing STORY_X_INTERACTIVE_GALLERY")
local function check(test,label)
    assert(test,"[GALLERY SCENE FAIL] "..label)
    print("[GALLERY SCENE PASS] "..label)
end
for _,partName in ipairs({
    "GalleryFloor","GalleryEntrance","RoadsideGalleryTerminal",
    "CuratorConsole","Exit_Spiral","Exit_Matrix","Exit_Library","Exit_Chess",
}) do
    check(world:FindFirstChild(partName)~=nil,"object: "..partName)
end
local catalog=require(script.Parent:WaitForChild("StoryXGalleryCatalog"))
for _,entry in ipairs(catalog.entries) do
    local model=world:FindFirstChild("Artwork_"..entry.id)
    check(model~=nil,"narrative exhibit: "..entry.id)
    if model then
        local painting=model:FindFirstChild("PixelCanvas")
        local stand=model:FindFirstChild("ReadExhibit")
        check(painting and painting:FindFirstChildOfClass("SurfaceGui")~=nil,
            "rendered 2D artwork: "..entry.id)
        check(stand and stand:FindFirstChildOfClass("ProximityPrompt")~=nil,
            "interaction prompt: "..entry.id)
    end
end
print("[GALLERY SCENE] Objects exist; test reachability and UI with actual players separately.")
