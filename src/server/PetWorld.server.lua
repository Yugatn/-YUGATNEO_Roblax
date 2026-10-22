-- Story X: discoverable virtual-pet capsule, server-authoritative care and saved progression.
-- Only virtual creatures. They never die from neglect or missing a visit.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local PetRules = require(script.Parent:WaitForChild("PetRules"))
local store = DataStoreService:GetDataStore("YUGATNEO_VIRTUAL_PET_V1")

local event = ReplicatedStorage:FindFirstChild("YugatneoPetEvent")
if not event then
    event = Instance.new("RemoteEvent")
    event.Name = "YugatneoPetEvent"
    event.Parent = ReplicatedStorage
end
local world = Instance.new("Folder")
world.Name = "YUGATNEO_PET_CAPSULES"
world.Parent = workspace

local profiles = {}
local offered = {}
local lastRemote = {}
local saving = {}
local function capsule(name, place)
    local platform = Instance.new("Part")
    platform.Name = name .. "_Pedestal"
    platform.Anchored = true
    platform.CanCollide = true
    platform.Size = Vector3.new(5, 0.75, 5)
    platform.CFrame = CFrame.new(place)
    platform.Material = Enum.Material.Metal
    platform.Color = Color3.fromRGB(14, 26, 47)
    platform.Parent = world

    local glass = Instance.new("Part")
    glass.Name = name .. "_Crystal"
    glass.Shape = Enum.PartType.Ball
    glass.Anchored = true
    glass.CanCollide = false
    glass.Size = Vector3.new(3, 4, 3)
    glass.Position = place + Vector3.new(0, 2.4, 0)
    glass.Material = Enum.Material.Glass
    glass.Transparency = 0.27
    glass.Color = Color3.fromRGB(54, 244, 196)
    glass.Parent = world
    local light = Instance.new("PointLight")
    light.Color = glass.Color
    light.Range = 19
    light.Brightness = 1.5
    light.Parent = glass

    local label = Instance.new("BillboardGui")
    label.Name = "PetLabel"
    label.Size = UDim2.fromOffset(220, 90)
    label.StudsOffsetWorldSpace = Vector3.new(0, 4.6, 0)
    label.AlwaysOnTop = true
    label.MaxDistance = 110
    label.Parent = glass
    local text = Instance.new("TextLabel")
    text.Size = UDim2.fromScale(1, 1)
    text.BackgroundTransparency = 1
    text.TextWrapped = true
    text.TextScaled = true
    text.Font = Enum.Font.GothamBlack
    text.TextColor3 = Color3.fromRGB(94, 255, 210)
    text.TextStrokeTransparency = 0.35
    text.Text = "YUGATNEO PET LAB\nНАЙДИ ДРУГА"
    text.Parent = label

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Найти питомца"
    prompt.ObjectText = "Капсула тамагочи"
    prompt.MaxActivationDistance = 13
    prompt.HoldDuration = 0.35
    prompt.RequiresLineOfSight = false
    prompt.Parent = glass
    return glass, prompt
end

-- Main hidden capsule at spiral step 64: same path formula as SpiralWorld.
local a = math.pi + 64 * (math.pi * 6 / 144)
local center = Vector3.new(500 + 120 * math.cos(a), 4 + 64 * 0.68, 120 * math.sin(a))
local shoulder = center + Vector3.new(8 * math.cos(a), 0.7, 8 * math.sin(a))
local spiralAnchor, spiralPrompt = capsule("SpiralPet", shoulder)
-- Optional convenient discovery near the Matrix start, reachable without a vehicle.
local plazaAnchor, plazaPrompt = capsule("MatrixPet", Vector3.new(29, 2.8, -6))
local anchors = {spiralAnchor, plazaAnchor}

local function nearAnchor(player, range)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then return false end
    if player:GetAttribute("InChessMatch") then return false end
    for _, anchor in ipairs(anchors) do
        if (root.Position - anchor.Position).Magnitude <= range then return true end
    end
    return false
end

local function stateToClient(player, message)
    local record = profiles[player]
    if not record then return end
    event:FireClient(player, "State", {
        pet = PetRules.public(record.pet),
        savingAvailable = record.loaded == true,
        loading = record.loading == true,
        message = message,
    })
end
local function load(player)
    local record = {pet = nil, loaded = false, loading = true, revision = 0}
    profiles[player] = record
    stateToClient(player, "Загружаем питомца...")
    local ok, snapshot = pcall(function() return store:GetAsync("pet_" .. player.UserId) end)
    if profiles[player] ~= record or player.Parent ~= Players then return end
    record.loading = false
    record.loaded = ok
    if ok then
        record.pet = PetRules.restore(snapshot, os.time())
        if record.pet then PetRules.advance(record.pet, os.time(), true) end
        stateToClient(player)
    else
        warn("[YUGATNEO Pet] DataStore is unavailable for", player.UserId)
        stateToClient(player, "Сохранение недоступно: питомец будет только в этом сеансе")
    end
end

local function save(player)
    local record = profiles[player]
    if not record or not record.pet or not record.loaded or saving[player] then return end
    saving[player] = true
    local now = os.time()
    PetRules.advance(record.pet, now, false)
    record.pet.lastUpdated = now
    local pet = record.pet
    local snapshot = {
        species = pet.species, hunger = pet.hunger, joy = pet.joy,
        energy = pet.energy, health = pet.health, xp = pet.xp,
        careCount = pet.careCount, createdAt = pet.createdAt,
        lastUpdated = pet.lastUpdated,
    }
    local success, err = pcall(function()
        store:UpdateAsync("pet_" .. player.UserId, function(old)
            if type(old) == "table" and type(old.lastUpdated) == "number"
                and old.lastUpdated > snapshot.lastUpdated then
                return nil -- reject older write if a newer server already saved
            end
            return snapshot
        end)
    end)
    saving[player] = nil
    if not success then warn("[YUGATNEO Pet] Save failed", player.UserId, err) end
end

local function discover(player)
    local record = profiles[player]
    if not record or record.loading or not nearAnchor(player, 16) then return end
    if record.pet then
        stateToClient(player, "Твой питомец уже с тобой!")
        event:FireClient(player, "Open")
        return
    end
    offered[player] = os.clock() + 40
    event:FireClient(player, "Choose", {
        {id = "Lumi", name = PetRules.species.Lumi.label, description = PetRules.species.Lumi.description},
        {id = "Miko", name = PetRules.species.Miko.label, description = PetRules.species.Miko.description},
        {id = "Sprout", name = PetRules.species.Sprout.label, description = PetRules.species.Sprout.description},
    })
end
spiralPrompt.Triggered:Connect(discover)
plazaPrompt.Triggered:Connect(discover)

event.OnServerEvent:Connect(function(player, action, arg)
    if type(action) ~= "string" or #action > 24 then return end
    local now = os.clock()
    if now - (lastRemote[player] or -100) < 0.3 then return end
    lastRemote[player] = now
    local record = profiles[player]
    if not record or record.loading then return end
    if action == "GetState" then
        stateToClient(player)
    elseif action == "Adopt" then
        if record.pet or not PetRules.species[arg] then return end
        if (offered[player] or -1) < now or not nearAnchor(player, 20) then return end
        offered[player] = nil
        record.pet = PetRules.create(arg, os.time())
        stateToClient(player, "Ты нашёл нового друга!")
        event:FireClient(player, "Open")
        task.spawn(save, player)
    elseif action == "Care" then
        if not record.pet or type(arg) ~= "string" or not PetRules.actions[arg] then return end
        PetRules.advance(record.pet, os.time(), false)
        local success, feedback = PetRules.act(record.pet, arg, os.time())
        if success then record.pet.lastUpdated = os.time() end
        stateToClient(player, feedback)
    end
end)

Players.PlayerAdded:Connect(function(player)
    task.spawn(load, player)
end)
Players.PlayerRemoving:Connect(function(player)
    save(player)
    profiles[player] = nil
    offered[player] = nil
    lastRemote[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(load, player) end

task.spawn(function()
    while true do
        task.wait(90)
        for player, record in pairs(profiles) do
            if record.pet and player.Parent == Players then
                PetRules.advance(record.pet, os.time(), false)
                stateToClient(player)
                task.spawn(save, player)
            end
        end
    end
end)
game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        save(player)
    end
end)
print("[YUGATNEO PET] Discoverable virtual pets and care persistence initialized.")
