local function TrueFn()
	return true
end

---------------------------------------
local function bearger_process(inst,data)
    inst.components.health:SetMaxHealth(8000)
    inst.components.locomotor.walkspeed = 8
    inst.components.combat:SetAttackPeriod(2)

	inst:AddComponent("true_damage")
    inst.components.true_damage:SetBaseDamage(8)
end
---------------------------------------
local function MakeBaby(inst,prefab)
    local angle = (inst.Transform:GetRotation() + 180) * DEGREES
    
    local spider = SpawnPrefab(prefab)
    if spider ~= nil then
        local rad = spider:GetPhysicsRadius(0) + inst:GetPhysicsRadius(0) + .25
        local x, y, z = inst.Transform:GetWorldPosition()
        spider.Transform:SetPosition(x + rad * math.cos(angle), 0, z - rad * math.sin(angle))
        spider.sg:GoToState("taunt")
		spider.components.lootdropper.DropLoot = TrueFn
        inst.components.leader:AddFollower(spider)
        if inst.components.combat.target ~= nil then
            spider.components.combat:SetTarget(inst.components.combat.target)
        end
    end
end

local function MakeBabies(inst)
	MakeBaby(inst,"spider_dropper")

	local type = math.random() > 0.5 and "spider_spitter" or "spider_healer"
	MakeBaby(inst,type)
end

local function MaxBabies(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = FindPlayersInRangeSq(x, y, z, 400, true)
    return RoundBiasedDown(#ents*8)
end

local function AdditionalBabies(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = FindPlayersInRangeSq(x, y, z, 400, true)
    return RoundBiasedUp(#ents * 2)
end

local function spider_process(inst)
	inst.components.health:SetMaxHealth(8000)
	inst.components.incrementalproducer.producefn = MakeBabies
	inst.components.incrementalproducer.maxcountfn = MaxBabies
	inst.components.incrementalproducer.incrementfn =	AdditionalBabies
end
--------------------------------------------
local function antlion_process(inst,data)
	inst:StartCombat()
end
--------------------------------------------
local function deerclops_process(inst)
    inst.components.health:SetMaxHealth(8000)
    inst.components.locomotor.walkspeed = 8
    inst.components.combat:SetAttackPeriod(3)
	inst:AddComponent("true_damage")
    inst.components.true_damage:SetBaseDamage(8)
end

local function winter_coming(inst)
	inst.components.temperatureoverrider:SetTemperature(-20)
	inst.components.temperatureoverrider:Enable()
end
--------------------------------------------
local function sharkboi_process(inst)
	inst:AddTag("hostile")
	inst.components.health:SetMinHealth(0)
	inst:AddComponent("true_damage")
    inst.components.true_damage:SetBaseDamage(8)
end
---------------------------------------------
local function bee_process(inst,manager)
	inst.components.health:SetMaxHealth(18000)
    inst.components.locomotor.walkspeed = 6
end
---------------------------------------------
local function dragon_process(inst,manager)
	inst.components.health:SetMaxHealth(18000)
    inst.components.combat:SetAttackPeriod(3)
	inst:AddComponent("true_damage")
    inst.components.true_damage:SetBaseDamage(8)
end

local function fire_era(inst)
	inst.components.temperatureoverrider:SetTemperature(80)
	inst.components.temperatureoverrider:Enable()

	local x, y, z = inst.Transform:GetWorldPosition()

	local angle_delta=0.4*PI
	for i=1, 5	do
		local lava = SpawnPrefab("lava_pond")
		lava.Transform:SetPosition(x + 24*math.cos(angle_delta*i), 0, z - 24* math.sin(angle_delta*i))
	end
end
---------------------------------------------
local function toadstool_process(inst)
	inst.components.health:SetMaxHealth(20000)
end
---------------------------------------------
local function eye_process(inst)
	TheNet:Announce(STRINGS.EYEOFTERROR_COMING)
	local x,y,z = inst.Transform:GetWorldPosition()
	local player = FindClosestPlayerInRangeSq(x, y, z,	900, true)
	inst.sg:GoToState("arrive", player)
	inst:PushEvent("set_spawn_target", player)
	inst:AddComponent("true_damage")
    inst.components.true_damage:SetBaseDamage(5)
end
---------------------------------------------
local function klaus_process(inst)
	local pos = inst:GetPosition()
	local minplayers = math.huge
	local spawnx, spawnz
	FindWalkableOffset(pos,
		math.random() * 2 * PI, 33, 16, true, true,
		function(pt)
			local count = #FindPlayersInRangeSq(pt.x, pt.y, pt.z, 400)
			if count < minplayers then
				minplayers = count
				spawnx, spawnz = pt.x, pt.z
				return count <= 0
			end
			return false
		end)

	if spawnx == nil then
		--No spawn point (with or without players), so try closer
		local offset = FindWalkableOffset(pos, math.random() * 2 * PI, 3, 8, false, true)
		if offset ~= nil then
			spawnx, spawnz = pos.x + offset.x, pos.z + offset.z
		end
	end

	local klaus = SpawnPrefab("klaus")
	klaus.Transform:SetPosition(spawnx or pos.x, 0, spawnz or pos.z)
	klaus.components.health:SetMaxHealth(8000*inst.mode)
	klaus:SpawnDeer()
	-- override the spawn point so klaus comes to his sack
	klaus.components.knownlocations:RememberLocation("spawnpoint", pos, false)
	klaus.components.spawnfader:FadeIn()
	klaus.components.lootdropper.DropLoot = TrueFn
	inst:ListenForEvent("death",function (klaus)
		if klaus:IsUnchained() then
			inst:NextStage()
		end		
	end,klaus)
	
end
--------------------------------------------
local function minotaur_process(inst)
	inst.components.combat:SetAttackPeriod(0.5)
	inst.components.locomotor.walkspeed = 7
    inst.components.locomotor.runspeed = 19
	inst:AddComponent("true_damage")
    inst.components.true_damage:SetBaseDamage(10)
end
local function pillar_process(inst)
	local x, y, z = inst.Transform:GetWorldPosition()

	local pillar1 = SpawnPrefab("pillar_ruins")
	pillar1.Transform:SetPosition(x +14, 0, z + 14)

	local pillar4 = SpawnPrefab("pillar_ruins")
	pillar4.Transform:SetPosition(x -14, 0, z - 14)

end
-------------------------------------------
local function daywalker_process(inst)
	inst.components.health:SetMinHealth(0)
	inst:AddComponent("true_damage")
    inst.components.true_damage:SetBaseDamage(10)
end
-------------------------------------------
local function heart_process(inst)	
	inst:PushEvent("summon")
end
--------------------------------------------
local function SummonSpawn(pt, upgrade)
	local spawn_pt
    local function OceanSpawnPoint(offset)
		local x = pt.x + offset.x
		local y = pt.y + offset.y
		local z = pt.z + offset.z
		return TheWorld.Map:IsAboveGroundAtPoint(x, y, z, true)
	end

	local offset = FindValidPositionByFan(math.random() * PI2, 24, 12, OceanSpawnPoint)
	if offset ~= nil then
		offset.x = offset.x + pt.x
		offset.z = offset.z + pt.z
		spawn_pt = offset
	end
    if spawn_pt ~= nil then
        local spawn = SpawnPrefab("hound")
        if spawn ~= nil then
            spawn.Physics:Teleport(spawn_pt:Get())
            spawn:FacePoint(pt)
			spawn.components.lootdropper.DropLoot = TrueFn
            if spawn.components.spawnfader ~= nil then
                spawn.components.spawnfader:FadeIn()
            end
            return spawn
        end
    end
end
local function SpawnHounds(inst, radius_override)
    local hounds = nil


    local num = 10
    if inst.max_hound_spawns then
        num = math.min(num,inst.max_hound_spawns)
        inst.max_hound_spawns = inst.max_hound_spawns - num
    end

    local pt = inst:GetPosition()
    for i = 1, num do
        local hound = SummonSpawn(pt)
        if hound ~= nil then
            if hound.components.follower ~= nil then
                hound.components.follower:SetLeader(inst)
            end
            if hounds == nil then
                hounds = {}
            end
            table.insert(hounds, hound)
        end
    end
    return hounds
end
local function mutatedwarg_postinit(inst)
	inst.components.health:SetMaxHealth(6000)
	inst.SpawnHounds = SpawnHounds
	inst:AddComponent("true_damage")
    inst.components.true_damage:SetBaseDamage(10)
end
--------------------------------------------
local function mutatedbearger_postinit(inst)
	inst.components.locomotor.walkspeed = 8
	inst.components.locomotor.runspeed = 12
    inst.components.combat:SetAttackPeriod(1)
	inst:AddComponent("true_damage")
    inst.components.true_damage:SetBaseDamage(10)
end
--------------------------------------------
local function daywalker2_postinit(inst)
	inst.components.health:SetMinHealth(0)
	inst:SetEngaged(true)
	inst.OnItemUsed = TrueFn
    inst:SetEquip("swing", "object")
    inst:SetEquip("tackle", "spike")
    inst:SetEquip("cannon", "cannon")
end
-------------------------------------------
local function stalker_postinit(inst)
	inst.components.health:SetMaxHealth(18000)
	inst.IsNearAtrium = TrueFn
	inst.components.lootdropper.DropLoot = TrueFn
	inst:AddComponent("true_damage")
    inst.components.true_damage:SetBaseDamage(20)
end
--------------------------------------------
local function hookup_twin_listeners(inst, twin)
	inst:ListenForEvent("death", function(t)
        local et = inst.components.entitytracker
        local t1 = et:GetEntity("twin1")
        local t2 = et:GetEntity("twin2")
        if (t1 == nil or t1.components.health:IsDead()) and (t2 == nil or t2.components.health:IsDead()) then
            -- This only really works because SetLoot doesn't clear lootdropper.chanceloottable
            inst:NextStage()
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
local TWINS_SPAWN_OFFSET = 5
local function get_spawn_positions(inst, targeted_player)
    local manager_position = inst:GetPosition()
    local player_position = targeted_player:GetPosition()
    local manager_to_player = (player_position - manager_position):Normalize()

    local offset_unit = manager_to_player:Cross(Vector3(0, 1, 0)):Normalize()

    local offset1_angle = math.atan2(offset_unit.z, offset_unit.x)
    local twin1_offset = FindWalkableOffset(manager_position, offset1_angle, TWINS_SPAWN_OFFSET, nil, false, true, nil, true, true)
        or (offset_unit * TWINS_SPAWN_OFFSET)

    local offset2_angle = offset1_angle + PI
    local twin2_offset = FindWalkableOffset(manager_position, offset2_angle, TWINS_SPAWN_OFFSET, nil, false, true, nil, true, true)
        or (offset_unit * -1 * TWINS_SPAWN_OFFSET)

    return manager_position + twin1_offset, manager_position + twin2_offset
end
local function twin_process(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local player = FindClosestPlayerInRangeSq(x, y, z,	900, true)

	local twin1spawnpos, twin2spawnpos = get_spawn_positions(inst, player)

    local twin1 = SpawnPrefab("twinofterror1")
	twin1.components.health:SetMaxHealth(10000*inst.mode)
	twin1.components.lootdropper.DropLoot = TrueFn
    inst.components.entitytracker:TrackEntity("twin1", twin1)
    twin1.Transform:SetPosition(twin1spawnpos:Get())
    twin1.sg:GoToState("arrive")
    hookup_twin_listeners(inst, twin1)

    local twin2 = SpawnPrefab("twinofterror2")
	twin2.components.health:SetMaxHealth(10000*inst.mode)
	twin2.components.lootdropper.DropLoot = TrueFn
    inst.components.entitytracker:TrackEntity("twin2", twin2)
    twin2.Transform:SetPosition(twin2spawnpos:Get())
    twin2.sg:GoToState("arrive_delay")
    hookup_twin_listeners(inst, twin2)
end
--------------------------------------------
local function alter_process(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local boss = SpawnPrefab("alterguardian_phase1")
	boss.Transform:SetPosition(x,0,z)

	if boss.components.lootdropper~=nil then
		boss.components.lootdropper.DropLoot = TrueFn
	end

	boss.sg:GoToState("prespawn_idle")
	inst:ListenForEvent("moonboss_defeated", function()
		inst:NextStage()
	end,	TheWorld)		

	for i, v in ipairs(AllPlayers) do
        if v.entity:IsVisible() and
            v:GetDistanceSqToPoint(x, y, z) < 2500 then
			v.components.sanity:EnableLunacy(true, "bossrush")
        end
    end
	
end
--------------------------------------------
local function Chat(inst,i)
	inst.components.talker:Chatter("BOSSRUSH", i, nil, nil, CHATPRIORITIES.HIGH)
end

local function lv1_start(inst)
	inst.level = 1
	inst:DoTaskInTime(40,function ()
		inst._musicdirty:set(1)
		inst:NextStage()
	end)
	inst:DoTaskInTime(10,Chat,2)
	inst:DoTaskInTime(20,Chat,3)
	inst:DoTaskInTime(30,Chat,4)
	inst:DoTaskInTime(35,Chat,5)
end

local function lv2_start(inst)
	inst.level = 2
	inst:DoTaskInTime(10,inst.NextStage)
	Chat(inst,6)
end
local function lv3_start(inst)
	inst.level = 3
	inst:DoTaskInTime(10,inst.NextStage)
	Chat(inst,7)
end
local function lv4_start(inst)
	inst.level = 4
	inst:DoTaskInTime(10,inst.NextStage)
	Chat(inst,8)
end
local function lv5_start(inst)
	inst.level = 5
	inst:DoTaskInTime(10,inst.NextStage)
	Chat(inst,9)
end



---------------------------------------------
local program = {

	---------------level 1-----------------
	{initfn = lv1_start, type_special = true},  --1
    {boss = "bearger",      postinitfn = bearger_process},
	{boss = "spiderqueen",  postinitfn = spider_process},
	{boss = "antlion",      postinitfn = antlion_process},
	{boss = "deerclops",    postinitfn = deerclops_process,	scenery_postinit = winter_coming},

	--------------level 2-------------------
	{initfn = lv2_start, type_special = true},  --6
	{boss = "eyeofterror",	postinitfn	= eye_process},
	{boss = "sharkboi",		postinitfn	= sharkboi_process},
    {boss = "beequeen",     postinitfn 	= bee_process},
	{boss = "dragonfly",	postinitfn	= dragon_process,	scenery_postinit = fire_era},
	{boss = "toadstool",	postinitfn	= toadstool_process},

	--------------level 3-------------------
	{initfn = lv3_start, 	type_special = true},  --12
	{boss = "klaus",		initfn	= klaus_process,	type_special = true},
	{boss = "minotaur",		postinitfn	= minotaur_process,	scenery_postinit= pillar_process},
	{boss = "daywalker",	postinitfn 	= 	daywalker_process},
	{boss = "corrupt_heart",postinitfn = heart_process},

	--------------level 4-------------------
	{initfn = lv4_start, type_special = true},  --17
	{boss = "mutateddeerclops",	scenery_postinit = winter_coming},
	{boss = "mutatedwarg",		postinitfn = mutatedwarg_postinit},
	{boss = "mutatedbearger",	postinitfn = mutatedbearger_postinit},
	{boss = "daywalker2",		postinitfn = daywalker2_postinit},

	-------------level 5----------------------
	{initfn = lv5_start, type_special = true},  --22
	{boss = "stalker_atrium",	postinitfn = stalker_postinit},
	{boss = "ancient_hulk"},
	{boss = "twinofterror",		initfn	= twin_process, type_special = true},
	{boss = "alterguardian",	initfn	= alter_process, type_special = true},
}

local function UpdatePlayerTargets(inst)
	local toadd = {}
	local toremove = {}
	local x, y, z = inst.Transform:GetWorldPosition()

	for k in pairs(inst.components.grouptargeter:GetTargets()) do
		toremove[k] = true
	end
	for i, v in ipairs(FindPlayersInRange(x, y, z, 40, true)) do
		if toremove[v] then
			toremove[v] = nil
		else
			table.insert(toadd, v)
		end
	end

	for k in pairs(toremove) do
		inst.components.grouptargeter:RemoveTarget(k)
	end
	for i, v in ipairs(toadd) do
		inst.components.grouptargeter:AddTarget(v)
	end
end

local function RetargetFn(inst)
	UpdatePlayerTargets(inst)

	local target = inst.components.combat.target
	local inrange = target ~= nil and inst:IsNear(target, 30 + target:GetPhysicsRadius(0))

	if target ~= nil and target:HasTag("player") then
		local newplayer = inst.components.grouptargeter:TryGetNewTarget()
		return newplayer ~= nil
			and newplayer:IsNear(inst, inrange and 12 + newplayer:GetPhysicsRadius(0) or 22)
			and newplayer
			or nil,
			true
	end

	local nearplayers = {}
	for k in pairs(inst.components.grouptargeter:GetTargets()) do
		if inst:IsNear(k, inrange and 18 + k:GetPhysicsRadius(0) or 30) then
			table.insert(nearplayers, k)
		end
	end
	return #nearplayers > 0 and nearplayers[math.random(#nearplayers)] or nil, true
end
local function KeepTargetFn(inst, target)
	return inst.components.combat:CanTarget(target)
		and target:IsNear(inst, 20)
end

local function ClearLand(inst)
	inst.components.temperatureoverrider:Disable()

	local x,y,z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, 0, z, 40, nil, {"player"})
	for i,v in ipairs(ents) do
		if v:HasOneOfTags("groundspike","rocky","lava","deer","charge_barrier","ancient_hulk_mine","structure","hound","quakedebris") 
			or v.prefab=="bigshadowtentacle"
			or v.prefab=="burntground" 
			or v.prefab=="moonrocknugget"
			or v.prefab=="moonglass"	then
			v:Remove()
		end
	end

	for i, v in ipairs(AllPlayers) do
        if v.entity:IsVisible() and
            v:GetDistanceSqToPoint(x, y, z) < 2500 then
			v.components.sanity:EnableLunacy(false, "bossrush")
        end
    end
end

local ProgressReset = {1,6,12,17,22}

local function ResetProgress(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, 0, z, 50, nil, {"player"},{"epic","hound","ancient_hulk_mine","groundspike"})
	for i,v in ipairs(ents) do
		v:Remove()
	end
	if not inst.level == 6 then
		inst._musicdirty:push()
		inst.progress = ProgressReset[inst.level]
		inst:OnProgressStart()
	end
end

local commonfn = {
    retarget = RetargetFn,
    keeptarget = KeepTargetFn,
	clearland = ClearLand,
}

return {program = program, commonfn = commonfn}


