local assets=
{
	Asset("ANIM", "anim/dragoon_heart.zip"),
}



local function item_commonfn(bank, build, masterfn)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("dragoon_heart")
    inst.AnimState:SetBuild("dragoon_heart")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    MakeInventoryPhysics(inst)

    inst.Light:SetFalloff(0.7)
    inst.Light:SetIntensity(.5)
    inst.Light:SetRadius(0.5)
    inst.Light:SetColour(169/255, 231/255, 245/255)
    inst.Light:Enable(true)

    inst:AddTag("lightbattery")
    inst:AddTag("vasedecoration")
	MakeInventoryFloatable(inst)	

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename = "dragoonheart"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/volcanoinventory.xml"	
	--inst.caminho = "images/inventoryimages/volcanoinventory.xml"
	
    inst:AddComponent("tradable")
    inst.components.tradable.goldvalue = 20

    inst:AddComponent("edible")

    inst:AddComponent("repairer")
    inst.components.repairer.repairmaterial="obsidian"
    inst.components.repairer.finiteusesrepairvalue = 50

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_MED)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    inst:AddComponent("fuel")
    inst.components.fuel.fueltype = FUELTYPE.WORMLIGHT

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_LARGEITEM

    if masterfn ~= nil then
        masterfn(inst)
    end

    return inst
end

local function movefast(inst,eater)
    eater:AddDebuff("fastbuff", "buff_fast")
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

local function itemfn()
    return item_commonfn(
        "dragoon_heart",
        "dragoon_heart",
        function(inst)
            inst.components.edible.foodtype = FOODTYPE.MEAT
            inst.components.edible.healthvalue = TUNING.HEALING_HUGE
            inst.components.edible.hungervalue = TUNING.CALORIES_MED
            inst.components.edible.sanityvalue = -TUNING.SANITY_SMALL
            inst.components.edible.temperaturedelta = TUNING.HOT_FOOD_BONUS_TEMP
            inst.components.edible.temperatureduration=TUNING.FOOD_TEMP_AVERAGE
            inst.components.edible:SetOnEatenFn(movefast)

            inst.components.fuel.fuelvalue = TUNING.LARGE_FUEL * 1.33
        end
    )
end

return  Prefab("dragoonheart", itemfn, assets)