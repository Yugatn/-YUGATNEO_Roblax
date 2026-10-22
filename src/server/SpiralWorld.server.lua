-- YUGATNEO MATRIX / STORY X -- explorable, driveable helix around the chess hall.
-- Generated with primitive geometry: no untrusted toolbox asset dependencies.
local Players = game:GetService("Players")
local worldName = "YUGATNEO_SPIRAL_SERPENTINE"
local previous = workspace:FindFirstChild(worldName)
if previous then previous:Destroy() end
local world = Instance.new("Folder")
world.Name = worldName
world.Parent = workspace

local CENTER = Vector3.new(500, 0, 0)
local CYAN = Color3.fromRGB(0, 250, 220)
local GREEN = Color3.fromRGB(70, 255, 145)
local PURPLE = Color3.fromRGB(155, 90, 245)
local DARK = Color3.fromRGB(8, 17, 34)

local function create(name, size, cf, color, material, collide, transparency)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.CFrame = cf
    p.Anchored = true
    p.CanCollide = collide == true
    p.Material = material or Enum.Material.Metal
    p.Color = color
    p.Transparency = transparency or 0
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = world
    return p
end

local function sign(name, position, label, tint, width)
    local anchor = create(name, Vector3.new(1, 1, 1), CFrame.new(position), tint, Enum.Material.Neon, false, 1)
    local bill = Instance.new("BillboardGui")
    bill.Name = "Hologram"
    bill.Size = UDim2.fromOffset(width or 550, 95)
    bill.AlwaysOnTop = true
    bill.MaxDistance = 900
    bill.Parent = anchor
    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.GothamBlack
    text.TextScaled = true
    text.TextWrapped = true
    text.TextStrokeTransparency = 0.22
    text.TextStrokeColor3 = DARK
    text.TextColor3 = tint
    text.Text = label
    text.Parent = bill
end

-- The legacy Matrix realm ends around X=210. The connecting causeway begins there.
create("ChessCauseway", Vector3.new(196, 2, 21), CFrame.new(288, 2.4, 0), DARK, Enum.Material.Metal, true)
for _, side in ipairs({-1, 1}) do
    create("CausewayBarrier_" .. side, Vector3.new(196, 3, 1), CFrame.new(288, 4.5, side * 11), DARK, Enum.Material.Metal, true)
    create("CausewayNeon_" .. side, Vector3.new(196, 0.3, 0.3), CFrame.new(288, 6.0, side * 11), CYAN, Enum.Material.Neon, false)
end

-- The chess hall is inside the spiral, not on a disconnected platform.
create("InnerHallFloor", Vector3.new(224, 2, 138), CFrame.new(CENTER.X, -1.3, 0), DARK, Enum.Material.Slate, true)
for x = CENTER.X - 100, CENTER.X + 100, 20 do
    create("HallGridX_" .. x, Vector3.new(0.22, 0.1, 128), CFrame.new(x, -0.23, 0), Color3.fromRGB(0, 75, 92), Enum.Material.Neon, false)
end
for z = -60, 60, 20 do
    create("HallGridZ_" .. z, Vector3.new(206, 0.1, 0.22), CFrame.new(CENTER.X, -0.23, z), Color3.fromRGB(0, 75, 92), Enum.Material.Neon, false)
end
sign("MatrixTitle", CENTER + Vector3.new(0, 36, -48), "YUGATNEO MATRIX", CYAN, 860)
sign("ChessTitle", CENTER + Vector3.new(0, 27, -45), "THE CHESS DIMENSION  /  STRATEGY • CONSENT • DISCOVERY", GREEN, 850)
sign("LobbyInstructions", CENTER + Vector3.new(0, 12, 40), "E: JOIN TOURNAMENT OR CASUAL QUEUE  |  WATCH OTHER PLAYERS", PURPLE, 850)

-- Walkable serpentine: three revolutions, broad tangent-aligned slabs and physical guardrails.
-- Starts on the western side by the causeway. Each ramp segment overlaps its neighbours.
local radius, steps, revolutions, rise = 120, 144, 3, 0.68
local angleStep = math.pi * 2 * revolutions / steps
local function pathPoint(i)
    local a = math.pi + i * angleStep
    return CENTER + Vector3.new(radius * math.cos(a), 4 + i * rise, radius * math.sin(a))
end
for i = 0, steps - 1 do
    local p0, p1 = pathPoint(i), pathPoint(i + 1)
    local midpoint = (p0 + p1) * 0.5
    local forward = (p1 - p0).Unit
    local frame = CFrame.lookAt(midpoint, midpoint + forward)
    local length = (p1 - p0).Magnitude + 2.5
    create(string.format("SerpentineRoad_%03d", i), Vector3.new(23, 1.5, length), frame,
        Color3.fromRGB(12, 31, 48), Enum.Material.Metal, true)
    create("RoadStripe_" .. i, Vector3.new(0.32, 0.12, length - 0.4),
        frame * CFrame.new(0, 0.84, 0), (i % 8 < 4) and CYAN or PURPLE, Enum.Material.Neon, false, 0.2)
    for _, side in ipairs({-1, 1}) do
        local edge = frame * CFrame.new(side * 12.05, 1.8, 0)
        create("RoadGuard_" .. i .. "_" .. side, Vector3.new(0.8, 3.0, length), edge,
            DARK, Enum.Material.Metal, true, 0.1)
        create("RoadGuardLight_" .. i .. "_" .. side, Vector3.new(0.28, 0.26, length),
            frame * CFrame.new(side * 12.05, 3.42, 0), side == 1 and CYAN or PURPLE,
            Enum.Material.Neon, false, 0.1)
    end
    if i % 12 == 0 then
        local tower = create("AscentBeacon_" .. i, Vector3.new(1.5, 9, 1.5),
            frame * CFrame.new(17, 4, 0), PURPLE, Enum.Material.Neon, false)
        local light = Instance.new("PointLight")
        light.Color = PURPLE
        light.Brightness = 0.7
        light.Range = 24
        light.Parent = tower
    end
end

local endPos = pathPoint(steps)
create("AscentFinish", Vector3.new(49, 2, 48), CFrame.new(endPos + Vector3.new(0, 0.2, 0)),
    DARK, Enum.Material.Metal, true)
sign("FinishSign", endPos + Vector3.new(0, 19, 0), "X IS THE UNKNOWN  /  KEEP EXPLORING", GREEN, 650)
create("CentralSpine", Vector3.new(6, 116, 6), CFrame.new(CENTER.X, 55, 0), CYAN, Enum.Material.Glass, false, 0.55)
for a = 0, 7 do
    local angle = a * math.pi / 4
    create("SpineLight_" .. a, Vector3.new(0.32, 112, 0.32),
        CFrame.new(CENTER.X + math.cos(angle) * 5, 55, math.sin(angle) * 5), GREEN,
        Enum.Material.Neon, false, 0.15)
end

local function portal(name, pos, label, destination)
    local p = create(name, Vector3.new(7, 0.5, 7), CFrame.new(pos), GREEN, Enum.Material.Neon, true, 0.1)
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Enter dimension"
    prompt.ObjectText = label
    prompt.HoldDuration = 0.2
    prompt.RequiresLineOfSight = false
    prompt.MaxActivationDistance = 12
    prompt.Parent = p
    local lastUse = {}
    prompt.Triggered:Connect(function(player)
        local time = os.clock()
        if time - (lastUse[player.UserId] or -100) < 2 then return end
        lastUse[player.UserId] = time
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root then
            root.AssemblyLinearVelocity = Vector3.zero
            root.CFrame = CFrame.new(destination)
        end
    end)
    Players.PlayerRemoving:Connect(function(player) lastUse[player.UserId] = nil end)
end
portal("ToChessDimension", Vector3.new(27, 1.35, 12), "Enter Chess Dimension", Vector3.new(CENTER.X, 5, 50))
portal("ReturnToMatrix", Vector3.new(CENTER.X + 86, 1.35, 48), "Return to Matrix", Vector3.new(0, 6, 13))
portal("ReturnFromSummit", endPos + Vector3.new(0, 2, 12), "Back to Chess Hall",
    Vector3.new(CENTER.X, 5, 48))

-- The quiet room is an optional, weapon-free interpretive space.
create("QuietRoom", Vector3.new(19, 1, 17), CFrame.new(CENTER.X + 86, 0.4, -47),
    Color3.fromRGB(14, 26, 44), Enum.Material.Slate, true)
sign("QuietRoomLabel", Vector3.new(CENTER.X + 86, 13, -47), "QUIET ROOM  /  THE RIGHT TO EXIT", GREEN, 430)

print("[YUGATNEO] Spiral dimension ready: chess hall, 3-revolution road, portals, summit.")
