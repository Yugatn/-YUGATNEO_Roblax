-- STORY X Gallery: mobile-friendly illustrated chapters and inquiry cards.
-- Never sends arbitrary points or user-generated text to other players.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local remote=ReplicatedStorage:WaitForChild("StoryXGalleryEvent")
local gui=Instance.new("ScreenGui")
gui.Name="StoryXGalleryReader";gui.ResetOnSpawn=false;gui.DisplayOrder=72
gui.Parent=player:WaitForChild("PlayerGui")
local shell=Instance.new("Frame")
shell.Name="GalleryChapter"
shell.AnchorPoint=Vector2.new(0.5,0.5)
shell.Position=UDim2.fromScale(0.5,0.5)
shell.Size=UDim2.new(0.93,0,0.84,0)
shell.BackgroundColor3=Color3.fromRGB(9,19,35)
shell.BorderSizePixel=0;shell.Visible=false;shell.Parent=gui
local size=Instance.new("UISizeConstraint")
size.MaxSize=Vector2.new(720,720);size.MinSize=Vector2.new(280,300);size.Parent=shell
local corner=Instance.new("UICorner")
corner.CornerRadius=UDim.new(0,12);corner.Parent=shell
local function makeLabel(text,sizeY,fontSize)
 local t=Instance.new("TextLabel")
 t.Size=UDim2.new(1,-20,0,sizeY)
 t.BackgroundTransparency=1
 t.TextColor3=Color3.fromRGB(206,246,229)
 t.TextWrapped=true;t.TextXAlignment=Enum.TextXAlignment.Left
 t.Font=Enum.Font.Gotham;t.TextSize=fontSize or 16
 t.Text=text;t.Parent=nil
 return t
end
local head=makeLabel("ГАЛЕРЕЯ СЮЖЕТА ИКС",45,20)
head.Position=UDim2.fromOffset(14,12);head.Font=Enum.Font.GothamBold;head.Parent=shell
local exit=Instance.new("TextButton")
exit.Size=UDim2.fromOffset(39,39);exit.Position=UDim2.new(1,-48,0,8)
exit.Text="×";exit.TextSize=27;exit.Font=Enum.Font.GothamBold
exit.TextColor3=Color3.new(1,1,1);exit.BackgroundTransparency=1;exit.Parent=shell
exit.Activated:Connect(function()shell.Visible=false end)
local scroll=Instance.new("ScrollingFrame")
scroll.Position=UDim2.new(0,12,0,65);scroll.Size=UDim2.new(1,-24,1,-82)
scroll.ScrollBarThickness=5;scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
scroll.CanvasSize=UDim2.fromOffset(0,0)
scroll.BackgroundTransparency=1;scroll.Parent=shell
local layout=Instance.new("UIListLayout")
layout.Padding=UDim.new(0,10);layout.SortOrder=Enum.SortOrder.LayoutOrder
layout.Parent=scroll
local function clear()
 for _,child in ipairs(scroll:GetChildren()) do
  if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("ImageLabel") then child:Destroy() end
 end
end
local function paragraph(txt,height,fontSize)
 local t=makeLabel(txt,height,fontSize)
 t.Parent=scroll
 return t
end
local function button(txt,callback)
 local b=Instance.new("TextButton")
 b.Size=UDim2.new(1,-16,0,52)
 b.TextColor3=Color3.fromRGB(251,253,254)
 b.TextSize=15;b.TextWrapped=true
 b.Font=Enum.Font.GothamBold
 b.Text=txt;b.BackgroundColor3=Color3.fromRGB(32,75,103)
 b.BorderSizePixel=0;b.Parent=scroll
 local r=Instance.new("UICorner");r.CornerRadius=UDim.new(0,8);r.Parent=b
 b.Activated:Connect(callback)
 return b
end
-- An optional in-world guide uses only per-player client highlights.
-- No timer, mandatory quiz or navigational information about other players.
local guide=Instance.new("Frame")
guide.Name="GuidedTour"
guide.Position=UDim2.new(0,12,0,88)
guide.Size=UDim2.fromOffset(282,124)
guide.BackgroundColor3=Color3.fromRGB(8,31,43)
guide.BorderSizePixel=0;guide.Visible=false
guide.Parent=gui
local guideCorner=Instance.new("UICorner")
guideCorner.CornerRadius=UDim.new(0,10);guideCorner.Parent=guide
local guideLabel=Instance.new("TextLabel")
guideLabel.Position=UDim2.fromOffset(10,8)
guideLabel.Size=UDim2.new(1,-20,0,66)
guideLabel.BackgroundTransparency=1
guideLabel.TextColor3=Color3.fromRGB(175,250,222)
guideLabel.Font=Enum.Font.GothamBold
guideLabel.TextWrapped=true
guideLabel.TextSize=14
guideLabel.Text="Экскурсия"
guideLabel.Parent=guide
local stop=Instance.new("TextButton")
stop.Position=UDim2.new(0,10,1,-42)
stop.Size=UDim2.new(1,-20,0,34)
stop.Text="ЗАВЕРШИТЬ ЭКСКУРСИЮ"
stop.TextColor3=Color3.new(1,1,1)
stop.TextSize=13;stop.Font=Enum.Font.GothamBold
stop.BackgroundColor3=Color3.fromRGB(38,89,102)
stop.Parent=guide
stop.Activated:Connect(function()remote:FireServer("StopTour")end)
local marker=Instance.new("Highlight")
marker.Name="NextStoryXArtwork"
marker.FillTransparency=0.86
marker.OutlineTransparency=0.05
marker.OutlineColor=Color3.fromRGB(248,211,92)
marker.FillColor=Color3.fromRGB(93,251,219)
marker.DepthMode=Enum.HighlightDepthMode.Occluded
marker.Enabled=false
-- Highlights must live in Workspace (client-only instance) to render on 3D parts.
marker.Parent=workspace
local function tourUpdate(info)
 if not info or not info.active then
  guide.Visible=false;marker.Enabled=false;marker.Adornee=nil
  return
 end
 guide.Visible=true
 guideLabel.Text="ЭКСКУРСИЯ • "..tostring(info.index).."/"..tostring(info.total)..
  "\nСледующий экспонат: "..tostring(info.nextTitle or "—")
 local world=workspace:FindFirstChild("STORY_X_GALLERY")
 local kiosk=world and world:FindFirstChild("Kiosk_"..tostring(info.nextId))
 if kiosk then
  marker.Adornee=kiosk
  marker.Enabled=true
 else
  marker.Enabled=false;marker.Adornee=nil
 end
end

local current
local progressLabel
local answerLabel
local score={completed=0,total=10,solved={},seen={}}
local function show(exhibit)
 current=exhibit
 shell.Visible=true
 clear()
 progressLabel=nil;answerLabel=nil
 head.Text="ГАЛЕРЕЯ X / "..exhibit.title
 paragraph("ГЛАВА: "..exhibit.chapter,54,15)
 if exhibit.imageAsset and exhibit.imageAsset>0 then
  local image=Instance.new("ImageLabel")
  image.Size=UDim2.new(1,-18,0,155)
  image.BackgroundTransparency=1;image.ScaleType=Enum.ScaleType.Fit
  image.Image="rbxassetid://"..exhibit.imageAsset
  image.Parent=scroll
 else
  paragraph("◈  Голографическая визуализация находится в выставочном зале. ◈",56,14)
 end
 paragraph(exhibit.caption,math.max(95,math.ceil((utf8.len(exhibit.caption) or #exhibit.caption)/54)*29),17)
 paragraph(exhibit.story,math.max(154,math.ceil((utf8.len(exhibit.story) or #exhibit.story)/54)*29),16)
 paragraph("ВОПРОС ДЛЯ ИССЛЕДОВАТЕЛЯ",36,17)
 paragraph(exhibit.question,math.max(68,math.ceil((utf8.len(exhibit.question) or #exhibit.question)/54)*28),15)
 for i,option in ipairs(exhibit.options) do
  local answer=i
  button(i..". "..option,function()
   if current and current.id==exhibit.id then
    remote:FireServer("Answer",exhibit.id,answer)
   end
  end)
 end
 paragraph("Ответ проверяется сервером. Экспозиция доступна без обязательного прохождения.",75,13)
 answerLabel=paragraph("",46,15)
 progressLabel=paragraph("Исследовано: "..tostring(score.completed).."/"..tostring(score.total),56,14)
 scroll.CanvasPosition=Vector2.zero
end
local function showAtlas(index)
 current=nil
 shell.Visible=true
 clear()
 progressLabel=nil;answerLabel=nil
 head.Text="АТЛАС X / ИСТОРИИ"
 paragraph("ЛИЧНЫЙ АТЛАС • без таймера и обязательных ответов",58,16)
 for n,entry in ipairs(index.entries or {}) do
  local isSeen=index.seen and index.seen[entry.id]
  local isSolved=index.solved and index.solved[entry.id]
  local state=isSolved and "● Изучено" or (isSeen and "○ Просмотрено" or "◇ Не открыто")
  button(n..". "..entry.title.." • "..state,function()
   clear()
   head.Text="АТЛАС X / "..entry.title
   paragraph(entry.chapter,50,16)
   paragraph(entry.caption,110,16)
   paragraph(entry.story,180,15)
   paragraph("Для ответов на вопросы подойди к картине в зале. "..
    "Все материалы доступны без экзамена.",100,13)
   button("← К АТЛАСУ",function()showAtlas(index)end)
   scroll.CanvasPosition=Vector2.zero
  end)
 end
 scroll.CanvasPosition=Vector2.zero
end
remote.OnClientEvent:Connect(function(action,payload)
 if action=="Exhibit" then
  show(payload)
 elseif action=="Atlas" then
  showAtlas(payload)
 elseif action=="Progress" then
  score=payload or score
  if progressLabel then
   progressLabel.Text="Исследовано: "..tostring(score.completed).."/"..tostring(score.total)..
    (score.persistent and " • прогресс сохраняется" or " • сохранение недоступно")
  end
 elseif action=="AnswerResult" then
  if current and payload.id==current.id and answerLabel then
   answerLabel.Text=payload.correct and
    "✓ Ответ принят! Экспонат изучен." or
    "Пока неверно. Проверь сюжетную карточку ещё раз."
  end
 elseif action=="Tour" then
  tourUpdate(payload)
 elseif action=="Notice" then
  shell.Visible=true
  clear()
  paragraph(tostring(payload),100,17)
 end
end)

-- Guide state is server-scoped. Request once after loading this LocalScript;
-- the server will reject requests from outside its gallery.
task.defer(function()remote:FireServer("Status")end)
player.CharacterAdded:Connect(function()
 guide.Visible=false;marker.Enabled=false;marker.Adornee=nil
end)
