local assets =
{
    Asset("ANIM", "anim/alterguardian_spike.zip"),
}

local prefabs =
{
    "alterguardian_phase2spike",
    "alterguardian_spike_breakfx",
    -- "alterguardian_spiketrail_fx", -- not a real prefab so it doesnt need to have a depenancy chain
}

local SPIKEDAMAGE = 160
local SPIKE_WALL_RADIUS = 2.2


local SPIKE_CANT_TAGS = { "DECOR", "flying", "FX", "ghost", "INLIMBO", "NOCLICK", "playerghost", "shadow"}
local SPIKE_ONEOF_TAGS = { "_health", "CHOP_workable", "DIG_workable", "HAMMER_workable", "MINE_workable" }

local function DoAttack(inst, pos)
    local hit_a_target = false

    -- Attack as a proxy of the main alter guardian, UNLESS it died and left before we went off.
    local attacker = (inst._aguard ~= nil and inst._aguard:IsValid() and inst._aguard) or inst
    local attacker_combat = attacker.components.combat

    local old_damage = attacker_combat.defaultdamage
    attacker_combat.ignorehitrange = true
    attacker_combat:SetDefaultDamage(SPIKEDAMAGE)

    pos = pos or inst:GetPosition()
    local x, y, z = pos:Get()

    local nearby_potential_targets = TheSim:FindEntities(x, y, z, SPIKE_WALL_RADIUS + 1, nil, SPIKE_CANT_TAGS, SPIKE_ONEOF_TAGS)
    for _, potential_target in ipairs(nearby_potential_targets) do
        if potential_target ~= inst._aguard and potential_target:IsValid()
                and not potential_target:IsInLimbo() then

            local dsq_to_target = potential_target:GetDistanceSqToPoint(x, y, z)

            if potential_target:HasTag("smashable") and dsq_to_target < (SPIKE_WALL_RADIUS^2) then
                potential_target.components.health:Kill()

                hit_a_target = true
            elseif potential_target.components.workable ~= nil
                    and potential_target.components.workable:CanBeWorked()
                    and potential_target.components.workable.action ~= ACTIONS.NET
                    and dsq_to_target < (SPIKE_WALL_RADIUS^2) then

                if not potential_target:HasTag("moonglass") then
                    SpawnPrefab("collapse_small").Transform:SetPosition(potential_target.Transform:GetWorldPosition())
                end

                potential_target.components.workable:Destroy(inst)

                hit_a_target = true
            elseif not (potential_target.components.health ~= nil and potential_target.components.health:IsDead()) then
                local rsq = (SPIKE_WALL_RADIUS + 0.25 + potential_target:GetPhysicsRadius(.5))^2
                if dsq_to_target <= rsq and inst.components.combat:CanTarget(potential_target) then
                    attacker_combat:DoAttack(potential_target)

                    hit_a_target = true
                end
            end
        end
    end

    attacker_combat.ignorehitrange = false
    attacker_combat:SetDefaultDamage(old_damage)

    return hit_a_target
end

local function SetOwner(inst, aguard)
    inst._aguard = aguard
end


local WALL_SPIKE_DELAY = 4*FRAMES
--[[local function emerge(inst)
    inst.Physics:Stop()
    inst._stop_trail:push()
    inst.SoundEmitter:KillSound("earthquake")

    local ipos = inst:GetPosition()
    if TheWorld.Map:IsPassableAtPoint(ipos:Get()) then
        try_spawn_spike(inst, ipos)
    end

    if inst._rotation == nil then
        inst._rotation = inst.Transform:GetRotation()
    end

    local theta = math.asin((SPIKE_WALL_RADIUS+0.25)/WALL_RADIUS)
    local WALL_SPIKE_COUNT = math.floor(PI*0.25/theta)+1
    for wall_index = 1, WALL_SPIKE_COUNT do
        local step = RoundBiasedUp((wall_index-1) / 2)
        inst:DoTaskInTime(step*WALL_SPIKE_DELAY, function(inst2)

            local angle = theta*wall_index + inst._rotation*DEGREES
            local spawn_point1 = Vector3(inst._center.x+WALL_RADIUS*math.cos(angle),0,inst._center.z-WALL_RADIUS*math.sin(angle))

            local spawn_point2 = Vector3(inst._center.x+WALL_RADIUS*math.cos(angle),0,inst._center.z+WALL_RADIUS*math.sin(angle))


            if TheWorld.Map:IsPassableAtPoint(spawn_point1:Get()) then
                try_spawn_spike(inst, spawn_point1)
            end
            if TheWorld.Map:IsPassableAtPoint(spawn_point2:Get()) then
                try_spawn_spike(inst, spawn_point2)
            end
        end)
    end

    ShakeAllCameras(CAMERASHAKE.FULL, .25, 0.05, 0.075, inst, 45)

    -- Make sure the remove is safely after all spikes are spawned.
    local safezone_remove_time = RoundBiasedUp(WALL_SPIKE_COUNT / 2) + 1
    inst:DoTaskInTime(WALL_SPIKE_DELAY * safezone_remove_time, inst.Remove)
end]]

local function emerge2(inst)
    local pos = inst:GetPosition()

    if DoAttack(inst, pos) then
        local breakfx = SpawnPrefab("alterguardian_spike_breakfx")
        breakfx.Transform:SetPosition(pos:Get())
    elseif math.random()<0.3 then
        local spike = SpawnPrefab("alterguardian_phase2spike")
        spike.Transform:SetPosition(pos:Get())
    end    

    inst.life = inst.life - 1
    if TheWorld.Map:IsPassableAtPoint(pos:Get()) and inst.life>0 then
        inst:DoTaskInTime(0.3,emerge2)
    else
        inst:Remove()
    end        
end

local TRAIL_SPEED_PERSECOND = 15 --units/second


local function MakeSpikeTrailPhysics(inst)
    local phys = inst.entity:AddPhysics()
    phys:SetMass(0.1)
    phys:SetFriction(0)
    phys:SetDamping(5)
    phys:SetCollisionGroup(COLLISION.SMALLOBSTACLES)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.GROUND)
    phys:SetCapsule(0.1, 1)
end

local function CLIENT_on_stop_trail(inst)
    if inst._trail_task ~= nil then
        inst._trail_task:Cancel()
        inst._trail_task = nil
    end
end


local function createtrailfx()
    local inst = CreateEntity("alterguardian_spiketrail_fx")

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst:AddTag("FX")

    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.AnimState:SetBank("alterguardian_spike")
    inst.AnimState:SetBuild("alterguardian_spike")
    inst.AnimState:PlayAnimation("trail")
    inst.AnimState:SetFinalOffset(-1)

    inst:ListenForEvent("animover", inst.Remove)

    inst.AnimState:SetLayer(LAYER_BACKGROUND)

    return inst
end

local function CLIENT_spawn_trail_fx(inst)
    local fx = createtrailfx()
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
end

local function spiketrailfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeSpikeTrailPhysics(inst)

    inst.AnimState:SetBank("alterguardian_spike")
    inst.AnimState:SetBuild("alterguardian_spike")
    inst.AnimState:PlayAnimation("empty")
    inst.AnimState:SetFinalOffset(1)


    inst:AddTag("groundspike")
    inst:AddTag("NOCLICK")
    inst:AddTag("notarget")

    inst._stop_trail = net_event(inst.GUID, "alterguardian_phase2spike._stop_trail")

    if not TheNet:IsDedicated() then
        inst:ListenForEvent("alterguardian_phase2spike._stop_trail", CLIENT_on_stop_trail)

        inst._trail_task = inst:DoPeriodicTask(4*FRAMES, CLIENT_spawn_trail_fx)
    end

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.Physics:SetMotorVelOverride(TRAIL_SPEED_PERSECOND, 0, 0)

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(SPIKEDAMAGE)
    inst.components.combat:SetRange(4)
    inst.components.combat.battlecryenabled = false

    inst.persists = false

    inst.life = 18
    inst.SetOwner = SetOwner

    --inst._emerge_task = inst:DoTaskInTime(WALL_RADIUS/TRAIL_SPEED_PERSECOND, emerge)
    --inst._watertest_task = inst:DoPeriodicTask(WATER_CHECK_RATE, check_over_water)

    inst._emerge_task = inst:DoTaskInTime(0.3,emerge2)
    --inst._aguard = nil
    --inst._rotation = nil

    inst.SoundEmitter:PlaySound("dontstarve/cave/earthquake", "earthquake")
    inst.SoundEmitter:SetParameter("earthquake", "intensity", .1)

    

    return inst
end


return Prefab("ray_spiketrail", spiketrailfn, assets, prefabs)