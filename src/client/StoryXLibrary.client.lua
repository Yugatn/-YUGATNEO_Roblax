-- Story X Library: readable pages, two-stage reading race, notes and live standings.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local event=RS:WaitForChild("LibraryEvent")
local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui")
gui.Name="StoryXLibraryUI"
gui.ResetOnSpawn=false
gui.DisplayOrder=95
gui.Parent=player:WaitForChild("PlayerGui")
local base=Instance.new("Frame")
base.Name="Reader"
base.AnchorPoint=Vector2.new(.5,.5)
base.Position=UDim2.fromScale(.5,.5)
base.Size=UDim2.new(.95,0,.92,0)
base.BackgroundColor3=Color3.fromRGB(10,23,41)
base.BorderSizePixel=0
base.Visible=false
base.Parent=gui
local limits=Instance.new("UISizeConstraint")
limits.MaxSize=Vector2.new(780,750)
limits.MinSize=Vector2.new(295,300)
limits.Parent=base
local corners=Instance.new("UICorner")
corners.CornerRadius=UDim.new(0,14)
corners.Parent=base

local function createText(name,text,pos,size,fontSize)
    local label=Instance.new("TextLabel")
    label.Name=name
    label.Position=pos
    label.Size=size
    label.BackgroundTransparency=1
    label.Text=text
    label.TextSize=fontSize or 16
    label.TextColor3=Color3.fromRGB(225,244,244)
    label.TextWrapped=true
    label.Font=Enum.Font.Gotham
    label.TextXAlignment=Enum.TextXAlignment.Left
    label.TextYAlignment=Enum.TextYAlignment.Top
    label.Parent=base
    return label
end
local heading=createText("Title","LIBRARY",UDim2.new(.035,0,.025,0),UDim2.new(.85,0,.10,0),20)
heading.Font=Enum.Font.GothamBold
local status=createText("Instructions","Read, find clues, and understand.",UDim2.new(.035,0,.13,0),
    UDim2.new(.92,0,.08,0),14)
local scroll=Instance.new("ScrollingFrame")
scroll.Name="Pages"
scroll.Position=UDim2.new(.035,0,.215,0)
scroll.Size=UDim2.new(.93,0,.38,0)
scroll.ScrollBarThickness=6
scroll.BackgroundColor3=Color3.fromRGB(20,36,55)
scroll.BorderSizePixel=0
scroll.CanvasSize=UDim2.fromScale(0,0)
scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
scroll.Parent=base
local padding=Instance.new("UIPadding")
padding.PaddingLeft=UDim.new(0,12)
padding.PaddingRight=UDim.new(0,12)
padding.PaddingTop=UDim.new(0,10)
padding.PaddingBottom=UDim.new(0,10)
padding.Parent=scroll
local layout=Instance.new("UIListLayout")
layout.Padding=UDim.new(0,12)
layout.Parent=scroll
local choicePanel=Instance.new("Frame")
choicePanel.Name="Choices"
choicePanel.Position=UDim2.new(.035,0,.64,0)
choicePanel.Size=UDim2.new(.93,0,.21,0)
choicePanel.BackgroundTransparency=1
choicePanel.Parent=base
local choiceGrid=Instance.new("UIGridLayout")
choiceGrid.FillDirectionMaxCells=2
choiceGrid.CellPadding=UDim2.new(.015,0,.04,0)
choiceGrid.CellSize=UDim2.new(.48,0,.44,0)
choiceGrid.Parent=choicePanel

local notes=Instance.new("TextBox")
notes.Name="PersonalNotes"
notes.Position=UDim2.new(.035,0,.87,0)
notes.Size=UDim2.new(.65,0,.07,0)
notes.Text=""
notes.PlaceholderText="My private notes (max. 350 characters)"
notes.ClearTextOnFocus=false
notes.TextColor3=Color3.new(1,1,1)
notes.TextSize=13
notes.Font=Enum.Font.Gotham
notes.BackgroundColor3=Color3.fromRGB(25,52,70)
notes.Parent=base
local currentBook,working=false,false
local function button(text,parent,callback)
    local b=Instance.new("TextButton")
    b.Size=UDim2.fromScale(1,1)
    b.BackgroundColor3=Color3.fromRGB(25,110,120)
    b.Font=Enum.Font.GothamBold
    b.TextSize=13
    b.TextWrapped=true
    b.TextColor3=Color3.new(1,1,1)
    b.Text=text
    b.Parent=parent
    local c=Instance.new("UICorner")
    c.CornerRadius=UDim.new(0,7)
    c.Parent=b
    b.Activated:Connect(callback)
    return b
end
local saveButton=Instance.new("TextButton")
saveButton.Name="SaveNotes"
saveButton.Position=UDim2.new(.69,0,.87,0)
saveButton.Size=UDim2.new(.26,0,.07,0)
saveButton.Text="SAVE NOTES"
saveButton.TextSize=12
saveButton.Font=Enum.Font.GothamBold
saveButton.TextColor3=Color3.new(1,1,1)
saveButton.BackgroundColor3=Color3.fromRGB(100,80,140)
saveButton.Parent=base
saveButton.Activated:Connect(function()
    if currentBook and #notes.Text>0 and #notes.Text<=350 then
        event:FireServer("SaveNote",currentBook.id,notes.Text)
    end
end)
local close=Instance.new("TextButton")
close.Size=UDim2.new(.10,0,.075,0)
close.Position=UDim2.new(.88,0,.015,0)
close.Text="×"
close.TextSize=25
close.TextColor3=Color3.new(1,1,1)
close.BackgroundTransparency=1
close.Parent=base
close.Activated:Connect(function()
    base.Visible=false
    currentBook=nil
end)
local function clearChoices()
    for _,obj in ipairs(choicePanel:GetChildren()) do
        if obj:IsA("TextButton") then obj:Destroy() end
    end
end
local function begin()
    if not currentBook then return end
    working=true
    clearChoices()
    event:FireServer("Start",currentBook.id)
    status.Text="Challenge started. Find the paragraph, then answer the question."
end
local function showStart()
    clearChoices()
    button("START READING RACE",choicePanel,begin)
end
local best={}
local function displayBook(book,note)
    currentBook=book
    working=false
    base.Visible=true
    heading.Text=book.title .. " · " .. book.language .. " · " .. book.age
    status.Text="Read the story. Then find a paragraph and solve a comprehension question."
    notes.Text=note or ""
    for _,obj in ipairs(scroll:GetChildren()) do
        if obj:IsA("TextLabel") then obj:Destroy() end
    end
    for i,paragraph in ipairs(book.paragraphs) do
        local row=Instance.new("TextLabel")
        row.Name="Paragraph_"..i
        row.LayoutOrder=i
        row.Size=UDim2.new(1,-6,0,0)
        row.AutomaticSize=Enum.AutomaticSize.Y
        row.BackgroundTransparency=1
        row.Text=tostring(i) .. ".  " .. paragraph
        row.TextSize=16
        row.TextWrapped=true
        row.TextColor3=Color3.fromRGB(238,243,233)
        row.Font=Enum.Font.Gotham
        row.TextXAlignment=Enum.TextXAlignment.Left
        row.TextYAlignment=Enum.TextYAlignment.Top
        row.Parent=scroll
    end
    scroll.CanvasPosition=Vector2.zero
    showStart()
end
event.OnClientEvent:Connect(function(action,a,b)
    if action=="Book" then
        displayBook(a,b)
    elseif action=="Question" then
        local data=a
        if not currentBook or data.bookId~=currentBook.id then return end
        clearChoices()
        status.Text=data.prompt
        for index,word in ipairs(data.choices) do
            button(tostring(word),choicePanel,function()
                if not working then return end
                working=false
                event:FireServer("Answer",currentBook.id,index)
            end)
        end
        working=true
    elseif action=="Feedback" then
        status.Text=tostring(b)
        working=true
    elseif action=="Completed" then
        local result=a
        working=false
        status.Text=string.format("Finished in %.1f seconds. +%d coins!",result.seconds,result.reward)
        showStart()
    elseif action=="Saved" then
        if currentBook and a==currentBook.id then
            notes.Text=b
            status.Text="Private note saved and filtered."
        end
    elseif action=="Leaderboard" then
        best=a
    end
end)
