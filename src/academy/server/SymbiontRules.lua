--!strict
-- Pure server-side rules: no instances, no DataStore, no client-authoritative actions.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Content = require(ReplicatedStorage:WaitForChild("SymbiontShared"):WaitForChild("AcademyContent"))

local Rules = {}

function Rules.newState()
    local state = {revision = 0, levels = {}}
    for _, levelId in ipairs(Content.order) do
        state.levels[levelId] = {
            done = {},
            selected = nil,
            completed = false,
            contributors = {},
        }
    end
    return state
end

function Rules.isUnlocked(state, levelId, actionId)
    local level = Content.levels[levelId]
    if not level or not level.actions[actionId] then
        return false, "Неизвестное задание."
    end
    local progress = state.levels[levelId]
    if not progress then
        return false, "Неизвестный уровень."
    end
    local action = level.actions[actionId]
    if progress.done[actionId] then
        return false, "Это действие уже выполнено."
    end
    if progress.completed then
        return false, "Эпизод уже пройден."
    end
    if action.group and progress.selected then
        return false, "Решение уже принято; другие варианты тоже могут быть разумными."
    end
    for _, requirement in ipairs(action.requires) do
        if not progress.done[requirement] then
            return false, "Сначала выполни предыдущие шаги. Подсказки есть на панели."
        end
    end
    return true, nil
end

function Rules.apply(state, levelId, actionId, userId)
    local allowed, why = Rules.isUnlocked(state, levelId, actionId)
    if not allowed then
        return false, why
    end
    local progress = state.levels[levelId]
    local level = Content.levels[levelId]
    local action = level.actions[actionId]
    progress.done[actionId] = true
    if action.group then
        progress.selected = actionId
    end
    if userId then
        progress.contributors[userId] = true
    end
    if (level.winAction and actionId == level.winAction)
        or (level.winGroup and action.group == level.winGroup) then
        progress.completed = true
    end
    state.revision += 1
    return true, action.feedback
end

function Rules.snapshot(state)
    local levels = {}
    for _, levelId in ipairs(Content.order) do
        local progress = state.levels[levelId]
        local contributorCount = 0
        for _ in pairs(progress.contributors) do
            contributorCount += 1
        end
        local done = {}
        for actionId, value in pairs(progress.done) do
            if value then
                done[actionId] = true
            end
        end
        levels[levelId] = {
            done = done,
            selected = progress.selected,
            completed = progress.completed,
            contributors = contributorCount,
        }
    end
    return {revision = state.revision, levels = levels}
end

return Rules
