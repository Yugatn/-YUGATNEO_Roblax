-- Client library reader: reading, local-session notes, text-search races and cosmetic shop.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local event=ReplicatedStorage:WaitForChild("YugatneoLibrary")
local rewards=ReplicatedStorage:WaitForChild("YugatneoRewards")
local books={}
local openId=nil
local selectedParagraph=nil
local selectedAnswer=nil
local activeRace=nil
local localNotes={}
local gui=Instance.new("ScreenGui")
gui.Name="YugatneoLibraryGUI"
gui.ResetOnSpawn=false
gui.DisplayOrder=95
gui.Parent=player:WaitForChild("PlayerGui")
local panel=Instance.new("Frame")
panel.AnchorPoint=Vector2.new(0.5,0.5)
panel.Position=UDim2.fromScale(0.5,0.5)
panel.Size=UDim2.fromScale(0.94,0.91)
panel.BackgroundColor3=Color3.fromRGB(12,22,41)
panel.Visible=false
panel.Parent=gui
local cap=Instance.new("UISizeConstraint")
cap.MaxSize=Vector2.new(850,800)
cap.MinSize=Vector2.new(300,400)
cap.Parent=panel
local rounded=Instance.new("UICorner")
rounded.CornerRadius=UDim.new(0,12)
rounded.Parent=panel
local function text(parent,title,size)
 local label=Instance.new("TextLabel")
 label.Size=UDim2.new(1,-20,0,size or 35)
 label.BackgroundTransparency=1
 label.Font=Enum.Font.GothamBold
 label.TextColor3=Color3.fromRGB(202,246,232)
 label.TextSize=15
 label.TextWrapped=true
 label.TextXAlignment=Enum.TextXAlignment.Left
 label.Text=title
 label.Parent=parent
 return label
end
local function button(parent,title,func)
 local b=Instance.new("TextButton")
 b.Size=UDim2.new(1,-12,0,39)
 b.BackgroundColor3=Color3.fromRGB(32,81,105)
 b.BorderSizePixel=0
 b.TextColor3=Color3.new(1,1,1)
 b.TextSize=14
 b.Font=Enum.Font.GothamBold
 b.TextWrapped=true
 b.Text=title
 b.Parent=parent
 b.Activated:Connect(func)
 return b
end
local head=text(panel,"YUGATNEO  |  БИБЛИОТЕКА X",45)
head.Position=UDim2.fromOffset(16,8)
head.TextSize=21
local exit=Instance.new("TextButton")
exit.Position=UDim2.new(1,-55,0,8)
exit.Size=UDim2.fromOffset(43,43)
exit.BackgroundTransparency=1
exit.Text="×"
exit.TextColor3=Color3.new(1,1,1)
exit.TextSize=30
exit.Parent=panel
exit.Activated:Connect(function() panel.Visible=false end)
local side=Instance.new("ScrollingFrame")
side.Position=UDim2.new(0,12,0,66)
side.Size=UDim2.new(0.33,-12,1,-84)
side.BackgroundColor3=Color3.fromRGB(17,31,52)
side.BorderSizePixel=0
side.ScrollBarThickness=4
side.AutomaticCanvasSize=Enum.AutomaticSize.Y
side.CanvasSize=UDim2.fromScale(0,0)
side.Parent=panel
local sideLayout=Instance.new("UIListLayout")
sideLayout.Padding=UDim.new(0,6)
sideLayout.Parent=side
local contentFrame=Instance.new("ScrollingFrame")
contentFrame.Position=UDim2.new(0.34,3,0,66)
contentFrame.Size=UDim2.new(0.66,-18,1,-84)
contentFrame.BackgroundColor3=Color3.fromRGB(20,37,59)
contentFrame.BorderSizePixel=0
contentFrame.ScrollBarThickness=5
contentFrame.AutomaticCanvasSize=Enum.AutomaticSize.Y
contentFrame.CanvasSize=UDim2.fromScale(0,0)
contentFrame.Parent=panel
local contentLayout=Instance.new("UIListLayout")
contentLayout.Padding=UDim.new(0,8)
contentLayout.Parent=contentFrame
local function clear(container)
 for _,child in ipairs(container:GetChildren()) do
  if child:IsA("TextButton") or child:IsA("TextLabel") or child:IsA("TextBox") then child:Destroy() end
 end
end
local raceState="Read a story, take notes, or join the race at the library podium."
local function openBook(id)
 local book=books[id]
 if not book then return end
 if openId and openId~=id then
  local field=contentFrame:FindFirstChild("ReaderNotes")
  if field then localNotes[openId]=string.sub(field.Text,1,1200) end
 end
 openId=id
 selectedParagraph=nil
 selectedAnswer=nil
 clear(contentFrame)
 local info=text(contentFrame,book.title.."  •  "..(book.age or "").."  •  "..book.author,65)
 info.TextSize=18
 for i,paragraph in ipairs(book.paragraphs) do
  local idx=i
  local selected=button(contentFrame,tostring(i)..". "..paragraph,function()
   selectedParagraph=idx
   raceState="Selected paragraph "..idx
   if activeRace then head.Text="РАУНД: "..raceState end
  end)
  selected.Size=UDim2.new(1,-12,0,math.max(90,math.ceil(utf8.len(paragraph) or #paragraph)/42)*28)
  selected.TextXAlignment=Enum.TextXAlignment.Left
  selected.TextYAlignment=Enum.TextYAlignment.Top
 end
 local notesHeader=text(contentFrame,"ЛИЧНЫЙ КОНСПЕКТ (только до закрытия игры)",46)
 notesHeader.TextSize=14
 local field=Instance.new("TextBox")
 field.Name="ReaderNotes"
 field.Size=UDim2.new(1,-12,0,100)
 field.TextColor3=Color3.new(1,1,1)
 field.TextSize=14
 field.MultiLine=true
 field.TextWrapped=true
 field.ClearTextOnFocus=false
 field.TextXAlignment=Enum.TextXAlignment.Left
 field.TextYAlignment=Enum.TextYAlignment.Top
 field.PlaceholderText="Какая мысль кажется тебе важной? Как бы ты её объяснил?"
 field.Text=localNotes[id] or ""
 field.BackgroundColor3=Color3.fromRGB(32,53,72)
 field.Parent=contentFrame
 field.FocusLost:Connect(function() localNotes[id]=string.sub(field.Text,1,1200) end)
end
local function updateSide()
 clear(side)
 text(side,"КНИЖНЫЕ ПОЛКИ",32)
 local order={}
 for id in pairs(books) do table.insert(order,id) end
 table.sort(order)
 for _,id in ipairs(order) do
  local book=books[id]
  button(side,book.title,function() openBook(id) end)
 end
 if activeRace then
  text(side,"ЗАДАНИЕ: "..activeRace.prompt,86)
  for i,answer in ipairs(activeRace.options) do
   local ix=i
   button(side,tostring(i)..". "..answer,function()
    selectedAnswer=ix
    raceState="Выбран ответ "..ix
   end)
  end
  button(side,"ПРОВЕРИТЬ АБЗАЦ + ОТВЕТ",function()
   if openId and selectedParagraph and selectedAnswer then
    event:FireServer("RaceAnswer",openId,selectedParagraph,selectedAnswer)
   end
  end)
  text(side,"Сначала найди книгу, затем отметь абзац и вариант ответа.",78)
 end
end
local function showRace(clue,catalog)
 for _,book in ipairs(catalog or {}) do books[book.id]=book end
 activeRace=clue
 panel.Visible=true
 head.Text="LIBRARY X / READING RACE"
 raceState="Read and find the right paragraph."
 updateSide()
end
local shop=Instance.new("Frame")
shop.AnchorPoint=Vector2.new(0.5,0.5)
shop.Position=UDim2.fromScale(0.5,0.5)
shop.Size=UDim2.new(0.9,0,0.8,0)
shop.BackgroundColor3=Color3.fromRGB(10,24,40)
shop.Visible=false
shop.Parent=gui
local shopConstraint=Instance.new("UISizeConstraint")
shopConstraint.MaxSize=Vector2.new(430,520)
shopConstraint.Parent=shop
local shopLayout=Instance.new("UIListLayout")
shopLayout.Padding=UDim.new(0,10)
shopLayout.Parent=shop
local shopTitle=text(shop,"НАГРАДЫ ВНУТРИ МИРА X",50)
button(shop,"ЗАКРЫТЬ",function() shop.Visible=false end)
local states={}
local function refreshShop()
 for _,child in ipairs(shop:GetChildren()) do
  if child:IsA("TextButton") and child.Text~="ЗАКРЫТЬ" then child:Destroy() end
 end
 shopTitle.Text="НАГРАДЫ • "..(states.coins or 0).." очков"
 local items=states.items or {}
 for _,name in ipairs({"Glasses","Crown","Trail","KartCyan"}) do
  local detail=items[name]
  if detail then
   local owned=states.owned and states.owned[name]
   local caption=name.." / "..(detail.description or "").." / "..detail.cost..
    (owned and " • ОТКРЫТО" or " • КУПИТЬ")
   button(shop,caption,function()
    if owned then rewards:FireServer("Equip",name)
    else rewards:FireServer("Buy",name) end
   end)
  end
 end
end
event.OnClientEvent:Connect(function(action,a,b)
 if action=="Catalog" then
  for _,book in ipairs(a or {}) do books[book.id]=book end
  if not activeRace then updateSide() end
 elseif action=="OpenBook" then
  if not next(books) then event:FireServer("GetCatalog") end
  if books[a] then
   panel.Visible=true
   activeRace=nil
   head.Text="LIBRARY X / READING ROOM"
   updateSide()
   openBook(a)
  else
   -- First interaction requests catalog; player may open again after it loads.
   event:FireServer("GetCatalog")
  end
 elseif action=="RaceStart" then
  showRace(a,b)
 elseif action=="RaceCorrect" then
  activeRace=nil
  head.Text="ВЕРНО • "..string.format("%.1f",a).." СЕК"
  updateSide()
 elseif action=="RaceIncorrect" then
  head.Text="ЕЩЁ НЕВЕРНО — ПРОВЕРЬ КНИГУ И АБЗАЦ"
 elseif action=="RaceResults" then
  activeRace=nil
  head.Text="ЧТЕНИЕ ЗАВЕРШЕНО"
  updateSide()
 elseif action=="Shop" then
  shop.Visible=true
 elseif action=="RaceStatus" then
  raceState=(a and a.message) or raceState
 end
end)
rewards.OnClientEvent:Connect(function(action, payload)
 if action=="State" then states=payload or {} refreshShop() end
end)
-- Catalog request is only served when in range; shelf prompt sends OpenBook.
event:FireServer("GetCatalog")
