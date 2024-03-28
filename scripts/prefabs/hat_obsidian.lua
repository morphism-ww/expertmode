local assets =
{
	Asset("ANIM", "anim/hat_dragonhead.zip"),
}

--[[local temperature_thresholds = { 20, 30, 40, 50 }

local function GetRateForTemperature(temp)
    local rate=0
    for i,v in ipairs(temperature_thresholds) do
        if temp > v then
            rate = rate + 1
        end
    end
    return rate
end]]


--[[local function DoRegen(inst, owner)
    local rate = GetRateForTemperature(inst.components.temperature:GetCurrent())
    inst.components.armor:Repair(3*rate)
	if not inst.components.armor:IsDamaged() then
		inst.regentask:Cancel()
		inst.regentask = nil
	end
end

local function StartRegen(inst, owner)
	if inst.regentask == nil then
		inst.regentask = inst:DoPeriodicTask(2, DoRegen, nil, owner)
	end
end

local function StopRegen(inst)
	if inst.regentask ~= nil then
		inst.regentask:Cancel()
		inst.regentask = nil
	end
end]]



local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "hat_dragonhead", "swap_hat")

    owner.AnimState:ClearOverrideSymbol("headbase_hat") --clear out previous overrides

    owner.AnimState:Show("HAT")
    owner.AnimState:Show("HAIR_HAT")
    owner.AnimState:Hide("HAIR_NOHAT")
    owner.AnimState:Hide("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Hide("HEAD")
        owner.AnimState:Show("HEAD_HAT")
        owner.AnimState:Show("HEAD_HAT_NOHELM")
        owner.AnimState:Hide("HEAD_HAT_HELM")
    end

    if owner.components.health ~= nil then
        owner.components.health.externalfiredamagemultipliers:SetModifier(inst, 0)
    end

    --[[if inst.components.armor:IsDamaged() then
		StartRegen(inst, owner)
	else
		StopRegen(inst)
	end]]
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("headbase_hat")
    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Show("HEAD")
        owner.AnimState:Hide("HEAD_HAT")
        owner.AnimState:Hide("HEAD_HAT_NOHELM")
        owner.AnimState:Hide("HEAD_HAT_HELM")
    end

    if owner.components.health ~= nil then
        owner.components.health.externalfiredamagemultipliers:RemoveModifier(inst)
    end
end


--[[local function OnTakeDamage(inst, amount)
	if inst.regentask == nil and inst.components.equippable:IsEquipped() then
		local owner = inst.components.inventoryitem.owner
		if owner ~= nil then
			StartRegen(inst, owner)
		end
	end
end]]

local function SelfRepair(inst,data)
    if  inst.components.armor:IsDamaged() then
        local last=data.last
        local new=data.new
        local delta=new-last
        if new>25 and delta>0 then
            local tempbonus=new>50 and 0.1 or 0
            inst.components.armor:Repair(math.max(tempbonus,4*delta))
        end
    end
end

local function fn()
	local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("dragonheadhat")
    inst.AnimState:SetBuild("hat_dragonhead")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")

    local swap_data = { bank = "dragonheadhat", anim = "anim" }
    MakeInventoryFloatable(inst)
    inst.components.floater:SetBankSwapOnFloat(false, nil, swap_data) --Hats default animation is not "idle", so even though we don't swap banks, we need to specify the swap_data for re-skinning to reset properly when floating
    inst.components.floater:SetSize("med")
    inst.components.floater:SetScale(0.65)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end


    inst:AddComponent("inventoryitem")
   

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(735, 0.8)
    

    inst:AddComponent("temperature")
    inst.components.temperature.current = TheWorld.state.temperature
    inst.components.temperature.inherentinsulation = TUNING.INSULATION_MED
    inst.components.temperature.mintemp= 0

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(0.4)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.walkspeedmult = 1.15

    inst:ListenForEvent("temperaturedelta",SelfRepair)

    MakeHauntableLaunch(inst)

    return inst

end

return Prefab( "obsidian_hat", fn,assets)
