local assets =
{
	Asset("ANIM", "anim/winter_ornaments2021.zip"),
}


local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()


    MakeInventoryPhysics(inst, 0.1)

    inst.AnimState:SetBank("winter_ornaments2021")
    inst.AnimState:SetBuild("winter_ornaments2021")
    inst.AnimState:PlayAnimation("boss_celestialchampion3")
    
    MakeInventoryFloatable(inst)

    inst:AddTag("ancient")
    
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    
    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "winter_ornament_boss_celestialchampion3"
    

    return inst
end


return Prefab( "void_key", fn, assets)
