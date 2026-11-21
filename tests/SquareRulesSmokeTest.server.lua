-- Manually insert this Script in ServerScriptService for Studio regression tests.
local Rules = require(game:GetService("ServerScriptService"):WaitForChild("SquareRules"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("SquareShared"):WaitForChild("SquareConfig"))

local function match()
    local s = Rules.new()
    for i=1,4 do assert(Rules.join(s,100+i)==i) end
    assert(Rules.start(s))
    assert(s.server==1 and s.receiver==4)
    return s
end

local s = match()
assert(Config.zone(-20,-20)==1 and Config.zone(20,-20)==2)
assert(Config.zone(-20,20)==3 and Config.zone(20,20)==4)
assert(Config.zone(0,0)==-1 and Config.zone(41,0)==0)
assert(Config.diagonal(1)==4 and Config.diagonal(2)==3)

assert(select(1,Rules.hit(s,1,"serve",0)))
assert(s.receiver==4 and s.isServe)
assert(Rules.bounce(s,4)=="continue" and s.bounceCount==1)
local allowed,reason=Rules.canHit(s,4,"foot")
assert(not allowed and reason=="early_foot")
assert(select(1,Rules.canHit(s,4,"head")))
assert(Rules.bounce(s,4)=="continue" and s.bounceCount==2)
assert(select(1,Rules.canHit(s,4,"foot")))
assert(Rules.bounce(s,4)=="goal" and s.missed[4]==1 and not s.out[4])

s=match()
assert(select(1,Rules.hit(s,1,"serve",4)))
assert(Rules.bounce(s,4)=="continue")
assert(Rules.bounce(s,4)=="continue")
assert(select(1,Rules.hit(s,4,"foot",2)))
assert(Rules.bounce(s,2)=="continue")
assert(Rules.bounce(s,2)=="goal" and s.missed[2]==1)

s=match()
assert(select(1,Rules.hit(s,1,"serve",4)))
assert(select(1,Rules.hit(s,4,"head",3)), "Volley header permitted")
assert(Rules.bounce(s,3)=="continue")
assert(Rules.bounce(s,3)=="goal")
assert(s.missed[3]==5 and s.out[3], "Instant elimination on header goal")

s=match()
assert(select(1,Rules.hit(s,1,"serve",4)))
assert(Rules.bounce(s,4)=="continue")
assert(Rules.bounce(s,4)=="continue")
assert(select(1,Rules.hit(s,4,"head",0)))
assert(Rules.bounce(s,-1)=="fault")
assert(s.missed[4]==1 and not s.out[4] and s.missed[1]==0)

s=match()
assert(not select(1,Rules.hit(s,2,"serve",1)))
assert(select(1,Rules.hit(s,1,"serve",4)))
assert(not select(1,Rules.hit(s,2,"head",4)))
assert(not select(1,Rules.hit(s,4,"foot",1)))
assert(not select(1,Rules.hit(s,4,"head",4)))
assert(not select(1,Rules.hit(s,4,"head",99)))

s=match()
s.out[4]=true
assert(Rules.beginServe(s,1))
assert(s.server==1 and s.receiver==2, "Fallback must exclude server")
assert(Rules.seatOf(s,101)==1)
assert(Rules.leave(s,101)==1 and Rules.seatOf(s,101)==0)
print("PASS: Four Square referee tests")
