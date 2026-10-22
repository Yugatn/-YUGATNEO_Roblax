-- Original Spiral Snake: client renders board and sends only turn requests.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local CAS=game:GetService("ContextActionService")
local player=Players.LocalPlayer
local event=ReplicatedStorage:WaitForChild("YugatneoRetro")
local gui=Instance.new("ScreenGui")
gui.Name="YugatneoRetroGUI"
gui.ResetOnSpawn=false
gui.DisplayOrder=85
gui.Parent=player:WaitForChild("PlayerGui")
local panel=Instance.new("Frame")
panel.AnchorPoint=Vector2.new(0.5,0.5)
panel.Position=UDim2.fromScale(0.5,0.5)
panel.Size=UDim2.new(0.9,0,0.86,0)
panel.BackgroundColor3=Color3.fromRGB(11,21,37)
panel.BorderSizePixel=0
panel.Visible=false
panel.Parent=gui
local sizeLimit=Instance.new("UISizeConstraint")
sizeLimit.MaxSize=Vector2.new(495,620)
sizeLimit.MinSize=Vector2.new(300,400)
sizeLimit.Parent=panel
local title=Instance.new("TextLabel")
title.BackgroundTransparency=1
title.TextColor3=Color3.fromRGB(75,255,196)
title.Font=Enum.Font.Code
title.TextSize=20
title.Size=UDim2.new(1,0,0,42)
title.Text="SPIRAL SNAKE  /  8-BIT"
title.Parent=panel
local board=Instance.new("Frame")
board.Size=UDim2.new(0.9,0,0.6,0)
board.Position=UDim2.new(0.05,0,0.09,0)
board.BackgroundColor3=Color3.fromRGB(17,34,41)
board.Parent=panel
local cells={}
local function build(w,h)
 for _,v in ipairs(board:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
 table.clear(cells)
 for y=1,h do
  for x=1,w do
   local cell=Instance.new("Frame")
   cell.Name="Cell_"..x.."_"..y
   cell.Position=UDim2.fromScale((x-1)/w,(y-1)/h)
   cell.Size=UDim2.fromScale(1/w-0.005,1/h-0.005)
   cell.BackgroundColor3=Color3.fromRGB(26,51,62)
   cell.BorderSizePixel=0
   cell.Parent=board
   cells[x..":"..y]=cell
  end
 end
end
local status=Instance.new("TextLabel")
status.BackgroundTransparency=1
status.Position=UDim2.new(0.04,0,0.70,0)
status.Size=UDim2.new(0.92,0,0.07,0)
status.Font=Enum.Font.GothamBold
status.TextSize=15
status.TextColor3=Color3.fromRGB(245,210,91)
status.Text="Arrows or WASD to steer."
status.Parent=panel
local active=false
local function button(txt,x,y,w,fn)
 local b=Instance.new("TextButton")
 b.Position=UDim2.new(x,0,y,0)
 b.Size=UDim2.new(w,0,0.065,0)
 b.BackgroundColor3=Color3.fromRGB(33,106,112)
 b.TextColor3=Color3.new(1,1,1)
 b.TextSize=17
 b.Font=Enum.Font.GothamBlack
 b.Text=txt
 b.Parent=panel
 b.Activated:Connect(fn)
end
local function turn(dir)
 if active then event:FireServer("TurnSnake",dir) end
end
button("↑",0.40,0.78,0.2,function()turn("Up")end)
button("←",0.17,0.86,0.2,function()turn("Left")end)
button("↓",0.40,0.86,0.2,function()turn("Down")end)
button("→",0.63,0.86,0.2,function()turn("Right")end)
button("EXIT",0.02,0.025,0.19,function()
 active=false
 panel.Visible=false
 unlockKeys()
 event:FireServer("StopSnake")
end)
button("AGAIN",0.81,0.025,0.17,function()
 event:FireServer("StartSnake")
end)
local function controls(name,state,input)
 if state~=Enum.UserInputState.Begin or not active then return Enum.ContextActionResult.Sink end
 local k=input.KeyCode
 if k==Enum.KeyCode.Up or k==Enum.KeyCode.W then turn("Up")
 elseif k==Enum.KeyCode.Down or k==Enum.KeyCode.S then turn("Down")
 elseif k==Enum.KeyCode.Left or k==Enum.KeyCode.A then turn("Left")
 elseif k==Enum.KeyCode.Right or k==Enum.KeyCode.D then turn("Right") end
 return Enum.ContextActionResult.Sink
end
local function lockKeys()
 CAS:BindActionAtPriority("YugatneoSnakeDirections",controls,false,3000,
  Enum.KeyCode.Up,Enum.KeyCode.Down,Enum.KeyCode.Left,Enum.KeyCode.Right,
  Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D)
end
local function unlockKeys()
 CAS:UnbindAction("YugatneoSnakeDirections")
end

local oldW,oldH=0,0
event.OnClientEvent:Connect(function(action,data)
 if action=="SnakeState" then
  active=data.alive
  panel.Visible=true
  if active then lockKeys() else unlockKeys() end
  if data.width~=oldW or data.height~=oldH then
   oldW,oldH=data.width,data.height
   build(oldW,oldH)
  end
  for _,cell in pairs(cells) do cell.BackgroundColor3=Color3.fromRGB(26,51,62) end
  if data.food then
   local k=data.food[1]..":"..data.food[2]
   if cells[k] then cells[k].BackgroundColor3=Color3.fromRGB(250,184,68) end
  end
  for i,point in ipairs(data.body) do
   local k=point[1]..":"..point[2]
   if cells[k] then cells[k].BackgroundColor3=
    i==1 and Color3.fromRGB(130,255,215) or Color3.fromRGB(27,181,125) end
  end
  status.Text="SCORE: "..data.score.." • "..(data.alive and "USE ARROWS / WASD" or "GAME OVER")
 elseif action=="SnakeEnd" then
  active=false
  unlockKeys()
  status.Text="FINAL: "..tostring(data.score).." • + "..tostring(data.reward).." X TOKENS"
 elseif action=="SnakeExit" then
  active=false
  panel.Visible=false
  unlockKeys()
 end
end)
