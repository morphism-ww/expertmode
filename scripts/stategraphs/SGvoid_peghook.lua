require("stategraphs/commonstates")
local events = {
    --CommonHandlers.OnAttacked(),
	CommonHandlers.OnDeath(),
    CommonHandlers.OnLocomote(true,false),
	EventHandler("doattack", function(inst, data)
		if not inst.components.health:IsDead() and (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then
			if inst:AbleAbility("spit") then
				inst.sg:GoToState("attack_spit", data.target)
            elseif inst:AbleAbility("cursed_spit") then
                inst.sg:GoToState("cursed_spit", data.target)
            else
				inst.sg:GoToState("attack", data.target)
			end
		end
	end),
    EventHandler("fossilized",function (inst)
        if not inst.components.health:IsDead() then
            inst.sg:GoToState("fossilized")
        end
    end)
}

local function idleonanimover(inst)
    if inst.AnimState:AnimDone() then
        inst.sg:GoToState("idle")
    end
end


local function ProjectileSpit(inst,target_pos)
    local target = inst.components.combat.target
    if target then
    	local spit = SpawnPrefab("gelblob_proj")
        --[[local tx,ty,tz = target.Transform:GetWorldPosition()
        local x,y,z = inst.Transform:GetWorldPosition()
    	spit.Transform:SetPosition(x,y,z)
        local desired_horizontal_distance = Metric2(x,z,tx,tz)
        local min_speed = spit.components.complexprojectile:CalculateMinimumSpeedForDistance(desired_horizontal_distance)
    	spit.components.complexprojectile:SetHorizontalSpeed(1.5*(min_speed or 20))]]
        spit.Transform:SetPosition(inst.Transform:GetWorldPosition())
        spit.thrower = inst
    	spit.components.complexprojectile:Launch(target_pos, inst)
    end
end

local function CurseFireSpit(inst,target)
    if not target:IsValid() then return end


    local proj = SpawnPrefab("cursefire_projectile")
    
    --proj.components.projectile.owner=inst
    proj.components.projectile:SetLaunchOffset(Vector3(0.2,0.5,0))

    local x, y, z = inst.Transform:GetWorldPosition()
    proj.Transform:SetPosition(x,y,z)
    proj.components.projectile:Throw(inst, target, inst)
end


local states = {
    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, start_anim)
            inst.AnimState:PlayAnimation("idle_loop")
            inst.components.locomotor:StopMoving()            
        end,

        events = {EventHandler("animover",idleonanimover)},
    },
    State {
		name = "taunt",
        tags = {"busy", "taunting",},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")

        end,

        events = {
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    },
	State{
        name = "fossilized",
        tags = { "busy", "fossilized"},

        onenter = function(inst)
            
            if inst.components.locomotor ~= nil then
                inst.components.locomotor:StopMoving()
            end
			inst.AnimState:PlayAnimation("fossilized",false)
            inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/fossilized_pre_1")
        end,
    },
	State{
        name = "unfossilizing",
        tags = { "busy" },

        onenter = function(inst)
			inst.AnimState:PlayAnimation("fossilized_shake",true)
            if inst.SoundEmitter:PlayingSound("shakeloop") then
                inst.SoundEmitter:KillSound("shakeloop")
            end
            inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/fossilized_shake_LP", "shakeloop")
            
        end,
        events = {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg.statemem.unfossilized = true
                    inst.sg:GoToState("unfossilized")
                end
            end),
        },

        onexit = function(inst)
            inst.SoundEmitter:KillSound("shakeloop")
        end,
	},
	State{
        name = "unfossilized",
        tags = { "busy" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("fossilized_pst",false)

            inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/fossilized_break")
        end,
        events = {
            EventHandler("animover",function (inst)
                inst:Releash()
                
            end),
        },
    },
    State{
        name = "attack",
        tags = { "attack", "busy" },

        onenter = function(inst, target)
            
            inst.components.locomotor:StopMoving()
           
            inst.AnimState:PlayAnimation("attack_pre")
            inst.AnimState:PushAnimation("attack", false)
            inst.SoundEmitter:PlaySound(inst.sounds.grunt)
            
            inst.components.combat:StartAttack()

            --V2C: Cached to force the target to be the same one later in the timeline
            --     e.g. combat:DoAttack(inst.sg.statemem.target)
            inst.sg.statemem.target = target
        end,

        timeline = {
            TimeEvent(12*FRAMES, function(inst)
                    if inst.sg.statemem.target then
                        inst:ForceFacePoint(inst.sg.statemem.target.Transform:GetWorldPosition())
                    end
                    inst.SoundEmitter:PlaySound(inst.sounds.attack)
                end),
            TimeEvent(15*FRAMES, function(inst)
                inst.components.combat:DoAttack(inst.sg.statemem.target)
                inst.sg:RemoveStateTag("pre_attack")
            end),
            TimeEvent(17*FRAMES, function(inst)
                inst.sg:RemoveStateTag("busy")
                inst.sg:RemoveStateTag("attack")
            end),
        },

        events =
        {
            EventHandler("animover", idleonanimover),
        },
    },
	State{
        name = "attack_spit",
        tags = {"attack", "busy"},

        onenter = function(inst,target)
			inst.components.locomotor:Stop()
			inst.components.combat:StartAttack()
			inst.AnimState:PlayAnimation("attack_pre")
            inst.AnimState:PushAnimation("spit", false)

            inst.sg.statemem.target = target

            inst:StartAbility("spit")
            --inst.components.combat.attackrange = 5
        end,

        timeline = {
			TimeEvent(0, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.grunt)
			end),
            TimeEvent(12*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(inst.sounds.taunt)
                local target = inst.sg.statemem.target
                if target  and target:IsValid() then
                    inst.sg.statemem.targetpos =target:GetPosition()
                    inst:ForceFacePoint(inst.sg.statemem.targetpos:Get())
                else
                    local theta = inst.Transform:GetRotation()*DEGREES
                    local offset = Vector3(6 * math.cos( theta ), 0, -6 * math.sin( theta ))            
                    inst.sg.statemem.targetpos = Vector3(inst.sg.statemem.startpos.x + offset.x, 0, inst.sg.statemem.startpos.z + offset.z)
                end
            end),
            TimeEvent(15*FRAMES, function(inst)
                if inst.sg.statemem.targetpos~=nil then
                    ProjectileSpit(inst,inst.sg.statemem.targetpos)
                end
                inst.SoundEmitter:PlaySound(inst.sounds.spit)
                
            end),
			TimeEvent(17*FRAMES, function(inst)
				inst.sg:RemoveStateTag("busy")
				inst.sg:RemoveStateTag("attack")
			end),
        },

        events = {
            EventHandler("animqueueover", function(inst)
				inst.sg:GoToState("idle")
			end),
        },
    },
    State{
        name = "cursed_spit",
        tags = {"attack", "busy"},

        onenter = function(inst,target)
			inst.components.locomotor:Stop()
			inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("spit")

            inst.sg.statemem.target = target

            inst:StartAbility("cursed_spit")
            --inst.components.combat.attackrange = 5
            --inst.sg:SetTimeout(1)
        end,

        timeline = {
			TimeEvent(0, function(inst)
				inst.SoundEmitter:PlaySound(inst.sounds.grunt)
			end),
            TimeEvent(12*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound(inst.sounds.taunt)
                local target = inst.sg.statemem.target
                if target  and target:IsValid() then
                    inst.sg.statemem.targetpos =target:GetPosition()
                    inst:ForceFacePoint(inst.sg.statemem.targetpos:Get())
                else
                    local theta = inst.Transform:GetRotation()*DEGREES
                    local offset = Vector3(6 * math.cos( theta ), 0, -6 * math.sin( theta ))            
                    inst.sg.statemem.targetpos = Vector3(inst.sg.statemem.startpos.x + offset.x, 0, inst.sg.statemem.startpos.z + offset.z)
                end
            end),
            TimeEvent(15*FRAMES, function(inst)
                inst.AnimState:Pause()

            end),
            TimeEvent(20*FRAMES, function(inst)
                if inst.sg.statemem.target~=nil then
                    CurseFireSpit(inst,inst.sg.statemem.target)
                end
                inst.SoundEmitter:PlaySound(inst.sounds.spit)
            end),
            TimeEvent(25*FRAMES, function(inst)
                if inst.sg.statemem.target~=nil then
                    CurseFireSpit(inst,inst.sg.statemem.target)
                end
                inst.SoundEmitter:PlaySound(inst.sounds.spit)
            end),
			TimeEvent(30*FRAMES, function(inst)
                if inst.sg.statemem.target~=nil then
                    CurseFireSpit(inst,inst.sg.statemem.target)
                end
                inst.SoundEmitter:PlaySound(inst.sounds.spit)

				inst.sg:RemoveStateTag("busy")
				inst.sg:RemoveStateTag("attack")
                inst.AnimState:Resume()
			end),
        },

        events = {
            EventHandler("animqueueover",idleonanimover),
        },
    },
    State{
        name = "death",
        tags = { "busy" },

        onenter = function(inst)
            
            inst.components.locomotor:StopMoving()
            
            inst.AnimState:PlayAnimation("death")
            RemovePhysicsColliders(inst)
            inst.SoundEmitter:PlaySound(inst.sounds.death)
            inst.components.lootdropper:DropLoot(inst:GetPosition())
            
            local loot = {
                "mask_sagehat",
                "mask_halfwithat",
                "mask_toadyhat",
            }

            local mask = SpawnPrefab(loot[math.random(3)])

            inst.components.lootdropper:FlingItem(mask)
            
        end,

    }
}

--CommonStates.AddHitState(states)


CommonStates.AddRunStates(states, {
	runtimeline = {
		TimeEvent(1*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(8*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(12*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(15*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(20*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(25*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(30*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(36*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
		TimeEvent(44*FRAMES, function(inst)
			inst.SoundEmitter:PlaySound(inst.sounds.step)
		end),
	},
})



return StateGraph("void_peghook", states, events, "fossilized")