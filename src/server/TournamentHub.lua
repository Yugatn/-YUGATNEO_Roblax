-- In-server chess matchmaking and four-player knockout brackets.
local Players = game:GetService("Players")
local Hub = {}
Hub.__index = Hub

local function remove(items, uid)
    for i = #items, 1, -1 do
        if items[i] == uid then table.remove(items, i) end
    end
end
local function contains(items, uid)
    for _, id in ipairs(items) do if id == uid then return true end end
    return false
end

function Hub.new(tables, membership, event, onChange)
    return setmetatable({
        tables = tables, membership = membership, event = event, onChange = onChange,
        casual = {}, signup = {}, current = nil, assignments = {}, serial = 0,
    }, Hub)
end

function Hub:name(uid)
    local p = uid and Players:GetPlayerByUserId(uid)
    return p and p.DisplayName or (uid and ("User " .. uid) or "—")
end

function Hub:snapshot()
    local t = self.current
    if not t then
        return {stage = "Registration", casual = #self.casual, signedUp = #self.signup}
    end
    return {
        stage = t.stage, edition = t.edition, casual = #self.casual, signedUp = #self.signup,
        first = self:name(t.p[1]) .. " vs " .. self:name(t.p[2]),
        second = self:name(t.p[3]) .. " vs " .. self:name(t.p[4]),
        winner1 = t.w[1] and self:name(t.w[1]) or "Pending",
        winner2 = t.w[2] and self:name(t.w[2]) or "Pending",
        champion = t.champion and self:name(t.champion) or nil,
    }
end

function Hub:pair(id, white, black)
    local t = self.tables[id]
    if not t or t.state ~= "Idle" then return false end
    if self.membership[white] or self.membership[black] then return false end
    local a, b = Players:GetPlayerByUserId(white), Players:GetPlayerByUserId(black)
    if not a or not b then return false end
    if not t:requestJoin(a, {mode = "Classic"}) then return false end
    if not t:requestJoin(b, {mode = "Classic"}) then
        t:cancelWaiting(a)
        return false
    end
    t:setReady(a, true)
    t:setReady(b, true)
    return true
end

function Hub:casualNext()
    if self.tables["3"].state ~= "Idle" or #self.casual < 2 then return end
    local a, b = table.remove(self.casual, 1), table.remove(self.casual, 1)
    if not self:pair("3", a, b) then
        -- Roll back if the match could not start, preserving the waiting order.
        if Players:GetPlayerByUserId(b) and not self.membership[b] then table.insert(self.casual, 1, b) end
        if Players:GetPlayerByUserId(a) and not self.membership[a] then table.insert(self.casual, 1, a) end
    end
    self.onChange()
end

function Hub:seriesMatch(id, white, black, round, idx)
    local record = {white = white, black = black, round = round, idx = idx}
    self.assignments[id] = record
    if self:pair(id, white, black) then return true end
    self.assignments[id] = nil
    return false
end

function Hub:final()
    local t = self.current
    if not t or t.stage ~= "Semifinals" or not t.w[1] or not t.w[2] then return end
    if self.tables["1"].state ~= "Idle" then return end
    if self:seriesMatch("1", t.w[1], t.w[2], "Final", 1) then
        t.stage = "Final"
    end
    self.onChange()
end

function Hub:nextTournament()
    if self.current or #self.signup < 4 then return end
    if self.tables["1"].state ~= "Idle" or self.tables["2"].state ~= "Idle" then return end
    local group = {}
    while #group < 4 and #self.signup > 0 do
        local id = table.remove(self.signup, 1)
        if Players:GetPlayerByUserId(id) and not self.membership[id] then table.insert(group, id) end
    end
    if #group < 4 then
        for i = #group, 1, -1 do table.insert(self.signup, 1, group[i]) end
        self.onChange()
        return
    end
    self.serial += 1
    self.current = {edition = self.serial, stage = "Semifinals", p = group, w = {}}
    local a = self:seriesMatch("1", group[1], group[2], "Semi", 1)
    local b = self:seriesMatch("2", group[3], group[4], "Semi", 2)
    if not a or not b then
        -- Exceptional disconnection, retain matches already started as exhibition.
        self.assignments["1"] = nil
        self.assignments["2"] = nil
        for _, id in ipairs(group) do
            if Players:GetPlayerByUserId(id) and not self.membership[id] then
                table.insert(self.signup, id)
            end
        end
        self.current = nil
    end
    self.onChange()
end

function Hub:join(player, tournament)
    local uid = player.UserId
    if self.membership[uid] or contains(self.casual, uid) or contains(self.signup, uid) then return false end
    if tournament then
        table.insert(self.signup, uid)
        self:nextTournament()
    else
        table.insert(self.casual, uid)
        self:casualNext()
    end
    self.onChange()
    return true
end

function Hub:leave(uid)
    remove(self.casual, uid)
    remove(self.signup, uid)
    self.onChange()
end

function Hub:finished(result)
    local winner = result.winner == "White" and result.white
        or (result.winner == "Black" and result.black or nil)
    local assignment, current = self.assignments[result.tableId], self.current
    if assignment and current then
        if winner then
            if assignment.round == "Semi" then
                current.w[assignment.idx] = winner
            else
                current.champion = winner
                current.stage = "Champion"
                self.event:FireAllClients("TournamentNotice", nil, "Champion: " .. self:name(winner))
            end
        else
            self.event:FireAllClients("TournamentNotice", nil, "Draw: rematch on table " .. result.tableId)
        end
    end
    self.onChange()
    task.delay(12, function()
        local tableObj = self.tables[result.tableId]
        if tableObj.state == "Finished" then tableObj:clearFinished(nil) end
        if self.assignments[result.tableId] == assignment then self.assignments[result.tableId] = nil end
        if assignment and not winner and self.current == current then
            self:seriesMatch(result.tableId, assignment.white, assignment.black, assignment.round, assignment.idx)
        elseif current and self.current == current and current.stage == "Champion" then
            self.current = nil
        end
        self:final()
        self:nextTournament()
        self:casualNext()
        self.onChange()
    end)
    return winner
end
return Hub
