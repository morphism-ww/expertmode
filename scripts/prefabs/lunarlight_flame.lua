local assets =
{
    --Asset("ANIM", "anim/fire_large_character.zip"),
    Asset("ANIM", "anim/campfire_fire.zip"),
    Asset("SOUND", "sound/common.fsb"),
}

local prefabs =
{
    "firefx_light",
}

local firelevels =
{
    {anim="level1", sound="dontstarve/common/nightlight", radius=4, intensity=.8, falloff=.33, colour = {130/255, 160/255, 170/255}, soundintensity=.1},
    {anim="level2", sound="dontstarve/common/nightlight", radius=6, intensity=.8, falloff=.33, colour = {130/255, 160/255, 170/255}, soundintensity=.3},
    {anim="level3", sound="dontstarve/common/nightlight", radius=8, intensity=.8, falloff=.33, colour = {130/255, 160/255, 170/255}, soundintensity=.6},
    {anim="level4", sound="dontstarve/common/nightlight", radius=11, intensity=.8, falloff=.4, colour = {130/255, 160/255, 170/255}, soundintensity=1},
}

local function fn()
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
    inst.components.firefx.levels = firelevels

    return inst
end

return Prefab("lunarlight_flame", fn, assets, prefabs)
