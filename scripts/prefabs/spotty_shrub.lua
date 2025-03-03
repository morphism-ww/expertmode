local assets =
{
    Asset("ANIM", "anim/quagmire_spiceshrub.zip"),
    Asset("ANIM", "anim/quagmire_spotspice_sprig.zip"),
   -- Asset("ANIM", "anim/quagmire_spotspice_ground.zip"),
}

local prefabs = {
    "spotty_sprig"
}

local function onpickedfn(inst, picker)
	inst.AnimState:PlayAnimation("picked")
    if inst:HasTag("needswaxspray") and picker.components.sanity~=nil then
        picker.components.sanity:GetSoulAttacked(inst, 30)
        picker.components.combat:GetAttacked(inst,50)
    end
end

local function onregenfn(inst)
	inst.AnimState:PlayAnimation("grow")
	inst.AnimState:PushAnimation("idle", true)
    inst.components.waxable:SetNeedsSpray(true)
end

local function makeemptyfn(inst)
	inst.AnimState:PlayAnimation("picked")
    inst.components.waxable:SetNeedsSpray(false)
end

local function OnWaxed(inst)
    inst.components.waxable:SetNeedsSpray(false)
    return true
end

local function shrub_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    

    inst.AnimState:SetBuild("quagmire_spiceshrub")
    inst.AnimState:SetBank("quagmire_spiceshrub")
    inst.AnimState:PlayAnimation("idle", true)

    MakeObstaclePhysics(inst, .3)
    
    inst:AddTag("plant")
    inst:AddTag("renewable")
    inst:AddTag("trapdamage")


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    

    inst:AddComponent("pickable")
    inst.components.pickable.picksound = "dontstarve/wilson/pickup_reeds"
    inst.components.pickable:SetUp("spotty_sprig", TUNING.ABYSS_GROWTH_FREQUENCY)
    inst.components.pickable.onregenfn = onregenfn
    inst.components.pickable.onpickedfn = onpickedfn
    inst.components.pickable.makeemptyfn = makeemptyfn

    inst:AddComponent("lootdropper")

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_LARGE

    local waxable = inst:AddComponent("waxable")
    waxable:SetWaxfn(OnWaxed)
    waxable:SetNeedsSpray(true)

    return inst
end

local function oneaten(inst,eater)
	
	eater:AddDebuff("buff_crazy", "buff_crazy")
	
end

local function sprig_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("quagmire_spotspice_sprig")
    inst.AnimState:SetBuild("quagmire_spotspice_sprig")
    inst.AnimState:PlayAnimation("idle")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem.imagename = "quagmire_spotspice_sprig"

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("edible")
    --inst.components.edible.foodtype = FOODTYPE.MONSTER
    inst.components.edible.healthvalue = 15
    inst.components.edible.hungervalue = 5
    inst.components.edible.sanityvalue = -40
    inst.components.edible:SetOnEatenFn(oneaten)

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_FAST)
    inst.components.perishable:StartPerishing()
    inst.components.perishable.onperishreplacement = "spoiled_food"

    MakeHauntableLaunch(inst)
    

    return inst
end

return Prefab("spotty_shrub", shrub_fn, assets, prefabs),
    Prefab("spotty_sprig", sprig_fn, assets)