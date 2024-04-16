local easing = require("easing")
local function OnUpdate(inst, self)
    if inst:IsNearPlayer(32) then
        self:SpawnCrazyMeteor()
    end

    if GetTime() >= self.tasktotime then
        self:StartCooldown()
    end
end
AddComponentPostInit("meteorshower", function(self)
    function self:StartCrazyShower()
        self:StopShower()       
    
        local duration = 30
        local rate = 2
    
        if duration > 0 and rate > 0 then
            self.dt = 1 / rate
            self.medium_remaining = 3
            self.large_remaining = 20
    
            self.task = self.inst:DoPeriodicTask(self.dt, OnUpdate, nil, self)
            self.tasktotime = GetTime() + duration
        end
    end
    function self:SpawnCrazyMeteor(mod)
        --Randomize spawn point
        local x, y, z = self.inst.Transform:GetWorldPosition()
        local theta = math.random() * 2 * PI
        -- Do some easing fanciness to make it less clustered around the spawner prefab
        local radius = easing.linear(math.random(), 4, 28, 1)
    
        local map = TheWorld.Map
        local fan_offset = FindValidPositionByFan(theta, radius, 18,
            function(offset)
                return map:IsPassableAtPoint(x + offset.x, y + offset.y, z + offset.z)
            end)
    
        if fan_offset ~= nil then
            local met = SpawnPrefab("shadowmeteor")
            met.Transform:SetPosition(x + fan_offset.x, y + fan_offset.y, z + fan_offset.z)

            if math.random()<0.4 then
                    met:SetSize("large", 1)
            else
                met:SetSize("medium", 1)
            end
            met:SetPeripheral(true)
            return met
        end
    end
end)
