-- Manual Roblox Studio smoke harness. Copy this file as a temporary Script in
-- ServerScriptService, then press Play. Remove after testing.
-- Tests only PURE module invariants; does not verify multiplayer, HTTP or DataStore.
local Catalog = require(script.Parent:WaitForChild("LibraryCatalog"))
local Arcade = require(script.Parent:WaitForChild("ArcadeLibrary"))
local Retro = require(script.Parent:WaitForChild("RetroEngine"))
local rng = Random.new(4242)

local function check(ok, description)
    assert(ok, "[StoryX Test] " .. description)
    print("[StoryX PASS]", description)
end

check(#Catalog.books >= 4,"book catalog contains >=4 original works")
for _, book in ipairs(Catalog.books) do
    check(#book.paragraphs >= 4,"book has numbered paragraphs: "..book.id)
    check(Catalog.get(book.id)==book,"lookup resolves "..book.id)
    for _, q in ipairs(book.questions) do
        local candidate={bookId=book.id,paragraph=q.paragraph,answer=q.answer}
        check(Catalog.check(candidate,book.id,q.paragraph,q.answer),"accepts real answer")
        check(not Catalog.check(candidate,book.id,q.paragraph+1,q.answer),"rejects wrong paragraph")
        check(not Catalog.check(candidate,book.id,q.paragraph,q.answer%#q.options+1),"rejects wrong meaning answer")
    end
end

for _,mode in ipairs(Arcade.modes) do
    local public,answer=Arcade.generate(mode,rng,2)
    check(public.kind==mode,"generator produces "..mode)
    check(Arcade.check(mode,answer,answer),"correct response is accepted "..mode)
end

local snake=Retro.newSnake(rng)
check(snake.alive==true and #snake.body==3,"retro snake initializes")
check(Retro.turnSnake(snake,"Left")==false,"retro snake rejects reversal")
Retro.stepSnake(snake,rng)
check(snake.body[1][1]==8,"retro snake moves forward one cell")
local duel=Retro.newDuel(1,0,true)
check(Retro.actDuel(duel,1,"Right",10)==true,"retro duel accepts legal movement")
check(Retro.actDuel(duel,1,"Teleport",11)==false,"retro duel rejects unknown action")
print("[StoryX] Pure-library smoke checks passed. RUN MULTIPLAYER TESTS SEPARATELY.")
