newcs_env.AddComponentPostInit("teleporter",function (self)
    function self:Activate(doer)
        if not self:IsActive() then
            return false
        end
    
        if self.onActivate ~= nil then
            self.onActivate(self.inst, doer, self.migration_data)
        end
    
        if self.migration_data ~= nil then
            local data = self.migration_data
            if data.worldid ~= TheShard:GetShardId() and Shard_IsWorldAvailable(data.worldid) then
                TheWorld:PushEvent("ms_playerdespawnandmigrate", { player = doer, portalid = nil, worldid = data.worldid, x = data.x, y = data.y, z = data.z })
                return true
            else
                return false
            end
        else 
            local targetTeleporter = self.targetTeleporterTemporary or self.targetTeleporter
            if (IsEntInAbyss(targetTeleporter) or IsEntInAbyss(self.inst)) 
                and not (targetTeleporter:HasTag("abyss_saveteleport") or self.inst:HasTag("abyss_saveteleport")) then
                
                return false
            end
        end
    
        self:Teleport(doer)
    
        local targetTeleporter = self.targetTeleporterTemporary or self.targetTeleporter
    
        if targetTeleporter.components.teleporter ~= nil then
            if doer:HasTag("player") then
                targetTeleporter.components.teleporter:ReceivePlayer(doer, self.inst)
            elseif doer.components.inventoryitem ~= nil then
                targetTeleporter.components.teleporter:ReceiveItem(doer, self.inst)
            end
        end
    
        if doer.components.leader ~= nil then
            for follower, v in pairs(doer.components.leader.followers) do
                if not (follower.components.follower ~= nil and follower.components.follower.noleashing) then
                    self:Teleport(follower)
                end
            end
        end
    
        --special case for the chester_eyebone: look for inventory items with followers
        if doer.components.inventory ~= nil then
            for k, item in pairs(doer.components.inventory.itemslots) do
                if item.components.leader ~= nil then
                    for follower, v in pairs(item.components.leader.followers) do
                        self:Teleport(follower)
                    end
                end
            end
            -- special special case, look inside equipped containers
            for k, equipped in pairs(doer.components.inventory.equipslots) do
                if equipped.components.container ~= nil then
                    for j, item in pairs(equipped.components.container.slots) do
                        if item.components.leader ~= nil then
                            for follower, v in pairs(item.components.leader.followers) do
                                self:Teleport(follower)
                            end
                        end
                    end
                end
            end
        end
    
        return true
    end
end)


newcs_env.AddComponentPostInit("RemoteTeleporter",function (self)
    local old_teleport = self.Teleport_Internal
    function self:Teleport_Internal(target, from_x, from_z, to_x, to_z, doer)
        if TheWorld.Map:NodeAtPointHasTag(from_x, 0,from_z, "Abyss") or TheWorld.Map:NodeAtPointHasTag(to_x, 0,to_z, "Abyss") then
            --AbyssForceDeath(doer)
            return false
        end
        old_teleport(self,target, from_x, from_z, to_x, to_z, doer)
    end
end)

newcs_env.AddComponentPostInit("playerspawner",function (self,inst)
    if not inst:HasTag("cave") then
        return
    end
    local old_Spawn = self.SpawnAtLocation
    function self:SpawnAtLocation(inst, player, x, y, z, isloading)
        local is_worldmigrate = player.migration~=nil
        old_Spawn(self,inst, player, x, y, z, isloading)
        if is_worldmigrate then
            player:DoTaskInTime(1,function (player)
                if player.components.areaaware:CurrentlyInTag("Abyss") then
                    local x, y, z = self:GetAnySpawnPoint()
                    player.Physics:Teleport(x,0,z)
                    AbyssForceDeath(player)
                end
            end)
        end
    end

    local source = "scripts/components/playerspawner.lua"
    local despawn_listener = inst.event_listeners["ms_playerdespawnandmigrate"][inst]
    for i, func in ipairs(despawn_listener) do
        -- We can find the correct func by the function's source since the
        -- event listeners likely won't have two different events of the same source
        if debug.getinfo(func, "S").source == source then
            
            despawn_listener[i] = function (inst, data)
                if data.player.components.areaaware:CurrentlyInTag("notele") then
                    AbyssForceDeath(data.player)
                    return false
                end
                func(inst, data)
            end
        end
    end
end)