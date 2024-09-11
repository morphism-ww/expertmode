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

local function CreateTerraformBlocker(parent)
    local inst = CreateEntity()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()

    inst:SetTerraformExtraSpacing(16)

    inst.entity:SetParent(parent.entity)
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
    
    --MakePondPhysics(inst, 0.4)

    CreateTerraformBlocker(inst)

    inst:AddTag("irreplaceable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end


    -----------------------
    inst:AddComponent("burnable")
    inst.components.burnable:SetFXLevel(3)
    inst.components.burnable:AddBurnFX("nightlight_flame", Vector3(0,0,0), "fire_marker")
    inst.components.burnable.canlight = false


    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(12,26)
    inst.components.playerprox:SetOnPlayerNear(onnear)
    inst.components.playerprox:SetOnPlayerFar(extinguish)
    
    inst:AddComponent("inspectable")

    return inst
end



return Prefab( "void_light", fn, assets, prefabs)
