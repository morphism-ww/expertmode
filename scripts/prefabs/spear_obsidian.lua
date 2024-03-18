local assets = {
    Asset("ANIM", "anim/spear_obsidian.zip"),
    Asset("ANIM", "anim/swap_spear_obsidian.zip"),
}

local function UpdateDamage(inst)
    if inst.components.weapon and inst.components.obsidiantool then
        local dmg = 51 * inst.components.obsidiantool:GetPercent()+51
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
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
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

    MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst, "med", 0.05, {1.1, 0.5, 1.1}, true, -9)


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(51)
    inst.components.weapon:SetOnAttack(onattack)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(375)
    inst.components.finiteuses:SetUses(375)

    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/volcanoinventory.xml"
	--inst.caminho = "images/inventoryimages/volcanoinventory.xml"

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(0)

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