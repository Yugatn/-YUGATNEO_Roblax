-- Server-side cooperative wave director for a Terminator-inspired arena.
-- Place as a ModuleScript under ServerScriptService. NPC model must be supplied
-- by the game and should have Humanoid + HumanoidRootPart.
local WaveDirector = {}
WaveDirector.__index = WaveDirector

function WaveDirector.new(config)
    assert(config and config.spawnPoints and #config.spawnPoints > 0, "spawn points required")
    assert(config.npcTemplate and config.npcTemplate:FindFirstChildOfClass("Humanoid"), "NPC Humanoid required")
    local self = setmetatable({}, WaveDirector)
    self.config = config
    self.wave = 0
    self.active = {}
    self.running = false
    self.onWave = config.onWave or function() end
    return self
end

function WaveDirector:aliveCount()
    local count = 0
    for npc in pairs(self.active) do
        local humanoid = npc.Parent and npc:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then
            count += 1
        else
            self.active[npc] = nil
        end
    end
    return count
end

function WaveDirector:spawnOne(index)
    local point = self.config.spawnPoints[((index - 1) % #self.config.spawnPoints) + 1]
    local npc = self.config.npcTemplate:Clone()
    npc:PivotTo(point.CFrame * CFrame.new(0, 3, 0))
    npc.Parent = self.config.npcFolder or workspace
    self.active[npc] = true
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    humanoid.Died:Connect(function()
        self.active[npc] = nil
        task.delay(5, function()
            if npc.Parent then npc:Destroy() end
        end)
    end)
    return npc
end

function WaveDirector:start()
    if self.running then return false end
    self.running = true
    task.spawn(function()
        local maxWaves = math.clamp(self.config.maxWaves or 10, 1, 20)
        local teamSize = math.clamp(self.config.teamSize or 1, 1, 4)
        for wave = 1, maxWaves do
            if not self.running then break end
            self.wave = wave
            local enemyCount = math.min(30, 2 + wave * 2 + teamSize)
            self.onWave(wave, enemyCount)
            for i = 1, enemyCount do
                if not self.running then break end
                self:spawnOne(i)
                task.wait(0.5)
            end
            while self.running and self:aliveCount() > 0 do
                task.wait(1)
            end
            if self.running then task.wait(self.config.intermission or 12) end
        end
        self.running = false
        self.onWave(0, 0) -- session ended
    end)
    return true
end

function WaveDirector:stop()
    self.running = false
    for npc in pairs(self.active) do
        if npc.Parent then npc:Destroy() end
    end
    table.clear(self.active)
end

return WaveDirector
