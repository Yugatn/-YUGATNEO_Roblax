-- Roblox mobile-friendly cognitive activities: sequence memory, attention, logic,
-- flexible rule switching, spatial route planning and duck-gallery timer.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("ArcadeEvent")

local gui = Instance.new("ScreenGui")
gui.Name = "YUGATNEO_CognitiveGames"
gui.ResetOnSpawn = false
gui.DisplayOrder = 80
gui.Parent = player:WaitForChild("PlayerGui")
local main = Instance.new("Frame")
main.Name = "PuzzleCabinet"
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Position = UDim2.fromScale(0.5,0.5)
main.Size = UDim2.new(0.92,0,0.77,0)
main.BackgroundColor3 = Color3.fromRGB(12, 20, 38)
main.BorderSizePixel = 0
main.Visible = false
main.Parent = gui
local constraint = Instance.new("UISizeConstraint")
constraint.MaxSize = Vector2.new(500, 550)
constraint.MinSize = Vector2.new(280, 300)
constraint.Parent = main
local rounding = Instance.new("UICorner")
rounding.CornerRadius = UDim.new(0,14)
rounding.Parent = main

local function text(parent, textValue, y, height, size)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Position = UDim2.new(0.04,0,y,0)
    l.Size = UDim2.new(0.92,0,height,0)
    l.Font = Enum.Font.GothamBold
    l.TextColor3 = Color3.fromRGB(195,248,234)
    l.TextSize = size or 16
    l.TextWrapped = true
    l.Text = textValue
    l.Parent = parent
    return l
end
local title = text(main,"STORY X / COGNITIVE ARCADE",0.025,0.09,20)
local question = text(main,"",0.135,0.16,16)
local subtitle = text(main,"",0.305,0.11,14)
local itemGrid = Instance.new("Frame")
itemGrid.Position = UDim2.new(0.07,0,0.43,0)
itemGrid.Size = UDim2.new(0.86,0,0.41,0)
itemGrid.BackgroundTransparency = 1
itemGrid.Parent = main
local grid = Instance.new("UIGridLayout")
grid.FillDirectionMaxCells = 4
grid.CellPadding = UDim2.new(0.02,0,0.03,0)
grid.CellSize = UDim2.new(0.235,0,0.21,0)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = itemGrid
local footer = text(main, "Play by observing, thinking and choosing.", 0.88,0.09,14)
local close = Instance.new("TextButton")
close.Name = "Close"
close.Text = "×"
close.Font = Enum.Font.GothamBlack
close.TextSize = 25
close.TextColor3 = Color3.fromRGB(255,255,255)
close.BackgroundTransparency = 1
close.Position = UDim2.new(0.86,0,0.02,0)
close.Size = UDim2.new(0.12,0,0.09,0)
close.Parent = main
local currentId, currentMode, response, enabled = nil, nil, {}, false
local generation = 0
local function tile(label, index, action, order)
    local b = Instance.new("TextButton")
    b.Name = "Tile_" .. tostring(index)
    b.LayoutOrder = order or index
    b.BackgroundColor3 = Color3.fromRGB(36, 85, 110)
    b.BorderSizePixel = 0
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = tostring(label)
    b.TextScaled = true
    b.Font = Enum.Font.GothamBold
    b.Parent = itemGrid
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,8)
    corner.Parent = b
    b.Activated:Connect(action)
end
local function clearTiles()
    for _, v in ipairs(itemGrid:GetChildren()) do
        if v:IsA("TextButton") then v:Destroy() end
    end
end
local function answer(n)
    if not enabled or not currentId then return end
    enabled = false
    event:FireServer("Answer",currentId,n)
    footer.Text = "Checking your answer..."
end
close.Activated:Connect(function()
    generation += 1
    event:FireServer("Close")
    main.Visible = false
    currentId = nil
    enabled = false
end)

local function reveal(id, data, score)
    generation += 1
    local stamp = generation
    clearTiles()
    currentId = id
    currentMode = data.kind
    response = {}
    enabled = true
    main.Visible = true
    title.Text = "COGNITIVE ARCADE / " .. string.upper(data.kind)
    question.Text = data.prompt
    footer.Text = "Solved: " .. tostring(score or 0) .. "  •  Use the controls below"
    subtitle.Text = ""
    if data.kind == "Memory" then
        enabled = false
        subtitle.Text = table.concat(data.sequence, "  •  ")
        for i = 1, 6 do
            tile(i,i,function()
                if not enabled then return end
                if #response >= #data.sequence then return end
                table.insert(response,i)
                subtitle.Text = "Recalled: " .. table.concat(response, " · ")
            end)
        end
        tile("CLEAR",7,function()
            if not enabled then return end
            response = {}
            subtitle.Text = "Recalled: "
        end)
        tile("SUBMIT",8,function()
            if #response == #data.sequence then answer(table.concat(response, ",")) end
        end)
        local duration = data.visibleSeconds or 5
        footer.Text = "Memorize the displayed sequence..."
        task.delay(duration, function()
            if generation ~= stamp or currentId ~= id then return end
            subtitle.Text = "Recalled: "
            enabled = true
            footer.Text = "Use 1–6 buttons in the same order."
        end)
    elseif data.kind == "Attention" then
        subtitle.Text = "Tap the unusual symbol."
        for i, symbol in ipairs(data.cells) do
            tile(symbol,i,function() answer(i) end)
        end
    elseif data.kind == "Logic" or data.kind == "Spatial" then
        if data.kind == "Logic" then
            subtitle.Text = table.concat(data.values, "   ·   ") .. "   ·   ?"
        else
            subtitle.Text = string.format("%dx%d grid | start (%d,%d) | end (%d,%d)",
                data.gridSize[1],data.gridSize[2],
                data.start[1],data.start[2],data.goal[1],data.goal[2])
        end
        for i, choice in ipairs(data.choices) do
            tile(choice,i,function() answer(choice) end)
        end
    elseif data.kind == "Switch" then
        subtitle.Text = data.stimulus .. "  /  " .. data.answerType
        for i, choice in ipairs(data.choices) do
            tile(choice,i,function() answer(i) end)
        end
    end
end

event.OnClientEvent:Connect(function(action, a,b,c)
    if action == "Challenge" then
        reveal(a,b,c)
    elseif action == "Result" then
        generation += 1
        clearTiles()
        enabled = false
        local correct, mode, total = a,b,c
        question.Text = correct and "CORRECT!  +1 POINT" or "TRY ANOTHER CHALLENGE"
        subtitle.Text = "Session points: " .. tostring(total or 0)
        footer.Text = "Practice is voluntary. You can stop at any moment."
        tile("PLAY AGAIN",1,function()
            if mode then event:FireServer("Next", mode) end
        end)
        tile("CLOSE",2,function()
            main.Visible = false
            currentId = nil
        end)
    end
end)

local gallery = Instance.new("TextLabel")
gallery.Name = "DuckGalleryScore"
gallery.AnchorPoint = Vector2.new(0.5,1)
gallery.Position = UDim2.fromScale(0.5,0.97)
gallery.Size = UDim2.new(0.83,0,0,52)
gallery.BackgroundColor3 = Color3.fromRGB(6, 30, 48)
gallery.TextColor3 = Color3.fromRGB(255,228,100)
gallery.Font = Enum.Font.GothamBlack
gallery.TextSize = 17
gallery.TextWrapped = true
gallery.Text = ""
gallery.Visible = false
gallery.Parent = gui
local counter = 0
event.OnClientEvent:Connect(function(action, a)
    if action == "DuckStart" then
        counter += 1
        local myCounter = counter
        gallery.Visible = true
        for seconds = 45, 0, -1 do
            task.delay(45-seconds, function()
                if counter ~= myCounter then return end
                gallery.Text = "HOLOGRAPHIC DUCK GALLERY  |  " .. seconds .. "s  |  Click moving ducks!"
            end)
        end
    elseif action == "DuckScore" then
        gallery.Text = "DUCK GALLERY  |  " .. tostring(a) .. " points"
    elseif action == "DuckEnd" then
        counter += 1
        gallery.Text = "FINISHED  |  Score: " .. tostring(a)
        task.delay(5,function() gallery.Visible = false end)
    end
end)
