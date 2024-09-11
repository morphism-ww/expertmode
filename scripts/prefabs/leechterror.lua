local assets =
{
    Asset("ANIM", "anim/shadow_oceanhorror.zip"),
}

local RETARGET_MUST_TAGS = { "_combat"}
local RETARGET_CANT_TAGS = { "minotaur","chess" }
local RETARGET_ONEOF_TAGS = {"character","monster","animal"}
local function retargetfn(inst)
    return FindEntity(
        inst,
        20,
        function(guy)
            return  guy.entity:IsVisible()
                and guy.components.health~=nil
                and not guy.components.health:IsDead()
        end,
        RETARGET_MUST_TAGS,RETARGET_CANT_TAGS,RETARGET_ONEOF_TAGS)
end

local function shouldKeepTarget(inst, target)
    return target ~= nil
        and target:IsValid()
        and target.components.health ~= nil
        and not target.components.health:IsDead()
        and target:IsNear(inst, 10)
end

local function OnHitOther(inst,target,damage, stimuli, weapon, damageresolved)
    if damageresolved>0 and target.components.sanity~=nil then
        target.components.sanity:DoDelta(-8)
    end
end


local function sethost(inst,host,followsymbal)
    inst.entity:SetParent(host.entity)
    inst.entity:AddFollower():FollowSymbol(host.GUID, followsymbal, 0, 0, 0)
    inst:ListenForEvent("death",function ()
        inst.sg:GoToState("death")
    end,host)
end


local function MakeLeech(name,scale)
    local function fn()
        local inst = CreateEntity()
    
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
    
        
        inst.AnimState:SetBank("oceanhorror")
        inst.AnimState:SetBuild("shadow_oceanhorror")
        inst.AnimState:PlayAnimation("idle_loop", true)
        inst.AnimState:SetMultColour(1, 1, 1, 0.5)
        inst.AnimState:SetScale(scale,scale,scale)
        inst.AnimState:HideSymbol("Symbol 1")
    
        inst:AddTag("shadow")
        inst:AddTag("NOCLICK")
        inst:AddTag("notarget")
        inst:AddTag("shadow_aligned")
    
        inst.entity:SetPristine()
    
        if not TheWorld.ismastersim then
            return inst
        end
        
        inst.persists = false
    
        inst:AddComponent("combat")
        inst.components.combat:SetRange(3*scale)
        inst.components.combat:SetDefaultDamage(50*scale)
        inst.components.combat:SetAttackPeriod(4)
        inst.components.combat:SetRetargetFunction(0.5, retargetfn)
        inst.components.combat:SetKeepTargetFunction(shouldKeepTarget)
        inst.components.combat.onhitotherfn = OnHitOther
    
        inst:SetStateGraph("SGleechterror")
        inst.SetHost = sethost
    
        
        return inst
    end
    return Prefab(name, fn, assets)
end

return MakeLeech("leechterror",1.5),
    MakeLeech("small_leechterror",1)