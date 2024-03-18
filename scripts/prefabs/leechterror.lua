local assets =
{
    Asset("ANIM", "anim/shadow_oceanhorror.zip"),
}

local function retargetfn(inst)
    local target = inst.components.combat.target
    if target ~= nil then
        if target:HasTag("player") then
            return
        end
        target = nil
    end
    local x, y, z = inst.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x, y, z, TUNING.SHADOWCREATURE_TARGET_DIST, true)
    local rangesq = math.huge
    for i, v in ipairs(players) do
        local distsq = v:GetDistanceSqToPoint(x, y, z)
        if distsq < rangesq and inst.components.combat:CanTarget(v) then
            rangesq = distsq
            target = v
        end
    end
    return target, true
end

local function shouldKeepTarget(inst, target)
    return target ~= nil
        and target:IsValid()
        and target.components.health ~= nil
end

local function OnHitOther(inst, data)
    if data.redirected then
        return
    end
    local target=data.target
	if target ~= nil then
        if target.components.sanity~=nil then
            target.components.sanity:DoDelta(-5)
        end
    end
end




local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddPhysics()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    --inst.Physics:SetCylinder(0.25, 2)

    inst.Transform:SetScale(1.5,1.5,1.5)

    inst.AnimState:SetMultColour(1, 1, 1, 0.5)

    inst.AnimState:SetBank("oceanhorror")
    inst.AnimState:SetBuild("shadow_oceanhorror")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst:AddTag("shadow")
    inst:AddTag("notarget")
    inst:AddTag("NOCLICK")
    inst:AddTag("shadow_aligned")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end


    inst:AddComponent("combat")
    inst.components.combat:SetRange(5)
    inst.components.combat:SetDefaultDamage(75)
    inst.components.combat:SetAttackPeriod(3)
    inst.components.combat:SetRetargetFunction(1, retargetfn)
    inst.components.combat:SetKeepTargetFunction(shouldKeepTarget)



    inst:SetStateGraph("SGleechterror")
    inst:ListenForEvent("onhitother", OnHitOther)

    return inst
end
local function smallfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddPhysics()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    --inst.Physics:SetCylinder(0.25, 2)
    inst.AnimState:SetMultColour(1, 1, 1, 0.5)
    inst.AnimState:SetBank("oceanhorror")
    inst.AnimState:SetBuild("shadow_oceanhorror")
    inst.AnimState:PlayAnimation("idle_loop", true)

    inst:AddTag("shadow")
    inst:AddTag("notarget")
    inst:AddTag("NOCLICK")
    inst:AddTag("shadow_aligned")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end


    inst:AddComponent("combat")
    inst.components.combat:SetRange(3)
    inst.components.combat:SetDefaultDamage(40)
    inst.components.combat:SetAttackPeriod(3)
    inst.components.combat:SetRetargetFunction(1, retargetfn)
    inst.components.combat:SetKeepTargetFunction(shouldKeepTarget)

    inst:SetStateGraph("SGleechterror")

    inst:ListenForEvent("onhitother", OnHitOther)
    return inst
end

return Prefab("leechterror", fn, assets),
    Prefab("small_leechterror",smallfn,assets)