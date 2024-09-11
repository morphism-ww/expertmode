local function TrueFn()
    return true
end

local function anticheating(inst)
    inst.components.freezable:SetRedirectFn(TrueFn)

    MakePlayerOnlyTarget(inst)
    if inst.components.shockable then
        inst:RemoveComponent("shockable") 
    end
end


--------------------------------------------
---PHASES1
--------------------------------------------


AddPrefabPostInit("alterguardian_phase1",function(inst)

    inst:AddTag("meteor_protection")
    inst:AddTag("no_rooted")
    inst:AddTag("electricdamageimmune")

    if not TheWorld.ismastersim then 
        return 
    end

	
    anticheating(inst)

	inst:AddComponent("meteorshower")
    

    inst.transfer_postinitfn = nil
end)


---SG-change
local function roll_screenshake(inst)
    ShakeAllCameras(CAMERASHAKE.VERTICAL, .5, 0.05, 0.075, inst, 40)
end


local function spawn_landfx(inst)
    local ix, iy, iz = inst.Transform:GetWorldPosition()
    local sinkhole = SpawnPrefab("bearger_sinkhole")
    sinkhole.Transform:SetPosition(ix, iy, iz)
	sinkhole:PushEvent("docollapse")
    SpawnPrefab("mining_moonglass_fx").Transform:SetPosition(ix, iy, iz)
end

AddStategraphPostInit("alterguardian_phase1", function(sg)
    sg.states.roll.onenter = function(inst,speed)
        inst:EnableRollCollision(true)

        inst.components.locomotor:Stop()
        inst.components.locomotor:EnableGroundSpeedMultiplier(false)
        inst.Physics:SetMotorVelOverride(speed or 10, 0, 0)
        inst.sg.statemem.rollhits = {}

        inst.AnimState:PlayAnimation("roll_loop", true)

        inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())

        if inst.sg.mem._num_rolls == nil then
            inst.sg.mem._num_rolls = TUNING.ALTERGUARDIAN_PHASE1_MINROLLCOUNT + (2*math.random())
        else
            inst.sg.mem._num_rolls = inst.sg.mem._num_rolls - 1
        end

        inst.components.combat:RestartCooldown()
    end
	sg.states.roll.timeline=
	{
            TimeEvent(FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian1/roll")

                roll_screenshake(inst)

                spawn_landfx(inst)
                local roll_speed = 10
                local target = inst.components.combat.target
                if target ~= nil and target:IsValid() and target.components.locomotor ~= nil then
                    roll_speed = math.max(10, target.components.locomotor:GetRunSpeed() * inst.components.locomotor:GetSpeedMultiplier()+3)
                    roll_speed = math.min(roll_speed, 35)
                end
                inst.sg.statemem.roll_speed = roll_speed
            end),
        }
    sg.states.roll.ontimeout = function(inst)
            if not inst.sg.statemem.hitplayer and inst.sg.mem._num_rolls > 0 then
                local final_rotation = nil
                if inst.components.combat.target ~= nil then
                    -- Retarget, and keep rolling!
                    local tx, ty, tz = inst.components.combat.target.Transform:GetWorldPosition()
                    local target_facing = inst:GetAngleToPoint(tx, ty, tz)

                    local current_facing = inst:GetRotation()

                    local target_angle_diff = ((target_facing - current_facing + 540) % 360) - 180

                    if math.abs(target_angle_diff) > 120 then
                        final_rotation = target_facing + GetRandomWithVariance(0, -4)
                    elseif target_angle_diff < 0 then
                        final_rotation = (current_facing + math.max(target_angle_diff, -120)) % 360
                    else
                        final_rotation = (current_facing + math.min(target_angle_diff, 120)) % 360
                    end
                else
                    final_rotation = 360*math.random()
                end

                inst.Transform:SetRotation(final_rotation)

                inst.sg:GoToState("roll",inst.sg.statemem.roll_speed)
            elseif inst.sg.statemem.hitplayer and inst.sg.mem._num_rolls > 0 then
                inst.sg.mem._num_rolls = math.max(inst.sg.mem._num_rolls-2,0)
                inst.sg:GoToState("roll",inst.sg.statemem.roll_speed)
            else
                inst.sg.mem._num_rolls=nil
                inst.sg:GoToState("roll_stop")
            end
    end

	local oldOnEntershield_pre = sg.states.shield_pre.onenter
    sg.states.shield_pre.onenter = function(inst, ...)
        oldOnEntershield_pre(inst, ...)
        inst.components.meteorshower:StartCrazyShower()
    end

end)


--------------------------------------------
---PHASES2
--------------------------------------------


local function OnCollide(inst, other)
    if other ~= nil and
        other:IsValid() and
        other.components.workable ~= nil and
        other.components.workable:CanBeWorked() and
        other.components.workable.action ~= ACTIONS.NET then
        inst:DoTaskInTime(2 * FRAMES, other.components.workable:Destroy(inst))
    end
end

local function spawn_spike_with_pos(inst, pos, angle)

    local spike = SpawnPrefab("alterguardian_phase2spiketrail")
    spike.Transform:SetPosition(pos.x, 0, pos.z)
    spike.Transform:SetRotation(angle)
    spike:SetOwner(inst)
end


local function spawnbarrier(inst)
    local angle = 0
    local radius = 15
    local number = 8
    local pos = inst:GetPosition()
    for i = 1,number do
        local offset = Vector3(radius * math.cos( angle*DEGREES ), 0, -radius * math.sin( angle*DEGREES ))
        local newpt = pos + offset

        --local tile = GetWorld().Map:GetTileAtPoint(newpt.x, newpt.y, newpt.z)
        if TheWorld.Map:IsPassableAtPoint(newpt.x, 0,newpt.z) then
            inst:DoTaskInTime(0.3, spawn_spike_with_pos,newpt,angle)
        end
        angle = angle + (360/number)
    end
end

AddPrefabPostInit("alterguardian_phase2",function(inst)


    inst:AddTag("toughworker")
    inst:AddTag("no_rooted")
    inst:AddTag("electricdamageimmune")

    if not TheWorld.ismastersim then 
        return 
    end

    inst.Physics:SetCollisionCallback(OnCollide)

    anticheating(inst)
	
    local oldDoSpikeAttack = inst.DoSpikeAttack
    inst.DoSpikeAttack = function (inst)
        oldDoSpikeAttack(inst)
        spawnbarrier(inst)
    end

end)




---SG
local AOE_RANGE_PADDING = 3
local CHOP_RANGE_DSQ = TUNING.ALTERGUARDIAN_PHASE2_CHOP_RANGE * TUNING.ALTERGUARDIAN_PHASE2_CHOP_RANGE
local SPIN_RANGE_DSQ = TUNING.ALTERGUARDIAN_PHASE2_SPIN_RANGE * TUNING.ALTERGUARDIAN_PHASE2_SPIN_RANGE
AddStategraphPostInit("alterguardian_phase2",function(sg)
	sg.events["doattack"].fn = function(inst,data)
		if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy"))
                and (data.target ~= nil and data.target:IsValid()) then
            local dsq_to_target = inst:GetDistanceSqToInst(data.target)
            local can_spin = not inst.components.timer:TimerExists("spin_cd")
            local can_deadspin=not inst.components.timer:TimerExists("deadspin_cd")
            local can_summon = not inst.components.timer:TimerExists("summon_cd")
            local can_spike = not inst.components.timer:TimerExists("spike_cd")
            local can_atk2 = not inst.components.timer:TimerExists("lightning_cd")
            local attack_state = (not data.target:IsOnValidGround() and "antiboat_attack")
                or (dsq_to_target < SPIN_RANGE_DSQ and can_spin and (can_deadspin and "deadspin_pre" or "spin_pre"))
                or (can_summon and "atk_summon")
                or (can_spike and (math.random()<0.5 and "atk_spike" or "atk_spike2"))
                or (can_atk2 and "lightning_trial")
                or (dsq_to_target < CHOP_RANGE_DSQ and "atk_chop")
                or nil
            if attack_state ~= nil then
                inst.sg:GoToState(attack_state, data.target)
            end
        end
	end
end)


local function dospark(inst)
    local shock_fx = SpawnPrefab("moonstorm_spark_shock_fx")
    shock_fx.Transform:SetScale(2,2,2)
    inst:AddChild(shock_fx)


	--inst:SpawnChild("electricchargedfx").AnimState:SetScale(1.5,1.5,1.5)
end


local function spawn_spike_with_target(inst,pos,angle)
    local spike = SpawnPrefab("ray_spiketrail")
    spike.Transform:SetPosition(pos:Get())
    spike.Transform:SetRotation(angle)
    spike:SetOwner(inst)
end

local SPIKE_DSQ = 400
local function do_spike2(inst)
    local ipos = inst:GetPosition()

    local spikes_spawned = 0
    local spikes_to_spawn = 4

    local angles_chosen = {}

    for _, p in ipairs(AllPlayers) do
        if not p:HasTag("playerghost") and p.entity:IsVisible()
                and (p.components.health ~= nil and not p.components.health:IsDead())
                and p:GetDistanceSqToPoint(ipos:Get()) < SPIKE_DSQ then
            local firing_angle = inst:GetAngleToPoint(p.Transform:GetWorldPosition())
            table.insert(angles_chosen, firing_angle)

            spawn_spike_with_target(inst, ipos, firing_angle)
            spikes_spawned = spikes_spawned + 1
            if spikes_spawned >= spikes_to_spawn then
                break
            end
        end
    end

    local remain_to_spawn = 3
    for i=1, remain_to_spawn do
        local start_angle = 360*math.random()
        local firing_angle = nil
        for ang = 0, 360, 60 do
            local possible_angle = start_angle + ang
            local angle_valid = true
            for _, used_ang in ipairs(angles_chosen) do
                if math.abs(possible_angle - used_ang) < 20 then
                    angle_valid = false
                    break
                end
            end

            if angle_valid then
                firing_angle = possible_angle
                break
            end
        end

        if firing_angle then
            table.insert(angles_chosen, firing_angle)
            spawn_spike_with_target(inst, ipos, firing_angle)
        end
    end    
end


local function go_to_idle(inst)
    inst.sg:GoToState("idle")
end


local function spawn_spintrail(inst)

    local spawn_pt = inst:GetPosition() --- Vector3(1.5 * math.cos(facing_dir), 0, -1.5 * math.sin(facing_dir))
    SpawnPrefab("alterguardian_spintrail_fx").Transform:SetPosition(spawn_pt:Get())
    SpawnPrefab("mining_moonglass_fx").Transform:SetPosition(spawn_pt:Get())
end


local SPIN_CANT_TAGS = { "brightmareboss","brightmare","INLIMBO", "FX", "NOCLICK", "playerghost", "flight", "invisible", "notarget", "noattack" }
local SPIN_ONEOF_TAGS = {"_health", "CHOP_workable", "HAMMER_workable", "MINE_workable"}
local SPIN_FX_RATE = 10*FRAMES

AddStategraphState("alterguardian_phase2",State{
    name = "lightning_trial",
    tags = {"attack", "busy"},

    onenter = function(inst)
        inst.components.locomotor:Stop()

        inst.components.combat:StartAttack()

        inst.AnimState:PlayAnimation("attk_chop")
       
        local target = inst.components.combat.target
        if target ~= nil and target:IsValid() then
            inst.sg.statemem.target = target
            inst.sg.statemem.targetpos = target:GetPosition()
            inst.sg.statemem.targetrot = target.Transform:GetRotation()
            inst:ForceFacePoint(inst.sg.statemem.targetpos)
        end

        if inst.sg.mem.num_summons == nil then
            inst.components.timer:StartTimer("lightning_cd", TUNING.ALTERGUARDIAN_PHASE2_LIGHTNINGCOOLDOWN)
            inst.sg.mem.num_summons = 4
        else
            inst.sg.mem.num_summons = inst.sg.mem.num_summons - 1
        end
        inst.sg:SetTimeout(1.5)
    end,

    timeline =
    {
        TimeEvent(0*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/summon")
        end),
        TimeEvent(20*FRAMES, function(inst)
            dospark(inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/swhoosh")
            inst.sg.statemem.target = nil
            local p = inst.sg.statemem.targetpos
            if p ~= nil then
                p.y=0
                local theta = inst.sg.statemem.targetrot*DEGREES
                local radius = 6 + 4*math.random()

                inst.sg.statemem.ping1 = SpawnPrefab("deerclops_icelance_ping_fx")
                inst.sg.statemem.ping1.Transform:SetPosition(p:Get())

                inst.sg.statemem.ping2 = SpawnPrefab("deerclops_icelance_ping_fx")
                inst.sg.statemem.ping2.Transform:SetPosition(p.x + radius*math.cos(theta), 0, p.z - radius*math.sin(theta))
            end
        end),
        TimeEvent(22*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/ground_hit")
            inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/spell_cast")
            ShakeAllCameras(CAMERASHAKE.VERTICAL, .75, 0.1, 0.1, inst, 30)
        end),
        TimeEvent(38*FRAMES, function(inst)
            if inst.sg.statemem.ping1 ~= nil then
                inst.sg.statemem.ping1:KillFX()
                inst.sg.statemem.ping1 = nil
                local lightning = SpawnPrefab("moon_lightning2")
                lightning:SetOwner(inst)
                lightning.Transform:SetPosition(inst.sg.statemem.targetpos:Get())
            end
        end),
        TimeEvent(40*FRAMES, function(inst)
            if inst.sg.statemem.ping2~= nil then
                local lightning = SpawnPrefab("moon_lightning2")
                lightning:SetOwner(inst)
                lightning.Transform:SetPosition(inst.sg.statemem.ping2.Transform:GetWorldPosition())
                inst.sg.statemem.ping2:KillFX()
                inst.sg.statemem.ping2 = nil
            end             
        end),
    },
    ontimeout = function (inst)
        if inst.sg.mem.num_summons and inst.sg.mem.num_summons > 0 then
            inst.sg:GoToState("lightning_trial")
        else
            inst.sg.mem.num_summons = nil
            inst.sg:GoToState("idle")
        end   
    end,

    onexit = function(inst)
        if inst.sg.statemem.ping1 ~= nil then
            inst.sg.statemem.ping1:KillFX()
            inst.sg.statemem.ping1 = nil
        end
        if inst.sg.statemem.ping2~= nil then
            inst.sg.statemem.ping2:KillFX()
            inst.sg.statemem.ping2 = nil
        end
    end
})


AddStategraphState("alterguardian_phase2",State {
    name = "atk_spike2",
    tags = {"attack", "busy"},

    onenter = function(inst, target)
        inst.components.locomotor:StopMoving()

        inst.components.combat:StartAttack()
        inst.components.timer:StartTimer("spike_cd",TUNING.ALTERGUARDIAN_PHASE2_SPIKECOOLDOWN)
        inst.AnimState:PlayAnimation("attk_stab_pre")
        inst.AnimState:PushAnimation("attk_stab_loop", true)
        inst.sg:SetTimeout(5)
    end,

    timeline =
    {
        TimeEvent(10*FRAMES, function(inst)
            dospark(inst)
            inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/atk_spike_pre")
        end),
        TimeEvent(30*FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/atk_spike")
            
            ShakeAllCameras(CAMERASHAKE.FULL, .75, 0.1, 0.1, inst, 50)
            inst.components.combat:DoAttack()
            spawnbarrier(inst)
        end),
        TimeEvent(40*FRAMES,function (inst)
            dospark(inst)
            do_spike2(inst)
        end),
        TimeEvent(90*FRAMES, function(inst)
            dospark(inst)
            do_spike2(inst)
        end),
        TimeEvent(150*FRAMES, function(inst)
            dospark(inst)
            do_spike2(inst)
        end),
    },

    ontimeout = function(inst)
        inst.sg:GoToState("atk_spike_pst")
    end,
})


AddStategraphState("alterguardian_phase2",State {
    name = "deadspin_pre",
    tags = {"busy", "canrotate", "spin"},

    onenter = function(inst, target)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("attk_spin_pre")
        
        dospark(inst)

        inst.components.timer:StartTimer("deadspin_cd",TUNING.ALTERGUARDIAN_PHASE2_SPIN2CD)
        inst.sg.mem.deadcount = 3
        --inst.Physics:ClearCollidesWith(COLLISION.WORLD)
        --inst.Physics:CollidesWith(COLLISION.GROUND)
        inst.sg.statemem.target = target
    end,

    onupdate = function(inst, dt)
        local target = inst.sg.statemem.target
        if target ~= nil and target:IsValid() then
            inst:ForceFacePoint(target.Transform:GetWorldPosition())
        end

        if inst.sg.timeinstate > 32*FRAMES then
            local time_in_spin = inst.sg.timeinstate - 32*FRAMES
            if time_in_spin > (FRAMES^3) and time_in_spin % SPIN_FX_RATE < (FRAMES^3) then
                spawn_spintrail(inst)
            end
        end

        -- Do a check for AOE damage & smashing occasionally.
        if inst.sg.statemem.attack_time == nil then
            --not yet
        elseif inst.sg.statemem.attack_time > 0 then
            inst.sg.statemem.attack_time = inst.sg.statemem.attack_time - dt
        else
            local ix, iy, iz = inst.Transform:GetWorldPosition()
            local targets = TheSim:FindEntities(
                ix, iy, iz, TUNING.ALTERGUARDIAN_PHASE2_CHOP_RANGE + AOE_RANGE_PADDING,
                nil, SPIN_CANT_TAGS, SPIN_ONEOF_TAGS
            )
            for _, target in ipairs(targets) do
                if target:IsValid() and not target:IsInLimbo() then
                    local range = TUNING.ALTERGUARDIAN_PHASE2_CHOP_RANGE + target:GetPhysicsRadius(0)
                    if target:GetDistanceSqToPoint(ix, iy, iz) < range * range then
                        local has_health = target.components.health ~= nil
                        if has_health and target:HasTag("smashable") then
                            target.components.health:Kill()
                        elseif target.components.workable ~= nil
                            and target.components.workable:CanBeWorked() then
                            if not target:HasTag("moonglass") then
                                local tx, ty, tz = target.Transform:GetWorldPosition()
                                local collapse_fx = SpawnPrefab("collapse_small")
                                collapse_fx.Transform:SetPosition(tx, ty, tz)
                            end

                            target.components.workable:Destroy(inst)
                        elseif has_health and not target.components.health:IsDead() then
                            inst.components.combat:DoAttack(target,nil,nil,"electric")
                        end
                    end
                end
            end

            inst.sg.statemem.attack_time = 8*FRAMES
        end
    end,

    timeline =
    {
        TimeEvent(30*FRAMES, function(inst)
            dospark(inst)
            inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/atk_spin_pre")
        end),
        TimeEvent(32*FRAMES, function(inst)
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)

            inst.Physics:SetMotorVelOverride(TUNING.ALTERGUARDIAN_PHASE2_DEADSPIN_SPEED, 0, 0)
        end),
        TimeEvent(35 * FRAMES, function(inst)
            inst.sg.statemem.attack_time = 0
        end),
    },

    events =
    {
        EventHandler("animover", function(inst)
            if inst.sg.statemem.target~=nil and not inst.sg.statemem.target.components.health:IsDead() then
                local loop_data =
                {
                    spin_time_remaining = (inst.sg.timeinstate - 18*FRAMES) % SPIN_FX_RATE,
                    target = inst.sg.statemem.target,
                    attack_time = inst.sg.statemem.attack_time,
                }
                inst.sg:GoToState("deadspin_loop", loop_data)
            else
                inst.sg.mem.deadcount = nil
                
                
                go_to_idle(inst)
            end        
        end ),
    },

    onexit = function(inst)
        
        inst.components.locomotor:EnableGroundSpeedMultiplier(true)
        inst.Physics:ClearMotorVelOverride()
        inst.components.locomotor:Stop()
    end,
})


AddStategraphState("alterguardian_phase2",State {
    name = "deadspin_loop",
    tags = {"busy", "canrotate", "spin"},

    onenter = function(inst, data)
        inst.components.locomotor:Stop()
        inst.components.locomotor:EnableGroundSpeedMultiplier(false)

        inst.AnimState:PlayAnimation("attk_spin_loop", true)
        dospark(inst)

        inst.sg.statemem.loop_len = inst.AnimState:GetCurrentAnimationLength()
        --local num_loops = 2
        inst.sg:SetTimeout(inst.sg.statemem.loop_len * 2)

        inst.sg.statemem.attack_time = data.attack_time or 0
        inst.sg.statemem.target = data.target
        inst.sg.statemem.speed = TUNING.ALTERGUARDIAN_PHASE2_DEADSPIN_SPEED
        inst.sg.statemem.initial_spin_fx_time = data.spin_time_remaining

        if data.target ~= nil and data.target:IsValid() then
            inst:ForceFacePoint(data.target.Transform:GetWorldPosition())
        end
        inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/atk_spin_LP","spin_loop")

        inst.Physics:SetMotorVelOverride(inst.sg.statemem.speed, 0, 0)
    end,

    onupdate = function(inst, dt)
        -- If our original target is still alive, chase them down.
        -- Otherwise, we'll just go in the direction we were facing until we finish.


        local fx_time_in_state = inst.sg.statemem.initial_spin_fx_time + inst.sg.timeinstate
        if fx_time_in_state % SPIN_FX_RATE < (FRAMES^3) then
            spawn_spintrail(inst)
        end

        -- Do a check for AOE damage & smashing occasionally.
        if inst.sg.statemem.attack_time > 0 then
            inst.sg.statemem.attack_time = inst.sg.statemem.attack_time - dt
        else
            local hit_player = false

            local ix, iy, iz = inst.Transform:GetWorldPosition()
            local targets = TheSim:FindEntities(
                ix, iy, iz, TUNING.ALTERGUARDIAN_PHASE2_CHOP_RANGE + AOE_RANGE_PADDING,
                nil, SPIN_CANT_TAGS, SPIN_ONEOF_TAGS
            )
            for _, target in ipairs(targets) do
                if target:IsValid() and not target:IsInLimbo() then
                    local range = TUNING.ALTERGUARDIAN_PHASE2_CHOP_RANGE + target:GetPhysicsRadius(0)
                    if target:GetDistanceSqToPoint(ix, iy, iz) < range * range then
                        local has_health = target.components.health ~= nil
                        if has_health and target:HasTag("smashable") then
                            target.components.health:Kill()
                        elseif target.components.workable ~= nil
                            and target.components.workable:CanBeWorked() then
                            if not target:HasTag("moonglass") then
                                local tx, ty, tz = target.Transform:GetWorldPosition()
                                local collapse_fx = SpawnPrefab("collapse_small")
                                collapse_fx.Transform:SetPosition(tx, ty, tz)
                            end

                            target.components.workable:Destroy(inst)
                        elseif has_health and not target.components.health:IsDead() then
                            inst.components.combat:DoAttack(target,nil,nil,"electric")
                            if target:HasTag("player") then
                                hit_player = true
                            end
                        end
                    end
                end
            end

            inst.sg.statemem.attack_time = 8*FRAMES

            -- If we hit a player and have more than a loop left, finish our looping early.
            -- This is to help prevent players being strung along in a long hit chain.
            if hit_player and (inst.sg.timeout == nil or inst.sg.timeout > inst.sg.statemem.loop_len) then
                inst.sg:SetTimeout(inst.sg.statemem.loop_len)
            end
        end
    end,
    timeline={
        TimeEvent(35*FRAMES, function(inst)
            dospark(inst)
            inst.sg.statemem.attack_time = 0
        end),
    },
    ontimeout = function(inst)
        inst.sg.statemem.exit_by_timeout = true
        if inst.sg.mem.deadcount and inst.sg.mem.deadcount>0 then
            inst.sg.mem.deadcount=inst.sg.mem.deadcount-1
            local loop_data =
                {
                    spin_time_remaining = (inst.sg.timeinstate - 18*FRAMES) % SPIN_FX_RATE,
                    target = inst.sg.statemem.target,
                    attack_time = inst.sg.statemem.attack_time,
                }
            inst.sg:GoToState("deadspin_loop", loop_data)
        else
            --inst.Physics:CollidesWith(COLLISION.WORLD)
            inst.sg:GoToState("spin_pst", inst.sg.statemem.speed)
        end
    end ,

    onexit = function(inst)
        inst.components.locomotor:EnableGroundSpeedMultiplier(true)
        inst.Physics:ClearMotorVelOverride()
        inst.components.locomotor:Stop()
        
        -- We may be exiting this state via death, freezing, etc.
        if not inst.sg.statemem.exit_by_timeout then
            inst.SoundEmitter:KillSound("spin_loop")
        end
    end,
})


--------------------------------------------
---PHASES3
--------------------------------------------


local function CalcSanityAura(inst, observer)
    return (inst.sg.statemem.in_eraser and 2*TUNING.SANITYAURA_HUGE) or
    (inst.components.combat.target ~= nil and TUNING.SANITYAURA_HUGE) or TUNING.SANITYAURA_LARGE
end

local function FallOffFn(inst,observer,dsq)
    return inst.sg.statemem.in_eraser and 1 or math.max(1, dsq)
end

AddPrefabPostInit("alterguardian_phase3",function(inst)
    
    inst:AddTag("no_rooted")
    inst:AddTag("toughworker")
    inst:AddTag("electricdamageimmune")

	if not TheWorld.ismastersim then 
        return 
    end

    anticheating(inst)
    inst:AddComponent("debuffable")
    inst.components.combat:SetAreaDamage(4)

    inst.components.sanityaura.aurafn = CalcSanityAura
    inst.components.sanityaura.max_distsq = 400
    inst.components.sanityaura.fallofffn = FallOffFn
    
end)



local MIN_TRAP_COUNT_FOR_RESPAWN = 4
local maxdeflect = 1
local RANGED_ATTACK_DSQ = TUNING.ALTERGUARDIAN_PHASE3_STAB_RANGE^2
local SUMMON_DSQ = TUNING.ALTERGUARDIAN_PHASE3_SUMMONRSQ - 36

local function post_attack_idle(inst)
    inst.components.timer:StopTimer("runaway_blocker")
    inst.components.timer:StartTimer("runaway_blocker", TUNING.ALTERGUARDIAN_PHASE3_RUNAWAY_BLOCK_TIME)

    inst.sg:GoToState("idle")
end

local function set_lightvalues(inst, val)
    inst.Light:SetIntensity(0.60 + (0.39 * val * val))
    inst.Light:SetRadius(5 * val)
    inst.Light:SetFalloff(0.85)
end

local function dowarning(inst,shouldadd)
    local ix, _, iz = inst.Transform:GetWorldPosition()
    if shouldadd then
        local rangersq = 16*16
        for i, p in ipairs(AllPlayers) do
            local dsq_to_player = p:GetDistanceSqToPoint(ix, 0, iz)
            if dsq_to_player < rangersq and not p:HasTag("playerghost") then
                if p.components.grogginess then
                    p.components.grogginess:AddGrogginess(1, 2)
                end
            end
        end
    end
    inst.components.debuffable:RemoveOnDespawn()
    SpawnPrefab("moonpulse_spawner").Transform:SetPosition(ix, 0, iz)
end


local function laser_sound(inst)
    inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian3/atk_beam_laser")
end

local NUM_STEPS = 10
local STEP = 1.0
local OFFSET = 2 - STEP

local function DoEraser(inst,target)
    if target.components.inventory then
        target.components.inventory:ApplyDamage(5000)
    end
    target.components.health:DeltaPenalty(0.4)
end

local function SpawnEraserBeam(inst, target_pos)
    if target_pos == nil then
        return
    end

    local ix, iy, iz = inst.Transform:GetWorldPosition()

    -- This is the "step" of fx spawning that should align with the position the beam is targeting.

    local angle = nil

    -- gx, gy, gz is the point of the actual first beam fx
    local gx, gy, gz = nil, 0, nil
    local x_step = STEP

    angle = math.atan2(iz - target_pos.z, ix - target_pos.x)

    gx, gy, gz = inst.Transform:GetWorldPosition()
    gx = gx + (2 * math.cos(angle))
    gz = gz + (2 * math.sin(angle))

    local targets, skiptoss = {}, {}
    local x, z = nil, nil
    local trigger_time = nil


    local i = -1
    while i < 40 do
        i = i + 1
        x = gx - i * x_step * math.cos(angle)
        z = gz - i * STEP * math.sin(angle)

        local first = (i == 0)
        local prefab = (i > 0 and "alterguardian_laser") or "alterguardian_laserempty"
        local x1, z1 = x, z

        trigger_time = (math.max(0, i - 1) * FRAMES)*0.2
        inst:DoTaskInTime(trigger_time, function(inst2,index)
            local fx = SpawnPrefab(prefab)
            fx.caster = inst2
            fx.Transform:SetPosition(x1, 0, z1)
            fx:Trigger(0, targets, skiptoss,false,2,2,2)
            if first then
                ShakeAllCameras(CAMERASHAKE.FULL, .7, .02, .2, target_pos or fx, 30)
            end

            if index%5==0 then
                local light = SpawnPrefab("alter_light")
                light.Transform:SetPosition(x1, 0, z1)
            end
        end,i)
        
    end

    
end


local function FindHolyLightTarget(inst,target)
    local targets = {}
    if target and target:IsValid() then
        table.insert(targets,target)
    end
    local ix, _, iz = inst.Transform:GetWorldPosition()
    for i, p in ipairs(AllPlayers) do
        local dsq_to_player = p:GetDistanceSqToPoint(ix, 0, iz)
        if dsq_to_player < 36*36
            and not p:HasTag("playerghost") and p~=target then
            table.insert(targets,p)
        end
    end
    return targets, next(targets)~=nil        
end



local function SummonHolyLight(inst,target,num,radius)
    if target and target:IsValid() then
        local x, _, z = target.Transform:GetWorldPosition()
        local angle=360*math.random()
        local angle_delta=360/num
        for i=1,num do
            local projectile = SpawnPrefab("alter_light")
            projectile.Transform:SetPosition(x + radius*math.cos(angle*DEGREES), 0, z - radius* math.sin(angle*DEGREES))
            angle = angle + angle_delta
        end
        SpawnPrefab("alter_light").Transform:SetPosition(x, 0, z)
    end
end


local function HolyLightAttack(inst)
    local targets = inst.sg.statemem.targets
    for k,v in pairs(targets) do
        SummonHolyLight(inst,v,3,8)
    end
    inst:DoTaskInTime(1.5,function ()
        for k,v in pairs(targets) do
            SummonHolyLight(inst,v,4,8)
        end
    end)
    inst:DoTaskInTime(3,function ()
        for k,v in pairs(targets) do
            SummonHolyLight(inst,v,6,8)
        end
    end)
end


AddStategraphPostInit("alterguardian_phase3",function (sg)
    sg.events["doattack"].fn = function(inst,data)
        if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy"))
                and (data.target ~= nil and data.target:IsValid()) then
            local dsq_to_target = inst:GetDistanceSqToInst(data.target)
            local hp = inst.components.health:GetPercent()
            if not inst.components.timer:TimerExists("eraser_cd") then
                inst.sg:GoToState("eraserbeam",data.target)
            elseif not inst.components.timer:TimerExists("summon_cd") and dsq_to_target < SUMMON_DSQ then
                inst.sg:GoToState("atk_summon_pre", data.target)
            elseif hp<0.5 and not inst.components.timer:TimerExists("eraser2_cd") and dsq_to_target < SUMMON_DSQ then
                inst.sg:GoToState("eraserflame", data.target)    
            else
                local attack_state = "atk_stab"
                local geyser_pos = inst.components.knownlocations:GetLocation("geyser")
                if not inst.components.timer:TimerExists("traps_cd")
                        and GetTableSize(inst._traps) <= MIN_TRAP_COUNT_FOR_RESPAWN
                        and (geyser_pos == nil
                            or inst:GetDistanceSqToPoint(geyser_pos:Get()) < (TUNING.ALTERGUARDIAN_PHASE3_GOHOMEDSQ / 2)) then
                    attack_state = "atk_traps"
                elseif dsq_to_target > RANGED_ATTACK_DSQ then
                    attack_state = (math.random() > 0.5 and "atk_beam" or "atk_sweep")
                end

                inst.sg:GoToState(attack_state, data.target)
            end
        end
    end
    sg.states.atk_traps.onenter = function(inst, target)
        inst.components.locomotor:StopMoving()

        inst.AnimState:PlayAnimation("attk_skybeam")
        inst.sg.statemem.skybeamanim_playing = true

        inst.components.combat:StartAttack()
    
        if inst.components.health:GetPercent()<0.8 then
            inst.sg.statemem.targets,inst.sg.statemem.shouldholylight = FindHolyLightTarget(inst,target)
        end
        inst.sg:SetTimeout(9)
    end

    local traptimeline = sg.states.atk_traps.timeline    
    table.insert(traptimeline,TimeEvent(45*FRAMES, function(inst)
        if inst.sg.statemem.shouldholylight then
            HolyLightAttack(inst)   
        end     
    end))
    sg.states.death.events["animover"].fn =function(inst)
        if not TheWorld:HasTag("cave") then
            local orb = SpawnPrefab("alterguardian_phase3deadorb")
            orb.Transform:SetPosition(inst.Transform:GetWorldPosition())
        end
        inst:Remove()
    end
end)


AddStategraphState("alterguardian_phase3",State{
    name = "eraserbeam",
    tags = {"attacking", "busy", "canrotate"},

    onenter = function(inst, target)
        inst.Transform:SetEightFaced()
        inst.components.locomotor:StopMoving()

        inst.AnimState:PlayAnimation("idle")

        if inst.components.combat:TargetIs(target) then
            inst.components.combat:StartAttack()
        end
        inst.components.timer:StartTimer("eraser_cd",TUNING.ALTERGUARDIAN_PHASE3_ERASERCOOLDOWN)
        inst:ForceFacePoint(target.Transform:GetWorldPosition())
        inst.sg.statemem.target = target

        inst.sg.statemem.in_eraser = true
        inst.sg:SetTimeout(4)
            --inst.AnimState:SetHaunted(true)
        --inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian3/atk_beam")
    end,

    onupdate = function(inst)
        if inst.sg.statemem.target ~= nil and inst.sg.statemem.target:IsValid() then
            local x, _, z = inst.Transform:GetWorldPosition()
            local x1, y1, z1 = inst.sg.statemem.target.Transform:GetWorldPosition()
            local dx, dz = x1 - x, z1 - z
            if math.abs(anglediff(inst.Transform:GetRotation(), math.atan2(-dz, dx) / DEGREES)) < 45 then
                inst:ForceFacePoint(x1, y1, z1)
                return
            end
        end
    end,

    timeline =
    {   
        TimeEvent(10*FRAMES,function (inst)
            set_lightvalues(inst, 1)
            inst:AddComponent("truedamage")
            inst.components.truedamage:SetBaseDamage(1000)
            inst.components.truedamage:SetOnAttack(DoEraser)
            dowarning(inst)
        end),
        TimeEvent(40*FRAMES,function (inst)
            inst.AnimState:PlayAnimation("attk_beam")
            inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian3/atk_beam")
        end),
        TimeEvent(68*FRAMES, function(inst)
            set_lightvalues(inst, 0.95)
            if inst.sg.statemem.target ~= nil and inst.sg.statemem.target:IsValid() then
                inst.sg.statemem.target_pos = inst.sg.statemem.target:GetPosition()
            end
            inst.sg.statemem.target = nil
        end),
        TimeEvent(72*FRAMES, function(inst)
            local ipos = inst:GetPosition()

            local target_pos = inst.sg.statemem.target_pos
            if target_pos == nil then
                local angle = inst.Transform:GetRotation() * DEGREES
                target_pos = ipos + Vector3(OFFSET * math.cos(angle), 0, -OFFSET * math.sin(angle))
            end
            --inst.components.combat:SetDefaultDamage(100000)
            SpawnEraserBeam(inst, target_pos)

        end),
        TimeEvent(73*FRAMES , laser_sound),

        TimeEvent(41*FRAMES, function(inst) set_lightvalues(inst, 0.9) end),
        TimeEvent(42*FRAMES, function(inst) set_lightvalues(inst, 0.875) end),
        TimeEvent(43*FRAMES, function(inst) set_lightvalues(inst, 0.85) end),
        TimeEvent(44*FRAMES, function(inst) set_lightvalues(inst, 0.825) end),
        TimeEvent(45*FRAMES, function(inst) set_lightvalues(inst, 0.8) end),
        TimeEvent(46*FRAMES, function(inst) set_lightvalues(inst, 0.775) end),
        TimeEvent(47*FRAMES, function(inst) set_lightvalues(inst, 0.75) end),
        TimeEvent(48*FRAMES, function(inst) set_lightvalues(inst, 0.725) end),
        TimeEvent(49*FRAMES, function(inst) set_lightvalues(inst, 0.7) end),
        TimeEvent(50*FRAMES, function(inst) set_lightvalues(inst, 0.675) end),
        TimeEvent(51*FRAMES, function(inst) set_lightvalues(inst, 0.65) end),
        TimeEvent(53*FRAMES, function(inst) set_lightvalues(inst, 0.6) end),
        TimeEvent(54*FRAMES, function(inst) set_lightvalues(inst, 0.575) end),
        TimeEvent(55*FRAMES, function(inst) set_lightvalues(inst, 0.55) end),
        TimeEvent(56*FRAMES, function(inst) set_lightvalues(inst, 0.525) end),
        TimeEvent(57*FRAMES, function(inst) set_lightvalues(inst, 0.5) end),

        TimeEvent(61*FRAMES, function(inst) set_lightvalues(inst, 0.7) end),
        TimeEvent(62*FRAMES, function(inst) set_lightvalues(inst, 0.675) end),
        TimeEvent(63*FRAMES, function(inst) set_lightvalues(inst, 0.65) end),
        TimeEvent(64*FRAMES, function(inst) set_lightvalues(inst, 0.625) end),
        TimeEvent(65*FRAMES, function(inst) set_lightvalues(inst, 0.6) end),


        TimeEvent(72*FRAMES, function(inst) set_lightvalues(inst, 0.7) end),
        TimeEvent(73*FRAMES, function(inst) set_lightvalues(inst, 0.8) end),
        TimeEvent(74*FRAMES, function(inst) set_lightvalues(inst, 0.9) end),
    },

    ontimeout = post_attack_idle,
    onexit = function(inst)
        inst.Transform:SetSixFaced()
        inst:RemoveComponent("truedamage")
        --inst.components.combat:SetDefaultDamage(TUNING.ALTERGUARDIAN_PHASE3_DAMAGE)
    end,
})


AddStategraphState("alterguardian_phase3",State{
    name = "eraserflame",
    tags = {"attacking", "busy", "canrotate"},

    onenter = function(inst, target)
        inst.Transform:SetEightFaced()
        inst.components.locomotor:StopMoving()

        inst.AnimState:PlayAnimation("idle")

        if inst.components.combat:TargetIs(target) then
            inst.components.combat:StartAttack()
        end
        inst.components.timer:StartTimer("eraser2_cd",TUNING.ALTERGUARDIAN_PHASE3_FLAMECOOLDOWN)
        inst:ForceFacePoint(target.Transform:GetWorldPosition())
        inst.sg.statemem.target = target

        inst.sg.statemem.in_eraser = true

        dowarning(inst,true)
        inst.AnimState:SetHaunted(true)

        inst.sg:SetTimeout(8)
    end,

    onupdate = function(inst)
        local target = inst.sg.statemem.target
        if target ~= nil and target:IsValid() and 
            target.components.health and not target.components.health:IsDead() then
            local angle = inst:GetAngleToPoint(target.Transform:GetWorldPosition())
            local x, _, z = inst.Transform:GetWorldPosition()
            local x1, y1, z1 = inst.sg.statemem.target.Transform:GetWorldPosition()
            local dx, dz = x1 - x, z1 - z
            if (dx * dx + dz * dz) < 900 then
                if inst.sg.statemem.dontkeep then
                    local anglediff = angle - inst.Transform:GetRotation()
                    if anglediff > 180 then
                        anglediff = anglediff - 360
                    elseif anglediff < -180 then
                        anglediff = anglediff + 360
                    end
                    if math.abs(anglediff) > maxdeflect then
                        anglediff = math.clamp(anglediff, -maxdeflect, maxdeflect)
                    end
    
                    inst.Transform:SetRotation(inst.Transform:GetRotation() + anglediff)
                else
                    inst.Transform:SetRotation(angle)
                end
                return    
            end
        end    
        if inst.sg.timeout > 0.5 then
            inst.sg:SetTimeout(0.5)
        end    
    end,

    timeline =
    {   
        TimeEvent(40*FRAMES,function (inst)
            inst.Transform:SetFourFaced()
            inst.AnimState:PlayAnimation("attk_swipe")
            inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian3/atk_beam")
        end),
        TimeEvent(45*FRAMES,function (inst)
            inst.sg.statemem.dontkeep = true
        end),
        TimeEvent(60*FRAMES, function(inst)
            local fx = SpawnPrefab("huge_flame_thrower")
            fx.entity:SetParent(inst.entity)
            fx:SetFlamethrowerAttacker(inst)
            inst.hugeflame = fx
        end),


        TimeEvent(31*FRAMES, function(inst) set_lightvalues(inst, 0.9) end),
        TimeEvent(32*FRAMES, function(inst) set_lightvalues(inst, 0.875) end),
        TimeEvent(33*FRAMES, function(inst) set_lightvalues(inst, 0.85) end),
        TimeEvent(34*FRAMES, function(inst) set_lightvalues(inst, 0.825) end),
        TimeEvent(35*FRAMES, function(inst) set_lightvalues(inst, 0.8) end),
        TimeEvent(36*FRAMES, function(inst) set_lightvalues(inst, 0.775) end),
        TimeEvent(37*FRAMES, function(inst) set_lightvalues(inst, 0.75) end),
        TimeEvent(38*FRAMES, function(inst) set_lightvalues(inst, 0.725) end),
        TimeEvent(39*FRAMES, function(inst) set_lightvalues(inst, 0.7) end),
        TimeEvent(40*FRAMES, function(inst) set_lightvalues(inst, 0.675) end),
        TimeEvent(41*FRAMES, function(inst) set_lightvalues(inst, 0.65) end),
        TimeEvent(42*FRAMES, function(inst) set_lightvalues(inst, 0.625) end),
        TimeEvent(43*FRAMES, function(inst) set_lightvalues(inst, 0.6) end),
        TimeEvent(44*FRAMES, function(inst) set_lightvalues(inst, 0.575) end),
        TimeEvent(45*FRAMES, function(inst) set_lightvalues(inst, 0.55) end),
        TimeEvent(46*FRAMES, function(inst) set_lightvalues(inst, 0.525) end),
        TimeEvent(47*FRAMES, function(inst) set_lightvalues(inst, 0.5) end),

        TimeEvent(51*FRAMES, function(inst) set_lightvalues(inst, 0.7) end),
        TimeEvent(52*FRAMES, function(inst) set_lightvalues(inst, 0.675) end),
        TimeEvent(53*FRAMES, function(inst) set_lightvalues(inst, 0.65) end),
        TimeEvent(54*FRAMES, function(inst) set_lightvalues(inst, 0.625) end),
        TimeEvent(55*FRAMES, function(inst) set_lightvalues(inst, 0.6) end),

        TimeEvent(56*FRAMES, function(inst) set_lightvalues(inst, 0.7) end),
        TimeEvent(57*FRAMES, function(inst) set_lightvalues(inst, 0.675) end),
        TimeEvent(58*FRAMES, function(inst) set_lightvalues(inst, 0.65) end),
        TimeEvent(59*FRAMES, function(inst) set_lightvalues(inst, 0.625) end),
        TimeEvent(60*FRAMES, function(inst) set_lightvalues(inst, 0.6) end),
        TimeEvent(61*FRAMES, function(inst) set_lightvalues(inst, 0.7) end),

        TimeEvent(62*FRAMES, function(inst) set_lightvalues(inst, 0.7) end),
        TimeEvent(63*FRAMES, function(inst) set_lightvalues(inst, 0.75) end),
        TimeEvent(64*FRAMES, function(inst) set_lightvalues(inst, 0.8) end),
        TimeEvent(65*FRAMES, function(inst) set_lightvalues(inst, 0.85) end),
        TimeEvent(66*FRAMES, function(inst) set_lightvalues(inst, 0.9) end),
    },

    ontimeout = post_attack_idle,
    onexit = function(inst)
        if inst.hugeflame~=nil then
            inst.hugeflame:KillFX()
            inst.hugeflame = nil
        end
        inst.Transform:SetSixFaced()
        inst.AnimState:SetHaunted(false)
    end,
})
