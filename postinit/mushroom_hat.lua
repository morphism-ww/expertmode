local function fertilize(inst,owner)
    local x,y,z = owner.Transform:GetWorldPosition()
    local tile_x, tile_z = TheWorld.Map:GetTileCoordsAtPoint(x,0,z)
    if TheWorld.Map:IsFarmableSoilAtPoint(x,0,z) then
        local nutrients = inst.components.fertilizer.nutrients
        TheWorld.components.farming_manager:AddTileNutrients(tile_x, tile_z, nutrients[1], nutrients[2], nutrients[3])
        owner.SoundEmitter:PlaySound(inst.components.fertilizer.fertilize_sound)
    end 
    for i,v in ipairs(TheSim:FindEntities(x, 0, z, 5, {"plant"}, { "DECOR", "INLIMBO", "burnt" })) do
        if v:IsValid() and v.components.pickable ~= nil and v.components.pickable:CanBeFertilized() then
            v.components.pickable:Fertilize(inst, owner)
        end
    end
end

local function start_fertilize(inst,owner)
    if inst.farmtask == nil then
        inst.farmtask = inst:DoPeriodicTask(1, fertilize, nil, owner)
    end
end

local function stop_fertilize(inst)
	if inst.farmtask ~= nil then
        inst.farmtask:Cancel()
        inst.farmtask = nil
    end
end



local function equip_red(inst,data)
    start_fertilize(inst,data.owner)

    if data.owner.components.bloomness~=nil then
        data.owner.components.combat.externaldamagemultipliers:SetModifier(inst, 1.2)
        data.owner.components.health.externalfiredamagemultipliers:SetModifier(inst, 0.2)
    end
end

local function unequip_red(inst,data)
    stop_fertilize(inst)

    if data.owner.components.bloomness~=nil then
        data.owner.components.combat.externaldamagemultipliers:RemoveModifier(inst)
        data.owner.components.health.externalfiredamagemultipliers:RemoveModifier(inst)
    end
end

local function equip_blue(inst,data)
    start_fertilize(inst,data.owner)

    if data.owner.components.bloomness~=nil then
        data.owner.components.health:AddRegenSource(inst,1,5)
    end
end

local function unequip_blue(inst,data)
    stop_fertilize(inst)

    if data.owner.components.bloomness~=nil then
        data.owner.components.health:RemoveRegenSource(inst)
    end
end

local function self_fertilize(inst,owner)
    if owner.components.fertilizable ~= nil then
        owner.components.fertilizable:Fertilize(inst)
        --applied = act.invobject.components.fertilizer:Heal(act.doer)
    end
end

local function equip_green(inst,data)
    start_fertilize(inst,data.owner)

    if data.owner.components.bloomness~=nil then
        if inst.self_fertilize_task == nil then
            inst.self_fertilize_task = inst:DoPeriodicTask(60,self_fertilize,nil,data.owner)
        end
        inst.components.equippable.walkspeedmult = 1.1
        inst.components.perishable:SetLocalMultiplier(1.1)
    end
end

local function unequip_green(inst,data)
    stop_fertilize(inst)

    inst.components.equippable.walkspeedmult = 1
    if inst.self_fertilize_task ~= nil then
        inst.self_fertilize_task:Cancel()
        inst.self_fertilize_task = nil
    end
    inst.components.perishable:SetLocalMultiplier(1)
end
--[[
FORMULA_NUTRIENTS_INDEX = 1,  blue   bloomness
COMPOST_NUTRIENTS_INDEX = 2,   green  compostheal_buff
MANURE_NUTRIENTS_INDEX = 3,   red  health:DoDelta

]]

newcs_env.AddPrefabPostInit("red_mushroomhat",function (inst)
    if not TheWorld.ismastersim then return end



    inst:AddComponent("fertilizer")
    inst.components.fertilizer.fertilizervalue = TUNING.GLOMMERFUEL_FERTILIZE
    inst.components.fertilizer.soil_cycles = 8
    inst.components.fertilizer.withered_cycles = 1
    inst.components.fertilizer:SetNutrients({  0,  0,  8 })


    inst:ListenForEvent("equipped",equip_red)
    inst:ListenForEvent("unequipped",unequip_red)
end)
newcs_env.AddPrefabPostInit("blue_mushroomhat",function (inst)
    if not TheWorld.ismastersim then return end



    inst:AddComponent("fertilizer")
    inst.components.fertilizer.fertilizervalue = TUNING.GLOMMERFUEL_FERTILIZE
    inst.components.fertilizer.soil_cycles = 8
    inst.components.fertilizer.withered_cycles = 1
    inst.components.fertilizer:SetNutrients({  8,  0,  0 })

    inst:ListenForEvent("equipped",equip_blue)
    inst:ListenForEvent("unequipped",unequip_blue)
end)
newcs_env.AddPrefabPostInit("green_mushroomhat",function (inst)
    if not TheWorld.ismastersim then return end

    
    inst:AddComponent("fertilizer")
    inst.components.fertilizer.fertilizervalue = TUNING.GLOMMERFUEL_FERTILIZE
    inst.components.fertilizer.soil_cycles = 8
    inst.components.fertilizer.withered_cycles = 1
    inst.components.fertilizer:SetNutrients({  0,  8,  0 })

    inst:ListenForEvent("equipped",equip_green)
    inst:ListenForEvent("unequipped",unequip_green)
end)