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
    inst.components.temperatureoverrider:Enable()
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
    inst.components.temperatureoverrider:Disable()
    if owner.components.health ~= nil then
        owner.components.health.externalfiredamagemultipliers:RemoveModifier(inst)
    end
end
AddPrefabPostInit("blueamulet",function(inst)
    inst:AddComponent("temperatureoverrider")
    if not TheWorld.ismastersim then
		return inst
	end
    inst.components.temperatureoverrider:SetRadius(3)
    inst.components.temperatureoverrider:SetTemperature(-10)
    inst.components.equippable:SetOnEquip(onequip_blue)
    inst.components.equippable:SetOnUnequip(onunequip_blue)

    inst.components.fueled.fueltype = FUELTYPE.NIGHTMARE
    inst.components.fueled.accepting = true
end)
AddPrefabPostInit("yellowamuletlight",function(inst)
    inst.Light:SetRadius(4)
    inst.Light:SetFalloff(.6)
    inst.Light:SetIntensity(.7)
    inst.Light:SetColour(223 / 255, 208 / 255, 69 / 255)
end)