local assets =
{
	Asset("ANIM", "anim/hat_orichal.zip"),
}

local prefabs = {
    "orichalhat_fx"
}

local util = require"util.newcs_hat_util"

local function OnEnabledSetBonus(inst)
    inst.components.equippable.insulated = true
	
    inst.components.damagetyperesist:AddResist("shadow_aligned", inst, TUNING.ARMOR_VOIDCLOTH_SETBONUS_SHADOW_RESIST, "setbonus")
    inst:AddTag("playercharge")

    if inst.electricfx == nil then
        inst.electricfx = SpawnPrefab("ancientelectric_fx")
    end

    inst.electricfx.entity:SetParent(inst._owner.entity)
end

local function OnDisabledSetBonus(inst)
    inst.components.equippable.insulated = false
	
    inst.components.damagetyperesist:RemoveResist("shadow_aligned", inst, "setbonus")
   
    inst:RemoveTag("playercharge")
    if inst.electricfx ~= nil then
        inst.electricfx:Remove()
        inst.electricfx = nil
    end
end


local function onequip(inst, owner)
    util.fullhelm_onequip(inst, owner)

    if inst.fx ~= nil then
        inst.fx:Remove()
    end
    inst.fx = SpawnPrefab("orichalhat_fx")
    inst.fx:AttachToOwner(owner)
    owner.AnimState:SetSymbolLightOverride("swap_hat", .1)

    if owner.components.grue ~= nil then
        owner.components.grue:AddImmunity("orichalhat")
    end

    owner:AddTag("notdevourable")
    
    inst._owner = owner
end

local function onunequip(inst, owner)
    util.fullhelm_onunequip(inst, owner)

    if inst.fx ~= nil then
        inst.fx:Remove()
        inst.fx = nil
    end
    owner.AnimState:SetSymbolLightOverride("swap_hat", 0)

    if owner.components.grue ~= nil then
        owner.components.grue:RemoveImmunity("orichalhat")
    end

    owner:RemoveTag("notdevourable")
end

local function SetupEquippable(inst)
	inst:AddComponent("equippable")
	inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

end

local SWAP_DATA_BROKEN = { bank = "hat_orichal", anim = "broken" }
local SWAP_DATA = { bank = "hat_orichal", anim = "anim" }

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
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("hat_orichal")
    inst.AnimState:SetBuild("hat_orichal")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")
    inst:AddTag("metal")
    inst:AddTag("mythical")
    inst:AddTag("goggles")
    inst:AddTag("show_broken_ui")

    inst.fname = "hat_orichal"

    inst.itemtile_colour = RGB(218,165,32)
    

    local swap_data = { bank = "hat_orichal", anim = "anim" }
    MakeInventoryFloatable(inst)
    inst.components.floater:SetBankSwapOnFloat(false, nil, swap_data) --Hats default animation is not "idle", so even though we don't swap banks, we need to specify the swap_data for re-skinning to reset properly when floating
    inst.components.floater:SetSize("med")
    inst.components.floater:SetScale(0.65)


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("tradable")

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    --------------------------------------------------------------------------------------------------
    inst:AddComponent("armor")
    inst.components.armor:InitCondition(2200, 0.9)

    inst:AddComponent("planardefense")
	inst.components.planardefense:SetBaseDefense(10)

    inst:AddComponent("damagetyperesist")
	inst.components.damagetyperesist:AddResist("shadow_aligned", inst, 0.9)

    -----------------------------------------------------------------------------------------------
    SetupEquippable(inst)

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(0.5)

    MakeForgeRepairable2(inst,OnBroken,OnRepaired)

    local setbonus = inst:AddComponent("setbonus")
    setbonus:SetSetName(EQUIPMENTSETNAMES.ORICHAL)
    setbonus:SetOnEnabledFn(OnEnabledSetBonus)
	setbonus:SetOnDisabledFn(OnDisabledSetBonus)


    MakeHauntableLaunch(inst)

    return inst

end

local function CreateFxFollowFrame(i)
	local inst = CreateEntity()

	--[[Non-networked entity]]
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddFollower()

	inst:AddTag("FX")

	inst.AnimState:SetBank("hat_orichal")
	inst.AnimState:SetBuild("hat_orichal")
	inst.AnimState:PlayAnimation("idle"..tostring(i), true)
	inst.AnimState:SetSymbolBloom("guang")
	inst.AnimState:SetSymbolLightOverride("guang", .6)
	inst.AnimState:SetLightOverride(.1)

	inst:AddComponent("highlightchild")

	inst.persists = false

	return inst
end

local function fx_OnUpdate(inst)
    local moving = inst.owner:HasTag("moving")
    if moving ~= inst.wasmoving then
        inst.wasmoving = moving
        if moving then
            for i, v in ipairs(inst.fx) do
                v.AnimState:PlayAnimation("settle"..tostring(i), true)
            end
        else
            for i, v in ipairs(inst.fx) do
                v.AnimState:PushAnimation("idle"..tostring(i), false)
            end
        end
    end
end

local function OnFollowFn(inst,owner)
    inst.owner = owner
    inst.wasmoving = false
    if owner:HasTag("locomotor") then
        inst:AddComponent("updatelooper")
        inst.components.updatelooper:AddOnUpdateFn(fx_OnUpdate)
    end
end


local function ElecFX()
    local inst = CreateEntity()

    --[[Non-networked entity]]
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    
    inst.AnimState:SetBank("elec_charged_fx")
    inst.AnimState:SetBuild("elec_charged_fx")
    inst.AnimState:PlayAnimation("discharged",true)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetMultColour(1,215/255,0,1)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end




return Prefab("orichalhat",fn,assets,prefabs),
    util.MakeFollowFx("orichalhat_fx",{
        createfn = CreateFxFollowFrame,
        framebegin = 1,
        frameend = 3,
        isfullhelm = true,
        OnFollowFx = OnFollowFn,
        assets = { Asset("ANIM", "anim/hat_orichal.zip") },
    }),
    Prefab("ancientelectric_fx",ElecFX)