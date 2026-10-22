-- Manual Roblox Studio ServerScriptService smoke harness (NOT active in the game).
-- Temporarily place this script in ServerScriptService after Rojo synchronization.
-- No user accounts or DataStores required; errors raise assertions.
local Arcade=require(script.Parent:WaitForChild("ArcadeLibrary"))
local Retro=require(script.Parent:WaitForChild("RetroEngine"))
local Books=require(script.Parent:WaitForChild("BookCatalog"))
local rng=Random.new(42321)

local total=0
local function expect(value,message)
    total+=1
    assert(value,message or ("Test failed #" .. total))
end
for _,name in ipairs(Arcade.modes) do
    for difficulty=1,5 do
        local data,answer=Arcade.generate(name,rng,difficulty)
        expect(data.kind==name,"Wrong mode")
        expect(Arcade.check(name,answer,answer)==true,"Correct answer rejected")
        local wrong=name=="Memory" and "bad" or -100
        expect(Arcade.check(name,answer,wrong)==false,"Wrong answer accepted")
        if name=="Attention" then
            expect(#data.cells==16,"Focus grid should have 16 cells")
            expect(answer>=1 and answer<=16,"Focus answer index out of range")
        elseif name=="Memory" then
            expect(#data.sequence>=4 and #data.sequence<=8,"Wrong memory length")
        elseif name=="Logic" or name=="Spatial" then
            expect(#data.choices==4,"Question needs 4 options")
            expect(table.find(data.choices,answer)~=nil,"Correct option missing")
        elseif name=="Switch" then
            expect(#data.choices==4 and answer>=1 and answer<=4,"Switch answer invalid")
        end
    end
end

local snake=Retro.newSnake(rng)
expect(snake.alive and #snake.body==3,"Invalid snake start")
expect(Retro.turnSnake(snake,"Left")==false,"Snake reverse should be illegal")
expect(Retro.turnSnake(snake,"Down")==true,"Snake turn failed")
Retro.stepSnake(snake,rng)
expect(snake.body[1][1]==7 and snake.body[1][2]==7,"Snake movement incorrect")
local steps=0
while snake.alive and steps<120 do
    Retro.stepSnake(snake,rng)
    steps+=1
end
expect(not snake.alive,"Snake must eventually collide with a wall")

local duel=Retro.newDuel(1,2,false)
local now=duel.started+1
local hp=duel.hp[2]
expect(Retro.actDuel(duel,1,"Punch",now),"Duel punch input rejected")
expect(duel.hp[2]==hp,"Punch across the arena should not hit")
duel.pos={5,7}
expect(Retro.actDuel(duel,2,"Block",now),"Block input rejected")
local ok=Retro.actDuel(duel,1,"Punch",now+1)
expect(ok and duel.hp[2]>0 and duel.hp[2]<hp,"Block should reduce but not negate damage")
expect(Retro.actDuel(duel,1,"Nonsense",now+2)==false,"Unknown duel action must fail")
Retro.timeoutDuel(duel,duel.started+duel.timeLimit+1)
expect(duel.ended,"Duel timed-out game should end")

for _,book in ipairs(Books.list()) do
    local full=Books.get(book.id)
    expect(full~=nil,"Book ID not retrievable")
    expect(#full.paragraphs>=4,"Book too short for paragraph search")
    expect(full.locateAnswer>=1 and full.locateAnswer<=#full.paragraphs,
        "Bad locate index")
    expect(#full.answers==4 and full.understandAnswer>=1 and full.understandAnswer<=4,
        "Bad reading-comprehension answers")
end

print("[YUGATNEO TEST] PASS: "..total.." arcade, retro and book catalog assertions.")
