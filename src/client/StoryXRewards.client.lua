-- A small optional store for earned in-world cosmetics; never Roblox catalog ownership.
local Players=game:GetService("Players")
local event=game:GetService("ReplicatedStorage"):WaitForChild("RewardEvent")
local gui=Instance.new("ScreenGui")
gui.Name="StoryXRewardShop"
gui.ResetOnSpawn=false
gui.DisplayOrder=70
gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")

local toggle=Instance.new("TextButton")
toggle.Name="RewardsButton"
toggle.Position=UDim2.new(0,14,1,-54)
toggle.Size=UDim2.fromOffset(170,40)
toggle.BackgroundColor3=Color3.fromRGB(38,104,104)
toggle.TextColor3=Color3.new(1,1,1)
toggle.Font=Enum.Font.GothamBold
toggle.TextSize=14
toggle.Text="REWARDS / 0"
toggle.Parent=gui

local panel=Instance.new("Frame")
panel.Name="Shop"
panel.Position=UDim2.new(0,15,.5,-130)
panel.Size=UDim2.fromOffset(285,260)
panel.BackgroundColor3=Color3.fromRGB(12,20,39)
panel.Visible=false
panel.Parent=gui
local title=Instance.new("TextLabel")
title.Position=UDim2.fromOffset(9,6)
title.Size=UDim2.new(1,-18,0,38)
title.BackgroundTransparency=1
title.Font=Enum.Font.GothamBold
title.TextColor3=Color3.fromRGB(75,245,205)
title.TextSize=16
title.Text="REWARDS / FREE COSMETICS"
title.Parent=panel
toggle.Activated:Connect(function() panel.Visible=not panel.Visible end)
local holders={}
local entries={
    {"NeonGlasses","Neon glasses",30},
    {"Halo","Observer halo",65},
    {"MatrixCrown","Matrix crown",100},
    {"VioletKart","Violet kart (reserved)",80},
}
for i,entry in ipairs(entries) do
    local b=Instance.new("TextButton")
    b.Position=UDim2.fromOffset(10,46+(i-1)*47)
    b.Size=UDim2.new(1,-20,0,39)
    b.BackgroundColor3=Color3.fromRGB(39,77,107)
    b.Font=Enum.Font.GothamBold
    b.TextSize=12
    b.TextColor3=Color3.new(1,1,1)
    b.Text=entry[2].." • "..entry[3].." coins"
    b.Parent=panel
    holders[entry[1]]=b
    b.Activated:Connect(function()
        local state=gui:GetAttribute("ShopState")
        if not state then return end
        local owned=b:GetAttribute("Owned")==true
        event:FireServer(owned and "Equip" or "Buy",entry[1])
    end)
end
local note=Instance.new("TextLabel")
note.Position=UDim2.fromOffset(11,238)
note.Size=UDim2.new(1,-22,0,22)
note.BackgroundTransparency=1
note.TextColor3=Color3.fromRGB(150,200,212)
note.Font=Enum.Font.Gotham
note.TextSize=11
note.Text="Only inside this experience; no real-money sales."
note.Parent=panel
event.OnClientEvent:Connect(function(action,state)
    if action~="Snapshot" or type(state)~="table" then return end
    gui:SetAttribute("ShopState",true)
    toggle.Text="REWARDS / "..tostring(state.coins or 0)
    for _,entry in ipairs(entries) do
        local b=holders[entry[1]]
        local owned=state.unlocked and state.unlocked[entry[1]]==true
        b:SetAttribute("Owned",owned==true)
        if not owned then b.Text=entry[2].." • BUY "..entry[3]
        elseif state.equipped==entry[1] then b.Text=entry[2].." • EQUIPPED"
        else b.Text=entry[2].." • EQUIP" end
    end
end)
