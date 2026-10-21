--!strict
-- YUGATNEO MATRIX: spiral ascent to an independent Chess Summit.
local Workspace = game:GetService("Workspace")
local NAME = "YUGATNEO_SPIRAL_LEVEL"
local old = Workspace:FindFirstChild(NAME)
if old then old:Destroy() end
local level = Instance.new("Folder")
level.Name = NAME
level.Parent = Workspace
local CENTER = Vector3.new(500, 0, 0)
local CYAN = Color3.fromRGB(0, 255, 225)
local GREEN = Color3.fromRGB(70, 255, 135)
local PURPLE = Color3.fromRGB(155, 70, 255)
local DARK = Color3.fromRGB(5, 12, 27)

local function part(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, transparency: number?, collide: boolean?)
 local p=Instance.new("Part"); p.Name=name; p.Size=size; p.CFrame=cf; p.Anchored=true; p.Color=color; p.Material=material
 p.Transparency=transparency or 0; p.CanCollide=collide==true; p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth; p.Parent=level
 return p
end
local function line(name: string, a: Vector3, b: Vector3, thickness: number, color: Color3)
 local d=b-a
 return part(name,Vector3.new(thickness,thickness,d.Magnitude),CFrame.lookAt((a+b)/2,b),color,Enum.Material.Neon,0.1,false)
end
local function holo(anchor: BasePart, text: string, width: number, height: number, color: Color3, offset: Vector3)
 local g=Instance.new("BillboardGui"); g.Name="SpiralHologram"; g.Adornee=anchor; g.Size=UDim2.fromOffset(width,height); g.StudsOffsetWorldSpace=offset; g.AlwaysOnTop=true; g.MaxDistance=1500; g.Parent=anchor
 local l=Instance.new("TextLabel"); l.Size=UDim2.fromScale(1,1); l.BackgroundTransparency=1; l.Text=text; l.TextColor3=color; l.TextStrokeColor3=Color3.fromRGB(0,20,35); l.TextStrokeTransparency=0.1; l.TextScaled=true; l.Font=Enum.Font.GothamBlack; l.Parent=g
end

-- Approach bridge from the edge of the existing Matrix island.
part("SpiralApproachBridge",Vector3.new(260,2,18),CFrame.new(330,1,0),Color3.fromRGB(8,23,42),Enum.Material.Metal,0,true)
line("ApproachRail_North",Vector3.new(200,2.2,-9),Vector3.new(460,2.2,-9),0.35,CYAN)
line("ApproachRail_South",Vector3.new(200,2.2,9),Vector3.new(460,2.2,9),0.35,PURPLE)
for x=215,455,20 do part("BridgeMarker_"..x,Vector3.new(1,0.15,15),CFrame.new(x,2.1,0),CYAN,Enum.Material.Neon,0.2,false) end

-- 4.5 turns; collidable treads let players climb the spiral.
local RADIUS, STEPS, RISE = 42,72,1.62
local previousRail: Vector3? = nil
for i=0,STEPS-1 do
 local angle=i*math.rad(22.5); local y=3+i*RISE
 local x=CENTER.X+math.cos(angle)*RADIUS; local z=CENTER.Z+math.sin(angle)*RADIUS
 local cf=CFrame.new(x,y,z)*CFrame.Angles(0,-angle,0)
 part("SpiralTread_"..string.format("%02d",i+1),Vector3.new(14,1.2,7),cf,Color3.fromRGB(8,22,40),Enum.Material.Metal,0,true)
 part("SpiralGlow_"..string.format("%02d",i+1),Vector3.new(13.5,0.12,6.5),cf*CFrame.new(0,0.67,0),i%4==0 and GREEN or CYAN,Enum.Material.Neon,0.2,false)
 local rail=Vector3.new(x+math.cos(angle)*6,y+3.2,z+math.sin(angle)*6)
 if previousRail then line("SpiralRail_"..i,previousRail,rail,0.25,i%6==0 and PURPLE or CYAN) end
 previousRail=rail
 if i%6==0 then
  local beacon=part("SpiralBeacon_"..i,Vector3.new(1.1,5,1.1),CFrame.new(x,y+3,z),PURPLE,Enum.Material.Neon,0.12,false)
  local light=Instance.new("PointLight"); light.Color=PURPLE; light.Range=16; light.Brightness=1.1; light.Parent=beacon
 end
end

part("SpiralCore",Vector3.new(7,132,7),CFrame.new(CENTER.X,62,CENTER.Z),Color3.fromRGB(7,25,44),Enum.Material.Glass,0.2,false)
for i=0,5 do local a=i*math.pi/3; part("CoreLight_"..i,Vector3.new(0.22,128,0.22),CFrame.new(CENTER.X+math.cos(a)*4.5,62,math.sin(a)*4.5),CYAN,Enum.Material.Neon,0.1,false) end

-- Independent summit. Chess board sits at y=121 in its own script.
local summitY=3+(STEPS-1)*RISE+7
part("ChessSummitPlatform",Vector3.new(84,5,84),CFrame.new(CENTER.X,summitY,CENTER.Z),DARK,Enum.Material.Metal,0,true)
for i=1,4 do
 local data={{0,-41},{0,41},{-41,0},{41,0}}[i]
 local sx=(data[1]==0) and 82 or 0.6; local sz=(data[2]==0) and 82 or 0.6
 part("SummitEdge_"..i,Vector3.new(sx,0.35,sz),CFrame.new(CENTER.X+data[1],summitY+2.7,data[2]),CYAN,Enum.Material.Neon,0.08,false)
end
local title=part("ChessSummitTitleAnchor",Vector3.new(1,1,1),CFrame.new(CENTER.X,summitY+27,-30),CYAN,Enum.Material.Neon,1,false)
holo(title,"YUGATNEO MATRIX",900,110,CYAN,Vector3.zero)
local sub=part("ChessSummitSubtitleAnchor",Vector3.new(1,1,1),CFrame.new(CENTER.X,summitY+19,-30),GREEN,Enum.Material.Neon,1,false)
holo(sub,"CHESS SUMMIT  /  STRATEGY IS ANOTHER WAY TO EXPLORE",780,54,GREEN,Vector3.zero)
local plaque=part("ChessSummitPlaque",Vector3.new(14,6,1),CFrame.new(CENTER.X,summitY+6,-34),Color3.fromRGB(6,19,35),Enum.Material.Metal,0,true)
holo(plaque,"CHESS LEVEL\nTwo minds. One board. Many possible futures.",400,100,CYAN,Vector3.new(0,5,0))
for i=1,12 do
 local a=i*math.pi/6; local x=CENTER.X+math.cos(a)*53; local z=math.sin(a)*53
 local p=part("SummitBeacon_"..i,Vector3.new(1.2,8,1.2),CFrame.new(x,summitY+5,z),i%2==0 and CYAN or PURPLE,Enum.Material.Neon,0.12,false)
 local light=Instance.new("PointLight"); light.Color=p.Color; light.Range=18; light.Brightness=0.7; light.Parent=p
end
print("[YUGATNEO MATRIX] Spiral route and independent Chess Summit created.")
