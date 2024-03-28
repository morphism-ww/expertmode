local assets=
{
	Asset("ANIM", "anim/axe_obsidian.zip"),
	Asset("ANIM", "anim/swap_axe_obsidian.zip"),	
}

local function UpdateDamage(inst)
    if inst.components.weapon and inst.components.obsidiantool then
        local dmg = 27 * inst.components.obsidiantool:GetPercent()+27
        inst.components.weapon:SetDamage(dmg)
    end
end
local function OnLoad(inst, data)
    UpdateDamage(inst)
end
local function PercentChanged(inst)
    local owner = inst.components.inventoryitem ~= nil and inst.components.inventoryitem.owner or nil
    if owner ~= nil and owner.sg and owner.sg:HasStateTag("prechop") then
        inst.components.obsidiantool:Use(owner, owner.bufferedaction.target)
    end
end	

local function onequipobsidian(inst, owner)
    UpdateDamage(inst)
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
	owner.AnimState:OverrideSymbol("swap_object", "swap_axe_obsidian", "swap_axe")	
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
 

local function obsidianfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

	inst.AnimState:SetBuild("axe_obsidian")
	inst.AnimState:SetBank("axe_obsidian")
	inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")
    inst:AddTag("axe")
    MakeInventoryFloatable(inst, "small", 0.05, {1.2, 0.75, 1.2})

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(27)
    inst.components.weapon:SetOnAttack(onattack)
	inst.components.weapon.attackwear = 1

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(250)
    inst.components.finiteuses:SetUses(250)
	inst.components.finiteuses:SetConsumption(ACTIONS.CHOP, 1)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("inspectable")
	
    inst:AddComponent("inventoryitem")

	
    inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequipobsidian)
	inst.components.equippable:SetOnUnequip(onunequipobsidian)

    inst:AddComponent("tool")	
	inst.components.tool:SetAction(ACTIONS.CHOP, 3)
		
    MakeObsidianTool(inst, "axe")
	

	inst:ListenForEvent("percentusedchange", PercentChanged)
	inst.OnLoad=OnLoad
    MakeHauntableLaunch(inst)

	return inst
end

return Prefab( "axeobsidian", obsidianfn, assets)