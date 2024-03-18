local assets =
{
    Asset("ANIM", "anim/spore_moon.zip"),
    Asset("ANIM", "anim/mushroom_spore_moon.zip"),
}
local brain = require "brains/sporebrain"
local function stop_testing(inst)
    if inst._prox_task ~= nil then
        inst._prox_task:Cancel()
        inst._prox_task = nil
    end
end

local function depleted(inst)
    if inst:IsInLimbo() then
        inst:Remove()
    else
        stop_testing(inst)

        inst:AddTag("NOCLICK")
        inst.persists = false

        inst.components.workable:SetWorkable(false)
        inst:PushEvent("pop")

        inst:RemoveTag("spore") -- so crowding no longer detects it

        -- clean up when offscreen, because the death event is handled by the SG
        inst:DoTaskInTime(3, inst.Remove)
    end
end

local function onworked(inst, worker)
    inst:PushEvent("pop")
    inst:RemoveTag("spore")
end



local AREAATTACK_EXCLUDETAGS = { "spore", "INLIMBO", "notarget", "noattack", "invisible", "playerghost", "shadow", "toadstool" }
local function onpopped(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/balloon_pop")
    inst.components.combat:DoAreaAttack(inst, TUNING.MOONSPORE_ATTACK_RANGE, nil, nil, nil, AREAATTACK_EXCLUDETAGS)
end

local function onload(inst)
    -- If we loaded, then just turn the light on
    inst.Light:Enable(true)
    inst.DynamicShadow:Enable(true)
end

local PROXIMITY_MUSTHAVE = { "_combat" }
local PROXIMITY_ONEOF = { "player", "monster", "character" }
local function do_proximity_test(inst)
    if inst.sg:HasStateTag("busy") then
        return
    end

    local ix, iy, iz = inst.Transform:GetWorldPosition()
    local target = FindEntity(inst, TUNING.MOONSPORE_ATTACK_PROXIMITY, nil, PROXIMITY_MUSTHAVE, AREAATTACK_EXCLUDETAGS, PROXIMITY_ONEOF)

    if target ~= nil then
        stop_testing(inst)
        inst:PushEvent("preparedpop")
    end
end

local function spore_entity_sleep(inst)
    do_proximity_test(inst)
    stop_testing(inst)
end

local PROXIMITY_TEST_TIME = 15 * FRAMES
local function schedule_testing(inst)
    stop_testing(inst)
    inst._prox_task = inst:DoPeriodicTask(PROXIMITY_TEST_TIME, do_proximity_test)
end

local function spore_entity_wake(inst)
    schedule_testing(inst)
    do_proximity_test(inst)
end

local function DoPoison(inst,target)
    if target:HasTag("character") then
		target:AddDebuff("spore_poison","poison_2",{upgrade=true,duration=10})
    end
end

local COLOUR_R, COLOUR_G, COLOUR_B = 146/255, 225/255, 146/255
local ZERO_VEC = Vector3(0,0,0)
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()
    inst.entity:AddDynamicShadow()


    inst.AnimState:SetBuild("mushroom_spore_moon")
    inst.AnimState:SetBank("spore_moon")
    inst.AnimState:PlayAnimation("idle_flight_loop", true)

    inst.DynamicShadow:Enable(false)
    inst.Light:SetColour(COLOUR_R, COLOUR_G, COLOUR_B)
    inst.Light:SetIntensity(0.5)
    inst.Light:SetFalloff(0.75)
    inst.Light:SetRadius(0.5)
    inst.Light:Enable(false)

    inst.DynamicShadow:SetSize(.8, .5)
    inst:AddTag("spore")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.NET)
    inst.components.workable:SetWorkLeft(1)
    inst.components.workable:SetOnFinishCallback(onworked)

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(20)
    inst.components.perishable:StartPerishing()
    inst.components.perishable:SetOnPerishFn(depleted)

    inst:AddComponent("burnable")
    inst.components.burnable:SetFXLevel(1)
    inst.components.burnable:SetBurnTime(1)
    inst.components.burnable:AddBurnFX("fire", ZERO_VEC, "spore_body")
    inst.components.burnable:SetOnIgniteFn(DefaultBurnFn)
    inst.components.burnable:SetOnBurntFn(DefaultBurntFn)
    inst.components.burnable:SetOnExtinguishFn(DefaultExtinguishFn)

    inst:AddComponent("propagator")
    inst.components.propagator.acceptsheat = true
    inst.components.propagator:SetOnFlashPoint(DefaultIgniteFn)
    inst.components.propagator.flashpoint = 1
    inst.components.propagator.decayrate = 0.5
    inst.components.propagator.damages = false

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(50)
    inst.components.combat.onhitotherfn=DoPoison


    inst:ListenForEvent("popped", onpopped)

    inst:SetStateGraph("SGmoonspore")
    -- note: the first check is faster, because this might be from dropping a stack
    --inst.crowdingtask = inst:DoTaskInTime(1 + math.random()*TUNING.MUSHSPORE_DENSITY_CHECK_VAR, checkforcrowding)

    inst.OnLoad = onload
    inst.OnEntitySleep = spore_entity_sleep
    inst.OnEntityWake = spore_entity_wake

    inst:DoTaskInTime(0, schedule_testing)

    return inst
end

return Prefab("spore_poison", fn, assets)
