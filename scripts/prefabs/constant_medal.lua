local assets =
{
    Asset("ANIM", "anim/quagmire_coins.zip"),
}


local function RemoveMedal(inst,owner)
    if owner.components.newcs_talisman ~= nil then
        owner.components.newcs_talisman:RemoveSource(inst)
    end
end

local function try_give_protect(inst,owner)
    inst.owner = owner
    if owner.components.newcs_talisman ~= nil then
        owner.components.newcs_talisman:AddSource(inst)
    end
end


local function on_drop(inst)
    if inst.owner~=nil then
        RemoveMedal(inst,inst.owner)
    end
    inst.owner = nil
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("quagmire_coins")
    inst.AnimState:SetBuild("quagmire_coins")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:OverrideSymbol("coin01", "quagmire_coins", "coin03")
    inst.AnimState:OverrideSymbol("coin_shad1", "quagmire_coins", "coin_shad3")

    MakeInventoryFloatable(inst)

    inst:AddTag("mythical")
    inst:AddTag("nosteal")

    inst.itemtile_colour = RGB(218,165,32)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "quagmire_coin3"
    inst.components.inventoryitem.canonlygoinpocket = true
    inst.components.inventoryitem:SetOnPutInInventoryFn(try_give_protect)
    inst.components.inventoryitem:SetOnDroppedFn(on_drop)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetMaxUses(20)
    inst.components.finiteuses:SetUses(20)

    inst.OnRemoveEntity = on_drop

    return inst
end


return Prefab("constant_medal", fn, assets)