local function OnRepaired(inst, target, doer)
	doer:PushEvent("repair")
end
local function MakeMaterial(name,build,repair_meterial)
    local assets = {
        Asset("ANIM", "anim/"..build..".zip"),
    }
    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
    
        MakeInventoryPhysics(inst)
    
        inst.AnimState:SetBank(build)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation("idle")
    
        inst.pickupsound = "rock"
    
        MakeInventoryFloatable(inst, "med", .145, { .77, .75, .77 })
    
        inst.entity:SetPristine()
    
        if not TheWorld.ismastersim then
            return inst
        end
    
        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
    
        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")
        
        --[[if repair_data then
            inst:AddComponent("repairer")
            inst.components.repairer.repairmaterial = MATERIALS.OBSIDIAN
            inst.components.repairer.finiteusesrepairvalue = 80
        end]]
        if repair_meterial then
            inst:AddComponent("forgerepair")
            inst.components.forgerepair:SetRepairMaterial(repair_meterial)
            inst.components.forgerepair:SetOnRepaired(OnRepaired)
        end
        

    
        MakeHauntableLaunch(inst)
    
    
        return inst
    end
    return Prefab(name,fn,assets)
end

return MakeMaterial("obsidian","obsidian"),
    MakeMaterial("cs_iron","iron_ore","iron"),
    MakeMaterial("cs_infused_iron","infused_iron")
