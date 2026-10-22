-- Original retro Snake display. Keyboard, mobile and gamepad-friendly directional buttons.
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")
local Players=game:GetService("Players")
local event=ReplicatedStorage:WaitForChild("RetroCabinetEvent")
local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui")
gui.Name="YugatneoRetroCabinet"
gui.DisplayOrder=105
gui.ResetOnSpawn=false
gui.Parent=player:WaitForChild("PlayerGui")
local panel=Instance.new("Frame")
panel.AnchorPoint=Vector2.new(0.5,0.5)
panel.Position=UDim2.fromScale(0.5,0.5)
panel.Size=UDim2.new(0.94,0,0.82,0)
panel.BackgroundColor3=Color3.fromRGB(6,25,40)
panel.Visible=false
panel.Parent=gui
local cap=Instance.new("UISizeConstraint")
cap.MaxSize=Vector2.new(470,660)
cap.MinSize=Vector2.new(275,350)
cap.Parent=panel
local top=Instance.new("TextLabel")
top.Size=UDim2.new(1,-20,0,50)
top.Position=UDim2.fromOffset(10,8)
top.TextColor3=Color3.fromRGB(70,255,215)
top.BackgroundTransparency=1
top.Font=Enum.Font.Code
top.TextSize=18
top.Text="RETRO // SNAKE"
top.Parent=panel
local canvas=Instance.new("Frame")
canvas.Name="PixelGrid"
canvas.Position=UDim2.new(0.08,0,0.17,0)
canvas.Size=UDim2.new(0.84,0,0.57,0)
canvas.BackgroundColor3=Color3.fromRGB(12,38,42)
canvas.BorderSizePixel=0
canvas.Parent=panel
local grid=Instance.new("UIGridLayout")
grid.FillDirectionMaxCells=14
grid.CellSize=UDim2.new(1/14,-2,1/11,-2)
grid.CellPadding=UDim2.new(0,2,0,2)
grid.SortOrder=Enum.SortOrder.LayoutOrder
grid.Parent=canvas
local cells={}
for i=1,154 do
 local tile=Instance.new("Frame")
 tile.Name="Pixel"..i
 tile.LayoutOrder=i
 tile.BackgroundColor3=Color3.fromRGB(11,44,41)
 tile.BorderSizePixel=0
 tile.Parent=canvas
 cells[i]=tile
end
local function control(title,x,y,callback)
 local b=Instance.new("TextButton")
 b.Size=UDim2.fromOffset(85,44)
 b.Position=UDim2.new(x,0,y,0)
 b.BackgroundColor3=Color3.fromRGB(30,101,111)
 b.TextColor3=Color3.fromRGB(243,255,245)
 b.Text=title
 b.TextSize=17
 b.Font=Enum.Font.GothamBold
 b.Parent=panel
 b.Activated:Connect(callback)
 return b
end
local function turn(direction)
 if panel.Visible then event:FireServer("Turn",direction) end
end
control("▲",0.42,0.75,function() turn("Up") end)
control("◀",0.16,0.83,function() turn("Left") end)
control("▼",0.42,0.83,function() turn("Down") end)
control("▶",0.68,0.83,function() turn("Right") end)
control("EXIT",0.72,0.02,function()
 event:FireServer("Exit")
 panel.Visible=false
end)
UserInputService.InputBegan:Connect(function(input,processed)
 if processed or not panel.Visible then return end
 local names={
  [Enum.KeyCode.W]="Up",[Enum.KeyCode.Up]="Up",
  [Enum.KeyCode.S]="Down",[Enum.KeyCode.Down]="Down",
  [Enum.KeyCode.A]="Left",[Enum.KeyCode.Left]="Left",
  [Enum.KeyCode.D]="Right",[Enum.KeyCode.Right]="Right",
  [Enum.KeyCode.DPadUp]="Up",[Enum.KeyCode.DPadDown]="Down",
  [Enum.KeyCode.DPadLeft]="Left",[Enum.KeyCode.DPadRight]="Right",
 }
 local direction=names[input.KeyCode]
 if direction then turn(direction) end
end)
local function render(state)
 local marked={}
 for _,part in ipairs(state.body or {}) do
  marked[part[2]..":"..part[1]]=true
 end
 for y=1,11 do
  for x=1,14 do
   local index=(y-1)*14+x
   local cell=cells[index]
   local isFood=state.food and state.food[1]==x and state.food[2]==y
   cell.BackgroundColor3=marked[y..":"..x] and Color3.fromRGB(40,255,170) or
      (isFood and Color3.fromRGB(255,186,82) or Color3.fromRGB(11,44,41))
  end
 end
 top.Text="8-BIT SNAKE | SCORE "..tostring(state.score or 0)
end
event.OnClientEvent:Connect(function(action,payload)
 if action=="Start" then
  panel.Visible=true
  render(payload)
 elseif action=="State" then
  if panel.Visible then render(payload) end
 elseif action=="End" then
  render(payload)
  top.Text="GAME OVER / SCORE "..tostring(payload.score)
 end
end)
