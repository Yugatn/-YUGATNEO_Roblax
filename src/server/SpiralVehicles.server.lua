-- Story X spiral driving: lightweight two-seatless hover-karts controlled by Roblox VehicleSeat.
-- Only a human occupant drives; server applies velocity and steering. No weapons on vehicles.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Rewards = require(script.Parent:WaitForChild("RewardService"))
local folder = Instance.new("Folder")
folder.Name = "YUGATNEO_SerpentineVehicles"
folder.Parent = workspace
local vehicles = {}

local function makeKart(index, position, color)
    local model = Instance.new("Model")
    model.Name = "SerpentineKart_" .. index
    model.Parent = folder
    local chassis = Instance.new("Part")
    chassis.Name = "Hull"
    chassis.Size = Vector3.new(6.4, 1.35, 9)
    chassis.CFrame = CFrame.lookAt(position, position + Vector3.new(1, 0, 0))
    chassis.Material = Enum.Material.Metal
    chassis.Color = color
    chassis.CustomPhysicalProperties = PhysicalProperties.new(1, 0.95, 0.05)
    chassis.Anchored = false
    chassis.Parent = model
    model.PrimaryPart = chassis

    local seat = Instance.new("VehicleSeat")
    seat.Name = "Drive"
    seat.Size = Vector3.new(3.3, 1.0, 3.6)
    seat.CFrame = chassis.CFrame * CFrame.new(0, 1.25, 0)
    seat.Color = Color3.fromRGB(20, 25, 40)
    seat.Material = Enum.Material.SmoothPlastic
    seat.CanCollide = false
    seat.Anchored = false
    seat.MaxSpeed = 0
    seat.Parent = model
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = chassis
    weld.Part1 = seat
    weld.Parent = chassis

    for _, x in ipairs({-3.05, 3.05}) do
        for _, z in ipairs({-3.1, 3.1}) do
            local wheel = Instance.new("Part")
            wheel.Name = "GlowingHub"
            wheel.Shape = Enum.PartType.Cylinder
            wheel.Size = Vector3.new(0.7, 1.8, 1.8)
            wheel.CFrame = chassis.CFrame * CFrame.new(x, -0.55, z) * CFrame.Angles(0, 0, math.rad(90))
            wheel.Anchored = false
            wheel.CanCollide = false
            wheel.Massless = true
            wheel.Material = Enum.Material.Neon
            wheel.Color = Color3.fromRGB(30, 245, 215)
            wheel.Parent = model
            local joint = Instance.new("WeldConstraint")
            joint.Part0 = chassis
            joint.Part1 = wheel
            joint.Parent = wheel
        end
    end

    local attachment = Instance.new("Attachment")
    attachment.Parent = chassis
    local stabilizer = Instance.new("AlignOrientation")
    stabilizer.Name = "UprightAndSteering"
    stabilizer.Attachment0 = attachment
    stabilizer.Mode = Enum.OrientationAlignmentMode.OneAttachment
    stabilizer.MaxTorque = 150000
    stabilizer.Responsiveness = 17
    stabilizer.Parent = chassis

    local promptBase = Instance.new("Part")
    promptBase.Name = "ResetSign"
    promptBase.Size = Vector3.new(2, 3, 2)
    promptBase.CFrame = chassis.CFrame * CFrame.new(-7, 0, 0)
    promptBase.Color = color
    promptBase.Material = Enum.Material.Neon
    promptBase.CanCollide = false
    promptBase.Anchored = true
    promptBase.Parent = folder
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Recover kart"
    prompt.ObjectText = "Kart " .. index
    prompt.MaxActivationDistance = 11
    prompt.HoldDuration = 0.25
    prompt.Parent = promptBase

    local startCF = chassis.CFrame
    local state = {model = model, chassis = chassis, seat = seat, aim = stabilizer,
        heading = math.pi / 2, start = startCF, lastReset = 0, baseColor = color}
    prompt.Triggered:Connect(function(player)
        if os.clock() - state.lastReset < 3 then return end
        if seat.Occupant then return end
        if player:GetAttribute("InChessMatch") then return end
        state.lastReset = os.clock()
        model:PivotTo(state.start)
        chassis.AssemblyLinearVelocity = Vector3.zero
        chassis.AssemblyAngularVelocity = Vector3.zero
        state.heading = math.pi / 2
    end)
    -- Keep server authority stable for simple multiplayer physics.
    pcall(function() chassis:SetNetworkOwner(nil) end)
    table.insert(vehicles, state)
end

makeKart(1, Vector3.new(244, 6.2, -4.5), Color3.fromRGB(30, 125, 165))
makeKart(2, Vector3.new(266, 6.2, 4.5), Color3.fromRGB(110, 55, 175))

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true
local clock = 0
RunService.Heartbeat:Connect(function(dt)
    clock += dt
    for _, car in ipairs(vehicles) do
        local hull, seat = car.chassis, car.seat
        if not hull.Parent then continue end
        if hull.Position.Y < -25 and clock > 1 then
            if seat.Occupant then seat.Occupant.Sit = false end
            car.model:PivotTo(car.start)
            hull.AssemblyLinearVelocity = Vector3.zero
            hull.AssemblyAngularVelocity = Vector3.zero
            car.heading = math.pi / 2
            continue
        end
        local occupant = seat.Occupant
        if occupant and occupant.Health > 0 then
            local driver = Players:GetPlayerFromCharacter(occupant.Parent)
            if not driver or driver:GetAttribute("InChessMatch") then
                occupant.Sit = false
                continue
            end
            local profile = Rewards.get(driver)
            local violet = profile and profile.unlocked.VioletKart and profile.equipped == "VioletKart"
            hull.Color = violet and Color3.fromRGB(160, 75, 225) or car.baseColor
            local throttle = math.clamp(seat.ThrottleFloat, -1, 1)
            local steer = math.clamp(seat.SteerFloat, -1, 1)
            local speed = hull.AssemblyLinearVelocity.Magnitude
            car.heading -= steer * dt * (0.65 + math.min(speed / 38, 1) * 0.7)
            local flatDirection = Vector3.new(math.sin(car.heading), 0, -math.cos(car.heading))
            local facing = CFrame.lookAt(Vector3.zero, flatDirection)
            car.aim.CFrame = facing
            rayParams.FilterDescendantsInstances = {car.model, folder}
            local ground = workspace:Raycast(hull.Position, Vector3.new(0, -12, 0), rayParams)
            local driveDirection = flatDirection
            if ground then
                local alongSlope = flatDirection - ground.Normal * flatDirection:Dot(ground.Normal)
                if alongSlope.Magnitude > 0.5 then driveDirection = alongSlope.Unit end
            end
            local target = driveDirection * (throttle >= 0 and throttle * 38 or throttle * 18)
            local existing = hull.AssemblyLinearVelocity
            local blend = math.clamp(dt * 4, 0, 1)
            local nextVelocity = existing:Lerp(target, blend)
            if throttle == 0 then
                nextVelocity = nextVelocity * math.max(0, 1 - dt * 3)
            end
            hull.AssemblyLinearVelocity = nextVelocity
        end
    end
end)
print("[YUGATNEO] Serpentine hover-karts installed (VehicleSeat W/S/A/D).")
