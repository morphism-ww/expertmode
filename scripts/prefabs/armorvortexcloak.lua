local assets=
{
    Asset("ANIM", "anim/armor_vortex_cloak.zip"),
    Asset("ANIM", "anim/cloak_fx.zip"),
    Asset("ANIM", "anim/vortex_cloak_fx.zip"),
    Asset("ANIM", "anim/ui_piggyback_2x6.zip")
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

local function setsoundparam(inst)
    local param = inst.components.fueled:GetPercent()
    inst.SoundEmitter:SetParameter( "vortex", "intensity", param )
end

local function spawnwisp(owner)
    local wisp = SpawnPrefab("armorvortexcloak_fx")
    local x,y,z = owner.Transform:GetWorldPosition()
    wisp.Transform:SetPosition(x+math.random()*0.25 -0.25/2,y,z+math.random()*0.25 -0.25/2)    
end

local function onequip(inst, owner) 
    owner.AnimState:OverrideSymbol("swap_body", "armor_vortex_cloak", "swap_body")
    owner.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/vortex_armour/equip_off")


    if not inst.components.fueled:IsEmpty() then
        inst.canshield=true
        for i, v in ipairs(RESISTANCES) do
            inst.components.resistance:AddResistance(v)
        end
    end

    inst.components.container:Open(owner)

    inst.wisptask = inst:DoPeriodicTask(0.1,function() spawnwisp(owner) end)

    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/vortex_armour/LP","vortex")

    setsoundparam(inst)
end

local function onunequip(inst, owner) 
    owner.AnimState:ClearOverrideSymbol("swap_body")
    --owner.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/vortex_armour/equip_on")

    --inst:RemoveEventCallback("armorhit", inst.OnBlocked)

    --owner:RemoveTag("not_hit_stunned")

    --owner.components.inventory:SetOverflow(nil)
    inst.components.container:Close(owner)
    for i, v in ipairs(RESISTANCES) do
        inst.canshield=false
        inst.components.resistance:RemoveResistance(v)
    end
    if inst.wisptask then
        inst.wisptask:Cancel()
        inst.wisptask= nil
    end

    --inst.SoundEmitter:KillSound("vortex")
end


local function ShouldResistFn(inst)
    if not inst.components.equippable:IsEquipped() then
        return false
    end
    local owner = inst.components.inventoryitem.owner
    return owner ~= nil
        and not inst.components.fueled:IsEmpty()
end

local function OnResistDamage(inst)--, damage)
    local owner = inst.components.inventoryitem:GetGrandOwner() or inst
    owner:AddChild(SpawnPrefab("vortex_cloak_fx"))
    setsoundparam(inst)

    owner.components.sanity:DoDelta(-10, false)
    inst.components.fueled:DoDelta(-TUNING.MED_FUEL)
end

local function CLIENT_PlayFuelSound(inst)
	local parent = inst.entity:GetParent()
	local container = parent ~= nil and (parent.replica.inventory or parent.replica.container) or nil
	if container ~= nil and container:IsOpenedBy(ThePlayer) then
		TheFocalPoint.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")
	end
end

local function SERVER_PlayFuelSound(inst)
	local owner = inst.components.inventoryitem.owner
	if owner == nil then
		inst.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")
	elseif inst.components.equippable:IsEquipped() and owner.SoundEmitter ~= nil then
		owner.SoundEmitter:PlaySound("dontstarve/common/nightmareAddFuel")
	else
		inst.playfuelsound:push()
		--Dedicated server does not need to trigger sfx
		if not TheNet:IsDedicated() then
			CLIENT_PlayFuelSound(inst)
		end
	end
end


local function ontakefuel(inst)
    if inst.components.equippable:IsEquipped() and
        inst.components.fueled:IsEmpty() or
        not inst.canshield then
        inst.canshield=true
        for i, v in ipairs(RESISTANCES) do
            inst.components.resistance:AddResistance(v)
        end
    end
    SERVER_PlayFuelSound(inst)
end

local function nofuel(inst)
    for i, v in ipairs(RESISTANCES) do
        inst.components.resistance:RemoveResistance(v)
    end
    inst.canshield=false
end


local function GetShadowLevel(inst)
	return not inst.components.fueled:IsEmpty() and TUNING.ARMOR_SKELETON_SHADOW_LEVEL or 0
end



local function canacceptfuelitem(self,item)
    if self.accepting and item then
		return item.prefab=="horrorfuel"
	end
	return false
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddMiniMapEntity()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst, "idle_water", "anim")


    inst:AddTag("backpack")
    inst:AddTag("vortex_cloak")
    inst:AddTag("heavyarmor")
    inst.AnimState:SetBank("armor_vortex_cloak")
    inst.AnimState:SetBuild("armor_vortex_cloak")
    inst.AnimState:PlayAnimation("anim")

    inst.MiniMapEntity:SetIcon("armorvortexcloak.tex")
    
    inst.foleysound = "dontstarve_DLC003/common/crafted/vortex_armour/foley"
    inst.playfuelsound = net_event(inst.GUID, "armorskeleton.playfuelsound")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.cangoincontainer = false



    inst:AddComponent("fueled")
    inst.components.fueled:InitializeFuelLevel(3 * TUNING.LARGE_FUEL)
    inst.components.fueled.fueltype = FUELTYPE.NIGHTMARE
    inst.components.fueled:SetDepletedFn(nofuel)
    inst.components.fueled:SetTakeFuelFn(ontakefuel)
    inst.components.fueled.accepting = true
    inst.components.fueled.CanAcceptFuelItem=canacceptfuelitem
    --inst.components.fueled.secondaryfueltype = "PURE"


    --[[inst:AddComponent("armor")
    inst.components.armor:InitCondition(450, 1)  --full_absorb
    inst.components.armor.dontremove = true
    --inst.components.armor:SetImmuneTags({"shadow"})
    inst.components.armor.bonussanitydamage = 0.2 -- Sanity drain when hit (damage percentage)
    inst.components.armor:SetOnFinished(onempty)0]]
    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(0)

    inst:AddComponent("resistance")
    inst.components.resistance:SetShouldResistFn(ShouldResistFn)
    inst.components.resistance:SetOnResistDamageFn(OnResistDamage)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("armorvortexcloak")
    
    inst:AddComponent("shadowlevel")
	inst.components.shadowlevel:SetDefaultLevel(TUNING.ARMOR_SKELETON_SHADOW_LEVEL)
	inst.components.shadowlevel:SetLevelFn(GetShadowLevel)

    inst.canshield=false

    MakeHauntableLaunchAndDropFirstItem(inst)
    return inst
end

local function fxfn()
    local inst = CreateEntity()
    
    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("cloakfx")
    inst.AnimState:SetBuild("cloak_fx")
    inst.AnimState:PlayAnimation("idle",true)

    inst:AddTag("FX")
    inst:AddTag("NOBLOCK")
    inst:AddTag("NOCLICK")

    for i=1,14 do
        inst.AnimState:Hide("fx"..i)
    end

    inst.AnimState:Show("fx"..math.random(1,14))

    inst.persists = false
    inst:ListenForEvent("animover", inst.Remove)
    inst:ListenForEvent("entitysleep", inst.Remove)

    return inst
end



local function fx2fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("vortex_cloak_fx")
    inst.AnimState:SetBuild("vortex_cloak_fx")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("FX")

	if not TheWorld.ismastersim then
        return inst
    end

	--inst:ListenForEvent("animover", function() inst:Remove() end)

    inst:ListenForEvent("animover", inst.Remove)

    return inst
end



return
    Prefab( "armorvortexcloak", fn, assets),
    Prefab( "armorvortexcloak_fx", fxfn, assets),
    Prefab("vortex_cloak_fx", fx2fn, assets)
