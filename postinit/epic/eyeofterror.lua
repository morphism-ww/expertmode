local function eyeofterror_should_crazy(inst, health_data)
    if health_data and health_data.newpercent < 0.35 then
        inst.crazy=true
    end
end



AddPrefabPostInit("eyeofterror",function(inst)

    if not TheWorld.ismastersim then return end

    inst._chargedata.mouthchargetimeout = 0.7
    inst.components.lootdropper:SetLoot({ "shieldofterror" })

    inst.components.sleeper:SetResistance(12)

    inst.components.locomotor.walkspeed = 9

    inst:ListenForEvent("healthdelta", eyeofterror_should_crazy)
end)

--------------------------------------------------------------
---
local CHARGE_RANGE_OFFSET = 3 - TUNING.EYEOFTERROR_CHARGE_AOERANGE
local CHARGE_LOOP_TARGET_ONEOF_TAGS = {"tree", "_health"}

local AOE_RANGE_PADDING = 3
local AOE_TARGET_CANT_TAGS = { "INLIMBO", "eyeofterror", "flight", "invisible", "notarget", "noattack" }
local function spawn_ground_fx(inst)
    if not TheWorld.Map:IsVisualGroundAtPoint(inst.Transform:GetWorldPosition()) then
        SpawnPrefab("boss_ripple_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())
    else
        local fx = SpawnPrefab("slide_puff")
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx.Transform:SetScale(1.3, 1.3, 1.3)
    end
end
local COLLIDE_TIME = 3*FRAMES
local FX_TIME = 5*FRAMES
local function get_rng_cooldown(cooldown)
    return GetRandomWithVariance(cooldown, cooldown/3)
end

AddStategraphState("eyeofterror",
State {
        name = "crazycharge_loop",
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
            inst.Physics:SetMotorVelOverride(21, 0, 0)
            inst.sg:SetTimeout(0.7)


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
                inst.sg:GoToState("crazycharge_loop",inst.sg.statemem.target)
            else
                inst.sg:GoToState("charge_pst")
            end
        end,
    })

AddStategraphPostInit("eyeofterror",function(sg)
    sg.states.transform.timeline[5]=
    TimeEvent(30*FRAMES, function(inst)
        local eye_position = inst:GetPosition()
        for i=1,7 do
            local minion_egg = SpawnPrefab("eyeofterror_mini_projectile")
            minion_egg.Transform:SetPosition(eye_position.x, eye_position.y + 1.5, eye_position.z)

            local angle = 360 * math.random()
            minion_egg.Transform:SetRotation(angle)

            angle = -angle * DEGREES
            local radius = minion_egg:GetPhysicsRadius(0) + 5.0
            local angle_vector = Vector3(radius * math.cos(angle), 0, radius * math.sin(angle))

            minion_egg.components.complexprojectile:Launch(eye_position + angle_vector, inst)

            inst.components.commander:AddSoldier(minion_egg)
        end
    end)
    sg.states.charge_pre.events["animover"].fn=function(inst)
        if inst.crazy then
            inst.sg.mem.mouthcharge_count = math.random(6, 8)
            inst.sg:GoToState("crazycharge_loop", inst.sg.statemem.target)
        elseif inst.sg.mem.transformed then
            inst.sg.mem.mouthcharge_count = math.random(4, 6)
            inst.sg:GoToState("mouthcharge_loop", inst.sg.statemem.target)
        else
            inst.sg:GoToState("charge_loop", inst.sg.statemem.target)
        end
    end
    sg.states.charge_pre.onenter=function(inst, target)
        inst.Physics:Stop()

        local cooldown = (inst.crazy and 3) or (inst.sg.mem.transformed and inst._cooldowns.mouthcharge)
            or inst._cooldowns.charge
        inst.components.timer:StartTimer("charge_cd", get_rng_cooldown(cooldown))

        inst.sg.statemem.target = target
        inst.sg.statemem.steering = true

        inst.AnimState:PlayAnimation("charge_pre")

        -- All users of this SG share this sound.
        inst.SoundEmitter:PlaySound("terraria1/eyeofterror/charge_pre_sfx")

        inst.components.stuckdetection:Reset()
    end
    sg.states.spawnminieyes_mouth_loop.onenter=function(inst)
        inst.components.locomotor:Stop()

        inst.AnimState:PlayAnimation("spawn2_loop")

        inst.SoundEmitter:PlaySound(inst._soundpath .. "spawn2_lp")

        inst:RemoveTag("flying")
        inst:PushEvent("on_landed")

        if inst.sg.mem.minieye_spawns == nil then
            inst.sg.mem.minieye_spawns = math.random(3, inst._mouthspawncount)
        end
        inst.sg.mem.minieye_spawns = inst.sg.mem.minieye_spawns - 1

        -- The spit part of the animation is right at the start,
        -- so we can just spawn the projectiles here.
        local eye_position = inst:GetPosition()

        for i=1,3 do
            local minion_egg = SpawnPrefab("eyeofterror_mini_projectile")
            minion_egg.Transform:SetPosition(eye_position.x, eye_position.y + 1.5, eye_position.z)

            local angle = 360 * math.random()
            minion_egg.Transform:SetRotation(angle)

            angle = -angle * DEGREES
            local radius = minion_egg:GetPhysicsRadius(0) + 5.0
            local angle_vector = Vector3(radius * math.cos(angle), 0, radius * math.sin(angle))

            minion_egg.components.complexprojectile:Launch(eye_position + angle_vector, inst)

            inst.components.commander:AddSoldier(minion_egg)
        end
    end
    sg.events["charge"].fn = function(inst)
        if not inst.components.health:IsDead()
                and not inst.components.freezable:IsFrozen()
                and not inst.components.sleeper:IsAsleep()
                and not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("charge_pre", inst.components.combat.target)
        end
    end
end)
----------------------------------------------------------------------
local function TrySpawnMiniEyes(inst)
    if inst.components.timer:TimerExists("spawneyes_cd") or inst.crazy then
        return nil
    end

    return (inst.components.commander:GetNumSoldiers() < inst:GetDesiredSoldiers() and "spawnminieyes")
        or false
end

local CHOMP_ATTACK_DSQ = (TUNING.EYEOFTERROR_ATTACK_RANGE * TUNING.EYEOFTERROR_ATTACK_RANGE) + 0.01
local function TryChompAttack(inst)
    if inst.sg.mem.transformed and not inst.crazy then
        local target = inst.components.combat.target
        if target ~= nil then
            local dsq_to_target = inst:GetDistanceSqToInst(target)
            if dsq_to_target < CHOMP_ATTACK_DSQ then
                return "chomp"
            end
        end
    end

    return false
end

local function TryChargeAttack(inst)
    if not inst.components.timer:TimerExists("charge_cd") then
        local target = inst.components.combat.target
        if target ~= nil then
            local dsq_to_target = inst:GetDistanceSqToInst(target)
            if dsq_to_target > TUNING.EYEOFTERROR_CHARGEMINDSQ and dsq_to_target < TUNING.EYEOFTERROR_CHARGEMAXDSQ then
                return "charge"
            end
        end
    end

    return false
end

local function TryFocusMiniEyesOnTarget(inst)
    if inst.components.timer:TimerExists("focustarget_cd") or inst.crazy
            or not inst.components.combat:HasTarget() then
        return nil
    end

    local num_soldiers = inst.components.commander:GetNumSoldiers()
    return (num_soldiers >= TUNING.EYEOFTERROR_MINGUARDS_PERSPAWN and "focustarget")
        or false
end


AddBrainPostInit("eyeofterrorbrain",function(self)
    function self:ShouldUseSpecialMove()
    self._special_move = TrySpawnMiniEyes(self.inst)
        or TryFocusMiniEyesOnTarget(self.inst)
        or TryChargeAttack(self.inst)
        or TryChompAttack(self.inst)
        or nil
    if self._special_move then
        return true
    else
        return false
    end
end
end)

AddPrefabPostInit("eyemaskhat",function (inst)
    if not TheWorld.ismastersim then return end
    inst.components.armor:InitCondition(2*TUNING.ARMOR_FOOTBALLHAT, 0.85)
    inst.components.equippable.walkspeedmult = 1.1
end)