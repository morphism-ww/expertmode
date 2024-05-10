local assets = {
    Asset("ANIM", "anim/obsidian.zip"),
}

local function hitwater(inst)
    inst.SoundEmitter:PlaySound("ia/common/obsidian_wetsizzles")
end

local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)


    inst.AnimState:SetBank("obsidian")
    inst.AnimState:SetBuild("obsidian")
    inst.AnimState:PlayAnimation("idle")

    inst.pickupsound = "rock"

    -- waterproofer (from waterproofer component) added to pristine state for optimization
    inst:AddTag("waterproofer")

    MakeInventoryFloatable(inst, "med", .145, { .77, .75, .77 })

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    
    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(0)

    inst:AddComponent("repairer")
    inst.components.repairer.repairmaterial=MATERIALS.OBSIDIAN
    inst.components.repairer.finiteusesrepairvalue = 80


    inst:ListenForEvent("floater_startfloating", hitwater)

    MakeHauntableLaunch(inst)


    return inst
end

return Prefab("obsidian", fn, assets)
