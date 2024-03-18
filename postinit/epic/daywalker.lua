require("stategraphs/commonstates")


TUNING.DAYWALKER_HEALTH_REGEN = 30
TUNING.DAYWALKER_COMBAT_STALKING_HEALTH_REGEN = 30
TUNING.DAYWALKER_COMBAT_TIRED_HEALTH_REGEN = 30
TUNING.DAYWALKER_FATIGUE_TIRED = 5
TUNING.DAYWALKER_AGGRO_DIST = 30
TUNING.DAYWALKER_KEEP_AGGRO_DIST = 25
--TUNING.DAYWALKER_POUNCE_DAMAGE = 75
TUNING.DAYWALKER_XCLAW_DAMAGE = 2*100
TUNING.DAYWALKER_SLAM_DAMAGE = 3*100



local PHASES =
{
	[0] = {
		hp = 1,
		fn = function(inst)
			inst.Transform:SetScale(1,1,1)
			inst.canfatigue = false
			inst.nostalkcd = true
			inst.canstalk = true
			inst.canslam = false
			inst.canwakeuphit = false
			inst.components.timer:StopTimer("stalk_cd")
			inst:ResetFatigue()
			inst.invisible=false
		end,
	},
	--
	[1] = {
		hp = 0.999,
		fn = function(inst)
			inst.invisible=false
			inst.Transform:SetScale(1,1,1)
			if inst.hostile then
				inst.canfatigue = true
				inst.nostalkcd = true
				inst.canstalk = false
				inst.canslam = false
				inst.canwakeuphit = false
			end
		end,
	},
	[2] = {
		hp = 0.8,
		fn = function(inst)
			inst.Transform:SetScale(1,1,1)
			inst.invisible=false
			if inst.hostile then
				inst.canfatigue = true
				inst.nostalkcd = false
				inst.canstalk = true
				inst.canslam = false
				inst.canwakeuphit = false

			end
		end,
	},
	[3] = {
		hp = 0.6,
		fn = function(inst)
			inst.invisible=false
			inst.Transform:SetScale(1.2,1.2,1.2)
			if inst.hostile then
				inst.canfatigue = true
				inst.nostalkcd = true
				inst.canstalk = true
				inst.canslam = true
				inst.canwakeuphit = false
				inst.components.timer:StopTimer("stalk_cd")

			end
		end,
	},
	[4] = {
		hp = 0.4,
		fn = function(inst)
			inst.invisible=false
			inst.Transform:SetScale(1.5,1.5,1.5)
			if inst.hostile then
				inst.canfatigue = false
				inst.nostalkcd = false
				inst.canstalk = true
				inst.canslam = true
				inst.canwakeuphit = true
				inst:ResetFatigue()
			end
		end,
	},
	[5]={
		hp = 0.2,
		fn = function(inst)
			inst.DynamicShadow:SetSize(0,0)
			inst.invisible=true
			inst.Transform:SetScale(1.5,1.5,1.5)
			if inst.hostile then
				inst.canfatigue = false
				inst.nostalkcd = false
				inst.canstalk = false
				inst.canslam = true
				inst.canwakeuphit = true
			end
		end,
	},
}

local function doinvisible(inst,a)
	inst.AnimState:SetMultColour(1,1,1,a)
end





local function setnormal(inst)
	inst:Show()
	inst.AnimState:SetMultColour(1,1,1,1)
	inst.Transform:SetScale(1,1,1)
	--inst.components.talker:MakeChatter()
end
local function OnLoad(inst, data)
	local healthpct = inst.components.health:GetPercent()
	for i = #PHASES, 1, -1 do
		local v = PHASES[i]
		if healthpct <= v.hp then
			v.fn(inst)
			break
		end
	end

	if inst.components.timer:TimerExists("despawn") then
		inst:MakeDefeated()
		if data ~= nil and data.looted then
			inst.looted = true
			inst.sg:GoToState("defeat_idle_pre")
		else
			inst.components.timer:PauseTimer("despawn")
			inst.components.timer:SetTimeLeft("despawn", 240)
			inst.sg:GoToState("defeat")
		end
	end
end


AddPrefabPostInit("daywalker",function(inst)
	if not TheWorld.ismastersim then return end
	for i, v in pairs(PHASES) do
		inst.components.healthtrigger:AddTrigger(v.hp, v.fn)
	end
	
	inst.DoInvisible=doinvisible
	inst.OnLoad = OnLoad
end)

local NON_COLLAPSIBLE_TAGS = { "flying", "bird", "ghost", "playerghost", "FX", "NOCLICK", "DECOR", "INLIMBO","shadow_aligned" ,"brightmareboss"}
local COLLAPSIBLE_TAGS = { "_combat", "pickable", "NPC_workable" }


--sinkhole
local function DoDamage(inst)
	local pos = inst:GetPosition()
	local ents = TheSim:FindEntities(
        pos.x, 0, pos.z,
        inst.radius, nil,
        NON_COLLAPSIBLE_TAGS, COLLAPSIBLE_TAGS
    )
	for _, v in ipairs(ents) do
		if  v.components.health ~= nil and not v.components.health:IsDead() then
			 inst.components.combat:DoAttack(v)
		end
	end
	--[[if inst.components.timer:TimerExists("repair") then
		inst.components.timer:SetTimeLeft("repair", 25)
	else
		inst.components.timer:StartTimer("repair",25)
	end]]
end

AddPrefabPostInit("daywalker_sinkhole",function(inst)
	if not TheWorld.ismastersim then return end
	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(TUNING.DAYWALKER_DAMAGE)
	inst.components.combat.playerdamagepercent = .5
	inst.components.combat:SetRange(TUNING.DAYWALKER_SLAM_SINKHOLERADIUS)  --3
	inst:ListenForEvent("docollapse",DoDamage)
end)


---stategraphs


local AOE_RANGE_PADDING = 3
local AOE_TARGET_MUSTHAVE_TAGS = { "_combat" }
local AOE_TARGET_CANT_TAGS = { "INLIMBO", "flight", "invisible", "notarget", "noattack" }
local MAX_SIDE_TOSS_STR = 0.8

local function DoAOEAttack(inst, dist, radius, heavymult, mult, forcelanded, targets)
	inst.components.combat.ignorehitrange = true
	local x, y, z = inst.Transform:GetWorldPosition()
	local rot0, x0, z0
	if dist ~= 0 then
		if dist > 0 and ((mult ~= nil and mult > 1) or (heavymult ~= nil and heavymult > 1)) then
			x0, z0 = x, z
		end
		rot0 = inst.Transform:GetRotation() * DEGREES
		x = x + dist * math.cos(rot0)
		z = z - dist * math.sin(rot0)
	end
	for i, v in ipairs(TheSim:FindEntities(x, y, z, radius + AOE_RANGE_PADDING, AOE_TARGET_MUSTHAVE_TAGS, AOE_TARGET_CANT_TAGS)) do
		if v ~= inst and
			not (targets ~= nil and targets[v]) and
			v:IsValid() and not v:IsInLimbo()
			and not (v.components.health ~= nil and v.components.health:IsDead())
			then
			local range = radius + v:GetPhysicsRadius(0)
			if v:GetDistanceSqToPoint(x, y, z) < range * range and inst.components.combat:CanTarget(v) then
				inst.components.combat:DoAttack(v)
				if mult ~= nil then
					local strengthmult = (v.components.inventory ~= nil and v.components.inventory:ArmorHasTag("heavyarmor") or v:HasTag("heavybody")) and heavymult or mult
					if strengthmult > MAX_SIDE_TOSS_STR and x0 ~= nil then
						--Don't toss as far to the side for frontal attacks
						local rot1 = (v:GetAngleToPoint(x0, 0, z0) + 180) * DEGREES
						local k = math.max(0, math.cos(math.min(PI, DiffAngleRad(rot1, rot0) * 2)))
						strengthmult = MAX_SIDE_TOSS_STR + (strengthmult - MAX_SIDE_TOSS_STR) * k * k
					end
					v:PushEvent("knockback", { knocker = inst, radius = radius + dist + 3, strengthmult = strengthmult, forcelanded = forcelanded })
				end
				if targets ~= nil then
					targets[v] = true
				end
			end
		end
	end
	inst.components.combat.ignorehitrange = false
end



local function ChooseAttack(inst)
	local running = inst.sg:HasStateTag("running")
	if inst.canslam and not running and (inst.nostalkcd or math.random() < 0.3) then
		inst.sg:GoToState("attack_slam_pre", inst.components.combat.target)
	elseif inst.invisible and math.random()>0.5 then
		inst.sg:GoToState("superslam_pre",inst.components.combat.target)
	else
		inst.sg:GoToState("attack_pounce_pre", {
			running = running,
			target = inst.components.combat.target,
		})
	end
	return true
end

AddStategraphState("daywalker",
State{
		name = "superslam_pre",
		tags = { "attack", "busy", "jumping" },

		onenter = function(inst)
			local target=inst.components.combat.target
			inst:SetStalking(nil)
			inst.components.locomotor:Stop()
			inst.components.locomotor:EnableGroundSpeedMultiplier(false)
			inst.AnimState:PlayAnimation("atk_slam_pre")
			if target ~= nil and target:IsValid() then
				inst.sg.statemem.target = target
				inst:ForceFacePoint(target.Transform:GetWorldPosition())

			end
			inst.sg.statemem.speed = 3.5
			inst.sg.statemem.decel = -0.25
		end,

		onupdate = function(inst)
			if inst.sg.statemem.decel ~= 0 then
				if inst.sg.statemem.speed <= 0 then
					inst.Physics:ClearMotorVelOverride()
					inst.Physics:Stop()
					inst.sg.statemem.decel = 0
				else
					inst.Physics:SetMotorVelOverride(inst.sg.statemem.speed, 0, 0)
					inst.sg.statemem.speed = inst.sg.statemem.speed + inst.sg.statemem.decel
				end
			end
		end,

		timeline =
		{
			FrameEvent(0, function(inst)
				inst.SoundEmitter:PlaySound("daywalker/voice/hurt")
				inst.SoundEmitter:PlaySound("daywalker/action/step", nil, 0.3)
			end),
			FrameEvent(10, function(inst)   --18
				inst.sg.statemem.decel = 0
				inst.Physics:SetMotorVelOverride(1, 0, 0)

			end),
			--FrameEvent(19, function(inst) inst.Physics:SetMotorVelOverride(2, 0, 0) end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					inst.sg.statemem.slam = true
					inst.sg:GoToState("super_attack_slam", inst.sg.statemem.target)
				end
			end),
		},

		onexit = function(inst)
			if not inst.sg.statemem.slam then
				inst.Physics:ClearMotorVelOverride()
				inst.Physics:Stop()
				inst.components.locomotor:EnableGroundSpeedMultiplier(true)
			end
		end,
	})
AddStategraphState("daywalker",
State{
		name = "super_attack_slam",
		tags = { "attack", "busy", "jumping", "notalksound" },

		onenter = function(inst, target)
			inst:SetStalking(nil)
			inst.components.locomotor:EnableGroundSpeedMultiplier(false)
			inst:StartAttackCooldown()
			inst.AnimState:PlayAnimation("atk_slam")
			if target ~= nil and target:IsValid() then
				inst.sg.statemem.target = target
				inst.sg.statemem.targetpos = target:GetPosition()
				inst.sg.statemem.tracking = true
				local x1, y1, z1 = target.Transform:GetWorldPosition()
				local rot = inst.Transform:GetRotation()
				local rot1 = inst:GetAngleToPoint(x1, y1, z1)
				local diff = DiffAngle(rot, rot1)
				if diff < 90 then
					inst.Transform:SetRotation(rot1)
				end

				--inst.Transform:SetPosition(x1,y1,z1)

			end
			inst.sg.statemem.speedmult = 1
			inst.sg.statemem.speed = 2
			inst.sg.statemem.decel = 0
			inst.Physics:SetMotorVelOverride(2, 0, 0)
		end,

		onupdate = function(inst)
			if inst.sg.statemem.tracking then
				if inst.sg.statemem.target ~= nil then
					if inst.sg.statemem.target:IsValid() then
						local p = inst.sg.statemem.targetpos
						p.x, p.y, p.z = inst.sg.statemem.target.Transform:GetWorldPosition()

					else
						inst.sg.statemem.target = nil
					end
				end
				if inst.sg.statemem.targetpos ~= nil then
					local rot = inst.Transform:GetRotation()
					local rot1 = inst:GetAngleToPoint(inst.sg.statemem.targetpos)
					local drot = ReduceAngle(rot1 - rot)
					if math.abs(drot) < 90 then
						rot1 = rot + math.clamp(drot / 2, -1, 1)
						inst.Transform:SetRotation(rot1)
					end

				end
			end
			if inst.sg.statemem.decel ~= 0 then
				if inst.sg.statemem.speed <= 0 then
					inst.Physics:ClearMotorVelOverride()
					inst.Physics:Stop()
					inst.sg.statemem.decel = 0
				else
					inst.Physics:SetMotorVelOverride(inst.sg.statemem.speed * inst.sg.statemem.speedmult, 0, 0)
					inst.sg.statemem.speed = inst.sg.statemem.speed + inst.sg.statemem.decel
				end
			end
		end,

		timeline =
		{
			FrameEvent(1, function(inst) inst.SoundEmitter:PlaySound("daywalker/action/attack_slam_whoosh") end),
			FrameEvent(2, function(inst)
				inst.SoundEmitter:PlaySound("daywalker/voice/attack_big")
				inst.SoundEmitter:PlaySound("daywalker/action/step")

			end),
			FrameEvent(25, function(inst) inst.SoundEmitter:PlaySound("daywalker/action/attack_slam_down") end),

			FrameEvent(3, function(inst)
				inst.Physics:SetMotorVelOverride(3, 0, 0)
				local x,y,z=inst.sg.statemem.target.Transform:GetWorldPosition()
				inst.Transform:SetPosition(x,y,z)
				inst:Show()
			end),
			FrameEvent(20, function(inst)
				inst.sg.statemem.tracking = false
			end),
			FrameEvent(38, function(inst)
				inst.sg:AddStateTag("nointerrupt")
			end),
			FrameEvent(26, function(inst)
				inst.sg.statemem.speed = 4
				inst.sg.statemem.decel = -1
				local x0, y0, z0 = inst.Transform:GetWorldPosition()
				local rot0 = inst.Transform:GetRotation() * DEGREES

				local sinkhole1 = SpawnPrefab("daywalker_sinkhole")
				sinkhole1.Transform:SetPosition(x0,y0,z0)
				sinkhole1:PushEvent("docollapse")

				local x1,z1,x2,z2
				x1=x0+4.2* math.cos(rot0)
				z1=z0-4.2* math.sin(rot0)
				x2=x0+8.4* math.cos(rot0)
				z2=z0-8.4* math.sin(rot0)


				local sinkhole2 = SpawnPrefab("daywalker_sinkhole")
				sinkhole2.Transform:SetPosition(x1,y0,z1)
				sinkhole2:PushEvent("docollapse")

				local sinkhole3 = SpawnPrefab("daywalker_sinkhole")
				sinkhole3.Transform:SetPosition(x2,y0,z2)
				sinkhole3:PushEvent("docollapse")


				inst.components.combat:SetDefaultDamage(TUNING.DAYWALKER_SLAM_DAMAGE)
				local targets = {}
				inst.sg.statemem.targets = targets
				DoAOEAttack(inst, 0, TUNING.DAYWALKER_SLAM_SINKHOLERADIUS, 0.7, 0.7, false, targets)
				--local targets table; this code is valid even if we left state
				for k in pairs(targets) do
					if k:IsValid() and k:HasTag("smallcreature") then
						targets[k] = nil
					end
				end
			end),
			FrameEvent(61, function(inst)
				inst.sg:RemoveStateTag("nointerrupt")
				inst.sg:AddStateTag("caninterrupt")
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				inst.sg:GoToState("idle")
			end),
		},

		onexit = function(inst)
			inst.Physics:ClearMotorVelOverride()
			inst.Physics:Stop()
			inst.components.locomotor:EnableGroundSpeedMultiplier(true)
			inst.components.combat:SetDefaultDamage(TUNING.DAYWALKER_DAMAGE)
			inst:Hide()
		end,
	})

AddStategraphPostInit("daywalker",function(sg)
	sg.events["doattack"].fn=function(inst)
		if not (inst.sg:HasStateTag("busy") or inst.defeated) then
			ChooseAttack(inst)
		end
	end
	--[[local _name,DoAOEAttack
	_name,DoAOEAttack= debug.getupvalue(sg.states.attack_slam.timeline[12].fn,1)]]
	sg.states.attack_slam.timeline[12].fn=function(inst)
		inst.sg.statemem.speed = 4
		inst.sg.statemem.decel = -1
		local x0, y0, z0 = inst.Transform:GetWorldPosition()
		local rot0 = inst.Transform:GetRotation() * DEGREES
		local sinkhole1 = SpawnPrefab("daywalker_sinkhole")
		sinkhole1.Transform:SetPosition(x0,y0,z0)
		sinkhole1:PushEvent("docollapse")

		local x1,z1,x2,z2
		x1=x0+4.2* math.cos(rot0)
		z1=z0-4.2* math.sin(rot0)
		x2=x0+8.4* math.cos(rot0)
		z2=z0-8.4* math.sin(rot0)


		local sinkhole2 = SpawnPrefab("daywalker_sinkhole")
		sinkhole2.Transform:SetPosition(x1,y0,z1)
		sinkhole2:PushEvent("docollapse")

		local sinkhole3 = SpawnPrefab("daywalker_sinkhole")
		sinkhole3.Transform:SetPosition(x2,y0,z2)
		sinkhole3:PushEvent("docollapse")

		inst.components.combat:SetDefaultDamage(TUNING.DAYWALKER_SLAM_DAMAGE)
		local targets = {}
		inst.sg.statemem.targets = targets
		DoAOEAttack(inst, 0, TUNING.DAYWALKER_SLAM_SINKHOLERADIUS, 0.7, 0.7, false, targets)
		--local targets table; this code is valid even if we left state
		for k in pairs(targets) do
			if k:IsValid() and k:HasTag("smallcreature") then
				targets[k] = nil
			end
		end
		if next(targets) ~= nil then
			--reinvigorated when successfully hitting something not small
			inst:DeltaFatigue(TUNING.DAYWALKER_FATIGUE.SLAM_HIT)
		end
	end
	sg.states.attack_slam.timeline[4].fn=function(inst)
		if inst.invisible then
			--inst:DoInvisible(0.2)
			inst:Show()
		else
			inst.Physics:SetMotorVelOverride(8, 0, 0)
		end
	end
	local oldpounce_pre=sg.states.attack_pounce_pre.onenter
	sg.states.attack_pounce_pre.onenter=function(inst)
		oldpounce_pre(inst)
		inst:Show()
	end
	sg.states.attack_pounce_pst.onexit=function(inst)
		if inst.invisible then
			inst:DoInvisible(0.1)
			inst:Hide()
		end
	end
	sg.states.attack_slam.onexit=function(inst)
		inst.Physics:ClearMotorVelOverride()
		inst.Physics:Stop()
		inst.components.locomotor:EnableGroundSpeedMultiplier(true)
		inst.components.combat:SetDefaultDamage(TUNING.DAYWALKER_DAMAGE)
		if inst.invisible then
			--inst:DoInvisible(0)
			inst:Hide()
		end
	end
	sg.states.defeat.onenter = function(inst)
		inst.components.locomotor:Stop()
		setnormal(inst)
		inst:SwitchToFacingModel(0) --inst.Transform:SetNoFaced()
		inst.AnimState:PlayAnimation("defeat")
	end

end)


--[[AddBrainPostInit("daywalker",expertbrain)
sg.states.attack_slam.timeline[4].fn=function(inst)
		if inst.invisible then
			inst:DoInvisible(0.2)
		else
			inst.Physics:SetMotorVelOverride(8, 0, 0)
		end
	end
	local oldpounce_pre=sg.states.attack_pounce_pre.onenter
	sg.states.attack_pounce_pre.onenter=function(inst)
		oldpounce_pre(inst)
		if inst.invisible then
			inst:DoInvisible(0.2)
		end
	end
	sg.states.attack_pounce_pst.onexit=function(inst)
		if inst.invisible then
			inst:DoInvisible(0)
		end
	end
	sg.states.attack_slam.onexit=function(inst)
		inst.Physics:ClearMotorVelOverride()
		inst.Physics:Stop()
		inst.components.locomotor:EnableGroundSpeedMultiplier(true)
		inst.components.combat:SetDefaultDamage(TUNING.DAYWALKER_DAMAGE)
		if inst.invisible then
			inst:DoInvisible(0)
		end
	end]]