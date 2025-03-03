

local brain = require "brains/twinofterror2brain"
----------------------------------------------------------------
local RETARGET_MUST_TAGS = { "_combat" }
local RETARGET_CANT_TAGS = { "decor", "eyeofterror", "FX", "INLIMBO", "NOCLICK", "notarget", "playerghost", "wall"}
local RETARGET_ONEOF_TAGS = { "player"}
local function update_targets(inst)
    local to_remove = {}
    local pos = inst:GetPosition()

    for k, _ in pairs(inst.components.grouptargeter:GetTargets()) do
        to_remove[k] = true
    end

    local ents_near_spawnpoint = TheSim:FindEntities(
        pos.x, 0, pos.z,
        TUNING.EYEOFTERROR_DEAGGRO_DIST,
        RETARGET_MUST_TAGS, RETARGET_CANT_TAGS, RETARGET_ONEOF_TAGS
    )
    for _, v in ipairs(ents_near_spawnpoint) do
        if to_remove[v] then
            to_remove[v] = nil
        else
            inst.components.grouptargeter:AddTarget(v)
        end
    end

    for non_target, _ in pairs(to_remove) do
        inst.components.grouptargeter:RemoveTarget(non_target)
    end
end

local TARGET_DIST = 30
local function get_target_test_range(inst, use_short_dist, target)
	return inst.sg:HasStateTag("charge")
		and inst.components.stuckdetection:IsStuck()
		and TUNING.EYEOFTERROR_CHARGE_AOERANGE + target:GetPhysicsRadius(0)
		or (use_short_dist and 8 + target:GetPhysicsRadius(0))
		or TARGET_DIST
end
local function ShareTargetFn(dude)
    return dude:HasTag("eyeofterror")
end
local function RetargetFn(inst)
	if inst:IsInLimbo() then
		return
	end
    local target0
    update_targets(inst)

    local current_target = inst.components.combat.target
    local target_in_range = current_target ~= nil and current_target:IsNear(inst, 8 + current_target:GetPhysicsRadius(0))

    if current_target ~= nil and current_target:HasTag("player") then
        local new_target = inst.components.grouptargeter:TryGetNewTarget()
        return (new_target ~= nil
			and new_target:IsNear(inst, get_target_test_range(inst, target_in_range, new_target))
            and new_target)
            or nil,
            true
    end

    local targets_in_range = {}
    for target, _ in pairs(inst.components.grouptargeter:GetTargets()) do
		if inst:IsNear(target, get_target_test_range(inst, target_in_range, target)) then
            table.insert(targets_in_range, target)
        end
    end
    if #targets_in_range > 0  then
        target0=targets_in_range[1]
        inst.components.combat:ShareTarget(target0, 36, ShareTargetFn, 5)
    end
    return target0, true
end

local TARGET_DSQ = TARGET_DIST * TARGET_DIST
local function KeepTargetFn(inst, target)
    return not inst:IsInLimbo() and inst.components.combat:CanTarget(target)
        --and target:GetDistanceSqToPoint(inst.components.knownlocations:GetLocation("spawnpoint")) < TARGET_DSQ
end

local function warning(inst, data)
    if data.attacker then
        inst.components.combat:ShareTarget(data.attacker, 36, ShareTargetFn, 8)
        if data.attacker:HasTag("player") then
            inst.attackerUSERIDs[data.attacker.userid] = true
        end
    end
end


--[[local function doupgrade(inst)
    if inst.sg.mem.transformed then
        local x,y,z=inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x,y,z, 24,{"_health"},nil)
        for i,v in ipairs(ents) do
            if (v.twin1 or v.twin2) and not v.components.health:IsDead() then
                v:PushEvent("health_transform")
            end
        end
    end
end]]




local function nofreeze()
    return true
end


local function SetStalking(inst, stalking)
	if stalking ~= inst._stalking then
        if inst._stalking ~= nil then
            inst:RemoveEventCallback("onremove", inst._onremovestalking, inst._stalking)
        end
        inst._stalking = stalking
        if stalking then
            inst:ListenForEvent("onremove", inst._onremovestalking, stalking)
            inst.components.timer:StopTimer("stalk_cd")
            inst.components.timer:StartTimer("stalk_cd", 30)
        end
	end
end

local function IsStalking(inst)
	return inst._stalking ~= nil
end



newcs_env.AddPrefabPostInit("twinofterror1",function(inst)
    inst:AddTag("no_rooted")
    inst:AddTag("nosinglefight_l")
    if not TheWorld.ismastersim then return end

    inst.cycle = false
    inst.twin1=true

    inst:AddComponent("planarentity")

    inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(30)

    MakePlayerOnlyTarget(inst)

    
    if inst.components.shockable then
        inst:RemoveComponent("shockable") 
     end


    inst.components.sleeper:SetResistance(500)

    inst.components.combat:SetRange(18)

    inst.components.locomotor.walkspeed =  8
    --inst.components.locomotor.runspeed = 18
    inst.components.locomotor.pathcaps = { ignorewalls = true, allowocean = true }

    --inst:AddComponent("follower")
    inst.components.freezable:SetRedirectFn(nofreeze)
    inst.components.combat:SetRetargetFunction(1, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    inst:AddComponent("entitytracker")

    inst.SetStalking = SetStalking
	inst.IsStalking = IsStalking
    inst._onremovestalking = function(stalking) inst._stalking = nil end

    inst.attackerUSERIDs = {}
    inst:ListenForEvent("attacked", warning)

    inst:SetStateGraph("SGtwinofterror")
    inst:SetBrain(brain)



    MakeSmartAbsorbDamageEnt(inst)

end)

newcs_env.AddPrefabPostInit("twinofterror2",function(inst)
    inst:AddTag("no_rooted")
    inst:AddTag("nosinglefight_l")
    if not TheWorld.ismastersim then return end

    inst.cycle = true
    inst.twin2=true



    inst.components.sleeper:SetResistance(500)
    inst.components.freezable:SetRedirectFn(nofreeze)

    inst.components.combat:SetRange(16)
    
    inst.components.locomotor.walkspeed = 8
    --inst.components.locomotor.runspeed = 18
    inst.components.locomotor.pathcaps = { ignorewalls = true, allowocean = true }

    inst:AddComponent("planarentity")

    inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(30)

    MakePlayerOnlyTarget(inst)


    if inst.components.shockable then
        inst:RemoveComponent("shockable") 
     end

    inst.components.combat:SetRetargetFunction(1, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    --inst:AddComponent("leader")
    inst:AddComponent("entitytracker")

    inst.SetStalking = SetStalking
	inst.IsStalking = IsStalking
    inst._onremovestalking = function(stalking) inst._stalking = nil end

    inst:SetStateGraph("SGtwinofterror")
    inst:SetBrain(brain)



    inst.attackerUSERIDs = {}
    inst:ListenForEvent("attacked", warning)

    MakeSmartAbsorbDamageEnt(inst)
    --inst.OnSave = OnSave
    --inst.OnLoad = OnLoad
end)

local function AbleToAcceptTest(inst, item, giver)
    if inst.components.worldsettingstimer:ActiveTimerExists("cooldown") then
        return false, "TERRARIUM_COOLDOWN"
    elseif item.prefab ~= "purebrilliance" then
        return false, "TERRARIUM_REFUSE"
    elseif inst._iscrimson:value() then
        return false, "SLOTFULL"
    else
        return true
    end
end

newcs_env.AddPrefabPostInit("terrarium",function(inst)
    if not TheWorld.ismastersim then return end
    inst.components.trader:SetAbleToAcceptTest(AbleToAcceptTest)
end)



local function make_team(inst, target)
    local twin1 = inst.components.entitytracker:GetEntity("twin1")

    local twin2 = inst.components.entitytracker:GetEntity("twin2")
    if twin1 and twin2 then
        twin2.components.entitytracker:TrackEntity("twin", twin1)
        twin1.components.entitytracker:TrackEntity("twin", twin2)
        --twin1.components.follower:SetLeader(twin2)
        --twin1.components.follower:StartLeashing()
    end
end

local function hookup_twin_listeners(inst, twin)
    inst:ListenForEvent("onremove", function(t)
        local et = inst.components.entitytracker
        if et:GetEntity("twin1") == nil and et:GetEntity("twin2") == nil then
            inst:Remove()
        end
    end, twin)

	inst:ListenForEvent("forgetme", function(t)
		local et = inst.components.entitytracker
		local t1 = et:GetEntity("twin1")
		local t2 = et:GetEntity("twin2")
		if t1 == t then
			if t2 == nil then
				inst:Remove()
			else
				et:ForgetEntity("twin1")
				if t2:IsInLimbo() and not t1:IsInLimbo() then
					inst:PushEvent("finished_leaving")
				end
			end
		elseif t2 == t then
			if t1 == nil then
				inst:Remove()
			else
				et:ForgetEntity("twin2")
				if t1:IsInLimbo() and not t2:IsInLimbo() then
					inst:PushEvent("finished_leaving")
				end
			end
		end
	end, twin)

    inst:ListenForEvent("death", function(t)
        local et = inst.components.entitytracker
        local t1 = et:GetEntity("twin1")
        local t2 = et:GetEntity("twin2")
        if (t1 == nil or t1.components.health:IsDead()) and (t2 == nil or t2.components.health:IsDead()) then
            -- This only really works because SetLoot doesn't clear lootdropper.chanceloottable
            local EXTRA_LOOT = {"chesspiece_twinsofterror_sketch"}
            for k,v in pairs(t.attackerUSERIDs) do
                table.insert(EXTRA_LOOT,"insight_soul")
            end
            t.components.lootdropper:SetLoot(EXTRA_LOOT)
        end
    end, twin)

    inst:ListenForEvent("turnoff_terrarium", function(t)
        local et = inst.components.entitytracker
        local t1 = et:GetEntity("twin1")
        local t2 = et:GetEntity("twin2")
        if (t1 == nil or t1.components.health:IsDead())
                and (t2 == nil or t2.components.health:IsDead()) then
            inst:PushEvent("turnoff_terrarium")
            inst:Remove()
        end
    end, twin)

    inst:ListenForEvent("finished_leaving", function(t)
        if t ~= nil and not t:IsInLimbo() then
            t:RemoveFromScene()
        end

        local et = inst.components.entitytracker
        local t1 = et:GetEntity("twin1")
        local t2 = et:GetEntity("twin2")
        if (t1 == nil or t1:IsInLimbo()) and (t2 == nil or t2:IsInLimbo()) then
            inst:PushEvent("finished_leaving")
        end
    end, twin)

    inst:ListenForEvent("healthdelta", function(t, data)
        local et = inst.components.entitytracker
        local t1 = et:GetEntity("twin1")
        local t2 = et:GetEntity("twin2")

        local t1_health = (t1 == nil and 0) or t1.components.health.currenthealth
        local t2_health = (t2 == nil and 0) or t2.components.health.currenthealth
        if (t1_health + t2_health) < ((TUNING.TWIN1_HEALTH + TUNING.TWIN2_HEALTH) * TUNING.EYEOFTERROR_TRANSFORMPERCENT) then
            if t1 ~= nil then
                t1:PushEvent("health_transform")
            end

            if t2 ~= nil then
                t2:PushEvent("health_transform")
            end
        end
    end, twin)
end




newcs_env.AddPrefabPostInit("twinmanager",function(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("set_spawn_target", make_team)

    --inst:DoPeriodicTask(10, Dont_skip,30)
    debug.setupvalue(inst.OnLoadPostPass,1,hookup_twin_listeners)
end)