-- STORY X art gallery HUD: Roblox ScreenGui, keyboard/touch compatible.
-- Trivia answers are server-checked; clients never receive the solution key.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local event=ReplicatedStorage:WaitForChild("StoryXGalleryEvent")
local gui=Instance.new("ScreenGui")
gui.Name="StoryXGalleryReader";gui.ResetOnSpawn=false
gui.DisplayOrder=92;gui.Parent=player:WaitForChild("PlayerGui")
local panel=Instance.new("Frame")
panel.Name="GalleryBook"
panel.AnchorPoint=Vector2.new(0.5,0.5)
panel.Position=UDim2.fromScale(0.5,0.5)
panel.Size=UDim2.new(0.94,0,0.85,0)
panel.BackgroundColor3=Color3.fromRGB(10,22,39)
panel.BorderSizePixel=0
panel.Visible=false
panel.Parent=gui
local bounds=Instance.new("UISizeConstraint")
bounds.MaxSize=Vector2.new(740,680);bounds.Parent=panel
local corner=Instance.new("UICorner")
corner.CornerRadius=UDim.new(0,12);corner.Parent=panel
local outline=Instance.new("UIStroke")
outline.Color=Color3.fromRGB(47,210,192)
outline.Thickness=1.5;outline.Parent=panel
local title=Instance.new("TextLabel")
title.Size=UDim2.new(1,-78,0,44)
title.Position=UDim2.fromOffset(18,9)
title.BackgroundTransparency=1
title.TextColor3=Color3.fromRGB(85,254,210)
title.Text="СЮЖЕТ ИКС / ГАЛЕРЕЯ"
title.TextSize=21;title.Font=Enum.Font.GothamBlack
title.TextXAlignment=Enum.TextXAlignment.Left
title.TextWrapped=true;title.Parent=panel
local close=Instance.new("TextButton")
close.Size=UDim2.fromOffset(43,43);close.Position=UDim2.new(1,-53,0,8)
close.Text="×";close.TextSize=28
close.TextColor3=Color3.new(1,1,1);close.BackgroundTransparency=1
close.Parent=panel
close.Activated:Connect(function()panel.Visible=false end)
local progress=Instance.new("TextLabel")
progress.Position=UDim2.fromOffset(16,54)
progress.Size=UDim2.new(1,-32,0,26)
progress.TextColor3=Color3.fromRGB(235,212,140)
progress.BackgroundTransparency=1
progress.TextSize=14;progress.Font=Enum.Font.GothamBold
progress.Text="Исследование галереи • прогресс текущего сеанса"
progress.TextXAlignment=Enum.TextXAlignment.Left
progress.Parent=panel
local scroll=Instance.new("ScrollingFrame")
scroll.Name="ExhibitPages"
scroll.Position=UDim2.new(0,16,0,87)
scroll.Size=UDim2.new(1,-32,1,-105)
scroll.BackgroundColor3=Color3.fromRGB(17,34,54)
scroll.BorderSizePixel=0
scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
scroll.CanvasSize=UDim2.fromScale(0,0)
scroll.ScrollBarThickness=5
scroll.Parent=panel
local padding=Instance.new("UIPadding")
padding.PaddingLeft=UDim.new(0,9);padding.PaddingRight=UDim.new(0,9)
padding.PaddingTop=UDim.new(0,8);padding.PaddingBottom=UDim.new(0,15)
padding.Parent=scroll
local layout=Instance.new("UIListLayout")
layout.SortOrder=Enum.SortOrder.LayoutOrder
layout.Padding=UDim.new(0,12)
layout.Parent=scroll
local function clear()
 for _,child in ipairs(scroll:GetChildren()) do
  if child:IsA("TextLabel") or child:IsA("TextButton") then child:Destroy() end
 end
 scroll.CanvasPosition=Vector2.zero
end
local order=0
local function prose(value,font,size,color)
 order+=1
 local txt=Instance.new("TextLabel")
 txt.Name="GalleryText_"..order
 txt.LayoutOrder=order
 txt.BackgroundTransparency=1
 txt.Text=tostring(value)
 txt.TextWrapped=true
 txt.AutomaticSize=Enum.AutomaticSize.Y
 txt.Size=UDim2.new(1,-8,0,0)
 txt.TextXAlignment=Enum.TextXAlignment.Left
 txt.TextYAlignment=Enum.TextYAlignment.Top
 txt.TextSize=size or 16
 txt.Font=font or Enum.Font.Gotham
 txt.TextColor3=color or Color3.fromRGB(217,244,242)
 txt.Parent=scroll
 return txt
end
local function actionButton(value,fn)
 order+=1
 local button=Instance.new("TextButton")
 button.Name="GalleryButton_"..order
 button.LayoutOrder=order
 button.Size=UDim2.new(1,-10,0,51)
 button.Text=tostring(value);button.TextSize=15
 button.TextWrapped=true
 button.Font=Enum.Font.GothamBold
 button.TextColor3=Color3.fromRGB(246,255,249)
 button.BackgroundColor3=Color3.fromRGB(32,86,110)
 button.Parent=scroll
 local round=Instance.new("UICorner")
 round.CornerRadius=UDim.new(0,8);round.Parent=button
 button.Activated:Connect(fn)
 return button
end
local current=nil
local feedback=nil
local answered=false
local function showExhibit(data)
 if not data or not data.entry then return end
 current=data.entry
 answered=data.solved==true
 panel.Visible=true;order=0;clear()
 title.Text=current.title
 prose(current.subtitle,Enum.Font.GothamBold,18,Color3.fromRGB(190,158,255))
 prose("ИСТОРИЯ",Enum.Font.GothamBlack,13,Color3.fromRGB(105,254,217))
 prose(current.scene,Enum.Font.Gotham,17)
 prose("ВОПРОС ДЛЯ РАЗМЫШЛЕНИЯ",Enum.Font.GothamBlack,13,Color3.fromRGB(105,254,217))
 prose(current.reflection,Enum.Font.GothamBold,16,Color3.fromRGB(244,206,126))
 prose(current.question,Enum.Font.GothamBold,17)
 feedback=prose(answered and "Экспонат уже изучен в этом сеансе." or
  "Найди ответ в сюжете. Ошибка не отнимает очки.",Enum.Font.Gotham,14,
  Color3.fromRGB(244,206,126))
 for index,option in ipairs(current.options) do
  local answerIndex=index
  local btn=actionButton(index..". "..option,function()
   if answered or not current then return end
   event:FireServer("Answer",current.id,answerIndex)
  end)
  if answered then btn.BackgroundColor3=Color3.fromRGB(47,67,78) end
 end
 prose("Знакомство с художественными сценами добровольно. Это авторская адаптация мира «Сюжета Икс», а не полные главы романа.",Enum.Font.Gotham,12,
  Color3.fromRGB(177,190,199))
end
local function showCatalog(rows)
 current=nil;panel.Visible=true;title.Text="ГАЛЕРЕЯ • ПУТЕВОДИТЕЛЬ"
 order=0;clear()
 prose("Восемь сюжетных сцен расположены по обеим сторонам зала. Подойди к подсвеченной стойке перед картиной, чтобы открыть историю.",Enum.Font.Gotham,17)
 for i,entry in ipairs(rows) do
  prose(i..". "..entry.title.." — "..entry.subtitle,Enum.Font.GothamBold,16)
 end
 prose("Здесь можно смотреть произведения без участия в викторине. Новые картины подключаются после загрузки и проверки прав на изображения.",Enum.Font.Gotham,13)
end
event.OnClientEvent:Connect(function(kind,data)
 if kind=="Entered" then
  panel.Visible=true
  title.Text="ДОБРО ПОЖАЛОВАТЬ В ГАЛЕРЕЮ X"
  order=0;clear()
  prose("Ты вошёл в галерею философской фантастики «Сюжет Икс». Исследуй картины и решай загадки по желанию.",Enum.Font.Gotham,19)
  prose("Для начала подойди к куратору в центре или к одному из восьми стендов. Дорога обратно находится возле входа.",Enum.Font.Gotham,16)
 elseif kind=="Catalog" then
  showCatalog(data or {})
 elseif kind=="OpenExhibit" then
  showExhibit(data)
 elseif kind=="Response" and data and current and data.id==current.id then
  if data.correct then
   answered=true
   feedback.Text=data.already and "Этот фрагмент уже изучен." or
    ("Верно! "..tostring(data.explanation or ""))
  else
   feedback.Text=tostring(data.explanation or "Попробуй ещё раз.")
  end
 elseif kind=="Progress" and data then
  progress.Text="Посещено: "..tostring(data.visited or 0)..
   "/"..tostring(data.total or 8)..
   " • Решено: "..tostring(data.solved or 0)..
   " • прогресс только в текущем сеансе"
 elseif kind=="Exit" then
  panel.Visible=false;current=nil
 end
end)
