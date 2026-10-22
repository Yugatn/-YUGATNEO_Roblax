-- Screen-only pixel art and controls. All motion and scoring are server-controlled.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local event=RS:WaitForChild("RetroEvent")
local gui=Instance.new("ScreenGui")
gui.Name="YUGATNEO_RetroCabinets"
gui.ResetOnSpawn=false
gui.DisplayOrder=105
gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")
local frame=Instance.new("Frame")
frame.AnchorPoint=Vector2.new(.5,.5)
frame.Position=UDim2.fromScale(.5,.5)
frame.Size=UDim2.new(.9,0,.77,0)
frame.BackgroundColor3=Color3.fromRGB(10,14,24)
frame.Visible=false
frame.Parent=gui
local limit=Instance.new("UISizeConstraint")
limit.MaxSize=Vector2.new(580,530)
limit.MinSize=Vector2.new(285,300)
limit.Parent=frame
local title=Instance.new("TextLabel")
title.Size=UDim2.new(1,-12,.12,0)
title.Position=UDim2.new(0,6,.01,0)
title.BackgroundTransparency=1
title.TextColor3=Color3.fromRGB(115,249,175)
title.Font=Enum.Font.Arcade
title.TextScaled=true
title.Text="YUGATNEO / RETRO"
title.Parent=frame

local canvas=Instance.new("TextLabel")
canvas.Position=UDim2.new(.04,0,.14,0)
canvas.Size=UDim2.new(.92,0,.53,0)
canvas.BackgroundColor3=Color3.fromRGB(4,25,23)
canvas.TextColor3=Color3.fromRGB(147,255,126)
canvas.TextScaled=true
canvas.TextWrapped=false
canvas.Font=Enum.Font.Code
canvas.TextXAlignment=Enum.TextXAlignment.Center
canvas.TextYAlignment=Enum.TextYAlignment.Center
canvas.Parent=frame

local instructions=Instance.new("TextLabel")
instructions.Position=UDim2.new(.04,0,.675,0)
instructions.Size=UDim2.new(.92,0,.065,0)
instructions.BackgroundTransparency=1
instructions.TextColor3=Color3.fromRGB(246,220,137)
instructions.TextSize=13
instructions.TextWrapped=true
instructions.Text=""
instructions.Parent=frame

local buttons=Instance.new("Frame")
buttons.Position=UDim2.new(.05,0,.75,0)
buttons.Size=UDim2.new(.9,0,.15,0)
buttons.BackgroundTransparency=1
buttons.Parent=frame
local grid=Instance.new("UIGridLayout")
grid.FillDirectionMaxCells=5
grid.CellSize=UDim2.new(.19,0,.93,0)
grid.CellPadding=UDim2.new(.01,0,.04,0)
grid.Parent=buttons
local mode,me=nil,nil
local function send(action)
    if mode=="Snake" then event:FireServer("SnakeTurn",action)
    elseif mode=="Duel" then event:FireServer("DuelMove",action) end
end
local function addButton(name,action)
    local b=Instance.new("TextButton")
    b.Text=name
    b.Name=action
    b.BackgroundColor3=Color3.fromRGB(41,97,100)
    b.TextColor3=Color3.new(1,1,1)
    b.Font=Enum.Font.GothamBold
    b.TextSize=12
    b.Parent=buttons
    b.Activated:Connect(function() send(action) end)
end
local function configure()
    for _,obj in ipairs(buttons:GetChildren()) do
        if obj:IsA("TextButton") then obj:Destroy() end
    end
    if mode=="Snake" then
        for _,entry in ipairs({{"UP","Up"},{"LEFT","Left"},{"DOWN","Down"},{"RIGHT","Right"}}) do
            addButton(entry[1],entry[2])
        end
    elseif mode=="Duel" then
        for _,entry in ipairs({{"◀","Left"},{"▶","Right"},{"PUNCH","Punch"},{"KICK","Kick"},{"BLOCK","Block"}}) do
            addButton(entry[1],entry[2])
        end
    end
end
local quit=Instance.new("TextButton")
quit.Position=UDim2.new(.70,0,.92,0)
quit.Size=UDim2.new(.27,0,.065,0)
quit.Text="EXIT / RETURN"
quit.Font=Enum.Font.GothamBold
quit.TextSize=12
quit.TextColor3=Color3.fromRGB(255,255,255)
quit.BackgroundColor3=Color3.fromRGB(101,56,70)
quit.Parent=frame
local function close()
    if mode=="Snake" then event:FireServer("SnakeExit")
    elseif mode=="Duel" then event:FireServer("DuelExit") end
    mode=nil
    me=nil
    frame.Visible=false
end
quit.Activated:Connect(close)
UIS.InputBegan:Connect(function(input,processed)
    if processed or not mode then return end
    local k=input.KeyCode
    if k==Enum.KeyCode.Escape then close() return end
    if k==Enum.KeyCode.W or k==Enum.KeyCode.Up then send("Up")
    elseif k==Enum.KeyCode.S or k==Enum.KeyCode.Down then send("Down")
    elseif k==Enum.KeyCode.A or k==Enum.KeyCode.Left then send("Left")
    elseif k==Enum.KeyCode.D or k==Enum.KeyCode.Right then send("Right")
    elseif k==Enum.KeyCode.J then send("Punch")
    elseif k==Enum.KeyCode.K then send("Kick")
    elseif k==Enum.KeyCode.L then send("Block") end
end)

local function snakeBoard(state)
    local occupied={}
    for _,cell in ipairs(state.body or {}) do occupied[cell[1]..":"..cell[2]]=true end
    local lines={}
    for y=1,state.height do
        local line={}
        for x=1,state.width do
            if state.food and state.food[1]==x and state.food[2]==y then table.insert(line,"✦")
            elseif occupied[x..":"..y] then table.insert(line,"■")
            else table.insert(line,"·") end
        end
        table.insert(lines,table.concat(line," "))
    end
    canvas.Text=table.concat(lines,"\n")
    instructions.Text="SCORE: "..state.score.."  |  WASD / arrows / touch"
    if state.alive==false then instructions.Text="Game over! Score: "..state.score end
end
local function duelBoard(state)
    local line={}
    for x=1,12 do
        if x==state.pos[1] and x==state.pos[2] then line[x]="XX"
        elseif x==state.pos[1] then line[x]="P1"
        elseif x==state.pos[2] then line[x]="P2"
        else line[x]="--" end
    end
    canvas.Text="16-BIT-STYLE FRIENDLY DUEL\n\n"..table.concat(line," ").."\n\n"..string.format("P1 HP: %d      P2 HP: %d",state.hp[1],state.hp[2])
    instructions.Text="Player "..tostring(me).."  |  "..tostring(state.remaining).."s  |  J punch, K kick, L block"
    if state.ended then
        instructions.Text=state.victor and ("WINNER: PLAYER "..state.victor) or "DRAW"
    end
end

event.OnClientEvent:Connect(function(action,a,b)
    if action=="SnakeStart" then
        mode="Snake"
        frame.Visible=true
        configure()
        title.Text="8-BIT / PIXEL SERPENT"
        snakeBoard(a)
    elseif action=="SnakeState" and mode=="Snake" then
        snakeBoard(a)
    elseif action=="DuelStart" then
        mode="Duel"
        me=a
        frame.Visible=true
        configure()
        title.Text="16-BIT / FRIENDLY DUEL"
        duelBoard(b)
    elseif action=="DuelState" and mode=="Duel" then
        duelBoard(a)
    elseif action=="Notice" then
        instructions.Text=tostring(a)
    end
end)
