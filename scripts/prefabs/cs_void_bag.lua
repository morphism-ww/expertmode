local assets =
{
	Asset("ANIM", "anim/cs_void_bag.zip"),
}



local function OnOpen(inst)
	
    inst.SoundEmitter:PlaySound("maxwell_rework/magician_chest/open")
    inst.SoundEmitter:PlaySound("maxwell_rework/shadow_magic/storage_void_LP", "loop")
    inst.SoundEmitter:PlaySound("maxwell_rework/magician_chest/curtain_lp", "curtain_loop")
		--inst._showopenfx:set(true)

end

local function OnClose(inst)
	
    --inst.AnimState:PlayAnimation("close")
    --inst.AnimState:PushAnimation("closed", false)
    inst.SoundEmitter:PlaySound("maxwell_rework/magician_chest/close")
    --inst.SoundEmitter:KillSound("loop")
    --inst._showopenfx:set(false)
	inst.SoundEmitter:KillSound("loop")
	inst.SoundEmitter:KillSound("curtain_loop")

end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddMiniMapEntity()

    inst.MiniMapEntity:SetIcon("cs_void_bag.tex")

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.AnimState:SetBank("cs_void_bag")
    inst.AnimState:SetBuild("cs_void_bag")
    inst.AnimState:PlayAnimation("idle",true)
    
    inst:AddTag("shadow_item")
    inst:AddTag("mythical")
    inst:AddTag("portablestorage")
    --inst:AddTag("backpack")
    inst:AddTag("nosteal")
    inst:AddTag("meteor_protection")
    inst:AddTag("NORATCHECK")

    inst.itemtile_colour = DEFAULT_MYTHICAL_COLOUR

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.canonlygoinpocket = true
    --[[inst.components.inventoryitem:SetOnDroppedFn(OnDropped)
    inst.components.inventoryitem:SetOnPickupFn(OnPickUp)]]

    inst:AddComponent("container")
    inst.components.container:WidgetSetup("cs_void_bag")
    inst.components.container.onopenfn = OnOpen
    inst.components.container.onclosefn = OnClose
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true
    --inst.components.inventoryitem.cangoincontainer = false
    

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(1)

    MakeHauntableLaunchAndDropFirstItem(inst)


    return inst
end



return Prefab("cs_void_bag", fn, assets)
