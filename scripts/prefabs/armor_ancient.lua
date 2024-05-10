local assets =
{
	Asset("ANIM", "anim/armor_hpextraheavy.zip"),
}


local function OnShieldOver(inst, OnResistDamage)
    inst.task = nil
    if inst._fx ~= nil then
        inst._fx:kill_fx()
        inst._fx = nil
    end
    inst.components.armor.ontakedamage = OnResistDamage
    inst.components.armor:SetAbsorption(0.95)
    if inst._owner~=nil and inst._owner.components.health~=nil then
        inst._owner.components.health.externalabsorbmodifiers:RemoveModifier(inst)
    end
end

local function OnResistDamage(inst)--, damage)
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end
    inst.task = inst:DoTaskInTime(5, OnShieldOver, OnResistDamage)
    inst.components.armor.ontakedamage = nil

    if not inst.components.cooldown:IsCharging() then
        inst.components.cooldown:StartCharging()
    end    
end

local function OnChargedFn(inst)
    if inst._fx ~= nil then
        inst._fx:kill_fx()
    end
    if inst._owner~=nil then
        inst._fx = SpawnPrefab("forcefieldfx")
        inst._fx.entity:SetParent(inst._owner.entity)
        inst._fx.Transform:SetPosition(0, 0.2, 0)
        if inst._owner.components.health ~= nil then
            inst._owner.components.health.externalabsorbmodifiers:SetModifier(inst, 1, "ruins_shield")
        end
    end   
    inst.components.armor:SetAbsorption(TUNING.FULL_ABSORPTION)
    inst.components.armor.ontakedamage = OnResistDamage
end

local function OnEnabledSetBonus(inst)
	inst.components.damagetyperesist:AddResist("shadow_aligned", inst, 0.5, "setbonus")
    inst.components.damagetyperesist:AddResist("lunar_aligned", inst, 0.5,  "setbonus")
end

local function OnDisabledSetBonus(inst)
    inst.components.damagetyperesist:RemoveResist("shadow_aligned", inst, "setbonus")
    inst.components.damagetyperesist:RemoveResist("lunar_aligned", inst, "setbonus")
end

local function DoRegen(inst, owner)
	if not owner.components.health:IsDead() then
		owner.components.health:DoDelta(6,true)
	end
end

local function StartRegen(inst, owner)
	if inst.regentask == nil then
		inst.regentask = inst:DoPeriodicTask(3, DoRegen, 0,owner)
	end
end

local function StopRegen(inst)
	if inst.regentask ~= nil then
		inst.regentask:Cancel()
		inst.regentask = nil
	end
end




local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "armor_hpextraheavy", "swap_body")
    owner:AddTag("stun_immune")

    if owner.components.grogginess ~= nil then
        owner.components.grogginess:AddResistanceSource(inst, 30)
    end

    if owner.components.health ~= nil then
        owner.components.health.externalfiredamagemultipliers:SetModifier(inst, 0)
		StartRegen(inst, owner)
    end
    if inst._owner ~= nil then
        inst:RemoveEventCallback("locomote", inst.onlocomote, inst._owner)
    end
    inst._owner = owner
    inst:ListenForEvent("locomote", inst.onlocomote, owner)
    inst.components.cooldown:StartCharging(math.max(6, inst.components.cooldown:GetTimeToCharged()))
    if owner.components.sanity ~= nil then
		owner.components.sanity.neg_aura_modifiers:SetModifier(inst, 0)
	end
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    owner:RemoveTag("stun_immune")

    if owner.components.grogginess ~= nil then
        owner.components.grogginess:RemoveResistanceSource(inst)
    end


    if inst._fx ~= nil then
        inst._fx:kill_fx()
    end
    if owner.components.health ~= nil then
        owner.components.health.externalfiredamagemultipliers:RemoveModifier(inst, 0)
		StopRegen(inst)
    end
    
    if owner.components.sanity ~= nil then
		owner.components.sanity.neg_aura_modifiers:RemoveModifier(inst)
	end
    

    if inst._owner ~= nil then
        inst:RemoveEventCallback("locomote", inst.onlocomote, inst._owner)
        inst._owner = nil
    end
    inst._owner = nil
end



local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
    
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("armor_hpextraheavy")
    inst.AnimState:SetBuild("armor_hpextraheavy")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("heavyarmor")
    inst:AddTag("ancient")
    inst:AddTag("metal")
    inst:AddTag("poison_immune")
    inst:AddTag("nosteal")
    inst.foleysound = "dontstarve/movement/foley/metalarmour"

	local swap_data = {bank = "armor_hpextraheavy", anim = "anim"}
    MakeInventoryFloatable(inst, "small", 0.2, 0.80, nil, nil, swap_data)
	
	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename="lavaarena_armor_hpextraheavy"

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(5000, 0.95)
    inst.components.armor.indestructible = true


    inst:AddComponent("planardefense")
	inst.components.planardefense:SetBaseDefense(40)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.dapperness = TUNING.DAPPERNESS_LARGE
    inst.components.equippable.insulated = true
    inst.components.equippable.restrictedtag = "player"

    local setbonus = inst:AddComponent("setbonus")
    setbonus:SetSetName("ancient")
    setbonus:SetOnEnabledFn(OnEnabledSetBonus)
	setbonus:SetOnDisabledFn(OnDisabledSetBonus)

    inst:AddComponent("cooldown")
    inst.components.cooldown.cooldown_duration = 12
    inst.components.cooldown.onchargedfn = OnChargedFn

    inst:AddComponent("damagetyperesist")
	inst.components.damagetyperesist:AddResist("shadow_aligned", inst, 0.8)
    inst.components.damagetyperesist:AddResist("lunar_aligned", inst, 0.8)

	MakeHauntableLaunch(inst)	

    inst._owner = nil
    inst._lastfxtime = 0
    inst.onlocomote=function (owner)
        if inst._lastfxtime >0 then
            inst._lastfxtime = inst._lastfxtime -1
        else
            inst._lastfxtime = 5
            SpawnPrefab("cane_ancient_fx").Transform:SetPosition(owner.Transform:GetWorldPosition())
        end    
    end
    return inst
end

return Prefab( "armor_ancient", fn, assets) 
