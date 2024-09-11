local assets =
{
	Asset("ANIM", "anim/armor_hpextraheavy.zip"),
}

local prefabs = {
    "cane_ancient_fx",
    "forcefieldfx"
}

local RESISTANCES =
{
    "_combat",
    "explosive",
    "quakedebris",
    "lunarhaildebris",
    "caveindebris",
    "trapdamage",
}


local function OnShieldOver(inst)
    inst.task = nil
    if inst._fx ~= nil then
        inst._fx:kill_fx()
        inst._fx = nil
    end
    for i, v in ipairs(RESISTANCES) do
        inst.components.resistance:RemoveResistance(v)
    end
    inst:RemoveTag("forcefield")  
end


local function OnTakeDamage(inst)
    if inst.canshield and inst.task == nil then
        inst.task = inst:DoTaskInTime(3, OnShieldOver)
        if not inst.components.cooldown:IsCharging() then
            inst.components.cooldown:StartCharging()
        end
    end
end

local function OnChargedFn(inst)
    if inst._fx ~= nil then
        inst._fx:kill_fx()
    end
    if inst.canshield then
        if inst._owner~=nil and inst._owner.isplayer then
            inst._fx = SpawnPrefab("forcefieldfx")
            inst._fx.entity:SetParent(inst._owner.entity)
            inst._fx.Transform:SetPosition(0, 0.2, 0)
        end
        inst:AddTag("forcefield")   
        --inst.components.armor:SetAbsorption(TUNING.FULL_ABSORPTION)
        for i, v in ipairs(RESISTANCES) do
            inst.components.resistance:AddResistance(v)
        end
    end
end

local function OnEnabledSetBonus(inst)
   
    inst.components.armor:SetAbsorption(0.95)
    inst.canshield = true
    inst.components.planardefense:AddBonus(inst, 5, "setbonus")
    inst.components.cooldown:StartCharging()
end

local function OnDisabledSetBonus(inst)

    inst.components.armor:SetAbsorption(0.9)
    inst.canshield = false
    inst.components.planardefense:RemoveBonus(inst,"setbonus")
    OnShieldOver(inst)
end

--[[local function DoRegen(inst, owner)
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
end]]


local TRAIL_FLAGS = { "shadowtrail" }
local function cane_do_trail(inst)
    local owner = inst.components.inventoryitem:GetGrandOwner() or inst
    if not owner.entity:IsVisible() then
        return
    end

    local x, y, z = owner.Transform:GetWorldPosition()
    if owner.sg ~= nil and owner.sg:HasStateTag("moving") then
        local theta = -owner.Transform:GetRotation() * DEGREES
        local speed = owner.components.locomotor:GetRunSpeed() * .1
        x = x + speed * math.cos(theta)
        z = z + speed * math.sin(theta)
    end
    local mounted = owner.components.rider ~= nil and owner.components.rider:IsRiding()
    local map = TheWorld.Map
    local offset = FindValidPositionByFan(
        math.random() * TWOPI,
        (mounted and 1 or .5) + math.random() * .5,
        4,
        function(offset)
            local pt = Vector3(x + offset.x, 0, z + offset.z)
            return map:IsPassableAtPoint(pt:Get())
                and not map:IsPointNearHole(pt)
                and #TheSim:FindEntities(pt.x, 0, pt.z, .7, TRAIL_FLAGS) <= 0
        end
    )

    if offset ~= nil then
        SpawnPrefab("cane_ancient_fx").Transform:SetPosition(x + offset.x, 0, z + offset.z)
    end
end


local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_body", "armor_hpextraheavy", "swap_body")
    
    
    if inst._trailtask == nil then
        inst._trailtask = inst:DoPeriodicTask(6 * FRAMES, cane_do_trail, 2 * FRAMES)
    end

    inst.components.cooldown:StartCharging(12)

    if owner.components.sanity ~= nil then
		owner.components.sanity.neg_aura_modifiers:SetModifier(inst, 0.05)
	end

    if owner.components.stunprotecter == nil then
        owner:AddComponent("stunprotecter")
    end
    owner.components.stunprotecter:AddSource(inst)

    inst._owner = owner
end

local function onunequip(inst, owner)
    if inst._fx ~= nil then
        inst._fx:kill_fx()
    end

    owner.AnimState:ClearOverrideSymbol("swap_body")
   
    --[[if owner.components.grogginess ~= nil then
        owner.components.grogginess:RemoveResistanceSource(inst)
    end]]    
    if owner.components.sanity ~= nil then
		owner.components.sanity.neg_aura_modifiers:RemoveModifier(inst)
	end

    if owner.components.stunprotecter ~= nil then
        owner.components.stunprotecter:RemoveSource(inst)
    end
    
    inst._owner = nil

    if inst._trailtask ~= nil then
        inst._trailtask:Cancel()
        inst._trailtask = nil
    end
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
    inst:AddTag("soul_protect")
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
    inst.components.inventoryitem.imagename = "lavaarena_armor_hpextraheavy"

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(3000, 0.9)

    inst:AddComponent("planardefense")
	inst.components.planardefense:SetBaseDefense(15)

    inst:AddComponent("resistance")
    inst.components.resistance:SetOnResistDamageFn(OnTakeDamage)
    
    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.insulated = true
    inst.components.equippable.restrictedtag = "player"

    local setbonus = inst:AddComponent("setbonus")
    setbonus:SetSetName(EQUIPMENTSETNAMES.ANCIENT)
    setbonus:SetOnEnabledFn(OnEnabledSetBonus)
	setbonus:SetOnDisabledFn(OnDisabledSetBonus)

    inst:AddComponent("cooldown")
    inst.components.cooldown.cooldown_duration = 12
    inst.components.cooldown.onchargedfn = OnChargedFn

    inst:AddComponent("damagetyperesist")
	inst.components.damagetyperesist:AddResist("shadow_aligned", inst, 0.9)

    inst:AddComponent("forgerepairable")
	inst.components.forgerepairable:SetRepairMaterial(FORGEMATERIALS.IRON)


	MakeHauntableLaunch(inst)	

    inst._owner = nil
    
    inst.canshield = false

    return inst
end

return Prefab("armor_ancient", fn, assets,prefabs) 
