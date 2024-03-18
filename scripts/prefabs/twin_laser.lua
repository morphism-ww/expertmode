local assets =
{
    Asset("ANIM", "anim/metal_hulk_projectile.zip"),
    Asset("SOUND", "sound/chess.fsb"),
}

local function OnHit(inst, owner, target)
    if owner and target and target.components.combat~=nil then
        target.components.combat:GetAttacked(owner,50)
    end
    inst:Remove()
end


local function OnAnimOver(inst)
    inst:DoTaskInTime(2, inst.Remove)
end

local function OnThrown(inst)
    inst:ListenForEvent("animover", OnAnimOver)
end




local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("metal_hulk_projectile")
    inst.AnimState:SetBuild("metal_hulk_projectile")
    inst.AnimState:PlayAnimation("spin_loop", true)

    --projectile (from projectile component) added to pristine state for optimization
    inst:AddTag("projectile")
    inst.Transform:SetScale(0.7,0.7,0.7)
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(36)
    inst.components.projectile:SetHoming(false)
    inst.components.projectile:SetHitDist(2)
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:SetOnMissFn(inst.Remove)
    inst.components.projectile:SetOnThrownFn(OnThrown)

    inst:AddComponent("weapon")


    return inst
end
return Prefab("twin_laser", fn,assets)