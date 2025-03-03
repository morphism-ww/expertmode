newcs_env.AddComponentPostInit("wagpunk_manager",function (self)
    self.should_spawn_ironlord = false
    --[[function self:FindSpotForMachines()

        if not self.should_spawn_ironlord and self.machinemarker and not self:IsWerepigInCharge() then        
            local pos = Vector3(self.machinemarker.Transform:GetWorldPosition())
    
            if not IsAnyPlayerInRange(pos.x, 0, pos.z, PLAYER_CAMERA_SEE_DISTANCE) then 
                return pos, true
            else
                if not TheWorld.components.timer:TimerExists("junkwagpunk") then
                    TheWorld.components.timer:StartTimer("junkwagpunk", math.random(240 + math.random()*240))
    
                    local offset = FindWalkableOffset(pos, math.random()*TWOPI, 30, 16, true)
                    local finalpos = pos + offset
    
                    local radius = 16
                    local theta = self.machinemarker:GetAngleToPoint(finalpos.x, 0, finalpos.z)*DEGREES
                    local offsetclose = Vector3(radius * math.cos(theta), 0, -radius * math.sin(theta))
    
                    self:SpawnJunkWagstaff(pos+offset, pos+offsetclose)
                end
            end
        else
    
            local nodes = {}
    
            for index, node in ipairs(TheWorld.topology.nodes) do
                if index ~= self._currentnodeindex and NodeCanHaveMachine(node) then
                    table.insert(nodes, index)
                end
            end
    
            local current_node = TheWorld.topology.nodes[self._currentnodeindex]
            local current_x, current_z = current_node and current_node.cent[1], current_node and current_node.cent[2]
    
            while #nodes > 0 do
                local rand = math.random(#nodes)
                local index = nodes[rand]
    
                table.remove(nodes, rand)
    
                local new_node = TheWorld.topology.nodes[index]
                local new_x, new_z = new_node.cent[1], new_node.cent[2]
                local new_pos = Vector3(new_x, 0, new_z)
    
                if not IsAnyPlayerInRange(new_x, 0, new_z, PLAYER_CAMERA_SEE_DISTANCE) and
                    (current_node == nil or VecUtil_LengthSq(new_x - current_x, new_z - current_z) > MIN_DIST_FROM_LAST_POSITION_SQ)
                then
                    local offset = FindWalkableOffset(new_pos, math.random()*TWOPI, math.random()*10, 16, nil, nil, IsPositionClearCenterPoint)
    
                    if offset ~= nil then
                        self._currentnodeindex = index
                        return new_pos + offset, false
                    end
                end
            end
        end
    end]]
    function self:PlaceMachinesAround(pos)
        --local ids = PickSome(NUM_MACHINES_PER_SPAWN, { 1, 2, 3, 4, 5 } ) -- NOTE(DiogoW): For later!
        if not self:IsWerepigInCharge() and self.should_spawn_ironlord then
            local offset = self:FindMachineSpawnPointOffset(pos)
            if offset ~= nil then
                local machine = SpawnPrefab("ironlord_death")
                self:AddMachine(machine.GUID)
                machine.Transform:SetPosition(pos.x + offset.x, pos.y + offset.y, pos.z + offset.z)
            end
        end
        for i = 1, 3 do
            local offset = self:FindMachineSpawnPointOffset(pos)
            if offset ~= nil then
                local machine = SpawnPrefab("wagstaff_machinery")
                machine.Transform:SetPosition(pos.x + offset.x, pos.y + offset.y, pos.z + offset.z)
                machine:SetDebrisType(i)
                --machine:SetDebrisType(ids[i]) -- NOTE(DiogoW): For later!
    
                self:AddMachine(machine.GUID)
            end
        end
    end
    function self:OnSave()
        local data = {
           nextspawntime = self.nextspawntime,
           nexthinttime = self.nexthinttime,
           hintcount = self.hintcount > 0 and self.hintcount or nil,
           currentnodeindex = self._currentnodeindex,
           spawnedfences = self.spawnedfences,
           should_spawn_ironlord = self.should_spawn_ironlord
        }
    
        return data
    end
    
    function self:OnLoad(data)
        if not data then return end
    
        self.nextspawntime = data.nextspawntime or self.nextspawntime
        self.nexthinttime  = data.nexthinttime  or self.nexthinttime
        self.hintcount     = data.hintcount     or self.hintcount
        self.should_spawn_ironlord = data.should_spawn_ironlord or self.should_spawn_ironlord
        self._currentnodeindex = data.currentnodeindex or self._currentnodeindex
    
        self.spawnedfences = data.spawnedfences
    end
end)

local function ShouldAcceptItem(inst, item)
    if item.prefab == "iron_soul" then
        return true
    end
end

local function OnGetItemFromPlayer(inst, giver, item)
    local chatter_index = math.random(#STRINGS.WAGSTAFF_NPC_GET_IRONSOUL)
    inst.components.talker:Chatter("WAGSTAFF_NPC_GET_IRONSOUL", chatter_index, nil, nil, CHATPRIORITIES.LOW)
    if TheWorld.components.wagpunk_manager then
        TheWorld.components.wagpunk_manager.should_spawn_ironlord = true
    end
end

local function OnRefuseItem(inst, giver, item)
    local chatter_table, chatter_index
    
    chatter_table = "WAGSTAFF_NPC_TOO_BUSY"
    chatter_index = math.random(#STRINGS.WAGSTAFF_NPC_TOO_BUSY)
    
    inst.components.talker:Chatter(chatter_table, chatter_index, nil, nil, CHATPRIORITIES.LOW)
end

newcs_env.AddPrefabPostInit("wagstaff_npc_mutations",function (inst)
    inst:AddTag("trader")
    if not TheWorld.ismastersim then
        return inst
    end	

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader.onaccept = OnGetItemFromPlayer
    inst.components.trader.onrefuse = OnRefuseItem
    --deleteitemonaccept

end)

local function GivePower(inst,target,doer)
    if target.prefab == "laser_cannon" then
        target.components.fueled:SetPercent(1)
    elseif target.prefab == "aurumite_kit" then
        target.components.rechargeable:SetPercent(1)
    end
    local item = SpawnPrefab("security_pulse_cage")
    local container = inst.components.inventoryitem:GetContainer()
    if container ~= nil then
        local slot = inst.components.inventoryitem:GetSlotNum()
        inst:Remove()
        container:GiveItem(item, slot)
    else
        local x, y, z = doer.Transform:GetWorldPosition()
        inst:Remove()
        item.Transform:SetPosition(x, y, z)
    end
    return true
end

newcs_env.AddPrefabPostInit("security_pulse_cage_full",function (inst)
    inst:AddTag("laser_cannon_targeter")
    inst:AddTag("aurumite_kit_targeter")
    if not TheWorld.ismastersim then
        return inst
    end
    inst:AddComponent("useabletargeteditem")
    inst.components.useabletargeteditem:SetOnUseFn(GivePower)
end)