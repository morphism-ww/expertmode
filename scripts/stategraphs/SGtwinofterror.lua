require("stategraphs/commonstates")

local actionhandlers =
{
}

local function PlaySpeechOnPlayerTarget(inst, speech_line_name)
    -- We don't want both twins playing speech lines,
    -- so we have a simple toggle set on the prefab.
    if inst._nospeech then
        return
    end

    -- Make our combat target speak.
    local target = inst.components.combat.target

    -- If we don't have a player combat target, find a nearby player.
    if not target or not target:HasTag("player") then
        local x, y, z = inst.Transform:GetWorldPosition()
        target = FindClosestPlayerInRangeSq(x, y, z, 324, true)
    end

    if target ~= nil and target.components.talker ~= nil and target:HasTag("player") then
        target.components.talker:Say(GetString(target, speech_line_name))
    end
end

local events =
{
    CommonHandlers.OnLocomote(false, true),
    CommonHandlers.OnSleepEx(),
    CommonHandlers.OnWakeEx(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),

    EventHandler("doattack", function(inst)
        if inst.components.health ~= nil and not inst.components.health:IsDead()
                and (not inst.sg:HasStateTag("busy") ) then---or inst.sg:HasStateTag("hit"))
            local target=inst.components.combat.target
            if not inst.sg.mem.transformed then
                inst.sg:GoToState("atk_shoot", target)
            elseif inst.twin1 then
                inst.sg:GoToState("quickshoot", target)
            else
                inst.sg:GoToState("charge_pre", target)
            end
        end
    end),

    EventHandler("charge", function(inst)
        if not inst.components.health:IsDead()---main ai
                and not inst.components.freezable:IsFrozen()
                and not inst.components.sleeper:IsAsleep()
                and not inst.sg:HasStateTag("busy") then
            local target=inst.components.combat.target
            if inst.sg.mem.transformed and inst.twin2 and not inst.components.timer:TimerExists("flame_cd") then
                inst.sg:GoToState("chargeflame_pre", target)
            elseif inst.sg.mem.transformed and inst.twin1 then
                inst.sg:GoToState("mouthshoot_pre", target)
            else
                inst.sg:GoToState("charge_pre", target)
            end
        end
    end),
    EventHandler("health_transform", function(inst)
        if not inst.sg.mem.transformed and not inst.sg.mem.wantstoleave then
            if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
                inst.sg:GoToState("transform")
            elseif not inst.sg:HasStateTag("transform") then
                inst.sg.mem.wantstotransform = true
            end
        end
    end),

    EventHandler("leave", function(inst)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
            inst.sg:GoToState("flyaway")
        elseif not inst.sg:HasStateTag("leaving") then
            inst.sg.mem.wantstoleave = true
        end
    end),

    EventHandler("arrive", function(inst)
        inst.sg:GoToState("arrive")
    end),

    EventHandler("flyback", function(inst)
        inst.sg:GoToState("flyback")
    end),
}

local function go_to_idle(inst)
    inst.sg:GoToState("idle")
end

local function lower_flying_creature(inst)
    inst:RemoveTag("flying")
    inst:PushEvent("on_landed")
end

local function raise_flying_creature(inst)
    inst:AddTag("flying")
    inst:PushEvent("on_no_longer_landed")
end

local function spawn_ground_fx(inst)
    if not TheWorld.Map:IsVisualGroundAtPoint(inst.Transform:GetWorldPosition()) then
        SpawnPrefab("boss_ripple_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())
    else
        local fx = SpawnPrefab("slide_puff")
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx.Transform:SetScale(1.3, 1.3, 1.3)
    end
end

local CHARGE_RANGE_OFFSET = 3 - TUNING.EYEOFTERROR_CHARGE_AOERANGE
local CHARGE_LOOP_TARGET_ONEOF_TAGS = {"tree", "_health"}

local AOE_RANGE_PADDING = 3
local AOE_TARGET_CANT_TAGS = { "INLIMBO", "eyeofterror", "flight", "invisible", "notarget", "noattack" }

local function ShareTargetFn(dude)
    return dude:HasTag("eyeofterror")
end
local function DoEpicScare(inst, duration)
    inst.components.epicscare:Scare(duration or 5)
    local x,y,z=inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, 24,{"_health"},nil)
    for i,v in ipairs(ents) do
        if (v.twin1 or v.twin2) and not v.components.health:IsDead() then
            v.components.sleeper:WakeUp()
        end
    end
    inst.components.combat:ShareTarget(inst.components.combat.target, 36, ShareTargetFn, 8)
end

local function get_rng_cooldown(cooldown)
    return GetRandomWithVariance(cooldown, cooldown/3)
end



local function shoot(inst,target)
    if not target or not target:IsValid() then return end
    local laser=SpawnPrefab("twin_laser")
    if inst.twin2 then laser=SpawnPrefab("twin_flame_projectile") end
    --laser.components.projectile.owner=inst

    local x, y, z = inst.Transform:GetWorldPosition()
    laser.Transform:SetPosition(x,y,z)
    laser.components.projectile:Throw(inst, target, inst)
end

local function TrytwinFire(inst)
    local fx = SpawnPrefab("twin_flamethrower_fx")
    fx.entity:SetParent(inst.entity)
    fx:SetFlamethrowerAttacker(inst)
    fx:DoTaskInTime(2.5, function()
        if fx then
            fx:KillFX()
            fx = nil
        end
    end)
end

local COLLIDE_TIME = 3*FRAMES
local FX_TIME = 5*FRAMES

local states =
{
	State{
		name = "standby",
		tags = { "busy" },

		onenter = function(inst)
			inst.sg.mem.wantstoleave = false
			inst.sg.mem.sleeping = false
		end,
	},

    State {
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            if inst.sg.mem.wantstoleave then
                inst.sg:GoToState("flyaway")
            elseif inst.sg.mem.wantstotransform then
                inst.sg:GoToState("transform")
            else
                inst.AnimState:PlayAnimation("idle")
                inst.SoundEmitter:PlaySound(inst._soundpath .. "mouthbreathing")
            end
        end,

        events =
        {
            EventHandler("animover", go_to_idle),
        },
    },

    State {
        name = "taunt",
        tags = { "busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")

            inst.SoundEmitter:PlaySound(inst._soundpath .. "taunt_roar")
        end,

        timeline =
        {
            TimeEvent(18*FRAMES, function(inst)
                DoEpicScare(inst, 2)
            end),
        },

        events =
        {
            EventHandler("animover", go_to_idle),
        },
    },

    State {
        name = "charge_pre",
        tags = {"busy", "canrotate", "charge"},

        onenter = function(inst, target)
            inst.Physics:Stop()

            local cooldown = (inst.sg.mem.transformed and inst._cooldowns.mouthcharge)
                or inst._cooldowns.charge
            inst.components.timer:StartTimer("charge_cd", get_rng_cooldown(cooldown))

            inst.sg.statemem.target = target
			inst.sg.statemem.steering = true

            inst.AnimState:PlayAnimation("charge_pre")

            -- All users of this SG share this sound.
            inst.SoundEmitter:PlaySound("terraria1/eyeofterror/charge_pre_sfx")

			inst.components.stuckdetection:Reset()
        end,

        onupdate = function(inst)
			if inst.sg.statemem.steering and inst.sg.statemem.target ~= nil then
				if inst.sg.statemem.target:IsValid() then
					inst:ForceFacePoint(inst.sg.statemem.target.Transform:GetWorldPosition())
				else
					inst.sg.statemem.target = nil
				end
			end
        end,

        timeline =
        {
            TimeEvent(11 * FRAMES, function(inst)
				--normal: stop tracking early
				inst.sg.statemem.steering = inst.sg.mem.transformed
            end),
			TimeEvent(25 * FRAMES, function(inst)
				--transformed: stop tracking 8 frames b4 dash
				inst.sg.statemem.steering = false
			end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.sg.mem.transformed then
                    inst.sg.mem.mouthcharge_count =math.random(6,8)
                    inst.sg:GoToState("mouthcharge_loop", inst.sg.statemem.target)
                else
                    inst.sg.mem.charge_count =math.random(3,4)
                    inst.sg:GoToState("charge_loop", inst.sg.statemem.target)
                end
            end),
        },
    },

    State {
        name = "charge_loop",
        tags = {"busy", "canrotate", "charge"},

        onenter = function(inst, target)
            inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)

            inst.AnimState:PlayAnimation("charge_loop", true)
            inst.SoundEmitter:PlaySound(inst._soundpath .. "charge_eye")
            inst.Physics:SetMotorVelOverride(inst._chargedata.eyechargespeed, 0, 0)

            inst.sg:SetTimeout(1)---inst._chargedata.eyechargetimeout
            inst.sg.statemem.collisiontime = 0
            inst.sg.statemem.fxtime = 0
            inst.sg.statemem.target = target
            if target ~= nil and target:IsValid() then
                inst:ForceFacePoint(target.Transform:GetWorldPosition())
            end
        end,

        onupdate = function(inst, dt)
            if inst.sg.statemem.collisiontime <= 0 then
				--assert(TUNING.EYEOFTERROR_CHARGE_AOERANGE <= inst.components.combat.hitrange)
                local x,y,z = inst.Transform:GetWorldPosition()
				local theta = inst.Transform:GetRotation() * DEGREES
				x = x + math.cos(theta) * CHARGE_RANGE_OFFSET
				z = z - math.sin(theta) * CHARGE_RANGE_OFFSET
				local ents = TheSim:FindEntities(x, y, z, TUNING.EYEOFTERROR_CHARGE_AOERANGE + AOE_RANGE_PADDING, nil, AOE_TARGET_CANT_TAGS, CHARGE_LOOP_TARGET_ONEOF_TAGS)
                for _, ent in ipairs(ents) do
					if ent:IsValid() then
						local range = TUNING.EYEOFTERROR_CHARGE_AOERANGE + ent:GetPhysicsRadius(0)
						if ent:GetDistanceSqToPoint(x, y, z) < range * range then
							inst:OnCollide(ent)
						end
					end
                end

                inst.sg.statemem.collisiontime = COLLIDE_TIME
            end
            inst.sg.statemem.collisiontime = inst.sg.statemem.collisiontime - dt

            if inst.sg.statemem.fxtime <= 0 then
                spawn_ground_fx(inst)

                inst.sg.statemem.fxtime = FX_TIME
            end
            inst.sg.statemem.fxtime = inst.sg.statemem.fxtime - dt
        end,

        onexit = function(inst)
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)

            inst.Physics:ClearMotorVelOverride()

            inst.components.locomotor:Stop()

            inst:ClearRecentlyCharged()
        end,

        ontimeout = function(inst)
            inst.sg.mem.charge_count = (inst.sg.mem.charge_count == nil and 0)
                or inst.sg.mem.charge_count - 1

			inst.sg:GoToState("charge_pst", inst.sg.statemem.target)
        end,
    },

    State {
        name = "charge_pst",
        tags = {"busy", "canrotate", "charge"},

        onenter = function(inst,target)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("charge_pst")

            -- All users of this SG share this sound.
            inst.SoundEmitter:PlaySound("terraria1/eyeofterror/charge_pst_sfx")
            if inst.sg.mem.charge_count ~= nil and inst.sg.mem.charge_count > 0 then
				inst.sg.statemem.charge = true
				if target ~= nil and target:IsValid() then
					inst.sg.statemem.target = inst.components.stuckdetection:IsStuck() and inst.components.combat.target or target
				else
					inst.components.combat:TryRetarget()
					inst.sg.statemem.target = inst.components.combat.target
				end
			end
        end,
        onupdate = function(inst)
			if inst.sg.statemem.steering and inst.sg.statemem.target ~= nil then
				if inst.sg.statemem.target:IsValid() then
					inst:ForceFacePoint(inst.sg.statemem.target.Transform:GetWorldPosition())
				else
					inst.sg.statemem.target = nil
				end
			end
		end,
        timeline =
        {
			TimeEvent(3 * FRAMES, function(inst)
				inst.sg.statemem.steering = inst.sg.statemem.mouthcharge
			end),
			TimeEvent(13 * FRAMES, function(inst)
				--transformed: stop tracking 4 frames before dash
				inst.sg.statemem.steering = false
			end),
            TimeEvent(17*FRAMES, function(inst)
				if inst.sg.statemem.charge then
                    inst.sg:GoToState("charge_loop", inst.sg.statemem.target)
                end
            end),
        },
        events =
        {
            EventHandler("animover", function(inst)
                if math.random() < inst._chargedata.tauntchance then
                    -- Try a target switch after finishing a charge move

                    inst.sg:GoToState("taunt")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State {
        name = "mouthcharge_loop",
        tags = {"busy", "canrotate", "charge"},

        onenter = function(inst, target)

            inst.SoundEmitter:PlaySound(inst._soundpath .. "charge")

            inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)

            inst.AnimState:PlayAnimation("charge_loop", true)

            if inst.sg.mem.mouthcharge_count ~= nil and inst.sg.mem.mouthcharge_count > 0 then
				inst.sg.statemem.mouthcharge = true
				if target ~= nil and target:IsValid() then
					inst.sg.statemem.target = target
				else
					inst.components.combat:TryRetarget()
					inst.sg.statemem.target = inst.components.combat.target
				end
			end
            if target ~= nil and target:IsValid() then
                inst:ForceFacePoint(target.Transform:GetWorldPosition())
            end
            inst.Physics:SetMotorVelOverride(27, 0, 0)
            inst.sg:SetTimeout(0.6)


            inst.sg.statemem.collisiontime = 0
            inst.sg.statemem.fxtime = 0
            inst.sg.statemem.target = target
        end,

        onupdate = function(inst, dt)
            if inst.sg.statemem.collisiontime <= 0 then
				--assert(TUNING.EYEOFTERROR_CHARGE_AOERANGE <= inst.components.combat.hitrange)
                local x,y,z = inst.Transform:GetWorldPosition()
				local theta = inst.Transform:GetRotation() * DEGREES
				x = x + math.cos(theta) * CHARGE_RANGE_OFFSET
				z = z - math.sin(theta) * CHARGE_RANGE_OFFSET
				local ents = TheSim:FindEntities(x, y, z, TUNING.EYEOFTERROR_CHARGE_AOERANGE + AOE_RANGE_PADDING, nil, AOE_TARGET_CANT_TAGS, CHARGE_LOOP_TARGET_ONEOF_TAGS)
                for _, ent in ipairs(ents) do
					if ent:IsValid() then
						local range = TUNING.EYEOFTERROR_CHARGE_AOERANGE + ent:GetPhysicsRadius(0)
						if ent:GetDistanceSqToPoint(x, y, z) < range * range then
							inst:OnCollide(ent)
						end
					end
                end

                inst.sg.statemem.collisiontime = COLLIDE_TIME
            end
            inst.sg.statemem.collisiontime = inst.sg.statemem.collisiontime - dt

            if inst.sg.statemem.fxtime <= 0 then
                spawn_ground_fx(inst)

                inst.sg.statemem.fxtime = FX_TIME
            end
            inst.sg.statemem.fxtime = inst.sg.statemem.fxtime - dt
        end,

        onexit = function(inst)
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)

            inst.Physics:ClearMotorVelOverride()

            inst.components.locomotor:Stop()

            inst:ClearRecentlyCharged()
        end,

        ontimeout = function(inst)
            inst.sg.mem.mouthcharge_count = (inst.sg.mem.mouthcharge_count == nil and 0)
                or inst.sg.mem.mouthcharge_count - 1
            if inst.sg.mem.mouthcharge_count ~= nil and inst.sg.mem.mouthcharge_count > 0 then
                inst.sg:GoToState("mouthcharge_loop",inst.sg.statemem.target)
            else
                inst.sg:GoToState("charge_pst")
            end
        end,
    },

    State {
        name = "mouthshoot_pre",
        tags = {"busy", "canrotate", "charge"},

        onenter = function(inst, target)
            inst.Physics:Stop()

            local cooldown = inst._cooldowns.mouthcharge

            inst.components.timer:StartTimer("charge_cd", get_rng_cooldown(cooldown))

            inst.sg.statemem.target = target

            inst.AnimState:PlayAnimation("charge_pre")

            -- All users of this SG share this sound.
            inst.SoundEmitter:PlaySound("terraria1/eyeofterror/charge_pre_sfx")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/charge")

        end,

        onupdate = function(inst)
            local target = inst.sg.statemem.target
            if target and target:IsValid() then
                inst:ForceFacePoint(target.Transform:GetWorldPosition())
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg.mem.mouthcharge_count=math.random(10,14)
                inst.sg:GoToState("mouthshoot_loop", inst.sg.statemem.target)
            end),
        },
    },
    State {
        name = "mouthshoot_loop",
        tags = {"busy", "canrotate", "charge"},

        onenter = function(inst, target)

            inst.SoundEmitter:PlaySound(inst._soundpath .. "charge")

            inst.AnimState:PlayAnimation("charge_loop")

            if target == nil or not target:IsValid() then
                inst.components.combat:TryRetarget()
                target = inst.components.combat.target
            end
            inst.sg.statemem.target=target
        end,

		timeline =
        {
			TimeEvent(FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/laser")
                shoot(inst,inst.sg.statemem.target)
			end),
        },

        onupdate = function(inst)
            local target = inst.sg.statemem.target
            if target and target:IsValid() then
                inst:ForceFacePoint(target.Transform:GetWorldPosition())
            end
        end,

        events =
        {
            EventHandler("animover", function(inst)
            inst.sg.mem.mouthcharge_count = (inst.sg.mem.mouthcharge_count == nil and 0)
                or (inst.sg.mem.mouthcharge_count - 1 )
                if inst.sg.mem.mouthcharge_count ~= nil and inst.sg.mem.mouthcharge_count > 0 then
					inst.sg:GoToState("mouthshoot_loop",inst.sg.statemem.target)
				else
					inst.sg:GoToState("mouthshoot_pst")
				end
            end),
        },
    },
    State {
        name = "quickshoot",
        tags = { "busy", "canrotate" },

        onenter = function(inst, target)

            inst.SoundEmitter:PlaySound(inst._soundpath .. "charge")

            inst.AnimState:PlayAnimation("charge_loop")

            if target == nil or not target:IsValid() then
                inst.components.combat:TryRetarget()
                target = inst.components.combat.target
            end
            inst.Physics:SetMotorVel(8,0,0)
            inst.sg.statemem.target=target
            inst.sg:SetTimeout(0.5)
        end,

        timeline = {
            TimeEvent(0, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/laser")
                shoot(inst, inst.sg.statemem.target)
            end),
            TimeEvent(4*FRAMES, function(inst)
                --inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/laser")
                shoot(inst, inst.sg.statemem.target)
            end),
            TimeEvent(8*FRAMES, function(inst)
                --inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/laser")
                shoot(inst, inst.sg.statemem.target)
            end),
        },
        onupdate = function(inst)
            local target = inst.sg.statemem.target
            if target and target:IsValid() then
                inst:ForceFacePoint(target.Transform:GetWorldPosition())
            end
        end,
        ontimeout = function(inst)
            inst.sg:GoToState("mouthshoot_pst")
            --inst.sg:GoToState("mouthshoot_pst")
        end,
    },
    State {
        name = "mouthshoot_pst",
        tags = {"busy", "canrotate", "charge"},

        onenter = function(inst, target)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("charge_pst")

            -- All users of this SG share this sound.
            inst.SoundEmitter:PlaySound("terraria1/eyeofterror/charge_pst_sfx")

            inst.sg.statemem.target = target
        end,

        events = {
            EventHandler("animover", function(inst)
                if math.random() < inst._chargedata.tauntchance then
                    inst.components.timer:StopTimer("runaway_blocker")
                    inst.components.timer:StartTimer("runaway_blocker", 1)
                    -- Try a target switch after finishing a charge move

                    inst.sg:GoToState("taunt")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        }
    },
    State {
        name = "atk_shoot",
        tags = {"busy", "canrotate"},

        onenter = function(inst, target)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("spawn")

            -- All users of this SG share this sound.
            inst.SoundEmitter:PlaySound(inst._soundpath .. "charge_eye")
            inst.sg.statemem.target = target

        end,

        timeline =
        {
			TimeEvent(0, function(inst)
				if inst.twin1 then
					inst.SoundEmitter:PlaySound("dontstarve/creatures/deerclops/laser")
                end
                shoot(inst,inst.sg.statemem.target)
			end),
        },
        onupdate = function(inst)
            local target = inst.sg.statemem.target
            if target and target:IsValid() then
                inst:ForceFacePoint(target.Transform:GetWorldPosition())
            end
        end,
        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
    State {
        name = "chargeflame_pre",
        tags = {"busy", "canrotate", "charge"},

        onenter = function(inst, target)
            inst.Physics:Stop()

            local cooldown = inst._cooldowns.mouthcharge*2

            inst.components.timer:StartTimer("flame_cd", get_rng_cooldown(cooldown))

            inst.sg.statemem.target = target
			inst.sg.statemem.steering = true

            inst.AnimState:PlayAnimation("charge_pre")

            -- All users of this SG share this sound.
            inst.SoundEmitter:PlaySound("terraria1/eyeofterror/charge_pre_sfx")

			inst.components.stuckdetection:Reset()
        end,

        onupdate = function(inst)
			if inst.sg.statemem.steering and inst.sg.statemem.target ~= nil then
				if inst.sg.statemem.target:IsValid() then
					inst:ForceFacePoint(inst.sg.statemem.target.Transform:GetWorldPosition())
				else
					inst.sg.statemem.target = nil
				end
			end
        end,

        timeline =
        {
            TimeEvent(11 * FRAMES, function(inst)
				--normal: stop tracking early
				inst.sg.statemem.steering = inst.sg.mem.transformed
            end),
			TimeEvent(25 * FRAMES, function(inst)
				--transformed: stop tracking 8 frames b4 dash
				inst.sg.statemem.steering = false
			end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg.mem.mouthcharge_count = math.random(6, 7)
                inst.sg:GoToState("chargeflame_loop", inst.sg.statemem.target)
            end),
        },
    },
    State {
        name = "chargeflame_loop",
        tags = {"busy", "canrotate", "charge"},

        onenter = function(inst, target)

            inst.SoundEmitter:PlaySound(inst._soundpath .. "charge")

            inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)

            inst.AnimState:PlayAnimation("charge_loop", true)

            inst.Physics:SetMotorVelOverride(12, 0, 0)

            inst.sg:SetTimeout(0.8)

            if target == nil or not target:IsValid() then
                inst.components.combat:TryRetarget()
                target = inst.components.combat.target
            end
            if target ~= nil and target:IsValid() then
                inst:ForceFacePoint(target.Transform:GetWorldPosition())
            end

            inst.sg.statemem.target = target
        end,
        timeline={
            TimeEvent(1*FRAMES,function(inst)
                TrytwinFire(inst)
            end),
        },

        onexit = function(inst)
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)

            inst.Physics:ClearMotorVelOverride()

            inst.components.locomotor:Stop()

            inst:ClearRecentlyCharged()
        end,

        ontimeout = function(inst)
            inst.sg.mem.mouthcharge_count = (inst.sg.mem.mouthcharge_count == nil and 0)
                or inst.sg.mem.mouthcharge_count - 1
            if inst.sg.mem.mouthcharge_count ~= nil and inst.sg.mem.mouthcharge_count > 0 then
                inst.sg:GoToState("chargeflame_loop",inst.sg.statemem.target)
            else
                inst.sg:GoToState("charge_pst")
            end
        end,
    },
    State {
        name = "transform",
        tags = { "busy", "noaoestun", "nofreeze", "nosleep", "nostun" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("transform")
            inst.AnimState:Show("mouth")
            inst.AnimState:Show("ball_mouth")
        end,

        timeline =
        {
            TimeEvent(9*FRAMES, lower_flying_creature),
            TimeEvent(29*FRAMES, raise_flying_creature),
            TimeEvent(30*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(inst._soundpath .. "taunt_epic")
            end),
            TimeEvent(33*FRAMES, DoEpicScare),
        },

        events =
        {
            CommonHandlers.OnNoSleepAnimOver("idle"),
        },

        onexit = function(inst)
            inst.sg.mem.transformed = true
            inst.sg.mem.wantstotransform = false
            inst.AnimState:Hide("eye")
            inst.AnimState:Hide("ball_eye")

            raise_flying_creature(inst)
        end,
    },

    State {
        name = "arrive_delay",
        tags = { "busy", "charge", "flight", "noaoestun", "noattack", "nofreeze", "nosleep", "nostun" },

        onenter = function(inst)
            inst.components.locomotor:Stop()

            inst.sg:SetTimeout(10*FRAMES)
            inst.components.health:SetInvincible(true)
            inst:Hide()
        end,

        ontimeout = function(inst)
            inst:PushEvent("arrive")
        end,

        onexit = function(inst)
            inst:Show()
            inst.components.health:SetInvincible(false)
        end,
    },

    State {
        name = "arrive",
        tags = { "busy", "charge", "flight", "noaoestun", "noattack", "nofreeze", "nosleep", "nostun" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("arrive")

            local arrive_fx = SpawnPrefab("eyeofterror_arrive_fx")
            arrive_fx.Transform:SetPosition(inst.Transform:GetWorldPosition())

            inst.components.health:SetInvincible(true)
        end,

        timeline =
        {
            TimeEvent(36*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(inst._soundpath .. "arrive")
            end),
            TimeEvent(44*FRAMES, function(inst)
                PlaySpeechOnPlayerTarget(inst, "ANNOUNCE_EYEOFTERROR_ARRIVE")
            end),
            TimeEvent(122*FRAMES, function(inst)
                inst.sg:RemoveStateTag("flight")
                inst.sg:RemoveStateTag("noattack")
                inst.components.health:SetInvincible(false)
            end),
        },

        events =
        {
            CommonHandlers.OnNoSleepAnimOver("taunt"),
        },

        onexit = function(inst)
            inst.components.health:SetInvincible(false)
        end,
    },
    State {
        name = "death",
        tags = { "busy" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            RemovePhysicsColliders(inst)
			inst:AddTag("NOCLICK")

            if not inst.sg.mem.transformed then
                inst.AnimState:Show("mouth")
                inst.AnimState:Show("ball_mouth")
                inst.sg.mem.transformed = true
                inst.components.combat:SetRange(24)
            end

            inst.AnimState:PlayAnimation("death")

            inst.SoundEmitter:PlaySound(inst._soundpath .. "death")
        end,

        timeline =
        {
            TimeEvent(26*FRAMES, DoEpicScare),
            TimeEvent(31*FRAMES, lower_flying_creature),
            TimeEvent(36*FRAMES, function(inst)
				if inst.persists then
					inst.persists = false
					inst.components.lootdropper:DropLoot(inst:GetPosition())
				end
                ShakeAllCameras(CAMERASHAKE.VERTICAL, 0.5, 0.15, 0.1, inst, 40)
				inst:PushEvent("forgetme")
            end),
			TimeEvent(5, ErodeAway),
        },

        events =
        {
            EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst:PushEvent("turnoff_terrarium")
				end
            end),
        },

		onexit = function(inst)
			--Should NOT happen!
			inst:RemoveTag("NOCLICK")
		end,
    },

    State {
        name = "flyaway",
        tags = {"busy", "charge", "leaving", "noaoestun", "nofreeze", "nosleep", "nostun" },

        onenter = function(inst)
            inst.components.locomotor:Stop()

            inst.AnimState:PlayAnimation("flyaway")
            inst.SoundEmitter:PlaySound(inst._soundpath .. "flyaway")


            inst.sg.mem.leaving = true
        end,

        timeline =
        {
            TimeEvent(23*FRAMES, function(inst)

                inst.sg:AddStateTag("flight")
                inst.sg:AddStateTag("noattack")
                inst.components.health:SetInvincible(true)
            end),
            TimeEvent(24*FRAMES, function(inst)
                PlaySpeechOnPlayerTarget(inst, "ANNOUNCE_EYEOFTERROR_FLYAWAY")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
                    inst.sg.mem.wantstoleave = false
					inst.sg.mem.sleeping = false        -- Clean up after the "gotosleep" sleepex listener, since we're doing something weird here.

					inst.sg.mem.leaving = false
					inst.components.health:SetInvincible(false)
					inst:PushEvent("finished_leaving")
				end
            end),
        },

        onexit = function(inst)
            inst.sg.mem.leaving = false
            inst.components.health:SetInvincible(false)
        end,
    },

    State {
        name = "flyback_delay",
        tags = { "busy", "charge", "flight", "noaoestun", "noattack", "nofreeze", "nosleep", "nostun" },

        onenter = function(inst)
            inst.components.locomotor:Stop()

            inst.sg:SetTimeout(10*FRAMES)
            inst.components.health:SetInvincible(true)
            inst:Hide()
        end,

        ontimeout = function(inst)
            inst:PushEvent("flyback")
        end,

        onexit = function(inst)
            inst:Show()
            inst.components.health:SetInvincible(false)
        end,
    },

    State {
        name = "flyback",
        tags = { "busy", "charge", "flight", "noaoestun", "noattack", "nofreeze", "nosleep", "nostun" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("flyback")

            local pos = inst:GetPosition()
            inst.components.knownlocations:RememberLocation("spawnpoint", pos)

            inst:FlybackHealthUpdate()

            inst.SoundEmitter:PlaySound(inst._soundpath .. "flyback")

            inst.components.health:SetInvincible(true)
        end,


        timeline =
        {
            TimeEvent(22*FRAMES, function(inst)
                PlaySpeechOnPlayerTarget(inst, "ANNOUNCE_EYEOFTERROR_FLYBACK")
            end),
            TimeEvent(25*FRAMES, function(inst)
                inst.sg:RemoveStateTag("flight")
                inst.sg:RemoveStateTag("noattack")
                inst.components.health:SetInvincible(false)
            end),
        },

        events =
        {
            CommonHandlers.OnNoSleepAnimOver("taunt"),
        },

        onexit = function(inst)
            inst.components.health:SetInvincible(false)
        end,
    },
}

CommonStates.AddHitState(states)

CommonStates.AddWalkStates(states)
CommonStates.AddFrozenStates(states, lower_flying_creature, raise_flying_creature)
CommonStates.AddSleepExStates(states,
{
    starttimeline =
    {
        TimeEvent(56*FRAMES, lower_flying_creature),
    },
    waketimeline =
    {
        TimeEvent(35*FRAMES, raise_flying_creature),
    },
},
{
    onsleep = function(inst)
        inst.SoundEmitter:PlaySound(inst._soundpath .. "sleep_pre")
    end,
    onsleeping = function(inst)
        inst.SoundEmitter:PlaySound(inst._soundpath .. "sleep_lp", "sleep_loop")
    end,
    onexitsleeping = function(inst)
        inst.SoundEmitter:KillSound("sleep_loop")
    end,
    onexitwake = raise_flying_creature,
})

return StateGraph("twinofterror", states, events, "idle", actionhandlers)
