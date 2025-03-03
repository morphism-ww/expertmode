local assets =
{
    Asset("ANIM", "anim/laser_ring_fx.zip"),
    Asset("ANIM", "anim/laser_explosion.zip"),	
}

local function Scorch_OnFadeDirty(inst)
    --V2C: hack alert: using SetHightlightColour to achieve something like OverrideAddColour
    --     (that function does not exist), because we know this FX can never be highlighted!
    local alpha = inst._fade:value()/90
    inst.AnimState:OverrideMultColour(1, 1, 1, alpha)
end

local function Scorch_OnUpdateFade(inst)
    if inst._fade:value() > 1 then
        inst._fade:set_local(inst._fade:value() - 1)
        Scorch_OnFadeDirty(inst)
    elseif TheWorld.ismastersim then
        inst:Remove()
    elseif inst._fade:value() > 0 then
        inst._fade:set_local(0)
        inst.AnimState:OverrideMultColour(1, 1, 1, 0)
    end
end


local function scorchfn()
    local inst = CreateEntity()
	
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
	
    inst.AnimState:SetBuild("laser_ring_fx")
    inst.AnimState:SetBank("laser_ring_fx")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)

    
    inst:AddTag("NOCLICK")
    inst:AddTag("FX")
    inst:AddTag("laser")

    inst.Transform:SetScale(0.85,0.85,0.85)

    inst._fade = net_byte(inst.GUID, "newcs_laser_ring._fade", "fadedirty")
    inst._fade:set(90)

    inst:DoTaskInTime(0.7,function()
        inst:DoPeriodicTask(0, Scorch_OnUpdateFade)
    end)  
    Scorch_OnFadeDirty(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("fadedirty", Scorch_OnFadeDirty)
        return inst
    end	 

    inst.persists = false

    inst.Transform:SetRotation(math.random() * 360)

    return inst
end

local function explosionfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("laser_explosion")
    inst.AnimState:SetBank("laser_explosion")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("FX")
    inst:AddTag("laser")

    inst.Transform:SetScale(0.85,0.85,0.85)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:ListenForEvent("animover", inst.Remove)
    inst.OnEntitySleep = inst.Remove

    return inst
end

--[[local function metal_hulk_ring_fx()
    local inst = CreateEntity()

	inst.entity:AddNetwork()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBuild("metal_hulk_ring_fx")
    inst.AnimState:SetBank("metal_hulk_ring_fx")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("FX")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:ListenForEvent("animover", inst.Remove)
    inst.OnEntitySleep = inst.Remove

    return inst
end]]

return Prefab("newcs_laser_ring", scorchfn, assets),
       Prefab("newcs_laser_explosion", explosionfn, assets)
       --Prefab("metal_hulk_ring_fx", metal_hulk_ring_fx, assets)