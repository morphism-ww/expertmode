local assets = {
    Asset("ANIM", "anim/spear_obsidian.zip"),
    Asset("ANIM", "anim/swap_spear_obsidian.zip"),
}

local function UpdateDamage(inst)
    if inst.components.weapon and inst.components.obsidiantool then
        local dmg = TUNING.OBSIDIAN_SPEAR_DAMAGE * (inst.components.obsidiantool:GetPercent() + 1)
        inst.components.weapon:SetDamage(dmg)
    end
end

local function OnLoad(inst, data)
    UpdateDamage(inst)
end

local function onequipobsidian(inst, owner)
    --owner:AddTag("controlled_burner")
    UpdateDamage(inst)
    owner.AnimState:OverrideSymbol("swap_object", "swap_spear_obsidian", "swap_spear")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
end

local function onunequipobsidian(inst, owner)
    UpdateDamage(inst)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
 end

local function onattack(inst,attacker,target)
    inst.components.obsidiantool:Use(attacker,target)
    UpdateDamage(inst)
end


local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

	inst.AnimState:SetBuild("spear_obsidian")
	inst.AnimState:SetBank("spear_obsidian")
	inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")
    inst:AddTag("pointy")

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

	MakeInventoryFloatable(inst, "med", 0.05, {1.1, 0.5, 1.1}, true, -9)


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.OBSIDIAN_SPEAR_DAMAGE)
    inst.components.weapon:SetOnAttack(onattack)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.OBSIDIAN_SPEAR_USES)
    inst.components.finiteuses:SetUses(TUNING.OBSIDIAN_SPEAR_USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("repairable")
    inst.components.repairable.repairmaterial = "obsidian"
    inst.components.repairable:SetFiniteUsesRepairable(true)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequipobsidian)
    inst.components.equippable:SetOnUnequip(onunequipobsidian)

    MakeObsidianTool(inst, "spear")
	inst.components.obsidiantool.maxcharge = 20
    inst.components.obsidiantool.cooldowntime = TUNING.TOTAL_DAY_TIME / 20

    inst.OnLoad = OnLoad


    MakeHauntableLaunch(inst)

	return inst
end


return Prefab("spear_obsidian", fn, assets)