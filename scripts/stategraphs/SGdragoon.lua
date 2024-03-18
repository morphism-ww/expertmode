require("stategraphs/commonstates")


--[[local function SpawnMoveFx(inst)
	SpawnPrefab("houndfire").Transform:SetPosition(inst.Transform:GetWorldPosition())
end]]


local actionhandlers =
{
	ActionHandler(ACTIONS.LAVASPIT, "spit"),
}

local events=
{
	EventHandler("attacked", 
		function(inst)
			if not inst.components.health:IsDead() and not inst.sg:HasStateTag("attack") then
				inst.sg:GoToState("hit")
			end
		end),

	EventHandler("death",
		function(inst)
			inst.sg:GoToState("death")
		end),

	EventHandler("doattack",
		function(inst, data)
			if not inst.components.health:IsDead() and (inst.sg:HasStateTag("hit") or not inst.sg:HasStateTag("busy")) then
				inst.sg:GoToState("attack", data.target)
			end
		end),

	EventHandler("locomote", 
		function(inst) 
			if not inst.sg:HasStateTag("idle") and not inst.sg:HasStateTag("moving") then return end
			
			if not inst.components.locomotor:WantsToMoveForward() then
				if not inst.sg:HasStateTag("idle") then
					inst.sg:GoToState("idle")
				end
			elseif inst.components.locomotor:WantsToRun() then
				if not inst.sg:HasStateTag("running") then
					inst.sg:GoToState("charge_pre")
				end
			else
				if not inst.sg:HasStateTag("walking") then
					inst.sg:GoToState("walk")
				end
			end
		end),

	CommonHandlers.OnSleep(),
	CommonHandlers.OnFreeze(),
    CommonHandlers.OnHop(),		
}

local states=
{

	State{
		name = "idle",
		tags = {"idle", "canrotate"},
		onenter = function(inst, playanim)
			inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/dragoon/idle")
			inst.Physics:Stop()
			if playanim then
				inst.AnimState:PlayAnimation(playanim)
				inst.AnimState:PushAnimation("idle_loop", true)
			else
				inst.AnimState:PlayAnimation("idle_loop", true)
			end
			inst.sg:SetTimeout(2*math.random()+.5)
		end,

	},

	
	State{
		name = "attack",
		tags = {"attack", "busy"},

		onenter = function(inst, target)
			inst.sg.statemem.target = target
			inst.Physics:Stop()
			inst.components.combat:StartAttack()
			inst.AnimState:PlayAnimation("atk")
			inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/dragoon/attack")
		end,

		timeline=
		{   

			--.inst:ForceFacePoint(self.target:GetPosition())
			
			TimeEvent(8*FRAMES, function(inst) 
				if inst.components.combat.target then 
					inst:ForceFacePoint(inst.components.combat.target:GetPosition()) 
				end 
			end),

			TimeEvent(15*FRAMES, function(inst)
				local target=inst.sg.statemem.target
				inst.components.combat:DoAttack(target)
				inst:ForceFacePoint(target:GetPosition())
				inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/dragoon/attack_strike")
			end),

			TimeEvent(20*FRAMES, function(inst) 
				if inst.sg.statemem.target then
					inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
				end 
			end),

			TimeEvent(27*FRAMES, function(inst) 
				if inst.sg.statemem.target then
					inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
				end 
			end),
		},

		events=
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		},
	},

	State{
		name = "eat",
		tags = {"busy"},

		onenter = function(inst)
			inst.Physics:Stop()
			-- inst.components.combat:StartAttack()
			inst.AnimState:PlayAnimation("atk")
		end,

		timeline=
		{
			TimeEvent(14*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/dragoon/attack_strike") end),
			TimeEvent(24*FRAMES, function(inst) if inst:PerformBufferedAction() then inst.components.combat:SetTarget(nil) end end),
		},

		events=
		{
			EventHandler("animover", function(inst)  inst.sg:GoToState("taunt")  end),
		},
	},

	State{
		name = "spit",
		tags = {"busy"},
		
		onenter = function(inst)
			-- print("snake spit")
			if ((inst.target ~= inst and not inst.target:HasTag("fire")) or inst.target == inst) and not (inst.recently_frozen) then
				if inst.components.locomotor then
					inst.components.locomotor:StopMoving()
				end
				inst.AnimState:PlayAnimation("spit")
				-- inst.vomitfx = SpawnPrefab("vomitfire_fx")
				-- inst.vomitfx.Transform:SetPosition(inst.Transform:GetWorldPosition())
				-- inst.vomitfx.Transform:SetRotation(inst.Transform:GetRotation())
				inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/dragoon/hork")
			else
				-- print("no spit")
				inst:ClearBufferedAction()
				inst.sg:GoToState("idle")
			end
		end,

		onexit = function(inst)
			-- print("spit onexit")

			if inst.last_target and inst.last_target ~= inst then
				inst.num_targets_vomited = inst.last_target.components.stackable and inst.num_targets_vomited + inst.last_target.components.stackable:StackSize() or inst.num_targets_vomited + 1
				inst.last_target_spit_time = GetTime()
			end
			--inst.Transform:SetFourFaced()
			if inst.vomitfx then 
				inst.vomitfx:Remove() 
			end
			inst.vomitfx = nil
		end,
		
		events=
		{
			EventHandler("animqueueover", function(inst) 
				-- print("spit animqueueover")
				inst.sg:GoToState("idle")
			end),
		},

		timeline=
		{
			TimeEvent(37*FRAMES, function(inst) 
				-- print("spit timeline")
				-- print("vomitfire_fx spawned")						
				inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/dragoon/split")
				inst:PerformBufferedAction()
				inst.last_target = inst.target
				inst.target = nil
				inst.spit_interval = math.random(20,30)
				inst.last_spit_time = GetTime()
			end),

			TimeEvent(39*FRAMES, function(inst) 
				-- print("spit timeline")
				-- print("vomitfire_fx spawned")
				inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/dragoon/fireball")
			end),
		},
	},
	
	State{
		name = "hit",
		tags = {"busy", "hit"},

		onenter = function(inst)
			inst.AnimState:PlayAnimation("hit")
			inst.Physics:Stop()
			inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/dragoon/hit")
		end,

		events=
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
		},
	},

	State{
		name = "taunt",
		tags = {"busy"},

		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("taunt")
			inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/dragoon/taunt")
		end,


		events=
		{
			EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
		},
	},

	State{
		name = "death",
		tags = {"busy"},

		onenter = function(inst)
			inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/dragoon/death")
			inst.AnimState:PlayAnimation("death")
			inst.Physics:Stop()
			RemovePhysicsColliders(inst)            
			inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))            
		end,

	},

	State{
		name = "walk",
		tags = {"moving", "canrotate", "walking"},
		
		onenter = function(inst) 
			inst.AnimState:PlayAnimation("walk_pre")
			inst.AnimState:PushAnimation("walk_loop", true)
			inst.components.locomotor:WalkForward()
			--inst.sg:SetTimeout(2*math.random()+.5)
		end,
		
		onupdate= function(inst)
			if not inst.components.locomotor:WantsToMoveForward() then
				inst.sg:GoToState("idle", "walk_pst")
			end
		end,

		timeline = {
			--TimeEvent(0, function(inst) inst.SoundEmitter:PlaySound("dragoon/dragoon/taunt") end),
			TimeEvent(0*FRAMES, PlayFootstep ),
			TimeEvent(4*FRAMES, PlayFootstep ),
		},
	},

	State{
		name = "charge_pre",
		tags = {"moving", "canrotate", "running"},
		
		onenter = function(inst)
			inst.AnimState:PlayAnimation("charge_pre")
			--inst.sg:SetTimeout(2*math.random()+.5)
		end,
		
		onupdate= function(inst)
			if not inst.components.locomotor:WantsToMoveForward() then
				inst.sg:GoToState("idle", "charge_pst")
			end
		end,

		events = {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("charge") end),
        }
	},

	State{
		name = "charge",
		tags = {"moving", "canrotate", "running"},
		
		onenter = function(inst) 
			inst.AnimState:PlayAnimation("charge_loop")
			inst.components.locomotor:RunForward()

			inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/dragoon/charge")
		end,
		
		onupdate= function(inst)
			if not inst.components.locomotor:WantsToMoveForward() then
				inst.sg:GoToState("idle", "charge_pst")
			end
		end,


		events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("charge") end),
        }
	},
}

CommonStates.AddSleepStates(states,
{
	sleeptimeline = {
		TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/dragoon/sleep") end),
	},
})

CommonStates.AddFrozenStates(states)
--CommonStates.AddHopStates(states, true, { pre = "walk_pre", loop = "walk_loop", pst = "walk_pst"})

return StateGraph("dragoon", states, events, "taunt", actionhandlers)
