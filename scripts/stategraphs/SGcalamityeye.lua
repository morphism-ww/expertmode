require("stategraphs/commonstates")
local events =
{

    EventHandler("death", function(inst) inst.sg:GoToState("death") end),

    EventHandler("locomote", function(inst)
        local is_moving = inst.sg:HasStateTag("moving")
        local is_idling = inst.sg:HasStateTag("idle")

        local should_move = inst.components.locomotor:WantsToMoveForward()
        
        if is_moving and not should_move then
            inst.sg:GoToState("idle")
        elseif is_idling and should_move then
            
            inst.sg:GoToState("moving")
        end
    end),
    EventHandler("charge",function (inst)
        if not inst.components.health:IsDead()
                and not inst.sg:HasStateTag("busy") then
            inst.sg.mem.crazy = inst.components.health:GetPercent()<=0.5
            inst.sg.mem.skullcharge = inst.components.health:GetPercent()<=0.3
            inst.sg:GoToState("charge_pre", inst.components.combat.target)
        end
    end)
}


local function TrytwinFire(inst)
    if inst.twinflame~=nil then
        inst.twinflame:KillFX()
        
    end
    local fx = SpawnPrefab("hell_flamethrower_fx")
    fx.entity:SetParent(inst.entity)
    fx:SetFlamethrowerAttacker(inst)
    inst.twinflame = fx
end

local CHARGE_RANGE_OFFSET = 3 - TUNING.EYEOFTERROR_CHARGE_AOERANGE
local CHARGE_LOOP_TARGET_ONEOF_TAGS = { "_health"}

local AOE_RANGE_PADDING = 3
local AOE_TARGET_CANT_TAGS = { "INLIMBO", "eyeofterror","flight", "invisible", "notarget", "noattack" }

local COLLIDE_TIME = 3*FRAMES
local FX_TIME = 6*FRAMES

local states =
{
    State{
        name = "idle",
        tags = { "idle", "canrotate" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            
            inst.AnimState:PlayAnimation("walk_loop")
        end,
        events =
        {
            EventHandler("animover", function (inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
    State {
        name = "flyaway",
        tags = {"busy", "charge", "leaving", "noaoestun",  "nostun" },

        onenter = function(inst)
            inst.components.locomotor:Stop()

            inst.AnimState:PlayAnimation("flyaway")
            inst.SoundEmitter:PlaySound(inst._soundpath .. "flyaway")

            inst.sg.mem.wantstoleave = false
            inst.sg.mem.leaving = true
        end,

        timeline =
        {
            TimeEvent(23*FRAMES, function(inst)
                inst.sg:AddStateTag("flight")
                inst.sg:AddStateTag("noattack")
                inst.components.health:SetInvincible(true)
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					

					inst.sg.mem.leaving = false
					inst.components.health:SetInvincible(false)
					inst:Remove()
				end
            end),
        },
    },
    State{
        name = "moving",
        tags = {"moving","canrotate"},

        onenter = function(inst)
            local target = inst.components.combat.target
            inst.AnimState:PushAnimation("walk_loop",false)
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
            if target and target:IsValid() then
                local dir = inst:GetAngleToPoint(target.Transform:GetWorldPosition())
                inst.Transform:SetRotation(dir)
            end
			inst.components.locomotor:WalkForward()
        end,
        ontimeout = function (inst)
            inst.sg:GoToState("moving")
        end
    },
    State {
        name = "arrive",
        tags = { "busy", "charge", "flight", "nostun" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:Show("ball_eye")
            inst.AnimState:PlayAnimation("arrive")

            local arrive_fx = SpawnPrefab("eyeofterror_arrive_fx")
            arrive_fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
            
            inst.components.health:SetInvincible(true)
        end,

        timeline =
        {
            TimeEvent(122*FRAMES, function(inst)
                inst.sg:RemoveStateTag("flight")
                inst.sg:RemoveStateTag("noattack")
                inst.components.health:SetInvincible(false)
            end),
        },


        events =
        {
            EventHandler("animover", function (inst)
                inst.AnimState:Hide("ball_eye")
                inst.sg:GoToState("taunt")
            end),
        },


        onexit = function(inst)
            inst.components.health:SetInvincible(false)
        end,
    },

    State {
        name = "taunt",
        tags = { "busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")

            --inst.SoundEmitter:PlaySound(inst._soundpath .. "taunt_roar")
        end,


        events =
        {
            EventHandler("animover", function (inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "charge_pre",
        tags = {"busy", "canrotate", "charge"},

        onenter = function(inst, target)
            inst.Physics:Stop()

            inst.sg.statemem.target = target
			inst.sg.statemem.steering = true

            inst.AnimState:PlayAnimation("charge_pre")

            -- All users of this SG share this sound.
            inst.SoundEmitter:PlaySound("terraria1/eyeofterror/charge_pre_sfx")

			inst.sg:SetTimeout(0.7)
            inst.components.locomotor:SetStrafing(false)
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
			TimeEvent(14 * FRAMES, function(inst)
				inst.sg.statemem.steering = false
			end),
        },

        ontimeout = function (inst)
            inst.sg.mem.mouthcharge_count = (inst.sg.mem.crazy and 2 or 0) + math.random(2,3)
            if inst.sg.mem.crazy then
                inst._tail:set(true)
            end
            
            inst.sg:GoToState("mouthcharge_loop", inst.sg.statemem.target)
        end,
    },

    

    State {
        name = "mouthcharge_loop",
        tags = {"busy", "canrotate", "charge","longattack"},

        onenter = function(inst, target)

            inst.SoundEmitter:PlaySound("terraria1/robo_eyeofterror2/charge")

            inst.components.locomotor:Stop()

            
            inst.AnimState:PlayAnimation("charge_loop", true)
            inst.sg.statemem.target = target

            
            inst.Physics:SetMotorVelOverride(inst.sg.mem.crazy and 32 or 25, 0, 0)
            local timeout = (inst.sg.mem.crazy and 0.6 or 1) + 0.4*math.random()
            inst.sg:SetTimeout(timeout)

            inst.sg.statemem.collisiontime = 0
            inst.sg.statemem.fxtime = 0
            inst.sg.statemem.target = target
            
        end,

        onupdate = function(inst, dt)
            local rot = inst.Transform:GetRotation()
            if inst.sg.statemem.collisiontime <= 0 then
				--assert(TUNING.EYEOFTERROR_CHARGE_AOERANGE <= inst.components.combat.hitrange)
                local x,y,z = inst.Transform:GetWorldPosition()
				local theta = rot * DEGREES
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
            if inst.sg.statemem.fxtime <= 0 and inst.sg.mem.skullcharge then
                local proj = SpawnPrefab("hellblasts")
            
                proj.Transform:SetPosition(inst.Transform:GetWorldPosition())
                proj:Trigger(rot)

                inst.sg.statemem.fxtime = FX_TIME
            end
            inst.sg.statemem.fxtime = inst.sg.statemem.fxtime - dt
        end,

        onexit = function(inst)
            inst.Physics:ClearMotorVelOverride()

            inst:ClearRecentlyCharged()

            inst.components.locomotor:Stop()

            inst._tail:set(false)
            
        end,

        ontimeout = function(inst)
            

            inst.sg.mem.mouthcharge_count = (inst.sg.mem.mouthcharge_count == nil and 0)
                or inst.sg.mem.mouthcharge_count - 1
            
            inst.sg:GoToState("charge_pst")
        end,
    },

    State {
        name = "charge_pst",
        tags = {"busy", "canrotate", "charge"},

        onenter = function(inst, target)
            inst.components.locomotor:Stop()
            
            inst.AnimState:PlayAnimation("charge_pst")
            -- All users of this SG share this sound.
            inst.SoundEmitter:PlaySound("terraria1/eyeofterror/charge_pst_sfx")

			if inst.sg.mem.mouthcharge_count ~= nil and inst.sg.mem.mouthcharge_count > 0 then
				inst.sg.statemem.mouthcharge = true
				if target ~= nil and target:IsValid() then
					inst.sg.statemem.target = inst.components.stuckdetection:IsStuck() and inst.components.combat.target or target
				else
					inst.components.combat:TryRetarget()
					inst.sg.statemem.target = inst.components.combat.target
				end
			end

            if inst.sg.statemem.target ~= nil and inst.sg.statemem.target:IsValid() then
				inst:ForceFacePoint(inst.sg.statemem.target.Transform:GetWorldPosition())
			end

            inst.sg:SetTimeout(0.1)
        end,
        ontimeout = function (inst)
            if inst.sg.statemem.mouthcharge then
                if inst.sg.mem.crazy then
                    inst._tail:set(true)
                end
                inst.sg:GoToState("mouthcharge_loop",inst.sg.statemem.target)
            else
                inst.components.locomotor:SetStrafing(true)
                if math.random() < 0.4 then
                    -- Try a target switch after finishing a charge move
                    --inst.components.combat:DropTarget()

                    inst.sg:GoToState("taunt")
                else
                    inst.sg:GoToState("idle")
                end        
                
            end    
        end
    },    
    State {
        name = "Xcharge_loop",
        tags = {"busy", "canrotate", "charge","longattack"},

        onenter = function(inst, target)

            inst.SoundEmitter:PlaySound("terraria1/robo_eyeofterror2/charge")

            inst.components.locomotor:Stop()

            
            --inst.AnimState:PlayAnimation("charge_loop", true)

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
            inst.Physics:SetMotorVelOverride(18, 0, 0)
            inst.sg:SetTimeout(2)


            inst.sg.statemem.shoottime = 0
            --inst.sg.statemem.fxtime = 0
            inst.sg.statemem.target = target
           
        end,

        onupdate = function(inst, dt)
            if inst.sg.statemem.shoottime<=0 then
                inst.sg.statemem.shoottime = 0.4
                local x,y,z = inst.Transform:GetWorldPosition()
                local proj = SpawnPrefab("darkball_projectile1")

                proj.Transform:SetPosition(x, 0, z)
                if inst.sg.statemem.target then
                    proj.components.linearprojectile:LineShoot(inst.sg.statemem.target:GetPosition(),inst)
                end    
                
           
                
            else
                inst.sg.statemem.shoottime = inst.sg.statemem.shoottime -dt
            end    
            --inst.sg.statemem.fxtime = inst.sg.statemem.fxtime - dt
        end,

        onexit = function(inst)
            inst.Physics:ClearMotorVelOverride()

            inst:ClearRecentlyCharged()

            inst.components.locomotor:Stop()

        end,

        ontimeout = function(inst)
            
            inst.sg.mem.mouthcharge_count = (inst.sg.mem.mouthcharge_count == nil and 0)
                or inst.sg.mem.mouthcharge_count - 1
            if inst.sg.mem.mouthcharge_count ~= nil and inst.sg.mem.mouthcharge_count > 0 then
                inst.sg:GoToState("Xcharge_loop",inst.sg.statemem.target)
            else
                
                inst.sg:GoToState("idle")
            end
        end,
    },
    State {
        name = "chargeflame_loop",
        tags = {"busy", "canrotate", "charge"},

        onenter = function(inst, target)

            --inst.SoundEmitter:PlaySound(inst._soundpath .. "charge")

            inst.components.locomotor:Stop()
           
            inst.AnimState:PlayAnimation("charge_loop", true)

            inst.Physics:SetMotorVelOverride(12, 0, 0)

            inst.sg:SetTimeout(1)

            if target == nil or not target:IsValid() then
                inst.components.combat:TryRetarget()
                target = inst.components.combat.target
            end
            if target ~= nil and target:IsValid() then
                inst:ForceFacePoint(target.Transform:GetWorldPosition())
            end

            inst.sg.statemem.target = target
            
            TrytwinFire(inst)
        end,


        onexit = function(inst)
            

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
                if inst.twinflame~=nil then
                    inst.twinflame:KillFX()
                    inst.twinflame = nil
                end
                inst.sg:GoToState("idle")
            end
        end,
    },
    State{
        name = "death",
        tags = { "busy","death" },

        onenter = function(inst)
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:Hide("mouth")
            
            
            inst.AnimState:PlayAnimation("death")
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(inst:GetPosition())
        end,

        
    }
}

return StateGraph("calamityeye", states, events, "idle")