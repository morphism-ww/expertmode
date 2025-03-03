local DIST = 4.5
local PHASES =
{
	[0] = {
		hp = 1,
		fn = function(inst)
			inst.canfatigue = false
			inst.nostalkcd = true
			inst.canstalk = true
			inst.canslam = false
			inst.canwakeuphit = false
			inst.components.timer:StopTimer("stalk_cd")
			inst:ResetFatigue()
		end,
	},
	--
	[1] = {
		hp = 0.999,
		fn = function(inst)
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
			
			if inst.hostile then
				inst.canfatigue = true
				inst.nostalkcd = false
				inst.canstalk = true
				inst.canslam = false
				inst.canwakeuphit = false
				inst.components.scaler:SetScale(1.2)
			end
		end,
	},
	[3] = {
		hp = 0.6,
		fn = function(inst)
			if inst.hostile then
				inst.canfatigue = true
				inst.nostalkcd = true
				inst.canstalk = true
				inst.canslam = true
				inst.canwakeuphit = false
				inst.components.timer:StopTimer("stalk_cd")
				inst.components.scaler:SetScale(1.3)
			end
		end,
	},
	[4] = {
		hp = 0.4,
		fn = function(inst)
			inst.DynamicShadow:Enable(true)
			if inst.hostile then
				inst.canfatigue = false
				inst.nostalkcd = false
				inst.canstalk = true
				inst.canslam = true
				inst.canwakeuphit = true
				inst:ResetFatigue()
				inst:RemoveTag("shadowhide")
				inst.components.scaler:SetScale(1.4)
			end
		end,
	},
	[5]={
		hp = 0.2,
		fn = function(inst)
			inst.DynamicShadow:Enable(false)
			if inst.hostile then
				inst.canfatigue = false
				inst.nostalkcd = false
				inst.canstalk = false
				inst.canslam = true
				inst.canwakeuphit = true
				inst:AddTag("shadowhide")
				inst.AnimState:HideSymbol("HEAD_follow")
				inst.components.scaler:SetScale(1.4)
			end
		end,
	},
}


local function OnLoad(inst, data)
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
	if data.hostile then
		local healthpct = inst.components.health:GetPercent()
		for i = #PHASES, 1, -1 do
			local v = PHASES[i]
			if healthpct <= v.hp then
				v.fn(inst)
				break
			end
		end
	end
	
end


local function CalcaulteTargetAlpha(self)
	if not self.inst:HasTag("shadowhide") then
		return 1
	end

	local player = ThePlayer
	if player == nil or not player:IsValid() then
		return 0
	end

	local dist = self.inst:GetDistanceSqToInst(player)

	local pct = Remap(math.min(dist,16),0,16,0.25,0)
	local combat = self.inst.replica.combat
	if combat ~= nil and combat:GetTarget() == player then
		pct = pct * 2
	end
	local sanity = player.replica.sanity
	if sanity ~= nil then
		pct = (1 - sanity:GetPercent())*pct
	end
			
	return pct	
end

newcs_env.AddPrefabPostInit("daywalker",function(inst)
	inst:AddTag("notraptrigger")
	if not TheNet:IsDedicated() then
		-- this is purely view related
		inst:AddComponent("transparentonsanity")
		inst.components.transparentonsanity.most_alpha = 1
		inst.components.transparentonsanity.osc_amp = .1
		inst.components.transparentonsanity.CalcaulteTargetAlpha = CalcaulteTargetAlpha
		inst.components.transparentonsanity:ForceUpdate()
	end

	if not TheWorld.ismastersim then 
		return 
	end

	local healthtrigger = inst.components.healthtrigger.triggers
	for k,v in pairs(healthtrigger) do
		healthtrigger[k] = nil
	end
	for i, v in ipairs(PHASES) do
		healthtrigger[v.hp] = v.fn
	end
	
	inst:AddComponent("scaler")


	inst.OnLoad = OnLoad

end)
local AOE_TARGET_MUSTHAVE_TAGS = { "_combat" }
local AOE_TARGET_CANT_TAGS = { "INLIMBO", "flight", "invisible", "notarget", "noattack" }

------------------------------------
---------sinkhole
------------------------------------
--[[local function DoDamage(inst)
	local pos = inst:GetPosition()
	local ents = TheSim:FindEntities(pos.x, 0, pos.z, inst.radius, AOE_TARGET_MUSTHAVE_TAGS, AOE_TARGET_CANT_TAGS)
	for _, v in ipairs(ents) do
		if inst.components.combat:CanTarget(v) and  v.components.health ~= nil and not v.components.health:IsDead() 
			and v~=inst.owner then
			v.components.combat:GetAttacked(inst.owner,50)
		end
	end
end

AddPrefabPostInit("daywalker_sinkhole",function(inst)
	
	if not TheWorld.ismastersim then return end
	inst:AddComponent("combat")
	inst:ListenForEvent("docollapse", DoDamage)
end)]]


---stategraphs


local AOE_RANGE_PADDING = 3
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
	if inst.canslam and not running and (inst.nostalkcd or math.random() < 0.3) or 
		(inst.canwakeuphit and math.random()>0.5 ) then
		inst.sg:GoToState("attack_slam_pre", inst.components.combat.target)
	else
		inst.sg:GoToState("attack_pounce_pre", {
			running = running,
			target = inst.components.combat.target,
		})
	end
	return true
end


newcs_env.AddStategraphPostInit("daywalker",function(sg)
	sg.events["doattack"].fn = function(inst)
		if not (inst.sg:HasStateTag("busy") or inst.defeated) then
			ChooseAttack(inst)
		end
	end
	--[[local _name,DoAOEAttack
	_name,DoAOEAttack= debug.getupvalue(sg.states.attack_slam.timeline[12].fn,1)]]
	sg.states.attack_slam.timeline[12].fn=function(inst)
		inst.sg.statemem.speed = 4
		inst.sg.statemem.decel = -1
		local x, y, z = inst.Transform:GetWorldPosition()
		local rot = inst.Transform:GetRotation() * DEGREES

		local cos_x = math.cos(rot)
		local sin_x = math.sin(rot)
		for i = 0,2 do
			local sinkhole = SpawnPrefab("daywalker_sinkhole")
			sinkhole.owner = inst
			sinkhole.Transform:SetPosition(x+i*DIST*cos_x,0,z-i*DIST*sin_x)
			sinkhole:PushEvent("docollapse")
		end

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
	sg.states.attack_slam.onupdate = function (inst)
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
				if inst:HasTag("shadowhide") then
					rot1 = rot + math.clamp(drot/2, -3, 3)
					inst.Transform:SetRotation(rot1)
				elseif math.abs(drot) < 120 then
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
	end
	sg.states.defeat.onenter = function(inst)
		inst.components.locomotor:Stop()
		inst:SwitchToFacingModel(0) --inst.Transform:SetNoFaced()
		inst.AnimState:PlayAnimation("defeat")
		inst:RemoveTag("shadowhide")
		inst.AnimState:ShowSymbol("HEAD_follow")
		inst.components.scaler:SetScale(1)
	end

end)