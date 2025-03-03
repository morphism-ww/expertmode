local assets =
{
    Asset("ANIM", "anim/aurumite_kit.zip"),
    Asset("ANIM","anim/ui_auric_2x2.zip"),
}


local function onrepair(inst,target,doer,material)
    inst.components.container:RemoveItem(material,false):Remove()
    inst.components.finiteuses:Use(1)
    doer:PushEvent("repair")
    --local current_charge =inst.components.rechargeable:GetCharge()-20
    --inst.components.rechargeable:SetCharge(current_charge)
end



local function ondischarged(inst)
    inst.components.finiteuses:Use(5)
end 

local function OnChargeChange(inst,data)
    if data.percent<0.2 then
        inst.AnimState:SetSymbolLightOverride("glow",0)
        inst.components.aurumiterepair:Enable(false)
    elseif not inst.components.aurumiterepair.enable then
        inst.components.aurumiterepair:Enable(true)
        inst.AnimState:SetSymbolLightOverride("glow",0.2)
    end
end

local function test_for_greengem(inst,gem)
    if gem.prefab=="greengem" then
        return true
    else
        return false, "WRONG_GEM_COLOUR"
    end    
end

local function ItemTradeTest(inst, item)
    if item == nil then
        return false
    elseif string.sub(item.prefab, -3) ~= "gem" then
        return false, "NOTGEM"
    elseif item.prefab~="greengem" then
        return false, "WRONGGEM"
    end
    return true
end

local function OnGemGiven(inst, giver, item)
    inst.components.finiteuses:SetUses(50)

    if inst:HasTag("broken") then
        inst.AnimState:ShowSymbol("gem")
        inst.components.aurumiterepair:Enable(true)
        inst.SoundEmitter:PlaySound("dontstarve/common/telebase_gemplace")
        
        inst.components.inventoryitem:ChangeImageName("aurumite_kit")
        inst:RemoveTag("broken")
        inst.components.inspectable.nameoverride = nil
    end
    
end


local function OnFinished(inst)
    inst.AnimState:HideSymbol("gem")
    inst.components.aurumiterepair:Enable(false)
    
    inst.components.inventoryitem:ChangeImageName("aurumite_kit_broken")
    inst:AddTag("broken")
	inst.components.inspectable.nameoverride = "BROKEN_FORGEDITEM"
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeInventoryPhysics(inst)

    inst:AddTag("mythical")
    inst:AddTag("portablestorage")
    inst:AddTag("show_broken_ui")
    inst:AddTag("gemsocket")

    inst.AnimState:SetBank("aurumite_kit")
    inst.AnimState:SetBuild("aurumite_kit")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetSymbolBloom("glow")
    inst.AnimState:SetSymbolLightOverride("glow",0.2)

    MakeInventoryFloatable(inst, "small", 0.2, { 1.4, 1, 1 })

    inst.itemtile_colour = RGB(218,165,32)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("trader")
    inst.components.trader:SetAbleToAcceptTest(ItemTradeTest)
    inst.components.trader.onaccept = OnGemGiven

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(50)
    inst.components.finiteuses:SetUses(50)
    inst.components.finiteuses:SetOnFinished(OnFinished)

    --[[inst:AddComponent("rechargeable")
    inst.components.rechargeable.chargetime = 900
    inst.components.rechargeable:SetOnDischargedFn(ondischarged)
    inst:ListenForEvent("rechargechange",OnChargeChange)]]
    
    inst:AddComponent("container")
    inst.components.container:WidgetSetup("aurumite_kit")
    --inst.components.container.droponopen = true

    inst:AddComponent("aurumiterepair")
    inst.components.aurumiterepair:SetOnRepaired(onrepair)    

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("aurumite_kit", fn, assets)

