local brain = require "brains/robot_spiderbrain"
local assets=
{
	Asset("ANIM", "anim/metal_spider.zip"),
    Asset("ANIM", "anim/metal_claw.zip"),
    Asset("ANIM", "anim/metal_leg.zip"),
    Asset("ANIM", "anim/metal_head.zip"),
}

local RETARGET_MUST_TAGS = { "_combat" ,"_health"}
local RETARGET_CANT_TAGS = { "INLIMBO" ,"chess"}
local RETARGET_ONEOF_TAGS = { "character", "monster" }

local function Retarget(inst)
    local homePos = inst.components.knownlocations:GetLocation("home")
    return not (homePos ~= nil and
    inst:GetDistanceSqToPoint(homePos:Get()) >= 900)
    and FindEntity(inst, 22, function(guy)
            return inst.components.combat:CanTarget(guy) and not guy.components.health:IsDead()
        end, RETARGET_MUST_TAGS,
            RETARGET_CANT_TAGS,
            RETARGET_ONEOF_TAGS
    ) or nil
end

local function KeepTarget(inst, target)
    local homePos = inst.components.knownlocations:GetLocation("home")
    return  (homePos ~= nil and target:GetDistanceSqToPoint(homePos:Get()) < 1600)
end

local function _ShareTargetFn(dude)
    return dude:HasTag("chess")
end


local function OnAttacked(inst, data)
    local attacker = data ~= nil and data.attacker or nil
    if attacker ~= nil and attacker:HasTag("chess") then
        return
    end
    inst.components.combat:SetTarget(attacker)
    inst.components.combat:ShareTarget(attacker, 40, _ShareTargetFn, 8)
end

local function revive(inst,data)
    if data~=nil and data.name=="revive" then
        inst.components.health:SetPercent(1)
        inst.sg:GoToState("activate")
    end
end


local function Ondeath(inst)
    inst:ListenForEvent("timerdone",revive)
    if not inst.components.timer:TimerExists("revive") then
        inst.components.timer:StartTimer("revive", 60)
    end
end


local function SetHomePosition(inst)
    if inst.components.knownlocations:GetLocation("home")==nil then
        inst.components.knownlocations:RememberLocation("home", inst:GetPosition())
    end
end

local function fn()
    local inst=CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(6, 2)

    MakeGiantCharacterPhysics(inst, 2000, 1)


    inst.AnimState:SetBank("metal_spider")
    inst.AnimState:SetBuild("metal_spider")
    inst.AnimState:PlayAnimation("idle", true)

    inst.Transform:SetFourFaced()
    inst.Transform:SetScale(1.5,1.5,1.5)

    inst.entity:AddLight()

    inst.Light:SetIntensity(.6)
    inst.Light:SetRadius(5)
    inst.Light:SetFalloff(3)
    inst.Light:SetColour(1, 0, 0)
    inst.Light:Enable(false)

    inst:AddTag("chess")
    inst:AddTag("hostile")
    inst:AddTag("mech")
    inst:AddTag("laser_immune")
   

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(2500)
    inst.components.health.nofadeout = true


    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body01"
    inst.components.combat:SetDefaultDamage(180)
    inst.components.combat.playerdamagepercent = 0.5
    inst.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 0.5, "ancient_armor")
    --inst.components.combat:SetAttackPeriod(5)
    inst.components.combat:SetRetargetFunction(2, Retarget)
    inst.components.combat:SetRange(9,12)
    inst.components.combat:SetKeepTargetFunction(KeepTarget)

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = 3
    inst.components.locomotor.runspeed = 3

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"gears","thulecite"})

    inst:AddComponent("timer")

    inst:AddComponent("knownlocations")

    inst:AddComponent("stuckdetection")
	inst.components.stuckdetection:SetTimeToStuck(4)

    inst:SetBrain(brain)
    inst:SetStateGraph("SGspider_robot")

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("death",Ondeath)
    inst:DoTaskInTime(0, SetHomePosition)


    return inst
end

return  Prefab("spider_robot",fn,assets)