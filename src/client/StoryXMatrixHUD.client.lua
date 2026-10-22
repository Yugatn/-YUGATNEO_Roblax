--!strict
-- STORY X: client HUD, reasoning terminals, and harmless pulse control.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local noticeEvent = ReplicatedStorage:WaitForChild("StoryXNotice") :: RemoteEvent
local puzzleEvent = ReplicatedStorage:WaitForChild("StoryXPuzzle") :: RemoteEvent
local answerEvent = ReplicatedStorage:WaitForChild("StoryXAnswer") :: RemoteEvent
local pulseEvent = ReplicatedStorage:WaitForChild("StoryXPulse") :: RemoteEvent
local modeEvent = ReplicatedStorage:WaitForChild("StoryXPulseMode") :: RemoteEvent
local progressEvent = ReplicatedStorage:WaitForChild("StoryXProgress") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "YUGATNEOMatrixHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

local function round(instance: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = instance
end

local function makeLabel(parent: Instance, name: string, text: string, pos: UDim2, size: UDim2, fontSize: number, color: Color3)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Position = pos
	l.Size = size
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = color
	l.TextWrapped = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.Font = Enum.Font.Gotham
	l.TextSize = fontSize
	l.Parent = parent
	return l
end

local panel = Instance.new("Frame")
panel.Name = "MissionPanel"
panel.Position = UDim2.new(0, 18, 0, 18)
panel.Size = UDim2.new(0, 310, 0, 158)
panel.BackgroundColor3 = Color3.fromRGB(4, 15, 30)
panel.BackgroundTransparency = 0.12
panel.BorderSizePixel = 0
panel.Parent = gui
round(panel, 12)

makeLabel(panel, "GameTitle", "YUGATNEO MATRIX", UDim2.new(0, 14, 0, 8), UDim2.new(1, -28, 0, 28), 20, Color3.fromRGB(0, 255, 210)).Font = Enum.Font.GothamBlack
local mission = makeLabel(panel, "Mission", "MISSION 01\nRecover memory fragments. Inspect terminals. Explore the districts.", UDim2.new(0, 14, 0, 42), UDim2.new(1, -28, 0, 62), 14, Color3.fromRGB(230, 255, 255))
local stats = makeLabel(panel, "Progress", "MEMORY SHARDS 0  |  DRONES 0", UDim2.new(0, 14, 0, 108), UDim2.new(1, -28, 0, 22), 13, Color3.fromRGB(90, 255, 145))
local help = makeLabel(panel, "Controls", "E: interact  •  Click / tap PULSE to train", UDim2.new(0, 14, 0, 130), UDim2.new(1, -28, 0, 20), 11, Color3.fromRGB(160, 195, 220))

local pulse = Instance.new("TextButton")
pulse.Name = "PulseButton"
pulse.AnchorPoint = Vector2.new(1, 1)
pulse.Position = UDim2.new(1, -22, 1, -22)
pulse.Size = UDim2.new(0, 150, 0, 54)
pulse.BackgroundColor3 = Color3.fromRGB(0, 115, 145)
pulse.Text = "PULSE  [F]"
pulse.TextColor3 = Color3.new(1, 1, 1)
pulse.TextSize = 18
pulse.Font = Enum.Font.GothamBlack
pulse.BorderSizePixel = 0
pulse.Parent = gui
round(pulse, 14)

local function firePulse()
	if player:GetAttribute("InChessMatch") then return end
	local camera = workspace.CurrentCamera
	if camera then pulseEvent:FireServer(camera.CFrame.LookVector.Unit) end
end
pulse.Activated:Connect(firePulse)

local loadout = Instance.new("Frame")
loadout.Name = "TrainingLoadout"
loadout.AnchorPoint = Vector2.new(1, 1)
loadout.Position = UDim2.new(1, -22, 1, -87)
loadout.Size = UDim2.fromOffset(252, 43)
loadout.BackgroundColor3 = Color3.fromRGB(8, 18, 36)
loadout.BorderSizePixel = 0
loadout.Parent = gui
round(loadout, 8)
local function selectMode(mode)
    if player:GetAttribute("InChessMatch") then return end
    modeEvent:FireServer(mode)
    pulse.Text = mode:upper() .. " [F]"
end
for i, mode in ipairs({"Pulse", "Rapid", "Charged"}) do
    local button = Instance.new("TextButton")
    button.Name = mode
    button.Position = UDim2.fromOffset(4 + (i - 1) * 83, 4)
    button.Size = UDim2.fromOffset(79, 35)
    button.BackgroundColor3 = Color3.fromRGB(31, 85, 112)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 11
    button.Text = mode
    button.Parent = loadout
    button.Activated:Connect(function() selectMode(mode) end)
end
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.F then firePulse()
    elseif input.KeyCode == Enum.KeyCode.One then selectMode("Pulse")
    elseif input.KeyCode == Enum.KeyCode.Two then selectMode("Rapid")
    elseif input.KeyCode == Enum.KeyCode.Three then selectMode("Charged") end
end)

local toast = Instance.new("Frame")
toast.Name = "StoryToast"
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0, 24)
toast.Size = UDim2.new(0, 490, 0, 138)
toast.BackgroundColor3 = Color3.fromRGB(3, 13, 28)
toast.BackgroundTransparency = 0.06
toast.BorderSizePixel = 0
toast.Visible = false
toast.Parent = gui
round(toast, 12)
local toastTitle = makeLabel(toast, "ToastTitle", "", UDim2.new(0, 16, 0, 10), UDim2.new(1, -32, 0, 28), 18, Color3.fromRGB(0, 255, 210))
toastTitle.Font = Enum.Font.GothamBlack
local toastBody = makeLabel(toast, "ToastBody", "", UDim2.new(0, 16, 0, 42), UDim2.new(1, -32, 1, -52), 14, Color3.fromRGB(230, 245, 255))
toastBody.TextYAlignment = Enum.TextYAlignment.Top
local toastClose = Instance.new("TextButton")
toastClose.Size = UDim2.new(0, 30, 0, 30)
toastClose.Position = UDim2.new(1, -36, 0, 5)
toastClose.Text = "×"
toastClose.TextSize = 22
toastClose.TextColor3 = Color3.new(1,1,1)
toastClose.BackgroundTransparency = 1
toastClose.Parent = toast
toastClose.Activated:Connect(function() toast.Visible = false end)

local puzzleFrame = Instance.new("Frame")
puzzleFrame.Name = "ReasoningTerminal"
puzzleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
puzzleFrame.Position = UDim2.fromScale(0.5, 0.5)
puzzleFrame.Size = UDim2.new(0, 480, 0, 280)
puzzleFrame.BackgroundColor3 = Color3.fromRGB(4, 13, 28)
puzzleFrame.BorderSizePixel = 0
puzzleFrame.Visible = false
puzzleFrame.Parent = gui
round(puzzleFrame, 14)
local puzzleTitle = makeLabel(puzzleFrame, "PuzzleTitle", "REASONING TERMINAL", UDim2.new(0, 18, 0, 12), UDim2.new(1, -36, 0, 30), 19, Color3.fromRGB(160, 100, 255))
puzzleTitle.Font = Enum.Font.GothamBlack
local question = makeLabel(puzzleFrame, "Question", "", UDim2.new(0, 18, 0, 50), UDim2.new(1, -36, 0, 62), 16, Color3.fromRGB(240, 250, 255))
question.TextYAlignment = Enum.TextYAlignment.Top
local hint = makeLabel(puzzleFrame, "Hint", "", UDim2.new(0, 18, 0, 112), UDim2.new(1, -36, 0, 38), 13, Color3.fromRGB(110, 220, 200))
local answerBox = Instance.new("TextBox")
answerBox.Name = "Answer"
answerBox.Position = UDim2.new(0, 18, 0, 158)
answerBox.Size = UDim2.new(1, -36, 0, 42)
answerBox.PlaceholderText = "Type your answer..."
answerBox.Text = ""
answerBox.ClearTextOnFocus = false
answerBox.TextSize = 16
answerBox.Font = Enum.Font.Gotham
answerBox.TextColor3 = Color3.new(1,1,1)
answerBox.PlaceholderColor3 = Color3.fromRGB(150, 170, 190)
answerBox.BackgroundColor3 = Color3.fromRGB(15, 32, 52)
answerBox.BorderSizePixel = 0
answerBox.Parent = puzzleFrame
round(answerBox, 8)
local submit = Instance.new("TextButton")
submit.Position = UDim2.new(0, 18, 0, 214)
submit.Size = UDim2.new(0.64, -10, 0, 42)
submit.Text = "SUBMIT ANSWER"
submit.TextColor3 = Color3.new(1,1,1)
submit.BackgroundColor3 = Color3.fromRGB(80, 45, 150)
submit.Font = Enum.Font.GothamBold
submit.TextSize = 15
submit.BorderSizePixel = 0
submit.Parent = puzzleFrame
round(submit, 8)
local closePuzzle = Instance.new("TextButton")
closePuzzle.Position = UDim2.new(0.64, 10, 0, 214)
closePuzzle.Size = UDim2.new(0.36, -28, 0, 42)
closePuzzle.Text = "LATER"
closePuzzle.TextColor3 = Color3.new(1,1,1)
closePuzzle.BackgroundColor3 = Color3.fromRGB(40, 55, 75)
closePuzzle.Font = Enum.Font.GothamBold
closePuzzle.TextSize = 15
closePuzzle.BorderSizePixel = 0
closePuzzle.Parent = puzzleFrame
round(closePuzzle, 8)

local activePuzzle: string? = nil
local function submitAnswer()
	if not activePuzzle then return end
	answerEvent:FireServer(activePuzzle, answerBox.Text)
	answerBox.Text = ""
	puzzleFrame.Visible = false
	activePuzzle = nil
end
submit.Activated:Connect(submitAnswer)
answerBox.FocusLost:Connect(function(enterPressed) if enterPressed then submitAnswer() end end)
closePuzzle.Activated:Connect(function() puzzleFrame.Visible = false; activePuzzle = nil end)

noticeEvent.OnClientEvent:Connect(function(titleText, bodyText)
	toastTitle.Text = tostring(titleText or "STORY X")
	toastBody.Text = tostring(bodyText or "")
	toast.Visible = true
	task.delay(8, function()
		if toast.Parent and toast.Visible and toastTitle.Text == tostring(titleText or "STORY X") then toast.Visible = false end
	end)
end)

puzzleEvent.OnClientEvent:Connect(function(id, titleText, questionText, hintText)
	activePuzzle = tostring(id)
	puzzleTitle.Text = tostring(titleText)
	question.Text = tostring(questionText)
	hint.Text = "HINT: " .. tostring(hintText)
	answerBox.Text = ""
	puzzleFrame.Visible = true
	answerBox:CaptureFocus()
end)

progressEvent.OnClientEvent:Connect(function(fragments, drones)
	stats.Text = "MEMORY SHARDS " .. tostring(fragments) .. "  |  DRONES " .. tostring(drones)
	if tonumber(fragments) and fragments >= 9 then
		mission.Text = "MISSION COMPLETE\nYou recovered the memories and questioned the model. The final clue is still unknown."
	elseif tonumber(fragments) and fragments >= 6 then
		mission.Text = "MISSION 03\nAll six memory fragments found. Solve terminals and explore the tower."
	elseif tonumber(fragments) and fragments >= 1 then
		mission.Text = "MISSION 02\nKeep collecting fragments. Three reasoning terminals are hidden in the districts."
	end
end)

print("[STORY X] YUGATNEO MATRIX HUD ready.")
