-- Story X Lumen Circuit HUD: copy into StarterPlayerScripts as a LocalScript.
-- The server alone moves lightcycles and adjudicates collisions.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local ContextActionService=game:GetService("ContextActionService")
local player=Players.LocalPlayer
local event=ReplicatedStorage:WaitForChild("LightCycleEvent")
local gui=Instance.new("ScreenGui")
gui.Name="YUGATNEO_LumenCircuitHUD";gui.ResetOnSpawn=false
gui.DisplayOrder=100;gui.Parent=player:WaitForChild("PlayerGui")
local frame=Instance.new("Frame")
frame.AnchorPoint=Vector2.new(0.5,1)
frame.Position=UDim2.new(0.5,0,1,-20)
frame.Size=UDim2.new(0.86,0,0,210)
frame.BackgroundColor3=Color3.fromRGB(9,23,41);frame.BackgroundTransparency=0.05
frame.BorderSizePixel=0;frame.Visible=false;frame.Parent=gui
local constraint=Instance.new("UISizeConstraint")
constraint.MaxSize=Vector2.new(550,250)
constraint.MinSize=Vector2.new(290,175);constraint.Parent=frame
local rounded=Instance.new("UICorner")
rounded.CornerRadius=UDim.new(0,12);rounded.Parent=frame
local function label(value,position,size,ts)
 local t=Instance.new("TextLabel")
 t.BackgroundTransparency=1;t.TextColor3=Color3.fromRGB(104,249,223)
 t.TextWrapped=true;t.Font=Enum.Font.GothamBold;t.TextSize=ts or 14
 t.Position=position;t.Size=size;t.Text=value;t.Parent=frame
 return t
end
local heading=label("STORY X / LUMEN CIRCUIT",UDim2.new(0,12,0,6),
 UDim2.new(1,-24,0,25),19)
local status=label("Активируй лазер на спирали.",UDim2.new(0,12,0,35),
 UDim2.new(1,-24,0,42),14)
local score=label("",UDim2.new(0.01,0,0.34,0),UDim2.new(0.98,0,0,20),12)
local function button(caption,position,size,callback)
 local b=Instance.new("TextButton")
 b.BackgroundColor3=Color3.fromRGB(20,102,128)
 b.BorderSizePixel=0;b.TextColor3=Color3.new(1,1,1)
 b.Font=Enum.Font.GothamBold;b.TextSize=14;b.Text=caption
 b.Position=position;b.Size=size;b.Parent=frame
 b.Activated:Connect(callback)
 local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,6);c.Parent=b
 return b
end
local participating=false
local watching=false
local originalCameraType
local originalSubject
local center=Vector3.new(1850,37,0)
local function releaseCamera()
 if not watching then return end
 watching=false
 ContextActionService:UnbindAction("YUGATNEO_LightCycleTurn")
 local camera=workspace.CurrentCamera
 if camera then
  camera.CameraType=Enum.CameraType.Custom
  if player.Character then
   local hum=player.Character:FindFirstChildOfClass("Humanoid")
   if hum then camera.CameraSubject=hum end
  end
 end
end
local function cameraFocus()
 local camera=workspace.CurrentCamera
 if not camera then return end
 camera.CameraType=Enum.CameraType.Scriptable
 camera.CFrame=CFrame.lookAt(center+Vector3.new(0,190,95),center)
 watching=true
end
local function turn(dir)
 if participating then event:FireServer("Turn",dir) end
end
local function capture(name,state,input)
 if state~=Enum.UserInputState.Begin then return Enum.ContextActionResult.Sink end
 local k=input.KeyCode
 if k==Enum.KeyCode.Left or k==Enum.KeyCode.A then turn("Left")
 elseif k==Enum.KeyCode.Right or k==Enum.KeyCode.D then turn("Right")
 elseif k==Enum.KeyCode.Up or k==Enum.KeyCode.W then turn("Up")
 elseif k==Enum.KeyCode.Down or k==Enum.KeyCode.S then turn("Down") end
 return Enum.ContextActionResult.Sink
end
local join=button("JOIN RACE",UDim2.new(0.02,0,0.62,0),UDim2.new(0.30,0,0,34),function()
 event:FireServer("Join")
end)
button("LEAVE QUEUE",UDim2.new(0.35,0,0.62,0),UDim2.new(0.32,0,0,34),function()
 if not participating then event:FireServer("LeaveQueue") end
end)
button("CLOSE",UDim2.new(0.70,0,0.62,0),UDim2.new(0.28,0,0,34),function()
 if participating then
  status.Text="Finish the round or use the exit console."
 else
  frame.Visible=false
  releaseCamera()
 end
end)
local dirs={
 {"◀","Left",0.02},{"▲","Up",0.27},{"▼","Down",0.52},{"▶","Right",0.77}
}
for _,def in ipairs(dirs) do
 button(def[1],UDim2.new(def[3],0,0.82,0),UDim2.new(0.20,0,0,31),
  function()turn(def[2])end)
end
local function startRound(data)
 local r=data and data.riders
 local me=r and r.riders and r.riders[player.UserId]
 center=data and data.center and Vector3.new(unpack(data.center)) or center
 participating=me~=nil
 frame.Visible=true
 status.Text=participating and "GO! Поворачивай на 90°; не пересекай лучи."
  or "Идёт гонка. Можно смотреть с трибуны."
 if participating then
  cameraFocus()
  ContextActionService:BindActionAtPriority("YUGATNEO_LightCycleTurn",capture,false,3000,
   Enum.KeyCode.Left,Enum.KeyCode.Right,Enum.KeyCode.Up,Enum.KeyCode.Down,
   Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D)
 end
end
event.OnClientEvent:Connect(function(action,payload)
 if action=="Entered" then
  frame.Visible=true
  status.Text="Ты внутри сетки. Встань в очередь у терминала или нажми JOIN."
  event:FireServer("GetStatus")
 elseif action=="Queue" then
  score.Text=string.format("Ожидают гонку: %s",tostring(payload.waiting or 0))
 elseif action=="Waiting" then
  frame.Visible=true
  status.Text="Ожидание гонки. Место в очереди: "..tostring(payload.position)
 elseif action=="MatchStart" then
  startRound(payload)
 elseif action=="Tick" and participating then
  score.Text="Круг "..tostring(payload.tick or 0).." • Смотри на трассу"
  for _,update in ipairs(payload.updates or {}) do
   if update.id==player.UserId and update.dead then
    participating=false
    releaseCamera()
    status.Text="СТОЛКНОВЕНИЕ • В этом раунде ты наблюдатель."
   end
  end
 elseif action=="MatchEnd" then
  local won=payload and payload.winner==player.UserId
  participating=false
  releaseCamera()
  frame.Visible=true
  status.Text=won and "ПОБЕДА! +20 жетонов" or
   (payload and payload.draw and "НИЧЬЯ • +5 жетонов" or "РАУНД ЗАВЕРШЁН • +5 жетонов")
 elseif action=="Released" then
  participating=false
  releaseCamera()
 elseif action=="Exited" then
  participating=false
  releaseCamera()
  frame.Visible=false
 end
end)
player.CharacterAdded:Connect(function()
 participating=false
 releaseCamera()
end)
