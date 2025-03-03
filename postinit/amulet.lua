local function onequip_blue(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "torso_amulets", "blueamulet")

    inst.freezefn = function(attacked, data)
        if data and data.attacker and data.attacker.components.freezable then
            data.attacker.components.freezable:AddColdness(0.67)
            data.attacker.components.freezable:SpawnShatterFX()
            inst.components.fueled:DoDelta(-0.03 * inst.components.fueled.maxfuel)
        end
    end

    inst:ListenForEvent("attacked", inst.freezefn, owner)

    if inst.components.fueled then
        inst.components.fueled:StartConsuming()
    end

    if owner.components.health ~= nil then
        owner.components.health.externalfiredamagemultipliers:SetModifier(inst, 0.1)
    end
end

local function onunequip_blue(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")

    inst:RemoveEventCallback("attacked", inst.freezefn, owner)

    if inst.components.fueled then
        inst.components.fueled:StopConsuming()
    end

    if owner.components.health ~= nil then
        owner.components.health.externalfiredamagemultipliers:RemoveModifier(inst)
    end
end
newcs_env.AddPrefabPostInit("blueamulet",function(inst)

    if not TheWorld.ismastersim then
		return inst
	end
    
    inst.components.equippable:SetOnEquip(onequip_blue)
    inst.components.equippable:SetOnUnequip(onunequip_blue)

    inst.components.fueled.fueltype = FUELTYPE.NIGHTMARE
    inst.components.fueled.accepting = true
end)

newcs_env.AddPrefabPostInit("yellowamuletlight",function(inst)
    inst.Light:SetRadius(4)
end)