local assets =
{
	Asset("ANIM", "anim/armor_obsidian.zip"),
}


local function OnBlocked(owner, data)
    owner.SoundEmitter:PlaySound("dontstarve_DLC002/common/armour/obsidian")
    if data.attacker ~= nil and
        not (data.attacker.components.health ~= nil and data.attacker.components.health:IsDead()) and
        (data.weapon == nil or ((data.weapon.components.weapon == nil or data.weapon.components.weapon.projectile == nil) and data.weapon.components.projectile == nil)) and
        data.attacker.components.burnable ~= nil and
        not data.redirected and
        not data.attacker:HasTag("thorny") then
        data.attacker.components.burnable:Ignite(nil,nil,owner)
    end
end

-- These represent the boundaries between the ranges (relative to ambient, so ambient is always "0")
local relative_temperature_thresholds = { -20, -10, 10, 20 }

local function GetRangeForTemperature(temp, ambient)
    local range = 1
    for i,v in ipairs(relative_temperature_thresholds) do
        if temp > ambient + v then
            range = range + 1
        end
    end
    return range
end


-- Heatrock emits constant temperatures depending on the temperature range it's in
local emitted_temperatures = { 0, 20, 40, 60, 80 }

local function HeatFn(inst, observer)
    local range = GetRangeForTemperature(inst.components.temperature:GetCurrent(),TheWorld.state.temperature)
    return emitted_temperatures[range]
end

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
    owner.AnimState:OverrideSymbol("swap_body", "armor_obsidian", "swap_body")

    inst:ListenForEvent("blocked", OnBlocked, owner)
    inst:ListenForEvent("attacked", OnBlocked, owner)

    if owner.components.health ~= nil then
        owner.components.health.externalfiredamagemultipliers:SetModifier(inst, 0)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")

    inst:RemoveEventCallback("blocked", OnBlocked, owner)
    inst:RemoveEventCallback("attacked", OnBlocked, owner)

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
    inst.entity:AddSoundEmitter()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
 
    inst.AnimState:SetBank("armor_obsidian")
    inst.AnimState:SetBuild("armor_obsidian")
    inst.AnimState:PlayAnimation("anim")

    inst.foleysound = "dontstarve_DLC002/common/foley/obsidian_armour"

    inst:AddTag("obsidian")
	local swap_data = {bank = "armor_obsidian", anim = "anim"}
    MakeInventoryFloatable(inst, "small", 0.2, 0.80, nil, nil, swap_data)
	
	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")


    inst:AddComponent("temperature")
    inst.components.temperature.current = TheWorld.state.temperature
    inst.components.temperature.inherentinsulation = TUNING.INSULATION_LARGE
    inst.components.temperature:IgnoreTags("obsidian")
    inst.components.temperature.mintemp= 0

    inst:AddComponent("heater")
    inst.components.heater.heatfn = HeatFn
    inst.components.heater.carriedheatfn = HeatFn
    inst.components.heater.carriedheatmultiplier = 0.8
    inst.components.heater.equippedheatfn = HeatFn
    inst.components.heater:SetThermics(true, false)
    

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(TUNING.ARMOROBSIDIAN, TUNING.ARMOROBSIDIAN_ABSORPTION)


    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)


    inst:ListenForEvent("temperaturedelta",SelfRepair)

	MakeHauntableLaunch(inst)	
    
    return inst
end

return Prefab( "newcs_armorobsidian", fn, assets) 
