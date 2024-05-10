TUNING.ARMOR_LUNARPLANT_REFLECT_PLANAR_DMG_VS_SHADOW=42.5
TUNING.ARMOR_LUNARPLANT_REFLECT_PLANAR_DMG=22.6
TUNING.ARMOR_LUNARPLANT = 1785
TUNING.ARMOR_LUNARPLANT_ABSORPTION=0.85
TUNING.ARMOR_VOIDCLOTH = 1785
TUNING.ARMOR_VOIDCLOTH_HAT=1260
TUNING.ARMOR_LUNARPLANT_HAT=1260


local function DoRegen(inst, owner)
	local fx = SpawnPrefab("ghostlyelixir_shield_fx")
	fx.entity:SetParent(owner.entity)
	fx.Transform:SetPosition(0, -1, 0)
	if not owner.components.health:IsDead() then
		owner.components.health:DoDelta(1)
	end
	if not owner.components.health:IsHurt() then
		inst.regentask:Cancel()
		inst.regentask = nil
	end
end


local function StartRegen(inst, owner)
	if inst.regentask == nil then
		inst.regentask = inst:DoPeriodicTask(4, DoRegen,nil,owner)
	end
end

local function StopRegen(inst)
	if inst.regentask ~= nil then
		inst.regentask:Cancel()
		inst.regentask = nil
	end
end


local function OnBlocked(inst,owner)
    if owner~=nil and not owner:HasDebuff("lunar_protect") and inst.components.setbonus:IsEnabled(EQUIPMENTSETNAMES.LUNARPLANT) then
        owner:AddDebuff("lunar_protect","lunar_shield")
	end
end

local function onequip_2(inst,data)
	local owner=data.owner
	if owner~=nil and owner.components.health~=nil then
		inst:ListenForEvent("blocked", inst.procfn,owner)
		inst:ListenForEvent("attacked", inst.procfn,owner)
		StartRegen(inst, owner)
	end
end

local function onunequip_2(inst,data)
	local owner=data.owner
	if owner~=nil and owner.components.health~=nil then
		inst:RemoveEventCallback("blocked", inst.procfn,owner)
		inst:RemoveEventCallback("attacked", inst.procfn,owner)
		StopRegen(inst)
	end		
end


AddPrefabPostInit("armor_lunarplant",function(inst)
    if not TheWorld.ismastersim then return end

	inst:ListenForEvent("equipped",onequip_2)
    inst:ListenForEvent("unequipped",onunequip_2)

	inst.procfn = function(owner) OnBlocked(inst, owner) end

end)

----------------------------------------------------------------------

TUNING.ARMOR_VOIDCLOTH_SETBONUS_PLANARDAMAGE_MAX = 64
TUNING.ARMOR_VOIDCLOTH_SETBONUS_PLANARDAMAGE_MAX_HITS = 6
TUNING.ARMOR_VOIDCLOTH_SETBONUS_PLANARDAMAGE_DECAY_TIME = 5


local function OnEnabledSetBonus2(inst)
	inst.components.damagetyperesist:AddResist("shadow_aligned", inst, TUNING.ARMOR_VOIDCLOTH_SETBONUS_SHADOW_RESIST, "setbonus")
	inst.components.equippable.walkspeedmult = 1.3
	inst.components.armor:SetAbsorption(0.85)
end

local function OnDisabledSetBonus2(inst)
	inst.components.damagetyperesist:RemoveResist("shadow_aligned", inst, "setbonus")
	inst.components.equippable.walkspeedmult = 1.2
	inst.components.armor:SetAbsorption(0.8)
end

local function onequip_void(inst,data)
	if data.owner~=nil then
		data.owner:AddTag("playercharge")
	end
end

local function onunequip_void(inst,data)
	if data.owner~=nil then
		data.owner:RemoveTag("playercharge")
	end		
end

AddPrefabPostInit("armor_voidcloth",function(inst)
    if not TheWorld.ismastersim then return end

	
	inst.components.setbonus:SetOnEnabledFn(OnEnabledSetBonus2)
	inst.components.setbonus:SetOnDisabledFn(OnDisabledSetBonus2)

	inst.components.equippable.walkspeedmult = 1.2

	inst:ListenForEvent("equipped",onequip_void)
    inst:ListenForEvent("unequipped",onunequip_void)
end)