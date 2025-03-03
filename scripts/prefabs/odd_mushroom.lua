local assets =
{
    Asset("ANIM", "anim/odd_mushroom.zip"),
}

local function crazy(inst,eater)
    eater:AddDebuff("buff_halluc", "buff_halluc")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("odd_mushroom")
    inst.AnimState:SetBuild("odd_mushroom")
    inst.AnimState:PlayAnimation("idle")


    inst.pickupsound = "vegetation_firm"


    inst:AddTag("mushroom")

    MakeInventoryFloatable(inst, "small", 0.1, 0.88)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("tradable")
    inst:AddComponent("inspectable")

    MakeSmallBurnable(inst, TUNING.TINY_BURNTIME)
    MakeSmallPropagator(inst)

    inst:AddComponent("inventoryitem")

    --this is where it gets interesting
    inst:AddComponent("edible")
    inst.components.edible.healthvalue = 8
    inst.components.edible.hungervalue = 8
    inst.components.edible.sanityvalue = -50
    inst.components.edible.foodtype = FOODTYPE.VEGGIE
    inst.components.edible:SetOnEatenFn(crazy)

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    MakeHauntableLaunchAndPerish(inst)

    return inst
end

return Prefab("odd_mushroom",fn,assets)