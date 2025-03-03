local assets =
{
	Asset("ANIM", "anim/armor_yjj.zip"),
}

local prefabs = {
    "cane_ancient_fx",
    "forcefieldfx",
	"armororichal_glow_fx"
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
    if inst.shield_fx ~= nil then
        inst.shield_fx:kill_fx()
        inst.shield_fx = nil
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
    if inst.shield_fx ~= nil then
        inst.shield_fx:kill_fx()
    end
    if inst.canshield then
        if inst._owner~=nil then
            inst.shield_fx = SpawnPrefab("forcefieldfx")
            inst.shield_fx.entity:SetParent(inst._owner.entity)
        end
        inst:AddTag("forcefield")   
        --inst.components.armor:SetAbsorption(TUNING.FULL_ABSORPTION)
        for i, v in ipairs(RESISTANCES) do
            inst.components.resistance:AddResistance(v)
        end
    end
end

local function OnEnabledSetBonus(inst)
	inst:AddTag("heavyarmor")

	inst.components.armor:SetAbsorption(0.95)

    inst.canshield = true
    inst.components.planardefense:AddBonus(inst, 5, "setbonus")
    inst.components.cooldown:StartCharging()
end

local function OnDisabledSetBonus(inst)
	inst:RemoveTag("heavyarmor")

	inst.components.armor:SetAbsorption(0.9)

    inst.canshield = false
    inst.components.planardefense:RemoveBonus(inst,"setbonus")
    OnShieldOver(inst)
end


local TRAIL_FLAGS = { "shadowtrail" }
local function do_trail(inst)
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
    owner.AnimState:OverrideSymbol("swap_body", "armor_yjj", "swap_body")
    if inst.fx ~= nil then
		inst.fx:Remove()
	end
	inst.fx = SpawnPrefab(inst.prefab.."_glow_fx")
	inst.fx:AttachToOwner(owner)
	owner.AnimState:SetSymbolLightOverride("swap_body", .1)


	if inst._trailtask == nil then
        inst._trailtask = inst:DoPeriodicTask(6 * FRAMES, do_trail, 2 * FRAMES)
    end
	inst.components.cooldown:StartCharging(12)

    if owner.components.sanity ~= nil then
		owner.components.sanity.neg_aura_modifiers:SetModifier(inst, 0.05)
	end

    inst._owner = owner
end

local function onunequip(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
    if inst.fx ~= nil then
		inst.fx:Remove()
		inst.fx = nil
	end
	owner.AnimState:SetSymbolLightOverride("swap_body", 0)
    
	if inst._trailtask ~= nil then
        inst._trailtask:Cancel()
        inst._trailtask = nil
    end

	if owner.components.sanity ~= nil then
		owner.components.sanity.neg_aura_modifiers:RemoveModifier(inst)
	end

    inst._owner = nil    

	if inst.shield_fx ~= nil then
        inst.shield_fx:kill_fx()
    end
end

local function SetupEquippable(inst)
	inst:AddComponent("equippable")
	inst.components.equippable.walkspeedmult = 1.2
	inst.components.equippable.equipslot = EQUIPSLOTS.BODY
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
end


local SWAP_DATA_BROKEN = { bank = "armor_orichal", anim = "broken" }
local SWAP_DATA = { bank = "armor_orichal", anim = "anim" }

local function OnBroken(inst)
	if inst.components.equippable ~= nil then
		inst:RemoveComponent("equippable")
		inst.AnimState:PlayAnimation("broken")
		inst.components.floater:SetSwapData(SWAP_DATA_BROKEN)
		inst:AddTag("broken")
		inst.components.inspectable.nameoverride = "BROKEN_FORGEDITEM"
	end
end

local function OnRepaired(inst)
	if inst.components.equippable == nil then
		SetupEquippable(inst)
		inst.AnimState:PlayAnimation("anim")
		inst.components.floater:SetSwapData(SWAP_DATA)
		inst:RemoveTag("broken")
		inst.components.inspectable.nameoverride = nil
	end
end


local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
    
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("armor_yjj")
    inst.AnimState:SetBuild("armor_yjj")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("metal")
	inst:AddTag("mythical")
    inst:AddTag("soul_protect")
	inst:AddTag("poison_immune")
    inst:AddTag("show_broken_ui")

	inst.itemtile_colour = RGB(218,165,32)

	local swap_data = {bank = "armor_hpextraheavy", anim = "anim"}
    MakeInventoryFloatable(inst, "small", 0.2, 0.80, nil, nil, swap_data)
	
	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    
	-------------------------------------------------------------
    inst:AddComponent("armor")
    inst.components.armor:InitCondition(3000, 0.9)

    inst:AddComponent("planardefense")
	inst.components.planardefense:SetBaseDefense(15)

    inst:AddComponent("resistance")
    inst.components.resistance:SetOnResistDamageFn(OnTakeDamage)

	inst:AddComponent("damagetyperesist")
	inst.components.damagetyperesist:AddResist("shadow_aligned", inst, 0.9)
	--------------------------------------------------------------
	
    SetupEquippable(inst)

	local setbonus = inst:AddComponent("setbonus")
    setbonus:SetSetName(EQUIPMENTSETNAMES.ORICHAL)
    setbonus:SetOnEnabledFn(OnEnabledSetBonus)
	setbonus:SetOnDisabledFn(OnDisabledSetBonus)

    inst:AddComponent("cooldown")
    inst.components.cooldown.cooldown_duration = 12
    inst.components.cooldown.onchargedfn = OnChargedFn

	MakeForgeRepairable2(inst,OnBroken,OnRepaired)

	inst._owner = nil
    
    inst.canshield = false

    MakeStunProtectArmor(inst)

	MakeHauntableLaunch(inst)	


    return inst
end


local function CreateFxFollowFrame(i, build)
	local inst = CreateEntity()

	--[[Non-networked entity]]
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddFollower()

	inst:AddTag("FX")

	inst.AnimState:SetBank("armor_yjj")
	inst.AnimState:SetBuild(build)
	inst.AnimState:PlayAnimation("idle"..tostring(i), true)
	inst.AnimState:SetSymbolBloom("guang")
	inst.AnimState:SetSymbolLightOverride("guang", .5)
	inst.AnimState:SetLightOverride(.1)

	inst:AddComponent("highlightchild")

	inst.persists = false

	return inst
end

local function glow_OnRemoveEntity(inst)
	for i, v in ipairs(inst.fx) do
		v:Remove()
	end
end

local function glow_ColourChanged(inst, r, g, b, a)
	for i, v in ipairs(inst.fx) do
		v.AnimState:SetAddColour(r, g, b, a)
	end
end

local function glow_SpawnFxForOwner(inst, owner)
	inst.fx = {}
	local frame
	for i = 1, 6 do
		local fx = CreateFxFollowFrame(i, inst.build)
		frame = frame or math.random(fx.AnimState:GetCurrentAnimationNumFrames()) - 1
		fx.entity:SetParent(owner.entity)
		fx.Follower:FollowSymbol(owner.GUID, "swap_body", nil, nil, nil, true, nil, i - 1)
		fx.AnimState:SetFrame(frame)
		fx.components.highlightchild:SetOwner(owner)
		table.insert(inst.fx, fx)
	end
	inst.components.colouraddersync:SetColourChangedFn(glow_ColourChanged)
	inst.OnRemoveEntity = glow_OnRemoveEntity
end

local function glow_OnEntityReplicated(inst)
	local owner = inst.entity:GetParent()
	if owner ~= nil then
		glow_SpawnFxForOwner(inst, owner)
	end
end

local function glow_AttachToOwner(inst, owner)
	inst.entity:SetParent(owner.entity)
	if owner.components.colouradder ~= nil then
		owner.components.colouradder:AttachChild(inst)
	end
	--Dedicated server does not need to spawn the local fx
	if not TheNet:IsDedicated() then
		glow_SpawnFxForOwner(inst, owner)
	end
end

local function MakeGlow(name, build, assets)
	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddNetwork()

		inst:AddTag("FX")

		inst:AddComponent("colouraddersync")

		inst.build = build

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			inst.OnEntityReplicated = glow_OnEntityReplicated

			return inst
		end

		inst.AttachToOwner = glow_AttachToOwner
		inst.persists = false

		return inst
	end

	return Prefab(name, fn, assets)
end




return Prefab("armororichal", fn, assets,prefabs),
MakeGlow("armororichal_glow_fx", "armor_yjj", assets)