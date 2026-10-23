-- STORY X / YUGATNEO MATRIX: discoverable, peaceful and age-friendly narrative gallery.
-- Standalone world near the spiral; no assets from copyrighted films are embedded.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Catalog=require(script.Parent:WaitForChild("StoryXGalleryCatalog"))
local Images=require(script.Parent:WaitForChild("StoryXGalleryAssets"))
local FOLDER_NAME="STORY_X_INTERACTIVE_GALLERY"
local old=workspace:FindFirstChild(FOLDER_NAME)
if old then old:Destroy() end
local folder=Instance.new("Folder");folder.Name=FOLDER_NAME;folder.Parent=workspace
local event=ReplicatedStorage:FindFirstChild("StoryXGalleryEvent")
if not event then event=Instance.new("RemoteEvent");event.Name="StoryXGalleryEvent";event.Parent=ReplicatedStorage end
local center=Vector3.new(3440,19,0)
local CYAN=Color3.fromRGB(54,247,219)
local PURPLE=Color3.fromRGB(149,99,250)
local GOLD=Color3.fromRGB(242,191,90)
local GREEN=Color3.fromRGB(104,244,146)
local BLUE=Color3.fromRGB(78,169,252)
local DARK=Color3.fromRGB(9,19,38)
local tints={cyan=CYAN,purple=PURPLE,gold=GOLD,green=GREEN,blue=BLUE}
local session,lastRequest={},{}
local function block(parent,name,size,cf,color,collides,material,transparency)
    local p=Instance.new("Part")
    p.Name=name;p.Size=size;p.CFrame=cf
    p.Color=color;p.Anchored=true;p.CanCollide=collides==true
    p.Material=material or Enum.Material.Metal
    p.Transparency=transparency or 0
    p.Parent=parent
    return p
end
local function label(anchor,message,tint,w,h)
    local gui=Instance.new("BillboardGui")
    gui.Name="GalleryLabel";gui.Size=UDim2.fromOffset(w or 320,h or 88)
    gui.StudsOffsetWorldSpace=Vector3.new(0,5,0)
    gui.AlwaysOnTop=true;gui.MaxDistance=155;gui.Parent=anchor
    local txt=Instance.new("TextLabel")
    txt.Size=UDim2.fromScale(1,1);txt.BackgroundTransparency=1
    txt.TextColor3=tint or CYAN;txt.TextStrokeTransparency=0.3
    txt.Font=Enum.Font.GothamBold;txt.TextScaled=true;txt.TextWrapped=true
    txt.Text=message;txt.Parent=gui
end
local function prompt(anchor,action,title,callback)
    local p=Instance.new("ProximityPrompt")
    p.Name="GalleryInteract";p.ActionText=action;p.ObjectText=title
    p.HoldDuration=0.15;p.MaxActivationDistance=12
    p.RequiresLineOfSight=false;p.Parent=anchor;p.Triggered:Connect(callback)
end
local function root(player)
    local c=player.Character
    local h=c and c:FindFirstChildOfClass("Humanoid")
    if not h or h.Health<=0 then return nil end
    return c:FindFirstChild("HumanoidRootPart")
end
local function close(player,point,range)
    local r=root(player)
    return r and (r.Position-point).Magnitude<=range
end
local function teleport(player,pos)
    if player:GetAttribute("InChessMatch") then return end
    local r=root(player)
    if r then
        r.AssemblyLinearVelocity=Vector3.zero
        r.CFrame=CFrame.new(pos)
    end
end
local function getSession(p)
    if not session[p] then session[p]={seen={},solved={},activeId=nil,selectedAt=0} end
    return session[p]
end
local function counts(s)
    local visited,solved=0,0
    for _ in pairs(s.seen) do visited+=1 end
    for _ in pairs(s.solved) do solved+=1 end
    return visited,solved
end
local function state(p)
    local s=getSession(p)
    local visited,solved=counts(s)
    event:FireClient(p,"Progress",{
        visited=visited,solved=solved,total=#Catalog.entries,
        -- No persistent achievement claim: prototype stores visits in this server session.
        persistent=false,
    })
end

block(folder,"GalleryFloor",Vector3.new(146,2,116),CFrame.new(center),DARK,true,Enum.Material.Slate)
for _,x in ipairs({-72.5,72.5}) do
    block(folder,"SideWall",Vector3.new(2,21,116),
        CFrame.new(center+Vector3.new(x,10,0)),Color3.fromRGB(19,43,60),true)
end
for _,z in ipairs({-57.5,57.5}) do
    block(folder,"EndWall",Vector3.new(146,21,2),
        CFrame.new(center+Vector3.new(0,10,z)),Color3.fromRGB(19,43,60),true)
end
-- Low ceilings are deliberately omitted for a clear, accessible camera.
for _,x in ipairs({-50,-25,0,25,50}) do
    block(folder,"FloorGuideX",Vector3.new(0.25,0.09,98),
        CFrame.new(center+Vector3.new(x,1.07,0)),CYAN,false,Enum.Material.Neon,0.55)
end
for _,z in ipairs({-35,0,35}) do
    block(folder,"FloorGuideZ",Vector3.new(125,0.09,0.25),
        CFrame.new(center+Vector3.new(0,1.07,z)),PURPLE,false,Enum.Material.Neon,0.6)
end
local titleBoard=block(folder,"StoryXTitle",Vector3.new(62,5,1),
    CFrame.new(center+Vector3.new(0,14,-54)),PURPLE,false,Enum.Material.Neon)
label(titleBoard,"СЮЖЕТ ИКС / ГАЛЕРЕЯ ВОСПРИЯТИЯ\nYUGATNEO MATRIX • ART • QUESTIONS",CYAN,700,120)
local info=block(folder,"CuratorConsole",Vector3.new(11,5,6),
    CFrame.new(center+Vector3.new(0,3,0)),Color3.fromRGB(47,99,121),true,Enum.Material.Metal)
label(info,"КУРАТОР / КАРТА ВОСЬМИ ИСТОРИЙ",GOLD,370,75)
prompt(info,"Открыть каталог","Галерея X",function(p)
    if not close(p,info.Position,15) then return end
    local rows={}
    for _,entry in ipairs(Catalog.entries) do
        table.insert(rows,{id=entry.id,title=entry.title,subtitle=entry.subtitle})
    end
    event:FireClient(p,"Catalog",rows)
    state(p)
end)
-- Four exhibitions on each wall; walls face inward.
for i,entry in ipairs(Catalog.entries) do
    local index=(i-1)%4
    local north=i<=4
    local x=-53+index*(106/3)
    local z=north and -48 or 48
    local tint=tints[entry.color] or CYAN
    local exhibit=Instance.new("Model")
    exhibit.Name="Artwork_"..entry.id
    exhibit.Parent=folder
    local panelCF=CFrame.new(center+Vector3.new(x,9,z))
        *CFrame.Angles(0,north and math.pi or 0,0)
    local canvas=block(exhibit,"PixelCanvas",Vector3.new(23,17,0.8),panelCF,
        Color3.fromRGB(20,26,51),false)
    -- Thin illuminated frame pieces, not a solid overlay hiding the artwork.
    for _,side in ipairs({-1,1}) do
        block(exhibit,"FrameVertical_"..side,Vector3.new(0.75,18,0.3),
            panelCF*CFrame.new(side*12.0,0,-0.48),
            tint,false,Enum.Material.Neon,0.12)
        block(exhibit,"FrameHorizontal_"..side,Vector3.new(24,0.75,0.3),
            panelCF*CFrame.new(0,side*9,-0.48),
            tint,false,Enum.Material.Neon,0.12)
    end
    local surface=Instance.new("SurfaceGui")
    surface.Name="StoryXArtwork"
    surface.Face=Enum.NormalId.Front
    surface.PixelsPerStud=30
    surface.LightInfluence=0
    surface.Parent=canvas
    local background=Instance.new("Frame")
    background.Size=UDim2.fromScale(1,1)
    background.BorderSizePixel=0
    background.BackgroundColor3=Color3.fromRGB(10,16,32)
    background.Parent=surface
    local asset=Images.get(entry.id)
    if asset then
        local image=Instance.new("ImageLabel")
        image.Name="LicensedArt"
        image.Size=UDim2.fromScale(1,1)
        image.Image="rbxassetid://"..tostring(asset)
        image.ScaleType=Enum.ScaleType.Fit
        image.BackgroundTransparency=1
        image.Parent=background
    else
        -- Procedural pixel placeholder = immediately viewable art without uploads.
        local pattern=entry.pattern
        for y,line in ipairs(pattern) do
            for px=1,#line do
                if line:sub(px,px)=="1" then
                    local pixel=Instance.new("Frame")
                    pixel.BorderSizePixel=0
                    pixel.Size=UDim2.fromScale(0.063,0.072)
                    pixel.Position=UDim2.fromScale(0.2+(px-1)*0.065,0.13+(y-1)*0.078)
                    pixel.BackgroundColor3=tint
                    pixel.Parent=background
                end
            end
        end
    end
    local caption=block(exhibit,"ExhibitCaption",Vector3.new(22,1.5,0.8),
        panelCF*CFrame.new(0,-10,0),tint,false,Enum.Material.Neon,0.18)
    local kioskPos=center+Vector3.new(x,3,north and -34 or 34)
    local kiosk=block(exhibit,"ReadExhibit",Vector3.new(5,4,4),
        CFrame.new(kioskPos),tint,true)
    label(kiosk,entry.title.."\n"..entry.subtitle,tint,310,83)
    prompt(kiosk,"Исследовать","История / "..entry.id,function(p)
        if not close(p,kiosk.Position,16) then return end
        local s=getSession(p)
        s.activeId=entry.id;s.selectedAt=os.clock();s.seen[entry.id]=true
        event:FireClient(p,"OpenExhibit",{entry=Catalog.public(entry),
            solved=s.solved[entry.id]==true})
        state(p)
    end)
end
-- Theme-matched room exits. No portal steals players from chess or active team match.
local destinations={
    {"Spiral",Vector3.new(0,3,42),nil},
    {"Matrix",Vector3.new(-42,3,43),Vector3.new(0,6,13)},
    {"Library",Vector3.new(-20,3,43),Vector3.new(-139,5,64)},
    {"Chess",Vector3.new(22,3,43),Vector3.new(500,5,48)},
}
-- Portal to spiral turn 76: stairs/ramp geometry follows the existing helix formula.
local spiralStep=76
local a=math.pi+spiralStep*math.pi*6/144
local path=Vector3.new(500+120*math.cos(a),4+spiralStep*0.68,120*math.sin(a))
local radial=Vector3.new(math.cos(a),0,math.sin(a))
local platform=path+radial*26
local bridge=block(folder,"GallerySpiralBridge",Vector3.new(12,1.7,34),
    CFrame.lookAt((path+platform)*0.5,platform),DARK,true)
block(folder,"GallerySpiralLanding",Vector3.new(29,1.7,25),
    CFrame.new(platform),DARK,true)
local entry=block(folder,"GalleryEntrance",Vector3.new(7,7,4),
    CFrame.new(platform+Vector3.new(0,4,0)),CYAN,false,Enum.Material.Neon,0.18)
label(entry,"ГАЛЕРЕЯ СЮЖЕТА ИКС\nВОСЕМЬ ГЛАВ — ВОСЕМЬ КЛЮЧЕЙ",CYAN,440,88)
prompt(entry,"Войти","Сюжет Икс",function(p)
    if not close(p,entry.Position,16) then return end
    teleport(p,center+Vector3.new(0,5,25))
    state(p)
    event:FireClient(p,"Entered",{})
end)
destinations[1][3]=platform+Vector3.new(0,4,3)
for _,data in ipairs(destinations) do
    local name,offset,target=data[1],data[2],data[3]
    local gate=block(folder,"Exit_"..name,Vector3.new(9,5,4),
        CFrame.new(center+offset),name=="Spiral" and GOLD or CYAN,true,Enum.Material.Neon)
    label(gate,"ВЫХОД: "..name,GOLD,245,55)
    prompt(gate,"Перейти",name,function(p)
        if not close(p,gate.Position,16) then return end
        teleport(p,target)
        event:FireClient(p,"Exit",{})
    end)
end

event.OnServerEvent:Connect(function(p,action,id,choice)
    if type(action)~="string" then return end
    local now=os.clock()
    if now-(lastRequest[p] or -100)<0.22 then return end
    lastRequest[p]=now
    local s=getSession(p)
    if action=="GetProgress" then
        if close(p,center,90) then state(p) end
        return
    end
    if action~="Answer" or type(id)~="string" or #id>40 then return end
    if type(choice)~="number" or choice%1~=0 or choice<1 or choice>3 then return end
    if not close(p,center,90) or s.activeId~=id or now-s.selectedAt>300 then return end
    if s.solved[id] then
        event:FireClient(p,"Response",{id=id,correct=true,already=true})
        return
    end
    local correct=Catalog.verify(id,choice)
    if correct then s.solved[id]=true end
    local exhibit=Catalog.get(id)
    event:FireClient(p,"Response",{
        id=id,correct=correct,already=false,
        explanation=correct and exhibit.explanation
            or "Проверь текст экспоната и попробуй ещё раз.",
    })
    state(p)
end)
Players.PlayerRemoving:Connect(function(p)
    session[p]=nil;lastRequest[p]=nil
end)
print("[STORY X] Narrative gallery ready: eight original exhibits, puzzles and spiral entrance.")
