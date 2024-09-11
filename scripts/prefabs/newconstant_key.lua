local function MakeKey(name, build, anim, imagename,rare)
    local assets =
    {
        Asset("ANIM", "anim/"..build..".zip"),
    }
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)

        inst.AnimState:SetBank(build)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation(anim)

        MakeInventoryFloatable(inst)

        if rare then
            inst:AddTag("irreplaceable")
        end
        

        --klaussackkey (from klaussackkey component) added to pristine state for optimization
        inst:AddTag("klaussackkey")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inventoryitem")
        inst.components.inventoryitem.imagename = imagename

        inst:AddComponent("klaussackkey")
        inst.components.klaussackkey.keytype = name

        inst:AddComponent("inspectable")

        if not rare then
            inst:AddComponent("stackable")
            inst.components.stackable.maxsize = TUNING.STACK_SIZE_MEDITEM
        end
        

        return inst
    end

    return Prefab(name, fn, assets)
end


return MakeKey("planar_key","winter_ornaments2021","boss_celestialchampion3","winter_ornament_boss_celestialchampion3",true),
    MakeKey("void_key","winter_ornaments2021","boss_celestialchampion4","winter_ornament_boss_celestialchampion4",true),
    MakeKey("maze_key","quagmire_key","safe_key","quagmire_key")
