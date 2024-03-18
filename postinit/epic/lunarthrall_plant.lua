local PLANT_MUST = {"lunarthrall_plant"}
local TARGET_MUST_TAGS = { "_combat", "character" }
local TARGET_CANT_TAGS = { "INLIMBO","lunarthrall_plant", "lunarthrall_plant_end" }
local function Retarget(inst)
    --print("RETARGET")
    if not inst.no_targeting then
        local target = FindEntity(
            inst,
            TUNING.LUNARTHRALL_PLANT_RANGE,
            function(guy)
                local total = 0
                local x,y,z = inst.Transform:GetWorldPosition()

                if inst.tired then
                    return nil
                end

                local plants = TheSim:FindEntities(x,y,z, 12, PLANT_MUST)
                for i, plant in ipairs(plants)do
                    if plant ~= inst then
                        if plant.components.combat.target and plant.components.combat.target == guy then
                            total = total +1
                        end
                    end
                end
                if total < 8 then
                    return inst.components.combat:CanTarget(guy)
                end
            end,
            TARGET_MUST_TAGS,
            TARGET_CANT_TAGS
        )

        if inst.vinelimit > 0 then
            if target and ( not inst.components.freezable or not inst.components.freezable:IsFrozen()) then

                local pos = Vector3(inst.Transform:GetWorldPosition())

                local theta = math.random()*2*PI
                local radius = TUNING.LUNARTHRALL_PLANT_MOVEDIST
                local offset = Vector3(radius * math.cos( theta ), 0, -radius * math.sin( theta ))
                pos = pos + offset

                if TheWorld.Map:IsVisualGroundAtPoint(pos.x,pos.y,pos.z) then

                    local vine = SpawnPrefab("lunarthrall_plant_vine_end")
                    vine.Transform:SetPosition(pos.x,pos.y,pos.z)
                    vine.Transform:SetRotation(inst:GetAngleToPoint(pos.x, pos.y, pos.z))
    				vine.components.freezable:SetRedirectFn(vine_addcoldness)
                    vine.sg:RemoveStateTag("nub")
                    if inst.tintcolor then
                        vine.AnimState:SetMultColour(inst.tintcolor, inst.tintcolor, inst.tintcolor, 1)
                        vine.tintcolor = inst.tintcolor
                    end

    				inst.components.colouradder:AttachChild(vine)

                    vine.parentplant = inst
                    table.insert(inst.vines,vine)
                    inst.vinelimit = inst.vinelimit -1
                    inst:DoTaskInTime(0,function() vine:ChooseAction() end)

                    return target
                end
            end
        end
    end
end


AddPrefabPostInit("lunarthrall_plant", function(inst)
    inst:AddTag("noauradamage")
	if not TheWorld.ismastersim then
		return
    end
    inst.components.health.fire_damage_scale=0
    inst.components.combat.targetfn=Retarget
end)

AddPrefabPostInit("lunarthrall_plant_vine_end", function(inst)
    inst:AddTag("noauradamage")
	if not TheWorld.ismastersim then
		return
    end
    inst.components.health.fire_damage_scale=0
end)
AddPrefabPostInit("lunarthrall_plant_vine", function(inst)
    inst:AddTag("noauradamage")
	if not TheWorld.ismastersim then
		return
    end
end)


AddComponentPostInit('lunarthrall_plantspawner',function (self)
    function self:PushInvade()
        local plants = {}

        local herd = self:FindHerd()

        if not herd then
            -- MAYBE FIND SOME WILD PLANTS?
            local patch = self:FindWildPatch()
            if patch and #patch > 0 then
                for i,member in ipairs(patch)do
                    table.insert(plants,member)
                end
            else
                --"NOTHING FOUND THIS TIME"
                return
            end
        else
            --"ALL PLANTS IN HERD"
            for member, bool in pairs(herd.components.herd.members)do
                table.insert(plants,member)
            end
        end

        local targets = {}
        local SPACE = 2.5
        local MAX_SPACE = 8
        local number_spawned = 0
        
        while #plants > 0 and number_spawned < 3 do
            local random = math.random(1,#plants)
            local plant = plants[random]
            if plant then

                local eligable = true

                if eligable and #targets > 0 then
                    -- NO TARGETED PLANTS ARE TOO CLOSE.
                    for t,target in ipairs(targets)do
                        if target:GetDistanceSqToInst(plant) < SPACE*SPACE then
                            eligable = false
                        end
                    end

                    -- FIND PLACE CLOSEISH TO TARGETED PLANTS.
                    for t,target in ipairs(targets)do
                        if target:GetDistanceSqToInst(plant) > MAX_SPACE*MAX_SPACE then
                            eligable = false
                        end
                    end
                end

                if eligable then
                    number_spawned = number_spawned + 1
                    table.insert(targets,plant)
                end
            end
            table.remove(plants,random)
        end

        for i,target  in ipairs(targets)do
            self:InvadeTarget(target)
        end
    end
end)

