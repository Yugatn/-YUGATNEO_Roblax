-- YUGATNEO Chess Arena — TableManager: several independent tables.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MatchTable = require(script.Parent:WaitForChild("MatchTable"))

local old = workspace:FindFirstChild("YUGATNEO_ChessArena")
if old then old:Destroy() end
for _, child in ipairs(workspace:GetChildren()) do
	if child.Name:match("^Table_") then child:Destroy() end
end

local event = ReplicatedStorage:FindFirstChild("ChessControlEvent")
if not event then
	event = Instance.new("RemoteEvent")
	event.Name = "ChessControlEvent"
	event.Parent = ReplicatedStorage
end

local tables = {}
local playerTable = {} -- userId -> tableId

local function setMembership(player, tableId)
	if tableId then
		playerTable[player.UserId] = tableId
		player:SetAttribute("InChessMatch", true)
	else
		playerTable[player.UserId] = nil
		player:SetAttribute("InChessMatch", false)
	end
end

local function tableFor(player)
	local tid = playerTable[player.UserId]
	return tid and tables[tid] or nil
end

local LAYOUT = {
	{ id = "1", origin = Vector3.new(0, 1, 0) },
	{ id = "2", origin = Vector3.new(55, 1, 0) },
	{ id = "3", origin = Vector3.new(-55, 1, 0) },
}

for _, layout in ipairs(LAYOUT) do
	tables[layout.id] = MatchTable.new({
		tableId = layout.id,
		origin = layout.origin,
		event = event,
		onJoin = function(player, tableId)
			setMembership(player, tableId)
		end,
		onLeave = function(player)
			setMembership(player, nil)
		end,
	})
end

event.OnServerEvent:Connect(function(player, action, ...)
	local args = { ... }

	if action == "Join" then
		local requestedId = args[1]
		local options = args[2] or {}
		local t = tables[tostring(requestedId or "")]
		if not t then
			for _, layout in ipairs(LAYOUT) do
				local cand = tables[layout.id]
				if cand.state == "Idle" or cand.state == "Waiting" then
					if not (cand.whitePlayerUserId and cand.blackPlayerUserId) then
						t = cand
						break
					end
				end
			end
		end
		if not t then
			event:FireClient(player, "Error", nil, "No free table")
			return
		end
		local current = tableFor(player)
		if current and current.tableId ~= t.tableId then
			event:FireClient(player, "Error", current.tableId, "Leave current table first")
			return
		end
		local ok, msg = t:requestJoin(player, options)
		if not ok then event:FireClient(player, "Error", t.tableId, tostring(msg)) end
		return
	end

	local t = tableFor(player)
	if not t then
		if action == "ListTables" then
			local list = {}
			for _, layout in ipairs(LAYOUT) do
				table.insert(list, tables[layout.id]:getPublicState())
			end
			event:FireClient(player, "Tables", nil, list)
		else
			event:FireClient(player, "Error", nil, "Not seated at a table")
		end
		return
	end

	if action == "Cancel" then
		t:cancelWaiting(player)
	elseif action == "Ready" then
		t:setReady(player, args[1] ~= false)
	elseif action == "Resign" then
		t:resign(player)
	elseif action == "Draw" then
		t:offerDraw(player)
	elseif action == "ClearFinished" then
		t:clearFinished(player)
	elseif action == "Promote" then
		t:promote(player, args[1])
	elseif action == "Deselect" then
		t:deselect(player)
	elseif action == "ListTables" then
		local list = {}
		for _, layout in ipairs(LAYOUT) do
			table.insert(list, tables[layout.id]:getPublicState())
		end
		event:FireClient(player, "Tables", t.tableId, list)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local t = tableFor(player)
	if t then
		t:handleDisconnect(player.UserId)
	end
	setMembership(player, nil)
end)

print("[YUGATNEO] Chess Arena loaded: tables 1, 2, 3 ready.")
