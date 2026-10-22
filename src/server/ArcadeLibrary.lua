-- Pure cognitive challenge generator: testable with deterministic Random.new(seed).
-- Every public challenge has a private answer retained by the server.
local Arcade = {}
local modes = {"Memory", "Attention", "Logic", "Switch", "Spatial"}
Arcade.modes = modes
local function pick(rng, list)
    return list[rng:NextInteger(1, #list)]
end
local function randomWrong(rng, answer, count, low, high)
    local choices, used = {answer}, {[answer] = true}
    while #choices < count do
        local candidate = rng:NextInteger(low, high)
        if not used[candidate] then
            used[candidate] = true
            table.insert(choices, candidate)
        end
    end
    for i = #choices, 2, -1 do
        local j = rng:NextInteger(1, i)
        choices[i], choices[j] = choices[j], choices[i]
    end
    return choices
end

function Arcade.generate(mode, rng, level)
    level = math.clamp(math.floor(tonumber(level) or 1), 1, 5)
    assert(table.find(modes, mode), "Unknown cognitive game mode")
    if mode == "Memory" then
        local sequence = {}
        for i = 1, math.min(3 + level, 8) do
            table.insert(sequence, rng:NextInteger(1, 6))
        end
        return {
            kind = mode, prompt = "Remember the sequence; reproduce it after it disappears.",
            sequence = sequence, visibleSeconds = 3 + #sequence * 0.6,
        }, table.concat(sequence, ",")
    elseif mode == "Attention" then
        local symbols = {"◆", "●", "■", "▲", "★", "⬢"}
        local common, odd = rng:NextInteger(1, #symbols), rng:NextInteger(1, #symbols)
        if odd == common then odd = (odd % #symbols) + 1 end
        local answer = rng:NextInteger(1, 16)
        local grid = {}
        for i = 1, 16 do grid[i] = symbols[i == answer and odd or common] end
        return {
            kind = mode, prompt = "Find the one different symbol (1–16), from left to right.",
            cells = grid,
        }, answer
    elseif mode == "Logic" then
        local start = rng:NextInteger(2, 16)
        local gap = rng:NextInteger(2, 7)
        local delta = rng:NextInteger(1, 3)
        local values = {}
        local x = start
        for i = 1, 4 do
            table.insert(values, x)
            x += gap
            if level >= 3 then gap += delta end
        end
        return {
            kind = mode, prompt = "What number continues the sequence?",
            values = values, choices = randomWrong(rng, x, 4, math.max(1,x-12), x+12),
        }, x
    elseif mode == "Switch" then
        local a = rng:NextInteger(1, 4)
        local b = rng:NextInteger(1, 4)
        local which = rng:NextInteger(1, 2)
        local colorWords = {"Red", "Blue", "Green", "Gold"}
        local shapes = {"Circle", "Square", "Triangle", "Star"}
        local target = which == 1 and a or b
        return {
            kind = mode, prompt = which == 1 and "RULE: pick the COLOR, ignore the shape."
                or "RULE: pick the SHAPE, ignore the color.",
            stimulus = colorWords[a] .. " " .. shapes[b],
            choices = which == 1 and colorWords or shapes,
            answerType = which == 1 and "Color" or "Shape",
        }, target
    else -- Spatial: count moves to shortest route across a simple grid.
        local width = rng:NextInteger(3, 5)
        local height = rng:NextInteger(3, 5)
        local x, y = rng:NextInteger(1, width), rng:NextInteger(1, height)
        local targetX = x == 1 and width or 1
        local targetY = y == 1 and height or 1
        local answer = math.abs(targetX-x) + math.abs(targetY-y)
        return {
            kind = mode, prompt = "Shortest grid route: moves up/down/left/right only.",
            gridSize = {width, height}, start = {x, y},
            goal = {targetX, targetY}, choices = randomWrong(rng, answer, 4, 1, 10),
        }, answer
    end
end

function Arcade.check(kind, secret, response)
    if kind == "Memory" then
        if type(response) ~= "string" or #response > 50 then return false end
        return response == secret
    end
    if type(response) ~= "number" or response ~= response or response == math.huge then
        return false
    end
    if response % 1 ~= 0 then return false end
    return response == secret
end

return Arcade
