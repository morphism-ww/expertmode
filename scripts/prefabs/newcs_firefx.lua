local assets = {
    Asset("ANIM", "anim/campfire_fire.zip"),
}

local heats = {70, 85, 100, 115}

local function GetHeatFn(inst)
    return heats[inst.components.firefx.level] or 20
end

local firelevels =
{
    {anim="level1", sound="dontstarve/common/campfire", radius=4, intensity=.8, falloff=.33, colour = {255/255,255/255,192/255}, soundintensity=.1},
    {anim="level2", sound="dontstarve/common/campfire", radius=8, intensity=.8, falloff=.33, colour = {255/255,255/255,192/255}, soundintensity=.3},
    {anim="level3", sound="dontstarve/common/campfire", radius=12, intensity=.8, falloff=.33, colour = {255/255,255/255,192/255}, soundintensity=.6},
    {anim="level4", sound="dontstarve/common/campfire", radius=14, intensity=.8, falloff=.33, colour = {255/255,255/255,192/255}, soundintensity=1},
}

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("campfire_fire")
    inst.AnimState:SetBuild("campfire_fire")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetFinalOffset(-1)

    inst:AddTag("FX")

    --HASHEATER (from heater component) added to pristine state for optimization
    inst:AddTag("HASHEATER")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("heater")
    inst.components.heater.heatfn = GetHeatFn

    inst:AddComponent("firefx")
    inst.components.firefx.levels = firelevels
    inst.components.firefx:SetLevel(1)
    inst.components.firefx.usedayparamforsound = true
    
    return inst
end


local function fireballfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()


    inst.AnimState:SetBank("fireball_fx")
    inst.AnimState:SetBuild("deer_fire_charge")
    inst.AnimState:PlayAnimation("blast")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetLightOverride(1)
    inst.AnimState:SetFinalOffset(-1)

    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    --inst:AddComponent("scaler")

    inst:ListenForEvent("animover", inst.Remove)

    return inst
end


local function colour_fire_fx()
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddFollower()

    inst.AnimState:SetBank("fire_large_character")
    inst.AnimState:SetBuild("fire_large_character")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetRayTestOnBB(true)
    inst.AnimState:SetFinalOffset(FINALOFFSET_MAX)

    inst.AnimState:PlayAnimation("pre_med")
    inst.AnimState:PushAnimation("loop_med",true)

    --inst.entity:AddLight()
    --inst.Light:SetIntensity(0.75)
    --inst.Light:SetRadius(2)
    --inst.Light:SetFalloff(0.5)

    inst.set_color = function (r,g,b)
        inst.Light:SetColour(r,g,b)

        inst.AnimState:SetMultColour(r,g,b,1)
    end

    inst.push_controlled = function ()
        inst.AnimState:PlayAnimation("pre_med_controlled_burn")
        inst.AnimState:PushAnimation("loop_med_controlled_burn",true)
    end

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false


    return inst
end

local lunar_firelevels =
{
    {anim="level1", sound="dontstarve/common/nightlight", radius=4, intensity=.8, falloff=.33, colour = {130/255, 160/255, 170/255}, soundintensity=.1},
    {anim="level2", sound="dontstarve/common/nightlight", radius=6, intensity=.8, falloff=.33, colour = {130/255, 160/255, 170/255}, soundintensity=.3},
    {anim="level3", sound="dontstarve/common/nightlight", radius=8, intensity=.8, falloff=.33, colour = {130/255, 160/255, 170/255}, soundintensity=.6},
    {anim="level4", sound="dontstarve/common/nightlight", radius=11, intensity=.8, falloff=.4, colour = {130/255, 160/255, 170/255}, soundintensity=1},
}

local function lunar_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("campfire_fire")
    inst.AnimState:SetBuild("campfire_fire")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetMultColour(30/255,144/255, 1, .6)
    inst.AnimState:SetRayTestOnBB(true)
    inst.AnimState:SetFinalOffset(3)

    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("firefx")
    inst.components.firefx.levels = lunar_firelevels

    return inst
end

return Prefab("obsidianfirefire", fn, assets),
    Prefab("cs_fireball_hit_fx",fireballfn),
    Prefab("newcs_firefx",colour_fire_fx),
    Prefab("lunarlight_flame", lunar_fn, assets)
