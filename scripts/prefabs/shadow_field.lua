local assets =
{
    Asset("ANIM", "anim/stalker_shield.zip"),
}

local function SpawnShield(s)
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false


    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()

    inst.AnimState:SetBank("stalker_shield")
    inst.AnimState:SetBuild("stalker_shield")
    inst.AnimState:PlayAnimation("idle1",true)
    inst.AnimState:SetFinalOffset(2)
    inst.AnimState:SetScale(2.36*s,2.36*s,2.36*s)

    return inst
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    --inst:AddTag("FX")

    if not TheNet:IsDedicated() then
        local shield = SpawnShield(2)
        shield.entity:SetParent(inst.entity)
        shield.Transform:SetPosition(0,-8,0)

    end


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/shield")

    inst.persists = false


    return inst
end

return Prefab("shadow_field", fn, assets)