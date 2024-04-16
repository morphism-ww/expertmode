local assets =
{
    Asset("ANIM", "anim/glasscutter.zip"),
    Asset("ANIM", "anim/swap_glasscutter.zip"),
}

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_glasscutter", "swap_glasscutter")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end


local function onattack(inst,owner,target)
    if target~=nil and target.components.health~=nil and not target.components.health:IsDead() then
        target.components.health:DoDelta(-10,owner.prefab,nil,true,owner,true)
        target.components.health:DeltaPenalty(0.05)
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("glasscutter")
    inst.AnimState:SetBuild("glasscutter")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")
    inst:AddTag("pointy")
    inst:AddTag("nosteal")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(100)
    inst.components.weapon:SetRange(20, 20)
	inst.components.weapon:SetOnAttack(onattack)

    inst:AddComponent("aoeweapon_leap")
    inst.components.aoeweapon_leap:SetDamage(100)
    inst.components.aoeweapon_leap:SetWorkActions()
    inst.components.aoeweapon_leap.tags = {"_combat"}

    local planardamage = inst:AddComponent("planardamage")
	planardamage:SetBaseDamage(15)

    --inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnDroppedFn(inst.Remove)

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    
    return inst
end

return Prefab("god_judge", fn, assets)