-- YUGATNEO LightCycle: deterministic grid simulation, no physics damage.
-- No Roblox services: call from a server Script; clients cannot write match state.
local Engine = {}
local V = {Up={0,-1},Down={0,1},Left={-1,0},Right={1,0}}
local opposite = {Up="Down",Down="Up",Left="Right",Right="Left"}
local function key(x,y) return x..":"..y end
local function spawnAt(n,w,h)
    local midX,midY=math.floor(w/2),math.floor(h/2)
    local spots={
        {3,3,"Right"}, {w-2,h-2,"Left"},
        {w-2,3,"Left"}, {3,h-2,"Right"},
        {midX,3,"Down"}, {midX,h-2,"Up"},
    }
    return spots[n]
end
function Engine.newMatch(ids,w,h)
    assert(type(ids)=="table" and #ids>=1 and #ids<=6, "1 to 6 riders")
    w,h=w or 34,h or 22
    assert(w>=16 and h>=12,"arena too small")
    local m={width=w,height=h,riders={},occupied={},roundTicks=0,over=false,
        winner=nil,draw=false,count=#ids,maxTicks=750}
    local seen={}
    for i,uid in ipairs(ids) do
        assert(type(uid)=="number" and not seen[uid],"unique numeric rider ids")
        seen[uid]=true
        local s=spawnAt(i,w,h)
        m.riders[uid]={x=s[1],y=s[2],direction=s[3],queued=s[3],
            alive=true,lastTurnTick=-1,trail={{s[1],s[2]}}}
        m.occupied[key(s[1],s[2])]=uid
    end
    return m
end
function Engine.turn(m,uid,dir)
    local p=m.riders[uid]
    if m.over or not p or not p.alive or not V[dir] then return false end
    if p.lastTurnTick==m.roundTicks or opposite[p.direction]==dir then return false end
    p.queued=dir
    p.lastTurnTick=m.roundTicks
    return true
end
function Engine.step(m)
    if m.over then return {} end
    m.roundTicks+=1
    local nextMove,dead,targets,events={},{},{},{}
    for uid,p in pairs(m.riders) do
        if p.alive then
            local vec=V[p.queued]
            local nx,ny=p.x+vec[1],p.y+vec[2]
            nextMove[uid]={nx,ny}
            local k=key(nx,ny)
            targets[k]=(targets[k] or 0)+1
            if nx<1 or nx>m.width or ny<1 or ny>m.height or m.occupied[k] then
                dead[uid]=true
            end
        end
    end
    for uid,pos in pairs(nextMove) do
        if targets[key(pos[1],pos[2])]>1 then dead[uid]=true end
    end
    for uid,p in pairs(m.riders) do
        if p.alive then
            if dead[uid] then
                p.alive=false
                table.insert(events,{id=uid,dead=true})
            else
                local pos=nextMove[uid]
                p.x,p.y=pos[1],pos[2]
                p.direction=p.queued
                m.occupied[key(p.x,p.y)]=uid
                table.insert(p.trail,{p.x,p.y})
                table.insert(events,{id=uid,x=p.x,y=p.y,direction=p.direction})
            end
        end
    end
    local survivors={}
    for uid,p in pairs(m.riders) do if p.alive then table.insert(survivors,uid) end end
    if (#survivors<=1 and (m.count>1 or #survivors==0)) or m.roundTicks>=m.maxTicks then
        m.over=true
        m.winner=(#survivors==1) and survivors[1] or nil
        m.draw=m.winner==nil
    end
    return events
end
function Engine.public(m)
    local riders={}
    for uid,p in pairs(m.riders) do
        riders[uid]={x=p.x,y=p.y,direction=p.direction,alive=p.alive}
    end
    return {width=m.width,height=m.height,tick=m.roundTicks,over=m.over,
        winner=m.winner,draw=m.draw,riders=riders}
end
return Engine
