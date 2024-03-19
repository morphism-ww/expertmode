local function fertilize(inst,owner)
    local x,y,z=owner.Transform:GetWorldPosition()
    local tile_x, tile_z = TheWorld.Map:GetTileCoordsAtPoint(x,0,z)
    if TheWorld.Map:IsFarmableSoilAtPoint(x,0,z) then
        local nutrients = inst.components.fertilizer.nutrients
        TheWorld.components.farming_manager:AddTileNutrients(tile_x, tile_z, nutrients[1], nutrients[2], nutrients[3])
        owner.SoundEmitter:PlaySound(inst.components.fertilizer.fertilize_sound)
    end
    local ents = TheSim:FindEntities(x, 0, z, 5, nil, { "FX", "DECOR", "INLIMBO", "burnt" },{"plant"})
    for i,v in ipairs(ents) do
        if v:IsValid() and v.components.pickable ~= nil then
            v.components.pickable:Fertilize(inst, owner)
        end
    end

end

local function onequip(inst,owner)
	inst._oldonequipfn(inst,owner)
	inst.farmtask = inst:DoPeriodicTask(2, fertilize, nil, owner)
end

local function onunequip(inst,owner)
	inst._oldunequipfn(inst,owner)
	if inst.farmtask ~= nil then
        inst.farmtask:Cancel()
        inst.farmtask = nil
    end
end


AddPrefabPostInit("red_mushroomhat",function (inst)
    if not TheWorld.ismastersim then return end

    inst._oldonequipfn=inst.components.equippable.onequipfn
	inst._oldunequipfn=inst.components.equippable.onunequipfn

    inst:AddComponent("fertilizer")
    inst.components.fertilizer.fertilizervalue = TUNING.GLOMMERFUEL_FERTILIZE
    inst.components.fertilizer.soil_cycles = 8
    inst.components.fertilizer.withered_cycles = 1
    inst.components.fertilizer:SetNutrients({  0,  0,  8 })

    inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
end)
AddPrefabPostInit("blue_mushroomhat",function (inst)
    if not TheWorld.ismastersim then return end

    inst._oldonequipfn=inst.components.equippable.onequipfn
	inst._oldunequipfn=inst.components.equippable.onunequipfn

    inst:AddComponent("fertilizer")
    inst.components.fertilizer.fertilizervalue = TUNING.GLOMMERFUEL_FERTILIZE
    inst.components.fertilizer.soil_cycles = 8
    inst.components.fertilizer.withered_cycles = 1
    inst.components.fertilizer:SetNutrients({  16,  0,  0 })

    inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
end)
AddPrefabPostInit("green_mushroomhat",function (inst)
    if not TheWorld.ismastersim then return end

    inst._oldonequipfn=inst.components.equippable.onequipfn
	inst._oldunequipfn=inst.components.equippable.onunequipfn

    inst:AddComponent("fertilizer")
    inst.components.fertilizer.fertilizervalue = TUNING.GLOMMERFUEL_FERTILIZE
    inst.components.fertilizer.soil_cycles = 8
    inst.components.fertilizer.withered_cycles = 1
    inst.components.fertilizer:SetNutrients({  0,  16,  0 })

    inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
end)