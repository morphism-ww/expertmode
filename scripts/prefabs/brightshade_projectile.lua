local assets =
{
    Asset("ANIM", "anim/brightmare_gestalt_evolved.zip"),
}



local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddLight()


    local phys = inst.entity:AddPhysics()
    phys:SetMass(1)
    phys:SetFriction(0)
    phys:SetDamping(5)
    phys:SetCollisionGroup(COLLISION.FLYERS)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.GROUND)
    phys:SetCapsule(0.5, 1)

	inst:AddTag("brightmare")
    inst.Light:SetFalloff(0.6)
    inst.Light:SetIntensity(.6)
    inst.Light:SetRadius(0.4)
    inst.Light:SetColour(237/255, 237/255, 209/255)
    inst.Light:Enable(true)

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBuild("brightmare_gestalt_evolved")
    inst.AnimState:SetBank("brightmare_gestalt_evolved")
    inst.AnimState:PlayAnimation("idle", true)

    inst.AnimState:SetLightOverride(0.2)


    --projectile (from projectile component) added to pristine state for optimization.

    inst:AddTag("NOCLICK")
    inst:AddTag("NOBLOCK")
    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end


    inst:DoTaskInTime(0.6,inst.Remove)



    return inst
end

return Prefab("brightshade_projectile",fn,assets)