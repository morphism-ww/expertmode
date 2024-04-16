local assets =
{
    Asset("ANIM", "anim/shadow_oceanhorror.zip"),
}



local RETARGET_MUST_TAGS = { "_combat", "_health" }
local RETARGET_CANT_TAGS = { "minotaur","chess" }
local function retargetfn(inst)
    return FindEntity(
        inst,
        10,
        function(guy)
            return guy.prefab ~= inst.prefab
                and guy.entity:IsVisible()
                and not guy.components.health:IsDead()
                and (guy.components.combat.target == inst or
                    guy:HasTag("character") or
                    guy:HasTag("monster") or
                    guy:HasTag("animal"))
				and (guy:HasTag("player") or
					not (guy.sg and guy.sg:HasStateTag("hiding")))
        end,
        RETARGET_MUST_TAGS,
        RETARGET_CANT_TAGS)
end

local function shouldKeepTarget(inst, target)
    return target ~= nil
        and target:IsValid()
        and target.components.health ~= nil
        and not target.components.health:IsDead()
end

local function OnHitOther(inst, data)
    if data.redirected then
        return
    end
    local target=data.target
	if target ~= nil then
        if target.components.sanity~=nil then
            target.components.sanity:DoDelta(-8)
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