-- Rewards only apply inside this Roblox experience, never to global Avatar Marketplace inventory.
-- Server-owned progress; DataStore writes use UpdateAsync on session finalization.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local store = DataStoreService:GetDataStore("YUGATNEO_WORLD_REWARDS_V1")
local event = ReplicatedStorage:FindFirstChild("YugatneoRewards") or Instance.new("RemoteEvent")
event.Name = "YugatneoRewards"
event.Parent = ReplicatedStorage
local Rewards = {}
local profiles = {}
Rewards.items = {
 Glasses = {cost=30,description="Neon glasses: in-world cosmetic"},
 Crown = {cost=75,description="Scholar crown: in-world cosmetic"},
 Trail = {cost=95,description="Explorer sparkle trail: in-world cosmetic"},
 KartCyan = {cost=130,description="Kart paint unlock: integration planned; no driving upgrade yet"}
}
local function profile(p)
 return profiles[p]
end
local function send(p)
 local data=profile(p)
 if data then event:FireClient(p,"State",{coins=data.coins,owned=data.owned,equipped=data.equipped,items=Rewards.items,storeLoaded=data.loaded}) end
end
local function decorate(p)
 local data=profile(p)
 if not data or not p.Character then return end
 local head=p.Character:FindFirstChild("Head")
 local root=p.Character:FindFirstChild("HumanoidRootPart")
 if not head or not root then return end
 for _,item in ipairs({"YugatneoGlasses","YugatneoCrown","YugatneoTrail"}) do
  local old=p.Character:FindFirstChild(item)
  if old then old:Destroy() end
 end
 if data.equipped=="Glasses" or data.equipped=="Crown" then
  local glasses=data.equipped=="Glasses"
  local part=Instance.new("Part")
  part.Name=glasses and "YugatneoGlasses" or "YugatneoCrown"
  part.Size=glasses and Vector3.new(1.7,0.23,0.32) or Vector3.new(1.2,0.45,1.2)
  part.Material=Enum.Material.Neon
  part.Color=glasses and Color3.fromRGB(20,255,220) or Color3.fromRGB(255,211,70)
  part.CanCollide=false
  part.Massless=true
  part.CFrame=head.CFrame*CFrame.new(0,glasses and 0.15 or 0.95,-0.48)
  part.Parent=p.Character
  local weld=Instance.new("WeldConstraint")
  weld.Part0=head
  weld.Part1=part
  weld.Parent=part
 elseif data.equipped=="Trail" then
  local a=Instance.new("Attachment")
  a.Name="YugatneoTrail"
  a.Parent=root
  local b=Instance.new("ParticleEmitter")
  b.Name="YugatneoTrailParticles"
  b.Rate=8
  b.Lifetime=NumberRange.new(0.2,0.6)
  b.Speed=NumberRange.new(0.5,1.2)
  b.Color=ColorSequence.new(Color3.fromRGB(25,255,205))
  b.Parent=a
 end
end

function Rewards.award(p,amount,reason,unique)
 local data=profile(p)
 if not data or type(amount)~="number" or amount<1 or amount>100 or amount%1~=0 then return false end
 if unique and data.receipts[unique] then return false end
 if unique then data.receipts[unique]=true end
 data.coins+=amount
 data.delta+=amount
 send(p)
 return true
end
function Rewards.get(p) return profile(p) end
function Rewards.send(p) send(p) end
event.OnServerEvent:Connect(function(p,action,item)
 local data=profile(p)
 if not data or type(item)~="string" then return end
 local def=Rewards.items[item]
 if not def then return end
 if action=="Buy" then
  if data.owned[item] or data.coins<def.cost then return end
  data.coins-=def.cost
  data.delta-=def.cost
  data.owned[item]=true
  send(p)
 elseif action=="Equip" then
  if not data.owned[item] or item=="KartCyan" then return end
  data.equipped=item
  decorate(p)
  send(p)
 end
end)
local function load(p)
 local data={coins=0,delta=0,owned={},equipped=nil,receipts={},loaded=false,saved=false}
 profiles[p]=data
 local ok,snapshot=pcall(function() return store:GetAsync("player_"..p.UserId) end)
 if profiles[p]~=data then return end
 if ok then
  if type(snapshot)=="table" then
   data.coins=math.max(0,math.floor(tonumber(snapshot.coins) or 0))
   if type(snapshot.owned)=="table" then
    for item,value in pairs(snapshot.owned) do if Rewards.items[item] and value==true then data.owned[item]=true end end
   end
   if type(snapshot.equipped)=="string" and data.owned[snapshot.equipped] then
    data.equipped=snapshot.equipped
   end
  end
  data.loaded=true
 else
  warn("[YUGATNEO Rewards] DataStore read unavailable; rewards remain session-only for",p.UserId)
 end
 send(p)
 decorate(p)
end
local function save(p)
 local data=profiles[p]
 if not data or data.saved then return end
 data.saved=true
 if not data.loaded then return end
 local delta=data.delta
 local owned=data.owned
 local equipped=data.equipped
 local ok,err=pcall(function()
  store:UpdateAsync("player_"..p.UserId,function(old)
   old=type(old)=="table" and old or {coins=0,owned={}}
   local all=type(old.owned)=="table" and old.owned or {}
   for item,val in pairs(owned) do if val then all[item]=true end end
   return {coins=math.max(0,(tonumber(old.coins) or 0)+delta),owned=all,equipped=equipped}
  end)
 end)
 if not ok then warn("[YUGATNEO Rewards] Write failed",err) end
end
Players.PlayerAdded:Connect(function(p)
 p.CharacterAdded:Connect(function()
  task.wait(0.5)
  decorate(p)
 end)
 task.spawn(load,p)
end)
Players.PlayerRemoving:Connect(function(p) save(p) profiles[p]=nil end)
game:BindToClose(function()
 for _,p in ipairs(Players:GetPlayers()) do save(p) end
end)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(load,p) end
return Rewards
