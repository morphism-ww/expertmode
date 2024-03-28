TUNING.ARMOR_LUNARPLANT_REFLECT_PLANAR_DMG_VS_SHADOW=42.5
TUNING.ARMOR_LUNARPLANT_REFLECT_PLANAR_DMG=22.6
TUNING.ARMOR_LUNARPLANT = 1785
TUNING.ARMOR_LUNARPLANT_ABSORPTION=0.85
TUNING.ARMOR_VOIDCLOTH = 1785
TUNING.ARMOR_VOIDCLOTH_HAT=1260
TUNING.ARMOR_LUNARPLANT_HAT=1260

local function OnEnabledSetBonus(inst)
	inst.components.damagetyperesist:AddResist("lunar_aligned", inst, TUNING.ARMOR_LUNARPLANT_SETBONUS_LUNAR_RESIST, "setbonus")
	inst.components.armor:SetAbsorption(0.9)
end

local function OnDisabledSetBonus(inst)
	inst.components.damagetyperesist:RemoveResist("lunar_aligned", inst, "setbonus")
	inst.components.armor:SetAbsorption(0.85)
end

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
	if inst.regentask == nil and owner.components.health then
		inst.regentask = inst:DoPeriodicTask(4, DoRegen,nil,owner)
	end
end

local function StopRegen(inst)
	if inst.regentask ~= nil then
		inst.regentask:Cancel()
		inst.regentask = nil
	end
end

local function OnTakeDamage(inst, amount)
	if inst.regentask == nil and inst.components.equippable~=nil and inst.components.equippable:IsEquipped() then
		local owner = inst.components.inventoryitem.owner
		if owner ~= nil and owner.components.health ~= nil then
			StartRegen(inst, owner)
		end
	end
end

local function OnBlocked(inst,owner)
    if owner~=nil and not owner:HasDebuff("lunar_protect") and inst.components.setbonus:IsEnabled(EQUIPMENTSETNAMES.LUNARPLANT) then
        owner:AddDebuff("lunar_protect","lunar_shield")
	end
end

local function onequip(inst,owner)
	inst._oldonequipfn(inst,owner)
	inst:ListenForEvent("blocked", inst.procfn,owner)
    inst:ListenForEvent("attacked", inst.procfn,owner)
	StartRegen(inst, owner)
end

local function onunequip(inst,owner)
	inst._oldunequipfn(inst,owner)
	inst:RemoveEventCallback("blocked", inst.procfn,owner)
	inst:RemoveEventCallback("attacked", inst.procfn,owner)
	StopRegen(inst)
end

local function SetupEquippable(inst)
	inst:AddComponent("equippable")
	inst.components.equippable.equipslot = EQUIPSLOTS.BODY
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
end

local SWAP_DATA = { bank = "armor_lunarplant", anim = "anim" }
local function OnRepaired(inst)
	if inst.components.equippable == nil then
		SetupEquippable(inst)
		inst.AnimState:PlayAnimation("anim")
		inst.components.floater:SetSwapData(SWAP_DATA)
		inst:RemoveTag("broken")
		inst.components.inspectable.nameoverride = nil
	end
end

AddPrefabPostInit("armor_lunarplant",function(inst)
    if not TheWorld.ismastersim then return end

    inst._oldonequipfn=inst.components.equippable.onequipfn
	inst._oldunequipfn=inst.components.equippable.onunequipfn

	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	inst.components.armor.ontakedamage = OnTakeDamage

	inst.components.setbonus:SetOnEnabledFn(OnEnabledSetBonus)
	inst.components.setbonus:SetOnDisabledFn(OnDisabledSetBonus)

	inst.procfn = function(owner) OnBlocked(inst, owner) end

	inst.components.forgerepairable:SetOnRepaired(OnRepaired)
end)

----------------------------------------------------------------------

TUNING.ARMOR_VOIDCLOTH_SETBONUS_PLANARDAMAGE_MAX = 48
TUNING.ARMOR_VOIDCLOTH_SETBONUS_PLANARDAMAGE_MAX_HITS = 12
TUNING.ARMOR_VOIDCLOTH_SETBONUS_PLANARDAMAGE_DECAY_TIME = 5


local function OnEnabledSetBonus2(inst)
	inst.components.damagetyperesist:AddResist("shadow_aligned", inst, TUNING.ARMOR_VOIDCLOTH_SETBONUS_SHADOW_RESIST, "setbonus")
	inst.components.armor:SetAbsorption(0.85)
end

local function OnDisabledSetBonus2(inst)
	inst.components.damagetyperesist:RemoveResist("shadow_aligned", inst, "setbonus")
	inst.components.armor:SetAbsorption(0.8)
end

local function onequip2(inst,owner)
	local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("swap_body", skin_build, "swap_body", inst.GUID, "armor_voidcloth")
    else
        owner.AnimState:OverrideSymbol("swap_body", "armor_voidcloth", "swap_body")
    end

    if inst.fx ~= nil then
        inst.fx:Remove()
    end
    inst.fx = SpawnPrefab("armor_voidcloth_fx")
    inst.fx:AttachToOwner(owner)

	if owner.components.sanity ~= nil then
		owner.components.sanity.neg_aura_modifiers:SetModifier(inst, 0)
	end
	if inst._owner ~= nil then
		inst:RemoveEventCallback("onattackother", inst.flamefn, inst._owner)
	end
	inst:ListenForEvent("onattackother", inst.flamefn, owner)
	inst._owner = owner
	if inst.components.container ~= nil then
		inst.components.container:Open(owner)
	end
end

local function onunequip2(inst,owner)
	owner.AnimState:ClearOverrideSymbol("swap_body")

    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end

    if inst.fx ~= nil then
        inst.fx:Remove()
        inst.fx = nil
    end

	if owner.components.sanity ~= nil then
		owner.components.sanity.neg_aura_modifiers:RemoveModifier(inst)
	end

	if inst._owner ~= nil then
		inst:RemoveEventCallback("onattackother", inst.flamefn, inst._owner)
		inst._owner = nil
	end
	if inst.components.container ~= nil then
		inst.components.container:Close()
	end
end

local function SpawnShadowFire(owner,target)
    local startangle = owner:GetAngleToPoint(target.Transform:GetWorldPosition())*DEGREES
	local burst = 3
    for i=1,burst do
        local theta = startangle-PI/2+i*PI/2
		local offset = Vector3(12  * math.cos( startangle ), 0,1 * math.sin( startangle ))
        local newpos = Vector3(owner.Transform:GetWorldPosition())+offset
        local fire = SpawnPrefab("void_flame")
        fire.Transform:SetRotation(theta/DEGREES)
        fire.Transform:SetPosition(newpos.x,newpos.y,newpos.z)
        fire:settarget(target,40,owner)
    end
end


local function tryflame(inst,owner,data)
	if owner~=nil and data and inst.components.setbonus:IsEnabled(EQUIPMENTSETNAMES.VOIDCLOTH) then
		local target=data.target
		local weapon=data.weapon
		if target and weapon
		and not (target:HasTag("wall") or target:HasTag("engineering"))then
			owner.components.health:DoDelta(3)
			--local item = inst.components.container:GetItemInSlot(1)
			if weapon:HasTag("shadowlevel") and weapon.components.shadowlevel.level>1 then
				--inst.components.container:RemoveItem(item, false):Remove()
				SpawnShadowFire(owner,target)
			end
		end
	end
end


local function SetupEquippable2(inst)
	inst:AddComponent("equippable")
	inst.components.equippable.equipslot = EQUIPSLOTS.BODY
	inst.components.equippable:SetOnEquip(onequip2)
	inst.components.equippable:SetOnUnequip(onunequip2)
end

AddPrefabPostInit("armor_voidcloth",function(inst)
    if not TheWorld.ismastersim then return end


	inst.components.equippable:SetOnEquip(onequip2)
	inst.components.equippable:SetOnUnequip(onunequip2)


	inst.components.setbonus:SetOnEnabledFn(OnEnabledSetBonus2)
	inst.components.setbonus:SetOnDisabledFn(OnDisabledSetBonus2)

	inst:AddComponent("container")
	inst.components.container:WidgetSetup("armor_voidcloth")

	debug.setupvalue(inst.components.forgerepairable.onrepaired,1,SetupEquippable2)
	inst._owner=nil
	inst.flamefn=function(owner,data) tryflame(inst,owner,data) end
end)

AddPrefabPostInit("voidcloth_scythe",function(inst)
	inst:AddTag("shadowhip")
end)
AddPrefabPostInit("nightsword",function(inst)
	inst:AddTag("shadowhip")
end)