require("stategraphs/commonstates")

local actionhandlers ={
	ActionHandler(ACTIONS.PLAYER_LEECH_JUMP,"jump_pre"),
	ActionHandler(ACTIONS.PLAYER_LEECH,
		function(inst,action)
			if action.target ~= nil and 
				not (action.target.components.health and action.target.components.health:IsDead()) and
				action.target.components.combat~=nil then
				return "jump_pre"
			end
		end),
	ActionHandler(ACTIONS.PICKUP,"doshortaction")
}

local events =
{
	CommonHandlers.OnLocomote(true,false),
	EventHandler("attacked", function(inst,data)
		if not (inst.sg:HasStateTag("noattack") or inst.sg:HasStateTag("temp_invincible") or inst.components.health:IsDead()) then
			inst.sg:GoToState("hit",data.attacker)
		end
	end),
	--[[EventHandler("death", function(inst)
		inst.sg:GoToState("death")
	end),]]
}

--[[local function ClearAttach(inst)
	if inst._leechtarget~=nil then
		inst._leechtarget = nil
		inst.Follower:StopFollowing()
		
	end
end]]


local function losshealth(inst,player)
    
    if inst.components.health ~= nil then
        inst.components.health:DoDelta(-4, nil, "shadow_leech")
    end
    if player.components.hunger~=nil and player.components.hunger:GetPercent()<1 then
		player.components.hunger:DoDelta(2,true,true)
	end
	if player.components.health~=nil and player.components.health:GetPercent()<1 then
		player.components.health:DoDelta(1,true,"shadow_leech",true)
	end
end



local function LeechTarget(inst)
	local target = inst._leechtarget
	if target~=nil then
		if target.components.hunger ~= nil then
			target.components.hunger.burnratemodifiers:SetModifier(inst, 1.1,"leech")
		end
		if not target.isplayer and target._p_leechtask==nil then
			target._p_leechtask = target:DoPeriodicTask(1,losshealth,nil,inst)
		end
		inst:ListenForEvent("death",inst.ClearLeech,target)
		inst:ListenForEvent("onremove",inst.ClearLeech,target)
		inst:ListenForEvent("minhealth",inst.ClearLeech,target)
	end
end

local function TryAttach(inst, target)
    if target==nil or not target:IsValid() then
		--ClearAttach(inst)
        return
    end
	if target:HasTag("player") and not target:HasTag("playerghost") and inst:IsNear(target, 2) then
        local oldarmor = target.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
        if oldarmor ~= nil then
            target.components.inventory:DropItem(oldarmor)
        end
		
	
		inst._leechtarget = target
        inst.Follower:FollowSymbol(target.GUID, "swap_body", nil, nil, nil, true)
		inst.sg:GoToState("attached")
    elseif target.components.combat and inst:IsNear(target, 2) then
		inst._leechtarget = target
		local symbol = target.components.combat.hiteffectsymbol
        inst.Follower:FollowSymbol(target.GUID, symbol, nil, nil, nil, true)
		inst.sg:GoToState("attached")
    end
end

local states =
{
	State{
		name = "idle",
		tags = { "idle", "canrotate" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("idle", true)
		end,
	},

	State{
        name = "doshortaction",
		tags = { "doing", "busy"},

        onenter = function(inst, silent)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("attach_loop")

            inst.sg.statemem.action = inst.bufferedaction
            inst.sg.statemem.silent = silent
            inst.sg:SetTimeout(10 * FRAMES)
        end,

        timeline =
        {
            TimeEvent(6 * FRAMES, function(inst)
				inst.sg:RemoveStateTag("busy")
                if inst.sg.statemem.silent then
                    inst.components.talker:IgnoreAll("silentpickup")
                    inst:PerformBufferedAction()
                    inst.components.talker:StopIgnoringAll("silentpickup")
                else
                    inst:PerformBufferedAction()
                end
            end),
        },

        ontimeout = function(inst)
            --pickup_pst should still be playing
            inst.sg:GoToState("idle", true)
        end,

        onexit = function(inst)
            if inst.bufferedaction == inst.sg.statemem.action and
            (inst.components.playercontroller == nil or inst.components.playercontroller.lastheldaction ~= inst.bufferedaction) then
                inst:ClearBufferedAction()
            end
        end,
    },

	State{
		name = "spawn_delay",
		tags = { "busy", "noattack", "temp_invincible", "invisible" },

		onenter = function(inst, delay)
			inst.components.locomotor:Stop()
			inst:Hide()
			inst.sg:SetTimeout(delay or math.random())
		end,

		ontimeout = function(inst)
			local target = inst.components.entitytracker:GetEntity("daywalker")
			if target ~= nil then
				inst:ForceFacePoint(target.Transform:GetWorldPosition())
			end
			inst.sg:GoToState("spawn")
		end,

		onexit = function(inst)
			inst:Show()
		end,
	},

	State{
		name = "spawn",
		tags = { "busy", "noattack", "temp_invincible" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("spawn")
		end,

		timeline =
		{
			FrameEvent(35, function(inst)
				inst.sg:RemoveStateTag("noattack")
				inst.sg:RemoveStateTag("temp_invincible")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
		},
	},

	State{
		name = "hit",
		tags = { "busy", "hit", "temp_invincible" },

		onenter = function(inst,attacker)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("disappear")
			inst.SoundEmitter:PlaySound("daywalker/leech/die")
			inst.sg.statemem.attacker = attacker
			--inst.SoundEmitter:PlaySound("dontstarve/sanity/death_pop")
		end,

		timeline =
		{
			FrameEvent(12, function(inst)
				inst.sg:AddStateTag("noattack")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					
					local x0, y0, z0 = inst.Transform:GetWorldPosition()
					local daywalker = inst.sg.statemem.attacker
					local dir0 = daywalker ~= nil and daywalker:GetAngleToPoint(x0, y0, z0) or nil
					for k = 1, 4 do
						local radius = GetRandomMinMax(4 - k, 8)
						local angle = dir0 ~= nil and (dir0 + math.random() * 90 - 45) * DEGREES or math.random() * TWOPI
						local x = x0 + math.cos(angle) * radius
						local z = z0 - math.sin(angle) * radius
						if TheWorld.Map:IsPassableAtPoint(x, 0, z) then
							inst.Physics:Teleport(x, 0, z)
							break
						end
					end
					inst.sg:GoToState("appear")
				end
			end),
		},
	},

	State{
		name = "appear",
		tags = { "busy", "temp_invincible" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("appear")
		end,

		timeline =
		{
			FrameEvent(17, function(inst)
				inst.sg:RemoveStateTag("temp_invincible")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
		},
	},

	State{
		name = "death",
		tags = { "busy", "noattack" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("disappear")
			inst.SoundEmitter:PlaySound("daywalker/leech/die")
			inst.SoundEmitter:PlaySound("dontstarve/sanity/death_pop")
			local pt = inst:GetPosition()
			pt.y = 1
			inst.components.lootdropper:DropLoot(pt)
			inst:AddTag("NOCLICK")
			inst.persists = false
		end,

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst:Remove()
				end
			end),
		},

		onexit = function(inst)
			--Shouldn't reach here!
			inst:RemoveTag("NOCLICK")
		end,
	},

	State{
		name = "jump_pre",
		tags = { "busy" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("jump_pre")
			inst.SoundEmitter:PlaySound("daywalker/leech/leap")

			--[[local target = inst
			if target ~= nil and target:IsValid() then
				inst.sg.statemem.target = target
				inst.sg.statemem.targetpos = target:GetPosition()
			end]]
		end,


		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst:PerformBufferedAction()
					--inst.sg:GoToState("jump", inst.sg.statemem.target or inst.sg.statemem.targetpos)
				end
			end),
			EventHandler("leech_jump", function(inst, data)
                inst.sg:GoToState("jump", data)
            end),
		},
	},

	State{
		name = "jump",
		tags = { "busy", "jumping", "noattack" },

		onenter = function(inst, data)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("jump")
			inst.SoundEmitter:PlaySound("daywalker/leech/vocalization")
			local dist
			if data.targetpos then
				dist = math.sqrt(inst:GetDistanceSqToPoint(data.targetpos))
			
			else
				local target = data.target
				if target == nil then
					dist = 6
					local theta = inst.Transform:GetRotation() * DEGREES
					target = inst:GetPosition()
					target.x = target.x + math.cos(theta) * dist
					target.z = target.z - math.sin(theta) * dist
				elseif target:IsValid() then
					inst.sg.statemem.target = target
					target = target:GetPosition()
					dist = math.sqrt(inst:GetDistanceSqToPoint(target))
				end
			end
			--inst:ForceFacePoint(target)
			inst.sg.statemem.speed = math.min(16.5, dist / (11 * FRAMES))
			inst.Physics:SetMotorVelOverride(inst.sg.statemem.speed, 0, 0)
			inst.Physics:ClearCollidesWith(COLLISION.WORLD)
		end,

		timeline =
		{
			FrameEvent(11, function(inst)
				TryAttach(inst, inst.sg.statemem.target)
			end),
			FrameEvent(12, function(inst)
				TryAttach(inst, inst.sg.statemem.target)
			end),
			FrameEvent(15, function(inst)
				inst.sg:RemoveStateTag("noattack")
				inst.Physics:SetMotorVelOverride(inst.sg.statemem.speed * .35, 0, 0)
				inst.Physics:CollidesWith(COLLISION.WORLD)
				inst.SoundEmitter:PlaySound("daywalker/leech/vocalization")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("flail")
				end
			end),
		},

		onexit = function(inst)
			inst.Physics:ClearMotorVelOverride()
			inst.Physics:Stop()
			inst.Physics:CollidesWith(COLLISION.WORLD)
		end,
	},

	State{
		name = "flail",
		tags = { "busy" },

		onenter = function(inst)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("flail_loop", true)
			inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength() * 3)
		end,

		ontimeout = function(inst)
			inst.sg:GoToState("flail_pst")
		end,
	},

	State{
		name = "flail_pst",
		tags = { "busy" },

		onenter = function(inst)
			inst.AnimState:PlayAnimation("flail_pst")
		end,

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("idle")
				end
			end),
		},
	},

	State{
		name = "attached",
		tags = { "idle","temp_invincible"},

		onenter = function(inst)
			inst.Physics:Stop()
			inst.AnimState:PlayAnimation("attach_loop", true)
			inst.Physics:SetActive(false)
			LeechTarget(inst)
			inst:AddTag("notarget")
			inst:AddTag("leeched")
			
			inst.SoundEmitter:PlaySound("daywalker/leech/suck", "suckloop")
		end,
		events =
		{
			EventHandler("locomote", function(inst,data)
				if data and data.dir then
					inst.ClearLeech(inst._leechtarget)
					--OnFlungFrom(inst,inst._leechtarget,data.dir)
				end
				
			end)
		},
		onexit = function(inst)
			inst.Follower:StopFollowing()
			inst.Physics:SetActive(true)
			inst:RemoveTag("notarget")
			inst:RemoveTag("leeched")
			inst.SoundEmitter:KillSound("suckloop")
		end,
	},

	State{
		name = "flung",
		tags = { "busy", "jumping", "noattack", "temp_invincible" },

		onenter = function(inst, speedmult)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("toss")
			inst.SoundEmitter:PlaySound("daywalker/leech/fall_off")
			inst.sg.statemem.speed = -10 * (speedmult or 1)
			inst.Physics:SetMotorVelOverride(inst.sg.statemem.speed, 0, 0)
			inst.Physics:ClearCollidesWith(COLLISION.SANITY)
		end,

		timeline =
		{
			FrameEvent(18, function(inst)
				inst.sg:RemoveStateTag("noattack")
				inst.sg:RemoveStateTag("temp_invincible")
				inst.Physics:SetMotorVelOverride(inst.sg.statemem.speed * .35, 0, 0)
				inst.Physics:CollidesWith(COLLISION.SANITY)
				inst.SoundEmitter:PlaySound("daywalker/leech/vocalization")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg:GoToState("flail")
				end
			end),
		},

		onexit = function(inst)
			inst.Physics:ClearMotorVelOverride()
			inst.Physics:Stop()
			inst.Physics:CollidesWith(COLLISION.SANITY)
		end,
	},
}

CommonStates.AddRunStates(states,
{
	starttimeline =
	{
		FrameEvent(6, function(inst)
			inst.components.locomotor:RunForward()
		end),
	},
},
nil, nil, true--[[delaystart]],
{
	runonenter = function(inst)
		inst.SoundEmitter:PlaySound("daywalker/leech/walk", "walkloop")
	end,
	runonexit = function(inst)
		inst.SoundEmitter:KillSound("walkloop")
	end,
})

return StateGraph("player_leech", states, events, "idle",actionhandlers)
