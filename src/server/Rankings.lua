-- Roblox OrderedDataStore global wins, with in-memory fallback if Studio API access is off.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Ranking = {}
local store = DataStoreService:GetOrderedDataStore("YUGATNEO_CHESS_WINS_V1")
local session = {}

function Ranking.awardWinner(uid)
    if type(uid) ~= "number" then return end
    session[uid] = (session[uid] or 0) + 1
    task.spawn(function()
        local ok, err = pcall(function()
            store:UpdateAsync(tostring(uid), function(old)
                return math.max(0, tonumber(old) or 0) + 1
            end)
        end)
        if not ok then warn("Chess data store unavailable: ", err) end
    end)
end

function Ranking.session()
    local rows = {}
    for uid, wins in pairs(session) do
        local player = Players:GetPlayerByUserId(uid)
        table.insert(rows, {id = uid, name = player and player.DisplayName or tostring(uid), wins = wins})
    end
    table.sort(rows, function(a,b)
        if a.wins == b.wins then return a.id < b.id end
        return a.wins > b.wins
    end)
    return rows
end

function Ranking.globalTop()
    local ok, pages = pcall(function() return store:GetSortedAsync(false, 10) end)
    if not ok then return {} end
    local rows = {}
    for rank, entry in ipairs(pages:GetCurrentPage()) do
        local uid = tonumber(entry.key)
        local player = uid and Players:GetPlayerByUserId(uid)
        local name = player and player.DisplayName or tostring(entry.key)
        if uid and not player then
            local nameOk, fetched = pcall(function() return Players:GetNameFromUserIdAsync(uid) end)
            if nameOk then name = fetched end
        end
        table.insert(rows, {rank = rank, name = name, wins = entry.value})
    end
    return rows
end
return Ranking
