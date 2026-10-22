-- Persistent non-Robux achievement progression. Server is sole source of currency.
-- Visual in-experience cosmetics do NOT grant Roblox platform catalog assets.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local Reward = {}
local store = DataStoreService:GetDataStore("YUGATNEO_PROGRESS_V1")
local profiles = {}
local saving = {}
local CATALOG = {
    NeonGlasses = {name="Neon glasses", cost=30},
    Halo = {name="Observer halo", cost=65},
    MatrixCrown = {name="Matrix crown", cost=100},
    VioletKart = {name="Violet kart unlock", cost=80},
}
Reward.catalog = CATALOG
local function clean(original)
    local data = type(original) == "table" and original or {}
    local result = {coins = math.clamp(math.floor(tonumber(data.coins) or 0),0,1000000),
        earned = math.clamp(math.floor(tonumber(data.earned) or 0),0,1000000),
        unlocked = {}, rewarded = {}, equipped = nil}
    if type(data.unlocked) == "table" then
        for id, active in pairs(data.unlocked) do
            if CATALOG[id] and active == true then result.unlocked[id] = true end
        end
    end
    if type(data.rewarded) == "table" then
        for id, active in pairs(data.rewarded) do
            if type(id) == "string" and #id <= 75 and active == true then result.rewarded[id] = true end
        end
    end
    if CATALOG[data.equipped] and result.unlocked[data.equipped] then result.equipped = data.equipped end
    return result
end
local function snapshot(profile)
    local unlocked = {}
    for id in pairs(profile.unlocked) do unlocked[id] = true end
    return {coins=profile.coins, earned=profile.earned, equipped=profile.equipped, unlocked=unlocked, catalog=CATALOG}
end
local function getRemote()
    local existing = game:GetService("ReplicatedStorage"):FindFirstChild("RewardEvent")
    if existing then return existing end
    local e=Instance.new("RemoteEvent")
    e.Name="RewardEvent"
    e.Parent=game:GetService("ReplicatedStorage")
    return e
end
local remote = getRemote()
local function send(player)
    local profile = profiles[player]
    if profile then remote:FireClient(player,"Snapshot",snapshot(profile)) end
end
local function render(player)
    local profile = profiles[player]
    local char = player.Character
    if not profile or not char then return end
    local old = char:FindFirstChild("StoryXCosmetic")
    if old then old:Destroy() end
    if not profile.equipped or profile.equipped == "VioletKart" then return end
    local head = char:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then return end
    local group = Instance.new("Model")
    group.Name = "StoryXCosmetic"
    group.Parent = char
    local function ornament(name, size, offset, color)
        local p=Instance.new("Part")
        p.Name=name
        p.Size=size
        p.Material=Enum.Material.Neon
        p.Color=color
        p.CanCollide=false
        p.CanTouch=false
        p.Massless=true
        p.CFrame=head.CFrame*CFrame.new(offset)
        p.Parent=group
        local weld=Instance.new("WeldConstraint")
        weld.Part0=head
        weld.Part1=p
        weld.Parent=p
    end
    if profile.equipped=="NeonGlasses" then
        ornament("LensLeft",Vector3.new(.55,.27,.13),Vector3.new(-.33,.06,-.58),Color3.fromRGB(0,244,199))
        ornament("LensRight",Vector3.new(.55,.27,.13),Vector3.new(.33,.06,-.58),Color3.fromRGB(0,244,199))
        ornament("Bridge",Vector3.new(.20,.07,.12),Vector3.new(0,.06,-.58),Color3.fromRGB(255,212,99))
    elseif profile.equipped=="Halo" then
        ornament("Halo",Vector3.new(2.2,.18,2.2),Vector3.new(0,1.15,0),Color3.fromRGB(147,103,255))
    elseif profile.equipped=="MatrixCrown" then
        ornament("Crown",Vector3.new(1.35,.45,1.35),Vector3.new(0,.76,0),Color3.fromRGB(255,215,100))
    end
end
local function persist(player)
    local p=profiles[player]
    if not p then return end
    if saving[player] then return end
    saving[player]=true
    local snapshotToSave=clean(p)
    local ok,err=pcall(function()
        store:UpdateAsync("u_"..player.UserId,function(previous)
            local was=clean(previous)
            local result=clean(snapshotToSave)
            -- First-writer-wins for one-time rewards, no client supplied balances.
            for id in pairs(was.rewarded) do result.rewarded[id]=true end
            for id in pairs(was.unlocked) do result.unlocked[id]=true end
            return result
        end)
    end)
    saving[player]=nil
    if not ok then warn("Reward save unavailable:",err) end
end
function Reward.awardOnce(player,reason,amount)
    local p=profiles[player]
    if not p or type(reason)~="string" or #reason>75 or p.rewarded[reason] then return false end
    amount=tonumber(amount)
    if not amount or amount<1 or amount>100 then return false end
    p.rewarded[reason]=true
    p.coins=math.min(p.coins+math.floor(amount),1000000)
    p.earned=math.min(p.earned+math.floor(amount),1000000)
    send(player)
    task.spawn(persist,player)
    return true
end
function Reward.awardMatch(player,reason,amount)
    local p=profiles[player]
    if not p or reason~="chess_win" or amount~=10 then return false end
    local now=os.clock()
    if now-(p.lastChessAward or -1000)<45 then return false end
    p.lastChessAward=now
    p.coins=math.min(p.coins+amount,1000000)
    p.earned=math.min(p.earned+amount,1000000)
    send(player)
    task.spawn(persist,player)
    return true
end
function Reward.get(player)
    local p=profiles[player]
    return p and snapshot(p) or nil
end
local cooldown={}
remote.OnServerEvent:Connect(function(player,action,id)
    if type(action)~="string" or type(id)~="string" or not CATALOG[id] then return end
    local now=os.clock()
    if now-(cooldown[player] or -100)>0.3 then
        cooldown[player]=now
    else
        return
    end
    local p=profiles[player]
    if not p then return end
    if action=="Buy" and not p.unlocked[id] and p.coins>=CATALOG[id].cost then
        p.coins-=CATALOG[id].cost
        p.unlocked[id]=true
        task.spawn(persist,player)
    elseif action=="Equip" and p.unlocked[id] then
        p.equipped=id
        render(player)
        task.spawn(persist,player)
    end
    send(player)
end)
local function joined(player)
    local profile=clean(nil)
    local ok,result=pcall(function() return store:GetAsync("u_"..player.UserId) end)
    if ok then profile=clean(result) end
    if not player.Parent then return end
    profiles[player]=profile
    player.CharacterAdded:Connect(function()
        task.defer(render,player)
    end)
    if player.Character then render(player) end
    send(player)
end
Players.PlayerAdded:Connect(function(player) task.spawn(joined,player) end)
Players.PlayerRemoving:Connect(function(player)
    persist(player)
    profiles[player]=nil
    cooldown[player]=nil
end)
for _,player in ipairs(Players:GetPlayers()) do task.spawn(joined,player) end
game:BindToClose(function()
    for _,player in ipairs(Players:GetPlayers()) do persist(player) end
end)
return Reward
