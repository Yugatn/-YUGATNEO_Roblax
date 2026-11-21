--!strict
-- Pure referee rules. No client commands are trusted; the server checks physical contact.
local Rules = {}

local function alive(state, seat)
    return type(seat) == "number" and seat % 1 == 0 and seat >= 1 and seat <= 4
        and state.players[seat] ~= nil and not state.out[seat]
end

function Rules.new()
    return {
        players = {}, missed = {}, out = {}, phase = "waiting",
        server = 1, receiver = 0, lastHitter = 0, lastHit = "none",
        bounceCount = 0, lastBounceZone = 0, isServe = false,
        winner = 0, round = 0, revision = 0, message = "Ожидание четырёх игроков.",
    }
end

function Rules.seatOf(state, userId)
    for i = 1, 4 do
        if state.players[i] == userId then return i end
    end
    return 0
end

function Rules.join(state, userId)
    local old = Rules.seatOf(state, userId)
    if old > 0 then return old end
    if state.phase ~= "waiting" and state.phase ~= "finished" then return 0 end
    for i = 1, 4 do
        if state.players[i] == nil then
            state.players[i] = userId
            state.missed[i] = 0
            state.out[i] = false
            state.revision += 1
            return i
        end
    end
    return 0
end

function Rules.leave(state, userId)
    local seat = Rules.seatOf(state, userId)
    if seat == 0 then return 0 end
    state.players[seat] = nil
    state.out[seat] = true
    state.revision += 1
    if state.phase == "waiting" or state.phase == "finished" then
        state.phase = "waiting"
        state.message = "Для игры нужно четыре участника."
    end
    return seat
end

function Rules.activeCount(state)
    local count, last = 0, 0
    for i = 1, 4 do
        if alive(state, i) then
            count += 1
            last = i
        end
    end
    return count, last
end

function Rules.nextSeat(state, preferred)
    -- The first serve is strictly diagonal. Later use diagonal when still active,
    -- otherwise select the next remaining participant clockwise.
    if alive(state, preferred) then return preferred end
    for step = 1, 4 do
        local seat = ((preferred + step - 2) % 4) + 1
        if alive(state, seat) then return seat end
    end
    return 0
end

function Rules.beginServe(state, preferred)
    local seat = Rules.nextSeat(state, preferred)
    if seat == 0 then
        state.phase = "waiting"
        return false
    end
    state.server = seat
    local diagonal = ({[1]=4, [2]=3, [3]=2, [4]=1})[seat]
    local target = if alive(state, diagonal) then diagonal else 0
    if target == 0 then
        for step=1,3 do
            local candidate = ((seat + step - 1) % 4) + 1
            if alive(state, candidate) then
                target = candidate
                break
            end
        end
    end
    if target == 0 then
        state.phase = "finished"
        state.winner = seat
        return false
    end
    state.receiver = target
    state.phase = "serve"
    state.isServe = false
    state.lastHitter = 0
    state.lastHit = "none"
    state.bounceCount = 0
    state.lastBounceZone = 0
    state.round += 1
    state.revision += 1
    state.message = "Игрок " .. seat .. " подаёт по диагонали игроку " .. target .. "."
    return true
end

function Rules.start(state)
    for i = 1, 4 do
        if state.players[i] == nil then return false end
    end
    state.missed = {}
    state.out = {}
    for i=1,4 do state.missed[i] = 0; state.out[i] = false end
    state.winner = 0
    state.round = 0
    state.phase = "waiting"
    return Rules.beginServe(state, 1)
end

function Rules.canHit(state, seat, kind)
    if not alive(state, seat) then return false, "not_playing" end
    if state.phase == "serve" then
        if kind == "serve" and seat == state.server then return true, "serve" end
        return false, "not_server"
    end
    if state.phase ~= "flight" and state.phase ~= "bounce" then
        return false, "no_ball"
    end
    if seat ~= state.receiver then return false, "not_receiver" end
    if kind ~= "foot" and kind ~= "head" then return false, "bad_kind" end
    if kind == "foot" then
        local needed = if state.isServe then 2 else 1
        if state.bounceCount < needed then return false, "early_foot" end
    end
    return true, "ok"
end

function Rules.hit(state, seat, kind, target)
    local ok, reason = Rules.canHit(state, seat, kind)
    if not ok then return false, reason end
    if kind == "serve" then
        target = state.receiver
    else
        if type(target) ~= "number" or target % 1 ~= 0 or target < 0
            or target > 4 or target == seat
            or (target > 0 and not alive(state, target)) then
            return false, "bad_target"
        end
    end
    state.phase = "flight"
    state.receiver = target
    state.lastHitter = seat
    state.lastHit = kind
    state.bounceCount = 0
    state.lastBounceZone = 0
    state.isServe = (kind == "serve")
    state.message = if kind == "head" then
        "Игрок " .. seat .. " бьёт головой! Если забьёт — мгновенное выбывание."
        else "Мяч направлен к квадрату " .. target .. "."
    state.revision += 1
    return true, "ok"
end

function Rules.penalty(state, seat, reason, forceSingle)
    if not alive(state, seat) then return 0 end
    -- A successful header goal awards five conceded goals and an immediate exit.
    local headerGoal = not forceSingle and state.lastHit == "head"
        and state.lastHitter > 0 and state.lastHitter ~= seat
    local points = if headerGoal then 5 else 1
    state.missed[seat] = (state.missed[seat] or 0) + points
    if state.missed[seat] >= 5 then state.out[seat] = true end
    state.phase = "pause"
    state.message = "Игрок " .. seat .. ": " .. reason .. " (+" .. points ..
        " пропущено, всего " .. state.missed[seat] .. "/5)." ..
        (if state.out[seat] then " Игрок выбыл." else "")
    state.revision += 1
    local n, winner = Rules.activeCount(state)
    if n <= 1 then
        state.phase = "finished"
        state.winner = winner
        state.message ..= if winner > 0 then " Победил игрок " .. winner .. "!" else " Матч окончен."
    end
    return points
end

function Rules.bounce(state, zone)
    if state.phase ~= "flight" and state.phase ~= "bounce" then return "ignored" end
    if zone == -1 then
        Rules.penalty(state, state.lastHitter, "Попадание в центральный квадрат", true)
        return "fault"
    end
    if zone == 0 or not alive(state, zone) or zone == state.lastHitter then
        Rules.penalty(state, state.lastHitter, "Мяч вне допустимого квадрата", true)
        return "fault"
    end
    if state.isServe and state.receiver ~= zone then
        Rules.penalty(state, state.lastHitter, "Подача не по диагонали", true)
        return "fault"
    end
    state.receiver = zone
    state.lastBounceZone = zone
    state.bounceCount += 1
    state.revision += 1
    if state.isServe then
        -- Opening serve exception: two bounces are mandatory. The THIRD is a goal.
        if state.bounceCount >= 3 then
            Rules.penalty(state, zone, "Не отбил после двух отскоков")
            return "goal"
        end
    elseif state.bounceCount >= 2 then
        Rules.penalty(state, zone, "Два отскока в своём квадрате")
        return "goal"
    end
    state.phase = "bounce"
    state.message = "Мяч в квадрате " .. zone .. ": " .. state.bounceCount ..
        (if state.isServe then "/2 обязательных отскока подачи." else "/2 — после второго гол.")
    return "continue"
end

function Rules.status(state, viewer)
    local scores, seats = {}, {}
    for i = 1, 4 do
        scores[i] = state.missed[i] or 0
        seats[i] = {
            occupied = state.players[i] ~= nil,
            out = state.out[i] == true,
            goals = state.missed[i] or 0,
        }
    end
    return {
        revision = state.revision, phase = state.phase,
        seat = Rules.seatOf(state, viewer), server = state.server,
        receiver = state.receiver, bounceCount = state.bounceCount,
        isServe = state.isServe, lastBounceZone = state.lastBounceZone,
        lastHitter = state.lastHitter, message = state.message,
        winner = state.winner, round = state.round, seats = seats,
    }
end

return Rules
