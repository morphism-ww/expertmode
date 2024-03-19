local assets =
{
    Asset("ANIM", "anim/wortox_soul_ball.zip"),
}

local function commonfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.AnimState:SetBank("wortox_soul_ball")
    inst.AnimState:SetBuild("wortox_soul_ball")
    inst.AnimState:PlayAnimation("idle_loop", true)
    --inst.AnimState:SetScale(SCALE, SCALE)

    inst:AddTag("nosteal")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("upgrader")


    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "wortox_soul"
    --inst.components.inventoryitem.atlasname = "images/inventoryimages/constant_soul.xml"

    inst:AddComponent("inspectable")

	inst:AddComponent("waterproofer")
	inst.components.waterproofer:SetEffectiveness(0)


    return inst
end

local function insightfn()
    local inst=commonfn()
    inst.AnimState:SetMultColour(0,1,0,0.2)
    inst.AnimState:SetAddColour(0,1,0,1)
    if not TheWorld.ismastersim then
        return inst
    end
    inst.components.upgrader.upgradetype = UPGRADETYPES.INSIGHT_SOUL
    return inst
end


local function ironfn()
    local inst=commonfn()
    inst.AnimState:SetMultColour(1,0,0,0.2)
    inst.AnimState:SetAddColour(1,165/255,0,0.5)
    if not TheWorld.ismastersim then
        return inst
    end
    inst.components.upgrader.upgradetype = UPGRADETYPES.IRON_SOUL
    return inst
end

return Prefab("insight_soul", insightfn, assets),
        Prefab("iron_soul", ironfn, assets)
