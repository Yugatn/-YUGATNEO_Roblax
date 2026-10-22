-- Small, opt-in 8-bit virtual pet HUD; one companion per Roblox player.
-- Client NEVER decides pet stats, growth or rewards.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("YugatneoPetEvent")

local gui = Instance.new("ScreenGui")
gui.Name = "YugatneoVirtualPet"
gui.ResetOnSpawn = false
gui.DisplayOrder = 45
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

local function round(object, size)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, size or 8)
    corner.Parent = object
end
local function makeText(parent, value, position, size, fontSize)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Position = position
    lbl.Size = size
    lbl.Font = Enum.Font.GothamBold
    lbl.TextColor3 = Color3.fromRGB(206, 252, 228)
    lbl.TextWrapped = true
    lbl.TextSize = fontSize or 14
    lbl.Text = value
    lbl.Parent = parent
    return lbl
end
local function makeButton(parent, label, position, size, callback)
    local button = Instance.new("TextButton")
    button.Position = position
    button.Size = size
    button.BackgroundColor3 = Color3.fromRGB(37, 105, 108)
    button.TextColor3 = Color3.new(1,1,1)
    button.TextSize = 14
    button.Font = Enum.Font.GothamBold
    button.Text = label
    button.Parent = parent
    round(button)
    button.Activated:Connect(callback)
    return button
end

local toggle = makeButton(gui, "PET", UDim2.new(1,-312,0,20), UDim2.fromOffset(106,40),
    function() end)
toggle.Visible = false
local panel = Instance.new("Frame")
panel.Name = "PetScreen"
panel.AnchorPoint = Vector2.new(1,0)
panel.Position = UDim2.new(1,-306,0,68)
panel.Size = UDim2.fromOffset(282,405)
panel.BackgroundColor3 = Color3.fromRGB(12, 28, 42)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
round(panel,14)
local panelScale = Instance.new("UIScale")
panelScale.Parent = panel
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(70,220,176)
stroke.Thickness = 1.5
stroke.Parent = panel
local heading = makeText(panel, "YUGATNEO • PET", UDim2.fromOffset(14,8),UDim2.fromOffset(230,30),20)
local close = makeButton(panel,"×",UDim2.new(1,-41,0,8),UDim2.fromOffset(32,32),function() panel.Visible=false end)
close.TextSize=24
local stage = makeText(panel,"",UDim2.fromOffset(14,42),UDim2.new(1,-28,0,25),13)
local art = Instance.new("Frame")
art.Position=UDim2.fromOffset(91,76)
art.Size=UDim2.fromOffset(99,99)
art.BackgroundColor3=Color3.fromRGB(8,18,29)
art.Parent=panel
round(art,6)

local patterns = {
    Lumi = {"000010000","000111000","001111100","011111110","111101111","011111110","001111100","000111000","000010000"},
    Miko = {"110000011","111000111","111111111","111111111","110110111","111111111","111011111","011111110","001111100"},
    Sprout = {"000010000","000111100","001111110","000111100","000010000","000111000","001111100","011111110","001111100"},
}
local pixelColors = {Lumi=Color3.fromRGB(255,221,112),Miko=Color3.fromRGB(140,233,250),Sprout=Color3.fromRGB(123,239,150)}
local function renderPet(species)
    for _, item in ipairs(art:GetChildren()) do
        if item:IsA("Frame") then item:Destroy() end
    end
    local pattern = patterns[species]
    if not pattern then return end
    for y, line in ipairs(pattern) do
        for x=1,#line do
            if line:sub(x,x)=="1" then
                local square=Instance.new("Frame")
                square.BorderSizePixel=0
                square.Position=UDim2.fromOffset((x-1)*11,(y-1)*11)
                square.Size=UDim2.fromOffset(11,11)
                square.BackgroundColor3=pixelColors[species]
                square.Parent=art
            end
        end
    end
end

local statFrame = Instance.new("Frame")
statFrame.Size=UDim2.new(1,-24,0,112)
statFrame.Position=UDim2.fromOffset(12,186)
statFrame.BackgroundTransparency=1
statFrame.Parent=panel
local names = {
    {"hunger","Сытость"}, {"joy","Радость"}, {"energy","Энергия"}, {"health","Здоровье"},
}
local bars={}
for i, row in ipairs(names) do
    local y=(i-1)*27
    makeText(statFrame,row[2],UDim2.fromOffset(0,y),UDim2.fromOffset(86,23),12)
    local bg=Instance.new("Frame")
    bg.Position=UDim2.fromOffset(92,y+6)
    bg.Size=UDim2.fromOffset(132,13)
    bg.BackgroundColor3=Color3.fromRGB(39,60,74)
    bg.Parent=statFrame
    round(bg,4)
    local fg=Instance.new("Frame")
    fg.Size=UDim2.fromScale(1,1)
    fg.BackgroundColor3=Color3.fromRGB(70,222,161)
    fg.Parent=bg
    round(fg,4)
    local count=makeText(statFrame,"",UDim2.fromOffset(228,y),UDim2.fromOffset(32,22),11)
    bars[row[1]]={fill=fg,number=count}
end

local actions={
    {"Feed","Кормить"}, {"Play","Играть"}, {"Rest","Сон"}, {"Care","Лечить"},
}
for i,row in ipairs(actions) do
    local x=(i-1)%2
    local y=math.floor((i-1)/2)
    makeButton(panel,row[2],UDim2.fromOffset(13+x*130,310+y*37),UDim2.fromOffset(124,31),function()
        event:FireServer("Care",row[1])
    end)
end
local feedback=makeText(panel,"",UDim2.fromOffset(10,382),UDim2.new(1,-20,0,20),11)
feedback.TextColor3=Color3.fromRGB(255,223,150)

local picker=Instance.new("Frame")
picker.Name="PetAdoption"
picker.AnchorPoint=Vector2.new(0.5,0.5)
picker.Position=UDim2.fromScale(0.5,0.5)
picker.Size=UDim2.new(0.90,0,0,330)
picker.BackgroundColor3=Color3.fromRGB(12,25,40)
picker.Visible=false
picker.Parent=gui
round(picker,14)
local constraint=Instance.new("UISizeConstraint")
constraint.MaxSize=Vector2.new(350,350)
constraint.Parent=picker
makeText(picker,"ВЫБЕРИ СВОЕГО ДРУГА",UDim2.fromOffset(12,15),UDim2.new(1,-24,0,37),19)
makeText(picker,"Забота добровольна. Питомец никогда не погибнет из-за перерыва.",
    UDim2.fromOffset(14,54),UDim2.new(1,-28,0,48),12)
local chooseOptions={"Lumi","Miko","Sprout"}
local labels={Lumi="✦ ЛЮМИ — звёздный друг",Miko="◆ МИКО — котик",Sprout="✿ РОСТОК — растение"}
for i,name in ipairs(chooseOptions) do
    makeButton(picker,labels[name],UDim2.new(0,12,0,101+(i-1)*54),
        UDim2.new(1,-24,0,45),function()
            event:FireServer("Adopt",name)
            picker.Visible=false
        end)
end
makeButton(picker,"ПОЗЖЕ",UDim2.new(0.25,0,1,-41),UDim2.new(0.5,0,0,31),function()
    picker.Visible=false
end)

local lastSpecies=nil
local function positionUI()
    local camera=workspace.CurrentCamera
    local width=camera and camera.ViewportSize.X or 1100
    local height=camera and camera.ViewportSize.Y or 800
    panelScale.Scale=math.clamp((height-100)/405,0.66,1)
    if width < 760 then
        toggle.Position=UDim2.new(1,-113,0,math.min(450,math.max(75,height-56)))
        panel.Position=UDim2.new(1,-10,0,65)
        panel.Size=UDim2.fromOffset(282,405)
    else
        toggle.Position=UDim2.new(1,-312,0,20)
        panel.Position=UDim2.new(1,-306,0,68)
    end
end
positionUI()
local cameraViewportConnection
local function watchCamera()
    if cameraViewportConnection then cameraViewportConnection:Disconnect() end
    local camera=workspace.CurrentCamera
    if camera then
        cameraViewportConnection=camera:GetPropertyChangedSignal("ViewportSize"):Connect(positionUI)
    end
    positionUI()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()
toggle.Activated:Connect(function()
    positionUI()
    panel.Visible=not panel.Visible
end)
event.OnClientEvent:Connect(function(action,payload)
    if action=="Choose" then
        picker.Visible=true
    elseif action=="Open" then
        panel.Visible=true
    elseif action=="State" then
        local state=payload or {}
        local pet=state.pet
        if not pet then
            toggle.Visible=false
            panel.Visible=false
            return
        end
        toggle.Visible=true
        toggle.Text="♥ "..(pet.label or "PET")
        heading.Text=(pet.label or "Питомец").."   •   Ур. "..tostring(pet.level or 1)
        stage.Text=(pet.stage or "").."  •  забота: "..tostring(pet.careCount or 0)
        if pet.species~=lastSpecies then
            lastSpecies=pet.species
            renderPet(pet.species)
        end
        for key,row in pairs(bars) do
            local value=math.clamp(tonumber(pet[key]) or 0,0,100)
            row.fill.Size=UDim2.fromScale(value/100,1)
            row.number.Text=tostring(value)
            row.fill.BackgroundColor3=value<25 and Color3.fromRGB(244,165,75)
                or Color3.fromRGB(70,222,161)
        end
        feedback.Text=state.message or (state.savingAvailable and "Прогресс сохраняется." or
            "Только текущая сессия: сохранение недоступно.")
    end
end)
event:FireServer("GetState")
