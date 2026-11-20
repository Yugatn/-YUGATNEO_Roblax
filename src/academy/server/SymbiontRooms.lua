--!strict
-- Authoritative, in-memory room registry. Player identity never leaves this module.
local Rules = require(script.Parent:WaitForChild("SymbiontRules"))

local Rooms = {}

function Rooms.new(maxRooms, maxPlayers)
    assert(type(maxRooms) == "number" and maxRooms > 0 and maxRooms % 1 == 0)
    assert(type(maxPlayers) == "number" and maxPlayers > 0 and maxPlayers <= 4)
    return {
        maxRooms = maxRooms,
        maxPlayers = maxPlayers,
        rooms = {},
        playerRoom = {},
        sequence = 0,
    }
end

function Rooms.getRoom(registry, roomId)
    return registry.rooms[roomId]
end

function Rooms.roomOf(registry, userId)
    return registry.playerRoom[userId]
end

function Rooms.join(registry, userId, roomId)
    if type(userId) ~= "number" or type(roomId) ~= "number"
        or roomId % 1 ~= 0 or roomId < 1 or roomId > registry.maxRooms then
        return false, "Недоступная комната."
    end
    if registry.playerRoom[userId] ~= nil then
        return false, "Сначала выйди из своей комнаты."
    end
    local room = registry.rooms[roomId]
    if room and #room.members >= registry.maxPlayers then
        return false, "В комнате уже четыре участника."
    end
    if not room then
        room = {members = {}, leader = userId, state = Rules.newState()}
        registry.rooms[roomId] = room
    end
    table.insert(room.members, userId)
    registry.playerRoom[userId] = roomId
    registry.sequence += 1
    room.state.revision += 1
    return true, "Ты вошёл в команду №" .. tostring(roomId) .. "."
end

function Rooms.leave(registry, userId)
    local roomId = registry.playerRoom[userId]
    if not roomId then
        return false, "Ты пока не выбрал команду.", nil
    end
    local room = registry.rooms[roomId]
    registry.playerRoom[userId] = nil
    if not room then
        registry.sequence += 1
        return false, "Комната больше не существует.", roomId
    end
    for index, memberId in ipairs(room.members) do
        if memberId == userId then
            table.remove(room.members, index)
            break
        end
    end
    if #room.members == 0 then
        -- Freeing the last member deletes progress and makes a clean room for newcomers.
        registry.rooms[roomId] = nil
    else
        if room.leader == userId then
            room.leader = room.members[1]
        end
        room.state.revision += 1
    end
    registry.sequence += 1
    return true, "Ты вернулся в общий холл.", roomId
end

function Rooms.reset(registry, userId)
    local roomId = registry.playerRoom[userId]
    local room = roomId and registry.rooms[roomId]
    if not room then
        return false, "Сначала выбери комнату.", nil
    end
    if room.leader ~= userId then
        return false, "Начать заново может только организатор команды.", roomId
    end
    local nextRevision = room.state.revision + 1
    room.state = Rules.newState()
    room.state.revision = nextRevision
    registry.sequence += 1
    return true, "Задания команды сброшены. Можно начать сначала.", roomId
end

function Rooms.apply(registry, userId, roomId, levelId, actionId)
    if registry.playerRoom[userId] ~= roomId then
        return false, "Это задание другой команды."
    end
    local room = registry.rooms[roomId]
    if not room then
        return false, "Комната не найдена."
    end
    local ok, message = Rules.apply(room.state, levelId, actionId, userId)
    if ok then
        registry.sequence += 1
    end
    return ok, message
end

function Rooms.snapshot(registry, userId)
    local roomId = registry.playerRoom[userId]
    local room = roomId and registry.rooms[roomId]
    if not room then
        return {
            serverSeq = registry.sequence,
            roomId = 0,
            revision = 0,
            members = 0,
            maxMembers = registry.maxPlayers,
            isLeader = false,
            levels = {},
        }
    end
    local summary = Rules.snapshot(room.state)
    return {
        serverSeq = registry.sequence,
        roomId = roomId,
        revision = summary.revision,
        members = #room.members,
        maxMembers = registry.maxPlayers,
        isLeader = room.leader == userId,
        levels = summary.levels,
    }
end

return Rooms
