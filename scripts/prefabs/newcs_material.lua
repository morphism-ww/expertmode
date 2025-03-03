local function shine_fn(inst)
    --inst.AnimState:SetLightOverride(0.1)
    inst.entity:AddLight()
    inst.Light:SetRadius(0.3)
    inst.Light:SetIntensity(.9)
    inst.Light:SetFalloff(.9)
    inst.Light:SetColour(1,215/255,0)

    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh") 
    --inst.AnimState:SetBloomEffectHandle(resolvefilepath("shaders/adamantitepulse.ksh"))   
    inst.AnimState:SetDefaultEffectHandle(resolvefilepath("shaders/auric.ksh"))
end

local function MakeMaterial(name,build,commonfn)
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

        if commonfn~=nil then
            commonfn(inst)
        end
    
        inst.entity:SetPristine()
    
        if not TheWorld.ismastersim then
            return inst
        end
    
        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
    
        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")
    
        MakeHauntableLaunch(inst)
    
    
        return inst
    end
    return Prefab(name,fn,assets)
end

return MakeMaterial("newcs_obsidian","obsidian"),
    MakeMaterial("aurumite","aurumite",shine_fn),
    MakeMaterial("cs_infused_iron","infused_iron")
