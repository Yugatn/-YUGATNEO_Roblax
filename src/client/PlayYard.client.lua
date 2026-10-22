-- Optional team-play HUD, never traps players inside a round.
local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local event=RS:WaitForChild("PlayYardEvent")
local gui=Instance.new("ScreenGui")
gui.Name="StoryXPlayYard"
gui.ResetOnSpawn=false
gui.DisplayOrder=55
gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")
local frame=Instance.new("Frame")
frame.AnchorPoint=Vector2.new(.5,0)
frame.Position=UDim2.new(.5,0,0,22)
frame.Size=UDim2.fromOffset(375,90)
frame.BackgroundColor3=Color3.fromRGB(10,30,45)
frame.BorderSizePixel=0
frame.Visible=false
frame.Parent=gui
local corner=Instance.new("UICorner")
corner.CornerRadius=UDim.new(0,11)
corner.Parent=frame
local info=Instance.new("TextLabel")
info.Position=UDim2.new(.025,0,.05,0)
info.Size=UDim2.new(.7,0,.85,0)
info.BackgroundTransparency=1
info.Font=Enum.Font.GothamBold
info.TextColor3=Color3.fromRGB(80,255,185)
info.TextSize=13
info.TextWrapped=true
info.Parent=frame
local quit=Instance.new("TextButton")
quit.Position=UDim2.new(.73,0,.22,0)
quit.Size=UDim2.new(.25,0,.55,0)
quit.BackgroundColor3=Color3.fromRGB(115,68,79)
quit.Font=Enum.Font.GothamBold
quit.TextColor3=Color3.new(1,1,1)
quit.TextSize=12
quit.Text="LEAVE"
quit.Parent=frame
quit.Activated:Connect(function()
    event:FireServer("Leave")
    frame.Visible=false
end)
event.OnClientEvent:Connect(function(action,payload,extra)
    if action=="Queued" then
        frame.Visible=true
        info.Text="Waiting for more players: "..tostring(payload).."  ("..tostring(extra)..")"
    elseif action=="Status" then
        frame.Visible=true
        info.Text=string.format("%s / %s | %s | %ss\n%s",
            payload.mode,payload.phase,payload.role,payload.remaining,payload.message)
    elseif action=="End" then
        info.Text="ROUND COMPLETE / "..tostring(payload)
        task.delay(5,function() frame.Visible=false end)
    elseif action=="Exited" then
        frame.Visible=false
    end
end)
