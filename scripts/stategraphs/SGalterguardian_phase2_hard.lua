require("stategraphs/commonstates")

local actionhandlers = nil

local AOE_RANGE_PADDING = 3
local CHOP_RANGE_DSQ = TUNING.ALTERGUARDIAN_PHASE2_CHOP_RANGE * TUNING.ALTERGUARDIAN_PHASE2_CHOP_RANGE
local SPIN_RANGE_DSQ = TUNING.ALTERGUARDIAN_PHASE2_SPIN_RANGE * TUNING.ALTERGUARDIAN_PHASE2_SPIN_RANGE
local ICE_RANGE_DSQ= 49
local LANCE_RANGE_DSQ=625
local events =
{
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnDeath(),
    CommonHandlers.OnLocomote(false, true),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnSink(),

    EventHandler("doattack", function(inst, data)
        if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy"))
                and (data.target ~= nil and data.target:IsValid()) then
            local dsq_to_target = inst:GetDistanceSqToInst(data.target)

            local can_spin = not inst.components.timer:TimerExists("spin_cd")
            local can_deadspin=not inst.components.timer:TimerExists("deadspin_cd")
            local can_summon = not inst.components.timer:TimerExists("summon_cd")
            local can_spike = not inst.components.timer:TimerExists("spike_cd")
            local can_icespell= not inst.components.timer:TimerExists("icespell_cd")
            local can_wave=not inst.components.timer:TimerExists("wave_cd")
            local function summon_or_lance()
                if math.random()<0.5 then
                    return "icelance"
                else
                    return "atk_summon"
                end
            end
            local function die_or_not()
                if can_deadspin then
                    inst.sg.mem.deadcount=math.random(3,4)
                    return "deadspin_pre"
                elseif can_spin then
                    return "spin_pre"
                end
            end
            local attack_state = (not data.target:IsOnValidGround() and "antiboat_attack")
                or (can_wave and "atk_wave")
                or (can_icespell and dsq_to_target<ICE_RANGE_DSQ and "icespell")
                or dsq_to_target < SPIN_RANGE_DSQ and die_or_not()
                or (can_summon and summon_or_lance())
                or (can_spike and "atk_spike")
                or (dsq_to_target < CHOP_RANGE_DSQ and "atk_chop")
                or nil
            if attack_state ~= nil then
                inst.sg:GoToState(attack_state, data.target)
            end
        end
    end),
}

local function go_to_idle(inst)
    inst.sg:GoToState("idle")
end

local function set_lightvalues(inst, val)
    inst.Light:SetIntensity(0.40 + (0.40 * val * val))
    inst.Light:SetRadius(4 * val)
    inst.Light:SetFalloff(0.85)
end

local function spawn_spintrail(inst)
    local facing_dir = inst.Transform:GetRotation() * DEGREES
    local spawn_pt = inst:GetPosition() --- Vector3(1.5 * math.cos(facing_dir), 0, -1.5 * math.sin(facing_dir))
    SpawnPrefab("alterguardian_spintrail_fx").Transform:SetPosition(spawn_pt:Get())
    SpawnPrefab("mining_moonglass_fx").Transform:SetPosition(spawn_pt:Get())
end

local NUM_SMALLGUARDS = 12
local Z_SPAWN_DIFF = 0.50
local X_SPAWN_DIFF = 1.75 * 2
local function do_gestalt_summon(inst)
    local target = inst.components.combat.target
    if target == nil then
        return
    end

    local tpos = target:GetPosition()
    local ipos = inst:GetPosition()

    local itot_normal, itot_len = (tpos - ipos):GetNormalizedAndLength()
    local itot_perp = Vector3(itot_normal.z, 0, -itot_normal.x)

    local spawn_len = math.max(2, itot_len - 4)
    local spawn_start = ipos + (itot_normal * spawn_len) + (itot_perp * GetRandomWithVariance(0, 0.5))
    for i = 1, NUM_SMALLGUARDS do
        inst:DoTaskInTime((i-1)*3*FRAMES, function(inst2)
            local spawn_pos = spawn_start
            if i ~= 1 then
                -- At each step, go "back" (towards the boss) a little bit, (RoundBiasedUp)
                -- then spawn subsequent objects on opposite sides. (IsNumberEven)
                local num_steps = RoundBiasedUp((i-1) / 2)
                local x_step, z_step = nil, nil
                if IsNumberEven(i) then
                    z_step = -1 * Z_SPAWN_DIFF * num_steps
                    x_step = X_SPAWN_DIFF * num_steps
                else
                    z_step = -1 * Z_SPAWN_DIFF * num_steps
                    x_step = -1 * X_SPAWN_DIFF * num_steps
                end
                spawn_pos = spawn_pos + (itot_normal*z_step) + (itot_perp*x_step)
            end

            local smallguard = SpawnPrefab("smallguard_alterguardian_projectile")
            smallguard.Transform:SetPosition(spawn_pos:Get())
            smallguard:SetTargetPosition(spawn_pos + itot_normal)
        end)
    end
end
local ICE_LANCE_RADIUS=5
local AREAATTACK_MUST_TAGS = { "_combat" }
local AREA_EXCLUDE_TAGS = { "INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost", "brightmareboss" }
local function DoIceLanceAOE(inst, pt, targets)
	inst.components.combat.ignorehitrange = true
	local dist = math.sqrt(inst:GetDistanceSqToPoint(pt))
	local ents = TheSim:FindEntities(pt.x, 0, pt.z, ICE_LANCE_RADIUS, AREAATTACK_MUST_TAGS, AREA_EXCLUDE_TAGS)
	for i, v in ipairs(ents) do
		if not targets[v] and v:IsValid() and not v:IsInLimbo() and
			not (v.components.health ~= nil and v.components.health:IsDead()) and
			inst.components.combat:CanTarget(v)
		then
            local wasfrozen = v.components.freezable ~= nil and v.components.freezable:IsFrozen()
			inst.components.combat:DoAttack(v)
            if v.components.freezable ~= nil then
				v.components.freezable:AddColdness(99,10)   --freezetime:12
            end
            if wasfrozen then
				v:PushEvent("knockback", { knocker = inst, radius = dist + ICE_LANCE_RADIUS })
			end
			targets[v] = true
		end
	end
	inst.components.combat.ignorehitrange = false
end


local function TryWave(inst,angle)
    local position=inst:GetPosition()
    --totalangle=360
    local anglePerWave = 36  --360/15
    local rot = angle
    for i = 1, 10 do
        local offset_direction = Vector3(math.cos(rot*DEGREES), 0, -math.sin(rot*DEGREES)):Normalize()
        local wavepos = position + (offset_direction * 2)
        local wave = SpawnPrefab("lunarwave")
        wave.Transform:SetPosition(wavepos:Get())
        wave.Transform:SetRotation(rot)
        rot = rot + anglePerWave
        wave.Physics:SetMotorVel(12, 0, 0)
    end
end



local SPIN_CANT_TAGS = { "brightmareboss","brightmare","INLIMBO", "FX", "NOCLICK", "playerghost", "flight", "invisible", "notarget", "noattack" }
local SPIN_ONEOF_TAGS = {"_health", "CHOP_workable", "HAMMER_workable", "MINE_workable"}
local SPIN_FX_RATE = 10*FRAMES
local states =
{
    State {
        name = "spawn",
        tags = {"busy", "noaoestun", "noattack", "nofreeze", "nosleep", "nostun" },

        onenter = function(inst)
            inst.AnimState:SetBuild("alterguardian_spawn_death")
            inst.AnimState:SetBankAndPlayAnimation("alterguardian_spawn_death", "phase2_spawn")
            inst.components.health:SetInvincible(true)

            set_lightvalues(inst, 0.1)
        end,

        events =
        {
            EventHandler("animover", go_to_idle),
        },

        timeline =
        {
            TimeEvent(0*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/spawn")
            end),
            TimeEvent(8*FRAMES, function(inst) set_lightvalues(inst, 0.4) end),

            TimeEvent(48*FRAMES, function(inst) set_lightvalues(inst, 0.425) end),
            TimeEvent(49*FRAMES, function(inst) set_lightvalues(inst, 0.45) end),
            TimeEvent(50*FRAMES, function(inst) set_lightvalues(inst, 0.475) end),
            TimeEvent(51*FRAMES, function(inst) set_lightvalues(inst, 0.5) end),
            TimeEvent(52*FRAMES, function(inst) set_lightvalues(inst, 0.525) end),
            TimeEvent(53*FRAMES, function(inst) set_lightvalues(inst, 0.55) end),
            TimeEvent(54*FRAMES, function(inst) set_lightvalues(inst, 0.575) end),
            TimeEvent(55*FRAMES, function(inst) set_lightvalues(inst, 0.6) end),

            TimeEvent(55*FRAMES, function(inst) set_lightvalues(inst, 0.56) end),
            TimeEvent(55*FRAMES, function(inst) set_lightvalues(inst, 0.52) end),
            TimeEvent(55*FRAMES, function(inst) set_lightvalues(inst, 0.48) end),
            TimeEvent(55*FRAMES, function(inst) set_lightvalues(inst, 0.44) end),

            TimeEvent(60*FRAMES, function(inst) set_lightvalues(inst, 0.4) end),
            TimeEvent(61*FRAMES, function(inst) set_lightvalues(inst, 0.45) end),
            TimeEvent(62*FRAMES, function(inst) set_lightvalues(inst, 0.5) end),
            TimeEvent(63*FRAMES, function(inst) set_lightvalues(inst, 0.55) end),
            TimeEvent(64*FRAMES, function(inst) set_lightvalues(inst, 0.6) end),

            TimeEvent(65*FRAMES, function(inst) set_lightvalues(inst, 0.6) end),
            TimeEvent(66*FRAMES, function(inst) set_lightvalues(inst, 0.55) end),
            TimeEvent(67*FRAMES, function(inst) set_lightvalues(inst, 0.5) end),
            TimeEvent(68*FRAMES, function(inst) set_lightvalues(inst, 0.45) end),
            TimeEvent(69*FRAMES, function(inst) set_lightvalues(inst, 0.4) end),

            TimeEvent(70*FRAMES, function(inst) set_lightvalues(inst, 0.45) end),
            TimeEvent(71*FRAMES, function(inst) set_lightvalues(inst, 0.5) end),
            TimeEvent(72*FRAMES, function(inst) set_lightvalues(inst, 0.55) end),
            TimeEvent(73*FRAMES, function(inst) set_lightvalues(inst, 0.575) end),

            TimeEvent(74*FRAMES, function(inst) set_lightvalues(inst, 0.6) end),
            TimeEvent(75*FRAMES, function(inst) set_lightvalues(inst, 0.625) end),
            TimeEvent(76*FRAMES, function(inst) set_lightvalues(inst, 0.65) end),
            TimeEvent(77*FRAMES, function(inst) set_lightvalues(inst, 0.675) end),
            TimeEvent(78*FRAMES, function(inst) set_lightvalues(inst, 0.7) end),
            TimeEvent(79*FRAMES, function(inst) set_lightvalues(inst, 0.725) end),
            TimeEvent(80*FRAMES, function(inst) set_lightvalues(inst, 0.75) end),
            TimeEvent(81*FRAMES, function(inst) set_lightvalues(inst, 0.775) end),
            TimeEvent(82*FRAMES, function(inst) set_lightvalues(inst, 0.8) end),
            TimeEvent(83*FRAMES, function(inst) set_lightvalues(inst, 0.825) end),
            TimeEvent(84*FRAMES, function(inst) set_lightvalues(inst, 0.85) end),
            TimeEvent(85*FRAMES, function(inst) set_lightvalues(inst, 0.875) end),
            TimeEvent(86*FRAMES, function(inst) set_lightvalues(inst, 0.9) end),

            TimeEvent(87*FRAMES, function(inst) set_lightvalues(inst, 0.875) end),
            TimeEvent(88*FRAMES, function(inst) set_lightvalues(inst, 0.85) end),
        },

        onexit = function(inst)
            inst.components.health:SetInvincible(false)
            inst.AnimState:SetBuild("alterguardian_phase2")
            inst.AnimState:SetBankAndPlayAnimation("alterguardian_phase2", "idle")
        end,
    },

    State {
        name = "idle",
        tags = {"idle", "canrotate", "canroll"},

        onenter = function(inst, playanim)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("idle")

            set_lightvalues(inst, 0.9)
        end,

        events =
        {
            EventHandler("animover", go_to_idle),
        },
    },

    State {
        name = "atk_chop",
        tags = {"attack", "busy"},

        onenter = function(inst, target)
            inst.components.locomotor:StopMoving()

            if target ~= nil and target:IsValid() then
                inst:ForceFacePoint(target:GetPosition())
            end

            inst.AnimState:PlayAnimation("attk_chop")

            inst.components.combat:StartAttack()
        end,

        timeline =
        {
            TimeEvent(8*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/scream")
            end),
            TimeEvent(21*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/swhoosh")
            end),
            TimeEvent(22*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/ground_hit")

                ShakeAllCameras(CAMERASHAKE.VERTICAL, .75, 0.1, 0.1, inst, 30)
            end),
            TimeEvent(23*FRAMES, function(inst)
                inst.components.combat:DoAttack()
            end),
        },

        events =
        {
            EventHandler("animover", go_to_idle),
        },
    },

    State {
        name = "atk_spike",
        tags = {"attack", "busy"},

        onenter = function(inst, target)
            inst.components.locomotor:StopMoving()

            inst.components.combat:StartAttack()
            inst.components.timer:StartTimer("spike_cd", 45)

            inst.AnimState:PlayAnimation("attk_stab_pre")
            inst.AnimState:PushAnimation("attk_stab_loop", true)

            inst.sg:SetTimeout(2.25 + math.random() * 0.25)
        end,

        timeline =
        {
            TimeEvent(11*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/atk_spike_pre")
            end),
            TimeEvent(28*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/atk_spike")

                ShakeAllCameras(CAMERASHAKE.FULL, .75, 0.1, 0.1, inst, 50)

                inst.components.combat:DoAttack()
            end),
            TimeEvent(32*FRAMES, function(inst)
                inst:DoSpikeAttack()
                inst:SpawnBarrier()
            end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("atk_spike_pst")
        end,
    },
    State {
        name = "atk_wave",
        tags = {"attack", "busy"},

        onenter = function(inst, target)
            inst.components.locomotor:StopMoving()

            inst.components.combat:StartAttack()
            --inst.components.timer:StartTimer("spike_cd", 40)

            inst.AnimState:PlayAnimation("attk_stab_pre")
            inst.AnimState:PushAnimation("attk_stab_loop", true)

            inst.sg:SetTimeout(5)
        end,

        timeline =
        {
            TimeEvent(11*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/atk_spike_pre")
            end),
            TimeEvent(28*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/atk_spike")

                ShakeAllCameras(CAMERASHAKE.FULL, .75, 0.1, 0.1, inst, 50)
                TryWave(inst,18)
                inst.components.combat:DoAttack()
            end),
            TimeEvent(50*FRAMES, function(inst)
                TryWave(inst,0)
            end),
            TimeEvent(70*FRAMES, function(inst)
                TryWave(inst,18)
            end),
            TimeEvent(90*FRAMES, function(inst)
                TryWave(inst,0)
            end),
            TimeEvent(110*FRAMES, function(inst)
                TryWave(inst,18)
            end),
        },

        ontimeout = function(inst)
            inst.components.timer:StartTimer("wave_cd", 50)
            inst.sg:GoToState("atk_spike_pst")
        end,
    },

    State {
        name = "atk_spike_pst",
        tags = {"attack", "busy"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()

            inst.AnimState:PlayAnimation("attk_stab_pst")
        end,

        events =
        {
            EventHandler("animover", go_to_idle),
        },
    },

    State {
        name = "spin_pre",
        tags = {"busy", "canrotate", "spin"},

        onenter = function(inst, target)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("attk_spin_pre")
            inst.Physics:ClearCollidesWith(COLLISION.WORLD)
            inst.Physics:CollidesWith(COLLISION.GROUND)
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
								inst.components.combat:DoAttack(target)
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
                inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/atk_spin_pre")
            end),
            TimeEvent(32*FRAMES, function(inst)
                inst.components.locomotor:EnableGroundSpeedMultiplier(false)

                local spin_speed = TUNING.ALTERGUARDIAN_PHASE2_SPIN_SPEED
                local target = inst.sg.statemem.target
                if target ~= nil and target:IsValid() and target.components.locomotor ~= nil then
                    spin_speed = math.max(spin_speed, target.components.locomotor:GetRunSpeed() * inst.components.locomotor:GetSpeedMultiplier()+2)
                    spin_speed = math.min(spin_speed, 35)
                end
                inst.sg.statemem.spin_speed = spin_speed
                inst.Physics:SetMotorVelOverride(spin_speed, 0, 0)
            end),
			TimeEvent(35 * FRAMES, function(inst)
				inst.sg.statemem.attack_time = 0
			end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                local loop_data =
                {
                    spin_time_remaining = (inst.sg.timeinstate - 18*FRAMES) % SPIN_FX_RATE,
                    target = inst.sg.statemem.target,
                    speed = inst.sg.statemem.spin_speed,
                    attack_time = inst.sg.statemem.attack_time,
                }
                inst.sg:GoToState("spin_loop", loop_data)
            end ),
        },

        onexit = function(inst)
            inst.Physics:CollidesWith(COLLISION.WORLD)
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            inst.Physics:ClearMotorVelOverride()
            inst.components.locomotor:Stop()
        end,
    },

    State {
        name = "spin_loop",
        tags = {"busy", "canrotate", "spin"},

        onenter = function(inst, data)
            inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)

            inst.AnimState:PlayAnimation("attk_spin_loop", true)

            inst.sg.statemem.loop_len = inst.AnimState:GetCurrentAnimationLength()
            local num_loops = math.random(TUNING.ALTERGUARDIAN_PHASE2_SPINMIN, TUNING.ALTERGUARDIAN_PHASE2_SPINMAX)
            inst.sg:SetTimeout(inst.sg.statemem.loop_len * num_loops)

			inst.sg.statemem.attack_time = data.attack_time or 0
            inst.sg.statemem.target = data.target
            inst.sg.statemem.speed = data.speed
            inst.sg.statemem.initial_spin_fx_time = data.spin_time_remaining

            inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/atk_spin_LP","spin_loop")

            inst.Physics:SetMotorVelOverride(data.speed, 0, 0)
        end,

        onupdate = function(inst, dt)
            -- If our original target is still alive, chase them down.
            -- Otherwise, we'll just go in the direction we were facing until we finish.
            if inst.sg.statemem.target ~= nil then
                if inst.sg.statemem.target:IsValid() and
                        (inst.sg.statemem.target.components.health ~= nil
                        and not inst.sg.statemem.target.components.health:IsDead()) then
                    inst:ForceFacePoint(inst.sg.statemem.target.Transform:GetWorldPosition())
                else
                    inst.sg.statemem.target = nil
                end
            end

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
								inst.components.combat:DoAttack(target)
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

        ontimeout = function(inst)
            inst.sg.statemem.exit_by_timeout = true
            inst.sg:GoToState("spin_pst", inst.sg.statemem.speed)
        end,

        onexit = function(inst)
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            inst.Physics:ClearMotorVelOverride()
            inst.components.locomotor:Stop()

            -- We may be exiting this state via death, freezing, etc.
            if not inst.sg.statemem.exit_by_timeout then
                inst.SoundEmitter:KillSound("spin_loop")
            end
        end,
    },
    State {
        name = "deadspin_pre",
        tags = {"busy", "canrotate", "spin"},

        onenter = function(inst, target)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("attk_spin_pre")
            inst:spark()
            inst.Physics:ClearCollidesWith(COLLISION.WORLD)
            inst.Physics:CollidesWith(COLLISION.GROUND)
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
								inst.components.combat:DoAttack(target)
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
                inst:spark()
                inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/atk_spin_pre")
            end),
            TimeEvent(32*FRAMES, function(inst)
                inst.components.locomotor:EnableGroundSpeedMultiplier(false)

                inst.Physics:SetMotorVelOverride(18, 0, 0)
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
                    go_to_idle(inst)
                end        
            end ),
        },

        onexit = function(inst)
            
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            inst.Physics:ClearMotorVelOverride()
            inst.components.locomotor:Stop()
        end,
    },
    State {
        name = "deadspin_loop",
        tags = {"busy", "canrotate", "spin"},

        onenter = function(inst, data)
            inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)

            inst.AnimState:PlayAnimation("attk_spin_loop", true)

            inst.sg.statemem.loop_len = inst.AnimState:GetCurrentAnimationLength()
            local num_loops = 2
            inst.sg:SetTimeout(inst.sg.statemem.loop_len * num_loops)

			inst.sg.statemem.attack_time = data.attack_time or 0
            inst.sg.statemem.target = data.target
            inst.sg.statemem.speed = 20
            inst.sg.statemem.initial_spin_fx_time = data.spin_time_remaining

            inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/atk_spin_LP","spin_loop")

            inst.Physics:SetMotorVelOverride(16, 0, 0)
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
								inst.components.combat:DoAttack(target)
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
            TimeEvent(30*FRAMES, function(inst)
                inst:spark()
            end),
        },
        ontimeout = function(inst)
            inst.sg.statemem.exit_by_timeout = true
            if inst.sg.mem.deadcount and inst.sg.mem.deadcount>0 then
                inst.sg.mem.deadcount=inst.sg.mem.deadcount-1
                inst.sg:GoToState("deadspin_pre", inst.sg.statemem.target)
            else
                inst.components.timer:StartTimer("deadspin_cd", 60)
                inst.Physics:CollidesWith(COLLISION.WORLD)
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
    },
    State {
        name = "spin_pst",
        tags = {"busy", "spin"},

        onenter = function(inst, speed)
            inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)
            inst.Physics:SetMotorVelOverride(speed, 0, 0)

            inst.AnimState:PlayAnimation("attk_spin_pst")

			inst.components.timer:StopTimer("spin_cd")
            inst.components.timer:StartTimer("spin_cd", TUNING.ALTERGUARDIAN_PHASE2_SPINCD)
        end,

        timeline =
        {
            TimeEvent(8*FRAMES, function(inst)
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
								inst.components.combat:DoAttack(target)
							end
						end
                    end
                end
            end),
            TimeEvent(11*FRAMES, function(inst)
                inst.sg.statemem._spin_cleaned_up = true
                inst.Physics:ClearMotorVelOverride()
                inst.components.locomotor:EnableGroundSpeedMultiplier(true)
                inst.components.locomotor:Stop()
            end),
            TimeEvent(10*FRAMES, function(inst)
                inst.sg.statemem._spin_sound_stopped = true
                inst.SoundEmitter:KillSound("spin_loop")
            end),
        },

        events =
        {
            EventHandler("animover", go_to_idle),
        },

        onexit = function(inst)
            if not inst.sg.statemem._spin_cleaned_up then
                inst.Physics:ClearMotorVelOverride()
                inst.components.locomotor:EnableGroundSpeedMultiplier(true)
                inst.components.locomotor:Stop()
            end

            if not inst.sg.statemem._spin_sound_stopped then
                inst.SoundEmitter:KillSound("spin_loop")
            end
        end,
    },

    State {
        name = "atk_summon",
        tags = {"attack", "busy"},

        onenter = function(inst)
            inst.components.locomotor:Stop()

            inst.components.combat:StartAttack()

            inst.AnimState:PlayAnimation("attk_chop")

            if inst.sg.mem.num_summons == nil then
                inst.components.timer:StartTimer("summon_cd", TUNING.ALTERGUARDIAN_PHASE2_SUMMONCOOLDOWN)
                inst.sg.mem.num_summons = 3

                inst.sg.mem.summon_fx = SpawnPrefab("alterguardian_summon_fx")
                inst.sg.mem.summon_fx.Transform:SetScale(1.3, 1.3, 1.3)
                inst.sg.mem.summon_fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
            else
                inst.sg.mem.num_summons = inst.sg.mem.num_summons - 1
            end
        end,

        timeline =
        {
            TimeEvent(0*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/summon")
            end),
            TimeEvent(18*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/swhoosh")
            end),
            TimeEvent(22*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/ground_hit")

                ShakeAllCameras(CAMERASHAKE.VERTICAL, .75, 0.1, 0.1, inst, 30)
            end),
            TimeEvent(22*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/spell_cast")
            end),
            TimeEvent(23*FRAMES, function(inst)
                inst.components.combat:DoAttack()
            end),
            TimeEvent(28*FRAMES, do_gestalt_summon),
            TimeEvent(32*FRAMES, function(inst)
                if inst.sg.mem.num_summons > 0 then
                    inst.sg.statemem.natural_exit = true
                    inst.sg:GoToState("atk_summon")
                end
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg.statemem.natural_exit = true

                inst.sg.mem.num_summons = nil
                inst.sg:GoToState("idle")
            end),
        },

        onexit = function(inst)
            if (not inst.sg.statemem.natural_exit or inst.sg.mem.num_summons == nil)
                    and inst.sg.mem.summon_fx ~= nil and inst.sg.mem.summon_fx:IsValid() then
                inst.sg.mem.summon_fx:PushEvent("endloop")
                inst.sg.mem.summon_fx = nil
            end
        end,
    },

    State {
        name = "antiboat_attack",
        tags = {"attack", "busy"},

        onenter = function(inst, target)
            inst.components.locomotor:StopMoving()

            inst.components.combat:StartAttack()

            inst.AnimState:PlayAnimation("attk_stab_pre")
            inst.AnimState:PushAnimation("attk_stab_loop", true)

            inst.sg.statemem.target = target
            inst.sg.statemem.stop_tracking = false

            inst.sg:SetTimeout(2.25 + math.random() * 0.5)
        end,

        onupdate = function(inst)
            -- Track the target's position, so long as they exist and they are over a platform.
            if inst.sg.statemem.stop_tracking then return end
            local target = inst.sg.statemem.target
            if target and target:IsValid() then
                local platform = target and target:GetCurrentPlatform()
                if platform then
                    inst.sg.statemem.target_platform = platform
                    inst.sg.statemem.target_position = target:GetPosition()
                end
            end
        end,

        timeline =
        {
            TimeEvent(11*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/atk_spike_pre")
                TryWave(inst,0)
                inst.components.combat:DoAttack()
                inst.sg.statemem.stop_tracking = true
            end),
            TimeEvent(28*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/atk_spike")
                inst.components.combat:DoAttack()
                ShakeAllCameras(CAMERASHAKE.FULL, .75, 0.1, 0.1, inst, 50)
            end),
            TimeEvent(43*FRAMES, function(inst)
                -- If we didn't find a target position by about the time the stab ends,
                if inst.sg.statemem.target_position == nil then
                    inst.sg:GoToState("atk_spike_pst")
                end
            end),
        },

        ontimeout = function(inst)
            local tpos = inst.sg.statemem.target_position
            if tpos ~= nil then
                local target_platform = inst.sg.statemem.target_platform
                if target_platform ~= nil and target_platform:IsValid() then
                    ShakeAllCamerasOnPlatform(CAMERASHAKE.VERTICAL, .75, 0.1, 0.1, target_platform)
                    inst.SoundEmitter:PlaySoundWithParams("moonstorm/creatures/boss/alterguardian2/spike", { intensity = 0.2*math.random() })

                    local dsq = target_platform:GetDistanceSqToPoint(tpos:Get())
                    if dsq < TUNING.GOOD_LEAKSPAWN_PLATFORM_RADIUS then
                        target_platform:PushEvent("spawnnewboatleak", {pt = tpos, leak_size = "med_leak", playsoundfx = true})
                        SpawnPrefab("mining_moonglass_fx").Transform:SetPosition(tpos:Get())
                    end
                    target_platform.components.health:DoDelta(-150)
                end
            end

            inst.sg:GoToState("atk_spike_pst")
        end,
    },
    State {
        name = "icespell",
        tags = {"attack", "busy"},

        onenter = function(inst, target)
            inst.components.locomotor:StopMoving()

            if target ~= nil and target:IsValid() then
                inst:ForceFacePoint(target:GetPosition())
            end

            inst.AnimState:PlayAnimation("attk_chop")

            inst.components.combat:StartAttack()
            --inst.startcastspell(inst,true)
            --inst.components.timer:StopTimer("icespell_cd")
            inst.components.timer:StartTimer("icespell_cd", 20)
            if not inst.components.timer:TimerExists("casting_timer") then
                inst.startcastspell(inst,inst.dofreezecast)
                if inst.dofreezecast then
                    inst.isfreezecast = true
                    inst.components.timer:StartTimer("casting_timer",TUNING.CRABKING_CAST_TIME_FREEZE - math.floor(inst.countgems(inst).yellow/2))
                else
                    inst.components.timer:StartTimer("casting_timer",TUNING.CRABKING_CAST_TIME - math.floor(inst.countgems(inst).yellow/2))
                end
            end

            inst.dofreezecast = nil
        end,

        onupdate = function(inst)
            if inst.components.timer:TimerExists("casting_timer") then
                local totaltime = TUNING.CRABKING_CAST_TIME - math.floor(inst.countgems(inst).yellow/2)
                if inst.isfreezecast then
                    totaltime = TUNING.CRABKING_CAST_TIME_FREEZE - math.floor(inst.countgems(inst).yellow/2)
                end
            end
        end,

        timeline =
        {
            TimeEvent(8*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/scream")
            end),
            TimeEvent(21*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/swhoosh")
            end),
            TimeEvent(22*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/ground_hit")

                ShakeAllCameras(CAMERASHAKE.VERTICAL, .75, 0.1, 0.1, inst, 30)
            end),
        },
        onexit = function(inst)
            if not inst.sg.statemem.keepcast then
                inst:DoTaskInTime(0,function()
                    inst.endcastspell(inst, inst.isfreezecast)
                end)
                inst.isfreezecast = nil
            end
        end,
        events =
        {
            EventHandler("animover", function(inst)
                inst.sg.statemem.keepcast = true
                inst.sg:GoToState("icespell")
            end),
            EventHandler("timerdone", function(inst,data)
                if data.name == "casting_timer" then
                    inst.components.timer:StopTimer("spin_cd")
                    inst.sg:GoToState("idle")
                end
            end)
        },
    },
    State {
        name = "icelance",
        tags = {"attack", "busy"},

        onenter = function(inst)
            inst.components.locomotor:Stop()

            inst.components.combat:StartAttack()

            inst.AnimState:PlayAnimation("attk_chop")
            local target=inst.components.combat.target
            if target ~= nil and target:IsValid() then
				inst.sg.statemem.target = target
				inst.sg.statemem.targetpos = target:GetPosition()
                inst:ForceFacePoint(inst.sg.statemem.targetpos)
			end

            if inst.sg.mem.num_summons == nil then
                inst.components.timer:StartTimer("summon_cd", TUNING.ALTERGUARDIAN_PHASE2_SUMMONCOOLDOWN)
                inst.sg.mem.num_summons = 4

                --inst.sg.mem.summon_fx = SpawnPrefab("alterguardian_summon_fx")
                --inst.sg.mem.summon_fx.Transform:SetScale(1.3, 1.3, 1.3)
                --inst.sg.mem.summon_fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
            else
                inst.sg.mem.num_summons = inst.sg.mem.num_summons - 1
            end
        end,

        timeline =
        {
            TimeEvent(0*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/summon")
            end),
            TimeEvent(18*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/swhoosh")
                inst.sg.statemem.target = nil
                local p = inst.sg.statemem.targetpos
                if p ~= nil then
                    p.y=0
                else
                    p = Vector3(0, 0, 0)
					inst.sg.statemem.targetpos = p
                end
                inst.sg.statemem.ping = SpawnPrefab("deerclops_icelance_ping_fx")
				inst.sg.statemem.ping.Transform:SetPosition(p:Get())
            end),
            TimeEvent(22*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/ground_hit")

                ShakeAllCameras(CAMERASHAKE.VERTICAL, .75, 0.1, 0.1, inst, 30)
            end),
            TimeEvent(22*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/spell_cast")
            end),
            TimeEvent(30*FRAMES, function(inst)
                inst.sg.statemem.ping:KillFX()
				inst.sg.statemem.ping = nil

				local lance = SpawnPrefab("deerclops_impact_circle_fx")
				lance.Transform:SetPosition(inst.sg.statemem.targetpos:Get())
				inst.sg.statemem.targets = {}
				inst.components.combat:SetDefaultDamage(100)
				DoIceLanceAOE(inst, inst.sg.statemem.targetpos, inst.sg.statemem.targets)
            end),
            TimeEvent(32*FRAMES, function(inst)
                if inst.sg.mem.num_summons > 0 then
                    inst.sg.statemem.natural_exit = true
                    inst.sg:GoToState("icelance")
                end
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg.statemem.natural_exit = true

                inst.sg.mem.num_summons = nil
                inst.sg:GoToState("idle")
            end),
        },
        onexit = function(inst)
			if inst.sg.statemem.ping ~= nil then
				inst.sg.statemem.ping:KillFX()
			end
		end
    },
    State {
        name = "death",
        tags = {"busy", "dead"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()

            inst.AnimState:SetBuild("alterguardian_spawn_death")
            inst.AnimState:SetBankAndPlayAnimation("alterguardian_spawn_death", "phase2_death")
            inst.AnimState:PushAnimation("phase2_death_idle", true)

            RemovePhysicsColliders(inst)

            inst.sg:SetTimeout(10)

            inst:SetNoMusic(true)
        end,

        timeline =
        {
            TimeEvent(0*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/death")
            end),
            TimeEvent(5*FRAMES, function(inst)
                inst.SoundEmitter:KillSound("idle_LP")
            end),
            TimeEvent(44*FRAMES, function(inst)
                if not inst._loot_dropped then
                    inst._loot_dropped = true

                    inst.components.lootdropper:DropLoot(inst:GetPosition())
                end

                ShakeAllCameras(CAMERASHAKE.FULL, 0.5, 0.1, 0.7, inst, 60)
            end),

            TimeEvent(16*FRAMES, function(inst) set_lightvalues(inst, 0.6) end),
            TimeEvent(17*FRAMES, function(inst) set_lightvalues(inst, 0.675) end),
            TimeEvent(18*FRAMES, function(inst) set_lightvalues(inst, 0.750) end),
            TimeEvent(19*FRAMES, function(inst) set_lightvalues(inst, 0.825) end),
            TimeEvent(20*FRAMES, function(inst) set_lightvalues(inst, 0.9) end),

            TimeEvent(21*FRAMES, function(inst) set_lightvalues(inst, 0.75) end),
            TimeEvent(22*FRAMES, function(inst) set_lightvalues(inst, 0.6) end),

            TimeEvent(23*FRAMES, function(inst) set_lightvalues(inst, 0.625) end),
            TimeEvent(24*FRAMES, function(inst) set_lightvalues(inst, 0.688) end),
            TimeEvent(25*FRAMES, function(inst) set_lightvalues(inst, 0.756) end),
            TimeEvent(26*FRAMES, function(inst) set_lightvalues(inst, 0.825) end),
            TimeEvent(27*FRAMES, function(inst) set_lightvalues(inst, 0.9) end),

            TimeEvent(29*FRAMES, function(inst) set_lightvalues(inst, 0.8) end),
            TimeEvent(30*FRAMES, function(inst) set_lightvalues(inst, 0.6) end),
            TimeEvent(31*FRAMES, function(inst) set_lightvalues(inst, 0.5) end),
            TimeEvent(32*FRAMES, function(inst) set_lightvalues(inst, 0.6) end),
            TimeEvent(33*FRAMES, function(inst) set_lightvalues(inst, 0.85) end),
            TimeEvent(34*FRAMES, function(inst) set_lightvalues(inst, 0.9) end),

            TimeEvent(35*FRAMES, function(inst) set_lightvalues(inst, 0.875) end),
            TimeEvent(36*FRAMES, function(inst) set_lightvalues(inst, 0.775) end),
            TimeEvent(37*FRAMES, function(inst) set_lightvalues(inst, 0.7) end),
            TimeEvent(38*FRAMES, function(inst) set_lightvalues(inst, 0.65) end),
            TimeEvent(39*FRAMES, function(inst) set_lightvalues(inst, 0.55) end),

            TimeEvent(45*FRAMES, function(inst) set_lightvalues(inst, 0) end),
        },

        ontimeout = function(inst)
            inst:PushEvent("phasetransition")
        end,
    },
}

local function play_foley(inst)
    inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/foley")
end

local function play_step(inst)
    inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian2/step")
end

CommonStates.AddWalkStates(states,
{
    starttimeline = {
        TimeEvent(3*FRAMES, play_foley ),
    },

    walktimeline = {
        TimeEvent(0*FRAMES, play_step ),
        TimeEvent(0*FRAMES, PlayFootstep ),

        TimeEvent(3*FRAMES, play_foley ),

        TimeEvent(22*FRAMES, play_foley ),
        TimeEvent(24*FRAMES, play_step ),

        TimeEvent(10*FRAMES, play_foley ),

        TimeEvent(36*FRAMES, play_step ),
        TimeEvent(36*FRAMES, PlayFootstep ),


        TimeEvent(48*FRAMES, play_step ),
        TimeEvent(48*FRAMES, PlayFootstep ),
    },

    endtimeline = {
        TimeEvent(0*FRAMES, play_step ),
        TimeEvent(0*FRAMES, PlayFootstep ),

        TimeEvent(10*FRAMES, play_foley ),

        TimeEvent(12*FRAMES, play_step ),
        TimeEvent(12*FRAMES, PlayFootstep ),

        TimeEvent(16*FRAMES, play_foley ),

        TimeEvent(18*FRAMES, play_step ),
        TimeEvent(18*FRAMES, PlayFootstep ),
    },
})

CommonStates.AddHitState(states)
CommonStates.AddFrozenStates(states)
CommonStates.AddSinkAndWashAshoreStates(states, {washashore = "hit"})

return StateGraph("alterguardian_phase2_hard", states, events, "idle", actionhandlers)
