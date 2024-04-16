AddPrefabPostInit("bishop_nightmare",function(inst)
    if not TheWorld.ismastersim then return end
    inst.shadow=SpawnPrefab("small_leechterror")
    inst.shadow.entity:SetParent(inst.entity)
    inst.shadow.entity:AddFollower():FollowSymbol(inst.GUID, "hips", 0, 0, 0)
end)
-----------------------------------------------------------------------------------
local function LaunchItem(inst, target, item)
    if item.Physics ~= nil and item.Physics:IsActive() then
        local x, y, z = item.Transform:GetWorldPosition()
        item.Physics:Teleport(x, .1, z)

        x, y, z = inst.Transform:GetWorldPosition()
        local x1, y1, z1 = target.Transform:GetWorldPosition()
        local angle = math.atan2(z1 - z, x1 - x) + (math.random() * 20 - 10) * DEGREES
        local speed = 5 + math.random() * 2
        item.Physics:SetVel(math.cos(angle) * speed, 10, math.sin(angle) * speed)
    end
end
local function OnHitOther(inst, data)
    if data.redirected then
        return
    end
    local target=data.target
	if target ~= nil then
        if target.components.inventory ~= nil then
            local item = target.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if item ~= nil then
                target.components.inventory:DropItem(item)
                LaunchItem(inst, target, item)
            end
        end
        if target.components.sanity~=nil then
            target.components.sanity:DoDelta(-5)
        end
    end
end


AddPrefabPostInit("knight_nightmare",function(inst)
    if not TheWorld.ismastersim then return end
    inst:AddComponent("damagetyperesist")
    inst.components.damagetyperesist:AddResist("animal", inst, 0.5)
    inst:ListenForEvent("onhitother", OnHitOther)
end)
----------------------------------------------------------

local function OnHitOther2(inst, data)
	if data.target ~= nil then
        data.target:PushEvent("knockback", { knocker = inst, radius = 5, strengthmult = 1.2})
        if data.target.components.sanity~=nil then
            data.target.components.sanity:DoDelta(-5)
        end
    end

end

AddPrefabPostInit("rook_nightmare",function(inst)
    if not TheWorld.ismastersim then return end
    inst:AddComponent("damagetyperesist")
    inst.components.damagetyperesist:AddResist("animal", inst, 0.5)
    inst:ListenForEvent("onhitother", OnHitOther2)
end)

local function spawnshadow(inst)
    local x,y,z=inst.Transform:GetWorldPosition()
    local dragon=SpawnPrefab("shadowdragon")
    dragon.Transform:SetPosition(x,y,z)
end


local function spawn_defender(inst)
    local pos=inst:GetPosition()
    if TheWorld.components.ancient_defender ~= nil and TheWorld.components.ancient_defender:AllowSpawn() then
        local node,node_index = TheWorld.Map:FindNodeAtPoint(pos:Get())
        if string.find(TheWorld.topology.ids[node_index],"Military") then
            local offset=FindWalkableOffset(pos,0,6,9)
            if offset~=nil then
                SpawnPrefab("spider_robot").Transform:SetPosition(pos.x+offset.x,0,pos.z+offset.z)
            end
        end    
    end   
end


AddPrefabPostInit("ancient_altar_broken",function(inst)
    if not TheWorld.ismastersim then return end
    inst:DoTaskInTime(0,spawn_defender)
    inst:ListenForEvent("onprefabswaped",spawnshadow)
end)