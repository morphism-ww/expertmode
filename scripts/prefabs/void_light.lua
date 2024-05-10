local assets =
{
	Asset("ANIM", "anim/maxwell_torch.zip"),
}

local prefabs =
{
    "nightlight_flame",
}


local function onnear(inst)
    if not inst.components.burnable:IsBurning() then 
        inst.components.burnable:Ignite() 
    end
end

local function extinguish(inst)
    if inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("maxwell_torch")
    inst.AnimState:SetBuild("maxwell_torch")
    inst.AnimState:PlayAnimation("idle")
    
    MakePondPhysics(inst, 0.2)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end


    -----------------------
    inst:AddComponent("burnable")
    inst.components.burnable:SetFXLevel(3)
    inst.components.burnable:AddBurnFX("campfirefire", Vector3(0,0,0), "fire_marker")
    inst.components.burnable.canlight = false


    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(10, 20 )
    inst.components.playerprox:SetOnPlayerNear(onnear)
    inst.components.playerprox:SetOnPlayerFar(extinguish)
    


    return inst
end



return Prefab( "void_light", fn, assets, prefabs)
