local assets =
{
    Asset("ANIM", "anim/mortis.zip"),
}


local function fn()

    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()	
    
    MakeCharacterPhysics(inst, 10, 1.5)
    RemovePhysicsColliders(inst)
    
    

    inst.AnimState:SetBank("mortis")
    inst.AnimState:SetBuild("mortis")
    inst.AnimState:PlayAnimation("idleloop")


	inst:AddTag("hostile")
	inst:AddTag("shadow_aligned")
    inst:AddTag("abysscreature")
    inst:AddTag("epic")
    inst:AddTag("shadowthrall")
    inst:AddTag("laser_immune")
    

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("timer")
    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = true }
    inst.sounds = sounds
    inst.sanityreward = TUNING.SANITY_LARGE

    inst:AddComponent("sanityaura")
	inst.components.sanityaura.aura = -TUNING.SANITYAURA_LARGE

    inst:AddComponent("lootdropper")

    inst:AddComponent("health")

    inst:AddComponent("combat")
    inst.components.combat:SetRange(4.5,5)
    

    
    return inst
end

return Prefab("mortis",fn,assets)