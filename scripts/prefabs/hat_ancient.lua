local assets =
{
	Asset("ANIM", "anim/hat_crowndamager.zip"),
}

local function OnEnabledSetBonus(inst)
	inst.components.equippable.walkspeedmult = 1.2
    inst.components.damagetyperesist:AddResist("shadow_aligned", inst, TUNING.ARMOR_VOIDCLOTH_SETBONUS_SHADOW_RESIST, "setbonus")
    inst:AddTag("playercharge")
    --[[if inst._owner.components.electricattacks == nil then
        inst._owner:AddComponent("electricattacks")
    end
    inst._owner.components.electricattacks:AddSource(inst)]]
    if inst.fx ~= nil then
        inst.fx:Remove()
    end
    inst.fx = SpawnPrefab("ancientelectric_fx")
    inst.fx:AttachToOwner(inst._owner)
    inst:AddTag("miasmaimmune")
end

local function OnDisabledSetBonus(inst)
	inst.components.equippable.walkspeedmult = 1
    inst.components.damagetyperesist:RemoveResist("shadow_aligned", inst, "setbonus")
   
    inst:RemoveTag("playercharge")
    if inst.fx ~= nil then
        inst.fx:Remove()
        inst.fx = nil
    end
    inst:RemoveTag("miasmaimmune")
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_hat", "hat_crowndamager", "swap_hat")

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
        --owner.components.planardamage:AddBonus(inst, 20, "ancienthat_buff")
        --owner.components.combat.externaldamagemultipliers:SetModifier(inst, 1.5)
        owner:AddTag("notdevourable")
    end
    inst._owner = owner
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

        owner:RemoveTag("notdevourable")
        --owner.components.planardamage:RemoveBonus(inst,  "ancienthat_buff")
    end
    --owner.components.combat.externaldamagemultipliers:RemoveModifier(inst)
    if inst.fx ~= nil then
        inst.fx:Remove()
        inst.fx = nil
    end
    inst._owner = nil
end


local function fn()
	local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("crowndamagerhat")
    inst.AnimState:SetBuild("hat_crowndamager")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")
    inst:AddTag("metal")
    inst:AddTag("ancient")
    inst:AddTag("nosteal")
    --inst:AddTag("moonstormgoggles")
    --inst:AddTag("goggles") 
    

    local swap_data = { bank = "crowndamagerhat", anim = "anim" }
    MakeInventoryFloatable(inst)
    inst.components.floater:SetBankSwapOnFloat(false, nil, swap_data) --Hats default animation is not "idle", so even though we don't swap banks, we need to specify the swap_data for re-skinning to reset properly when floating
    inst.components.floater:SetSize("med")
    inst.components.floater:SetScale(0.65)


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end


    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "lavaarena_crowndamagerhat"

    inst:AddComponent("armor")
    inst.components.armor:InitCondition(2200, 0.9)


    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(0.5)

    inst:AddComponent("planardefense")
	inst.components.planardefense:SetBaseDefense(10)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.restrictedtag = "player"

    inst:AddComponent("damagetyperesist")
	inst.components.damagetyperesist:AddResist("shadow_aligned", inst, TUNING.ARMOR_VOIDCLOTH_SHADOW_RESIST)

    local setbonus = inst:AddComponent("setbonus")
    setbonus:SetSetName(EQUIPMENTSETNAMES.ANCIENT)
    setbonus:SetOnEnabledFn(OnEnabledSetBonus)
	setbonus:SetOnDisabledFn(OnDisabledSetBonus)

    --inst:AddComponent("true_defence")
    inst:AddComponent("forgerepairable")
	inst.components.forgerepairable:SetRepairMaterial(FORGEMATERIALS.IRON)


    --[[inst:AddComponent("aoeweapon_lunge")
    inst.components.aoeweapon_lunge:SetDamage(68)
    inst.components.aoeweapon_lunge:SetSideRange(2)
    inst.components.aoeweapon_lunge:SetWorkActions()
    inst.components.aoeweapon_lunge:SetTags("_combat")]]

    MakeHauntableLaunch(inst)

    inst._owner = nil
    
    return inst

end

----------------------------------------------------------------
local fxassets=
{
    Asset("ANIM", "anim/elec_charged_fx.zip"),
}


local function CreateFxFollowFrame(i)
    local inst = CreateEntity()

    --[[Non-networked entity]]
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddSoundEmitter()

    inst:AddTag("FX")

    inst.AnimState:SetBank("elec_charged_fx")
    inst.AnimState:SetBuild("elec_charged_fx")
    inst.AnimState:PlayAnimation("discharged",true)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetMultColour(1,215/255,0,1)

    inst:AddComponent("highlightchild")

    inst.persists = false

    return inst
end

local function fx_OnRemoveEntity(inst)
    inst.fx:Remove()
end


local function fx_SpawnFxForOwner(inst, owner)
    inst.owner = owner
    inst.wasmoving = false
    

    local fx = CreateFxFollowFrame()
    fx.entity:SetParent(owner.entity)
    fx.Follower:FollowSymbol(owner.GUID, "swap_body")
    fx.components.highlightchild:SetOwner(owner)
    inst.fx = fx
    inst.OnRemoveEntity = fx_OnRemoveEntity
end

local function fx_OnEntityReplicated(inst)
    local owner = inst.entity:GetParent()
    if owner ~= nil then
        fx_SpawnFxForOwner(inst, owner)
    end
end

local function fx_AttachToOwner(inst, owner)
    inst.entity:SetParent(owner.entity)
	if owner.components.colouradder ~= nil then
		owner.components.colouradder:AttachChild(inst)
	end
    --Dedicated server does not need to spawn the local fx
    if not TheNet:IsDedicated() then
        fx_SpawnFxForOwner(inst, owner)
    end
end

local function fxfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

	inst:AddComponent("colouraddersync")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = fx_OnEntityReplicated

        return inst
    end

    inst.AttachToOwner = fx_AttachToOwner
    inst.persists = false

    return inst
end

return Prefab( "hat_ancient", fn,assets),
    Prefab("ancientelectric_fx",fxfn,fxassets)
