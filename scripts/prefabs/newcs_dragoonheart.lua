local assets=
{
	Asset("ANIM", "anim/dragoon_heart.zip"),
}

local function movefast(inst,eater)
    eater:AddDebuff("buff_fast", "buff_fast")
    if eater.wormlight ~= nil then
        if eater.wormlight.prefab == "wormlight_light_greater" then
            eater.wormlight.components.spell.lifetime = 0
            eater.wormlight.components.spell:ResumeSpell()
            return
        else
            eater.wormlight.components.spell:OnFinish()
        end
    end
    local light = SpawnPrefab("wormlight_light_greater")
    light.components.spell:SetTarget(eater)
    if light:IsValid() then
        if light.components.spell.target == nil then
            light:Remove()
        else
            light.components.spell:StartSpell()
        end
    end
end

local function StartPumping(inst)

    inst.pumptask = inst:StartThread(function ()
        inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/dragoon/heart")
        Sleep(inst.AnimState:GetCurrentAnimationLength())
    end)
end

local function StopPumping(inst)
    if inst.pumptask then
        KillThread(inst.pumptask)
        inst.pumptask = nil
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("dragoon_heart")
    inst.AnimState:SetBuild("dragoon_heart")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    MakeInventoryPhysics(inst)

    local light = inst.entity:AddLight()
    light:SetFalloff(0.7)
    light:SetIntensity(.5)
    light:SetRadius(0.5)
    light:SetColour(232/255, 141/255, 67/255)
    light:Enable(true)

    MakeInventoryFloatable(inst, "idle_water", "idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:SetOnPickupFn(StopPumping)
    inst.components.inventoryitem:SetOnDroppedFn(StartPumping)

    inst:AddComponent("tradable")
    inst.components.tradable.goldvalue = 10

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.MEAT
    inst.components.edible.healthvalue = TUNING.HEALING_HUGE
    inst.components.edible.hungervalue = TUNING.CALORIES_MED
    inst.components.edible.sanityvalue = -TUNING.SANITY_SMALL
    inst.components.edible.temperaturedelta = TUNING.HOT_FOOD_BONUS_TEMP
    inst.components.edible.temperatureduration=TUNING.FOOD_TEMP_AVERAGE
    inst.components.edible:SetOnEatenFn(movefast)

    inst:AddComponent("fuel")
    inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL * 1.33
    inst.components.fuel.fueltype = FUELTYPE.WORMLIGHT


    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    MakeHauntableLaunch(inst)

    return inst
end



return  Prefab("newcs_dragoonheart",fn,assets)