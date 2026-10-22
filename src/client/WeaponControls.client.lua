-- YUGATNEO weapons client: keys 1/2/3 select, left click fires.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("WeaponEvent")
local mouse = player:GetMouse()

local current = "Pistol"
local canShoot = true

local gui = Instance.new("ScreenGui")
gui.Name = "YUGATNEOWeapons"
gui.ResetOnSpawn = false
gui.DisplayOrder = 15
gui.Parent = player:WaitForChild("PlayerGui")

local bar = Instance.new("Frame")
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -24)
bar.Size = UDim2.new(0, 320, 0, 52)
bar.BackgroundColor3 = Color3.fromRGB(17, 22, 32)
bar.BackgroundTransparency = 0.15
bar.BorderSizePixel = 0
bar.Parent = gui
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 10)

local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.Text = "[1] Pistol  [2] Rifle  [3] SMG  |  LMB shoot"
label.TextColor3 = Color3.fromRGB(235, 190, 92)
label.Font = Enum.Font.GothamBold
label.TextSize = 13
label.Parent = bar

local function setWeapon(name)
	event:FireServer("Equip", name)
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.One then
		setWeapon("Pistol")
	elseif input.KeyCode == Enum.KeyCode.Two then
		setWeapon("Rifle")
	elseif input.KeyCode == Enum.KeyCode.Three then
		setWeapon("SMG")
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		if player:GetAttribute("InChessMatch") then return end
		local char = player.Character
		local head = char and char:FindFirstChild("Head")
		if not head then return end
		local origin = head.Position
		local target = mouse.Hit.Position
		local dir = (target - origin)
		if dir.Magnitude < 0.1 then return end
		event:FireServer("Fire", origin, dir.Unit)
	end
end)

event.OnClientEvent:Connect(function(action, a, b, c)
	if action == "Equipped" then
		current = a
		label.Text = string.format("Weapon: %s  |  [1][2][3] switch  |  LMB fire", tostring(a))
	elseif action == "Hit" then
		label.Text = string.format("Hit %s (−%s)", tostring(a), tostring(b))
		task.delay(1.2, function()
			label.Text = string.format("Weapon: %s  |  [1][2][3] switch  |  LMB fire", current)
		end)
	elseif action == "Tracer" then
		local origin, hitPos = a, b
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.Material = Enum.Material.Neon
		part.Color = Color3.fromRGB(255, 220, 120)
		local dist = (hitPos - origin).Magnitude
		part.Size = Vector3.new(0.12, 0.12, dist)
		part.CFrame = CFrame.new(origin, hitPos) * CFrame.new(0, 0, -dist / 2)
		part.Parent = Workspace
		task.delay(0.08, function()
			part:Destroy()
		end)
	end
end)

print("[YUGATNEO] Weapon controls ready")
