-- Original 8-bit and 16-bit-inspired arcade rules. No external ROMs or brand assets.
local Retro = {}
local function key(x,y) return x .. ":" .. y end
local vectors = {Up = {0,-1}, Down = {0,1}, Left = {-1,0}, Right = {1,0}}
local opposite = {Up="Down",Down="Up",Left="Right",Right="Left"}

function Retro.newSnake(random)
    local state = {
        width = 14, height = 11,
        body = {{7,6},{6,6},{5,6}},
        direction = "Right", pending = "Right", alive = true, score = 0, food = nil,
    }
    Retro.placeFood(state,random)
    return state
end

function Retro.placeFood(state,random)
    local occupied, available = {}, {}
    for _, cell in ipairs(state.body) do occupied[key(cell[1],cell[2])] = true end
    for y=1,state.height do
        for x=1,state.width do
            if not occupied[key(x,y)] then table.insert(available,{x,y}) end
        end
    end
    if #available == 0 then state.alive = false state.food = nil return end
    state.food = available[random:NextInteger(1,#available)]
end

function Retro.turnSnake(state,direction)
    if not state.alive or type(direction) ~= "string" or not vectors[direction] then return false end
    if direction == opposite[state.direction] then return false end
    state.pending = direction
    return true
end

function Retro.stepSnake(state,random)
    if not state.alive then return end
    state.direction = state.pending
    local vector = vectors[state.direction]
    local x, y = state.body[1][1]+vector[1], state.body[1][2]+vector[2]
    if x < 1 or y < 1 or x > state.width or y > state.height then
        state.alive = false
        return
    end
    local eats = state.food and x == state.food[1] and y == state.food[2]
    -- The tail cell is legal only when it moves out on this same tick.
    for i,cell in ipairs(state.body) do
        if cell[1] == x and cell[2] == y and (eats or i < #state.body) then
            state.alive = false
            return
        end
    end
    table.insert(state.body,1,{x,y})
    if eats then
        state.score += 10
        Retro.placeFood(state,random)
    else
        table.remove(state.body)
    end
end

function Retro.newDuel(uidA, uidB, isBot)
    return {
        players = {uidA,uidB},
        isBot = isBot == true,
        pos = {3, 10},
        hp = {100,100},
        guardUntil = {0,0},
        cooldown = {0,0},
        timeLimit = 75,
        started = os.clock(),
        ended = false,
        victor = nil,
    }
end
function Retro.actDuel(state,index,action,now)
    if state.ended or index < 1 or index > 2 or type(action) ~= "string" then return false end
    if now < state.cooldown[index] then return false end
    local opponent = 3-index
    local x = state.pos[index]
    if action == "Left" or action == "Right" then
        local dir = action == "Left" and -1 or 1
        state.pos[index] = math.clamp(x+dir, 1, 12)
        state.cooldown[index] = now + 0.18
    elseif action == "Block" then
        state.guardUntil[index] = now + 0.7
        state.cooldown[index] = now + 0.4
    elseif action == "Punch" or action == "Kick" then
        local maxRange = action == "Punch" and 2 or 3
        local damage = action == "Punch" and 12 or 17
        if math.abs(x-state.pos[opponent]) <= maxRange then
            if now < state.guardUntil[opponent] then damage = math.floor(damage/4) end
            state.hp[opponent] = math.max(0,state.hp[opponent]-damage)
        end
        state.cooldown[index] = now + (action == "Punch" and 0.45 or 0.75)
    else
        return false
    end
    if state.hp[opponent] <= 0 then
        state.ended = true
        state.victor = index
    end
    return true
end

function Retro.timeoutDuel(state,now)
    if state.ended or now-state.started < state.timeLimit then return end
    state.ended = true
    if state.hp[1] > state.hp[2] then state.victor = 1
    elseif state.hp[2] > state.hp[1] then state.victor = 2 end
end
function Retro.publicDuel(state)
    return {
        pos = {state.pos[1],state.pos[2]},
        hp = {state.hp[1],state.hp[2]},
        guard = {state.guardUntil[1] > os.clock(),state.guardUntil[2] > os.clock()},
        players = state.players,
        isBot = state.isBot,
        remaining = math.max(0, math.ceil(state.timeLimit - (os.clock()-state.started))),
        ended = state.ended, victor = state.victor,
    }
end
return Retro
