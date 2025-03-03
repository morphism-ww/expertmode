local easing = require("easing")

newcs_env.AddComponentPostInit("meteorshower", function(self)
    local function OnUpdate(inst, self)
        if inst:IsNearPlayer(30) then
            self:SpawnCrazyMeteor()
        end
    
        if GetTime() >= self.tasktotime then
            self:StartCooldown()
        end
    end
    function self:StartCrazyShower()
        self:StopShower()       
    
        local duration = 30
    
        self.dt = 1
        self.medium_remaining = 3
        self.large_remaining = 20

        self.task = self.inst:DoPeriodicTask(self.dt, OnUpdate, nil, self)
        self.tasktotime = GetTime() + duration
    end
    --[[function self:SpawnCrazyMeteor()
        local x, y, z = self.inst.Transform:GetWorldPosition()
        local theta = math.random() * PI2
        for i, v in ipairs(AllPlayers) do
            if  v.entity:IsVisible() and
                v:GetDistanceSqToPoint(x, y, z) < 900 then
                local radius = 1+3*math.random()
                local px,py,pz = v.Transform:GetWorldPosition()
                local met = SpawnPrefab("shadowmeteor")
                met.Transform:SetPosition(px + radius*math.cos(theta), 0, pz - radius*math.sin(theta))
                met:SetPeripheral(true)
                met:SetSize("large", 1)
            end
        end
    end]]
    function self:SpawnCrazyMeteor(mod)
        --Randomize spawn point
        local x, y, z = self.inst.Transform:GetWorldPosition()
        local theta = math.random() * PI2
        -- Do some easing fanciness to make it less clustered around the spawner prefab
        local radius = easing.linear(math.random(), math.random() * 7, 22, 1)
    
        local met = SpawnPrefab("shadowmeteor")
        met.Transform:SetPosition(x + radius*math.cos(theta), 0, z - radius*math.sin(theta))
        met:SetSize("large", 1)

        met:SetPeripheral(true)

        return met
        
    end
end)
