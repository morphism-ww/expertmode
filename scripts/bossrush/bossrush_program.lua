local function TrueFn()
	return true
end

local function MakeNoStun(inst)
	inst:AddTag("no_rooted")
	if inst.sg.sg.events.attacked then
		inst.sg.sg.events.attacked.fn = function ()
			return false
		end
	end
end

---------------------------------------
local function bearger_process(inst,data)
	local brain = require("brains/bossrush_beargerbrain")
	inst:SetBrain(brain)
    inst.Transform:SetScale(1.5,1.5,1.5)
	inst:RemoveTag("hibernation")
	inst.components.combat:SetRange(4,8)
	MakeNoStun(inst)
	inst.components.groundpounder.ringWidth = 2
	inst.components.groundpounder.numRings = 4
	inst.components.groundpounder.damageRings = 4
	inst.components.groundpounder.destructionRings = 4
	inst.components.sleeper:SetResistance(30)
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
		spider:AddComponent("planarentity")
		MakeNoStun(spider)
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
	MakeNoStun(inst)
	inst.components.incrementalproducer.producefn = MakeBabies
	inst.components.incrementalproducer.maxcountfn = MaxBabies
	inst.components.incrementalproducer.incrementfn =	AdditionalBabies
	inst.components.incrementalproducer.incrementdelay = 5
end
--------------------------------------------
local function antlion_process(inst,data)
	MakeNoStun(inst)
	inst:StartCombat()

end
--------------------------------------------
local function deerclops_process(inst)
	inst.Transform:SetScale(1.5,1.5,1.5)
	inst.components.combat:SetRange(6,TUNING.DEERCLOPS_ATTACK_RANGE)
    inst.components.locomotor.walkspeed = 12
	inst.freezepower = 5
	MakeNoStun(inst)
end

local function winter_coming(inst)
	inst.components.temperatureoverrider:SetTemperature(-20)
	
end
--------------------------------------------
local function sharkboi_process(inst)
	inst:AddTag("hostile")
	inst.Transform:SetScale(1.5,1.5,1.5)
	inst.components.health:SetMinHealth(0)
	inst:SetStateGraph("SGbr_sharkboi")
	inst:AddTag("no_rooted")
	inst.components.sleeper:SetResistance(30)

end
---------------------------------------------
local function bee_process(inst,manager)
	MakeNoStun(inst)
    inst.components.locomotor.walkspeed = 6
	inst.components.sleeper:SetResistance(20)
end
---------------------------------------------


local function fire_era(inst)
	inst.components.temperatureoverrider:SetTemperature(80)


	local x, y, z = inst.Transform:GetWorldPosition()

	local angle_delta = PI/2
	for i=1, 4	do
		local lava = SpawnPrefab("lava_pond")
		lava.Transform:SetPosition(x + 18*math.cos(angle_delta*i), 0, z - 18* math.sin(angle_delta*i))
	end
end

local function OnHealthTrigger(inst)
    inst:PushEvent("transform", { transformstate = "fire" })
    inst.components.rampingspawner:Start()
end

local function dragon_process(inst)
	for k,v in pairs(inst.components.healthtrigger.triggers) do
		inst.components.healthtrigger.triggers[k] = OnHealthTrigger
	end
	MakeNoStun(inst)
	inst.OnEntitySleep = TrueFn

	local brain = require("brains/br_dragonflybrain")
	inst:SetBrain(brain)
	
	inst.components.rampingspawner.spawn_prefab = "dragoon_cs"

	inst.components.sleeper:SetResistance(30)
	inst.components.freezable:SetResistance(50)
end
---------------------------------------------
local function toadstool_process(inst)
	MakeNoStun(inst)
	--inst.Transform:SetScale(0.5,0.5,0.5)
	local brain = require("brains/bossrush_toadstoolbrain")
	inst:SetBrain(brain)
	inst.components.sleeper:SetResistance(20)
end
---------------------------------------------
local function eye_process(inst)
	TheNet:Announce(STRINGS.EYEOFTERROR_COMING)

	local x,y,z = inst.Transform:GetWorldPosition()
	local player = FindClosestPlayerInRangeSq(x, y, z,	1600, true)
	inst.sg:GoToState("arrive", player)
	inst:PushEvent("set_spawn_target", player)
	MakeNoStun(inst)
	inst.components.sleeper:SetResistance(30)
	inst.components.freezable:SetResistance(30)
end
---------------------------------------------
local function klaus_process(inst)
	local pos = inst:GetPosition()
	local minplayers = math.huge
	local spawnx, spawnz
	FindWalkableOffset(pos,
		math.random() * 2 * PI, 30, 16, true, true,
		function(pt)
			local count = #FindPlayersInRangeSq(pt.x, pt.y, pt.z, 900)
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

	klaus.components.sleeper:SetResistance(30)
	klaus.components.freezable:SetResistance(10)
	klaus.Transform:SetPosition(spawnx or pos.x, 0, spawnz or pos.z)
	klaus.persists = false
	MakeNoStun(klaus)
	local pos = inst:GetPosition()
    local rot = klaus.Transform:GetRotation()
    local theta = (rot - 90) * DEGREES
    local offset =
        FindWalkableOffset(pos, theta, klaus.deer_dist, 5, true, false) or
        FindWalkableOffset(pos, theta, klaus.deer_dist * .5, 5, true, false) or
        Vector3(0, 0, 0)

    local deer = SpawnPrefab("deer_red")
    deer.Transform:SetRotation(rot)
    deer.Transform:SetPosition(pos.x + offset.x, 0, pos.z + offset.z)
	deer.components.health:SetAbsorptionAmount(0.99)
    deer.components.spawnfader:FadeIn()
    klaus.components.commander:AddSoldier(deer)

    theta = (rot + 90) * DEGREES
    offset =
        FindWalkableOffset(pos, theta, klaus.deer_dist, 5, true, false) or
        FindWalkableOffset(pos, theta, klaus.deer_dist * .5, 5, true, false) or
        Vector3(0, 0, 0)

    deer = SpawnPrefab("deer_blue")
    deer.Transform:SetRotation(rot)
    deer.Transform:SetPosition(pos.x + offset.x, 0, pos.z + offset.z)
	deer.components.health:SetAbsorptionAmount(0.99)
    deer.components.spawnfader:FadeIn()
    klaus.components.commander:AddSoldier(deer)
	
	klaus:AddComponent("planardamage")
	klaus.components.planardamage:SetBaseDamage(20)
	klaus.soulcount = 100
	-- override the spawn point so klaus comes to his sack
	klaus.components.knownlocations:RememberLocation("spawnpoint", pos, false)
	klaus.components.spawnfader:FadeIn()
	klaus.components.lootdropper.DropLoot = TrueFn
	inst:ListenForEvent("death",function (klaus)
		if klaus:IsUnchained() then
			inst.components.battlemanager:Next()
		end		
	end,klaus)
	
end
--------------------------------------------
local function TryShadowFire(inst)
    local startangle = 0
   
    local burst = 4
    
	local target = inst.components.combat.target
    for i=1,burst do
        local radius = 2
        local theta = startangle + (PI*2/burst*i) - (PI*2/burst)
        local offset = Vector3(radius * math.cos( theta ), 0, -radius * math.sin( theta ))

        local newpos = Vector3(inst.Transform:GetWorldPosition()) + offset
        local fire = SpawnPrefab("shadow_flame")
        fire.Transform:SetRotation(theta/DEGREES)
        fire.Transform:SetPosition(newpos.x,newpos.y,newpos.z)
		fire:settargetdread(target,20,inst)
    end
end
local function minotaur_process(inst)
	local brain = require("brains/bossrush_minotaurbrain")
	inst:SetBrain(brain)
	inst.atphase3 = true
	MakeNoStun(inst)
	inst.components.freezable:SetResistance(30)
	inst.components.sleeper:SetResistance(30)
	inst.components.groundpounder.groundpoundFn = TryShadowFire
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
	--inst:AddTag("shadowhide")
	inst.AnimState:HideSymbol("HEAD_follow")
	inst.components.health:SetMinHealth(0)
	MakeNoStun(inst)

	local healthtrigger = inst.components.healthtrigger.triggers
	healthtrigger[0.2](inst)
	for k,v in pairs(healthtrigger) do
		healthtrigger[k] = nil
	end
end
-------------------------------------------
local function ChessProcess(inst)
	inst:LevelUp(3)
	inst.persists = false
	inst.components.combat.playerdamagepercent = 1.5
	inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(25)
end
local function heart_process(inst)	
	inst:RemoveComponent("healthtrigger")

	inst:AddComponent("planarentity")
	inst:AddComponent("planardamage")
	inst.components.combat:SetAttackPeriod(4)
	inst.components.planardamage:SetBaseDamage(35)

	inst.echodamage = 100

	inst.StartBattle = function (inst)
		ChessProcess(inst:DoSpawnChess("shadow_rook"))
		ChessProcess(inst:DoSpawnChess("shadow_knight"))
		ChessProcess(inst:DoSpawnChess("shadow_bishop"))
	end
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
        local spawn = SpawnPrefab(math.random()<0.5 and "icehound" or "hound")
        if spawn ~= nil then
			spawn:AddComponent("planarentity")
			MakeNoStun(spawn)
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


    local num = 8
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
	MakeNoStun(inst)
	inst.SpawnHounds = SpawnHounds

end
--------------------------------------------
local function mutatedbearger_postinit(inst)
	local brain = require("brains/bossrush_beargerbrain")
	inst:SetBrain(brain)
	inst.components.combat:SetRange(4,TUNING.MUTATED_BEARGER_ATTACK_RANGE)
	MakeNoStun(inst)
	inst.components.groundpounder.ringWidth = 3
	inst.components.groundpounder.numRings = 5
	inst.components.groundpounder.damageRings = 5
	inst.components.groundpounder.destructionRings = 5

	inst.Transform:SetScale(1.6,1.6,1.6)
	inst.components.locomotor.walkspeed = 13
	inst.components.locomotor.runspeed = 15
end
--------------------------------------------
local function daywalker2_postinit(inst)
	inst.Transform:SetScale(1.5,1.5,1.5)
	inst.components.health:SetMinHealth(0)
	inst:SetEngaged(true)
	inst.OnItemUsed = TrueFn
	MakeNoStun(inst)
	inst.components.sleeper:SetResistance(30)
	inst.components.freezable:SetResistance(30)
    inst:SetEquip("swing", "object")
    inst:SetEquip("tackle", "spike")
    inst:SetEquip("cannon", "cannon")
end
-------------------------------------------
local function dont_leave(inst)
	local x,y,z=inst.Transform:GetWorldPosition()
	local players = FindPlayersInRange(x,y,z,50,true)
	for i,v in ipairs(players) do
		if v:IsValid() and not v:IsNear(inst, 26) then
			local px,py,pz = v.Transform:GetWorldPosition()
			SpawnPrefab("stalker_shield").Transform:SetPosition(1.02*(px-x)+x,0,1.02*(pz-z)+z)
			--v.Physics:Teleport(x,y,z)
		end
	end
end


local function darkworld(inst)
	if inst.leashtask==nil then
		inst.leashtask = inst:DoPeriodicTask(5*FRAMES, dont_leave)
	end
	local x,y,z = inst.Transform:GetWorldPosition()
	for i = -3,3 do
		for j = -3,3 do
			if i==3 or j==3 or i==-3 or j==-3 then
				local nightmare = SpawnPrefab("nightmaregrowth_abyss")
				nightmare.Transform:SetPosition(x+12*i,0,z+12*j)
				nightmare.components.workable:SetShouldRecoilFn(TrueFn)
			end
		end
	end

	inst._miastrigger:set(true)
	--SpawnPrefab("darkcloudring_spawner").Transform:SetPosition(inst.Transform:GetWorldPosition())
end
local function cleardarkworld(inst)
	if inst.leashtask~=nil then
		inst.leashtask:Cancel()
		inst.leashtask = nil
	end
	inst._miastrigger:set(false)
end	
local function spawnvortex(inst)
    local vortex = SpawnPrefab("darkvortex")
    vortex.Transform:SetPosition(inst.Transform:GetWorldPosition())
    --vortex.sg:GoToState("spawn")
    vortex:SetScale(2)
    inst._vortexes[vortex] = true
    inst:ListenForEvent("onremove",function (inst2)
        inst._vortexes[inst2] = nil
    end,vortex)
end
local function SpawnVortexes(inst)
    for i = 1,2 do
        spawnvortex(inst)
    end    
end 

local function stalker_postinit(inst)
	RemovePhysicsColliders(inst)
	inst.Physics:SetCollisionGroup(COLLISION.SANITY)
	inst.Physics:CollidesWith(COLLISION.SANITY)
	inst.SpawnVortex = SpawnVortexes
	inst.IsNearAtrium = TrueFn
end
--------------------------------------------
local function ironlord_postinit(inst) 
	
	inst.components.combat:SetAttackPeriod(2)
	inst.components.locomotor.walkspeed = 16
	inst.sg:GoToState("morph")
end
local function ancienthulk_postinit(inst)
	MakeNoStun(inst)
	inst.components.combat:SetAttackPeriod(1)
	inst.components.locomotor.walkspeed = 10
	inst.lob_count = 50
	inst.angry = true
	inst.cancharge = true
end
--------------------------------------------
local function hookup_twin_listeners(inst, twin)
	inst:ListenForEvent("death", function(t)
        local et = inst.components.entitytracker
        local t1 = et:GetEntity("twin1")
        local t2 = et:GetEntity("twin2")
        if (t1 == nil or t1.components.health:IsDead()) and (t2 == nil or t2.components.health:IsDead()) then
            -- This only really works because SetLoot doesn't clear lootdropper.chanceloottable
            inst.components.battlemanager:Next()
        end
    end, twin)

    inst:ListenForEvent("healthdelta", function(t, data)
        local et = inst.components.entitytracker
        local t1 = et:GetEntity("twin1")
        local t2 = et:GetEntity("twin2")

        local t1_health = (t1 == nil and 0) or t1.components.health:GetPercent()
        local t2_health = (t2 == nil and 0) or t2.components.health:GetPercent()
        if (t1_health< 0.6 or t2_health<0.6) then
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
	local player = FindClosestPlayerInRangeSq(x, y, z,	1600, true) or inst

	local twin1spawnpos, twin2spawnpos = get_spawn_positions(inst, player)

    local twin1 = SpawnPrefab("twinofterror1")


	twin1.components.lootdropper.DropLoot = TrueFn
	twin1.persists = false
    inst.components.entitytracker:TrackEntity("twin1", twin1)
    twin1.Transform:SetPosition(twin1spawnpos:Get())
    twin1.sg:GoToState("arrive")
    hookup_twin_listeners(inst, twin1)

    local twin2 = SpawnPrefab("twinofterror2")
	twin2.persists = false
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
	inst:ListenForEvent("moonboss_defeated", function(world)
		world.components.voidland_manager:ForceLunacy(false)
		inst.components.battlemanager:Next()
	end,	TheWorld)		

	--[[for i, v in ipairs(AllPlayers) do
        if v.entity:IsVisible() and
            v:GetDistanceSqToPoint(x, y, z) < 2500 then
			v.components.sanity:EnableLunacy(true, "bossrush")
        end
    end]]
	TheWorld.components.voidland_manager:ForceLunacy(true)
end

--------------------------------------------


local function NextStage(inst)
	inst.components.battlemanager:Next()
end

local function lv1_start(inst)
	inst._talkerdirty:set(1)
	inst:DoTaskInTime(10,function ()
		inst._musicdirty:set(2)
		NextStage(inst)
	end)
end

local function lv2_start(inst)
	
	inst:DoTaskInTime(10,NextStage)
	inst._talkerdirty:set(2)
end
local function lv3_start(inst)
	
	inst._musicdirty:set(2)
	inst:DoTaskInTime(10,NextStage)
	inst._talkerdirty:set(3)
end
local function lv4_start(inst)
	
	inst:DoTaskInTime(10,NextStage)
	inst._talkerdirty:set(4)
end
local function lv5_start(inst)
	
	inst._musicdirty:set(1)
	inst:DoTaskInTime(10,NextStage)
	inst._talkerdirty:set(5)
end



---------------------------------------------
local program = {

	{---------------level 1-----------------
	{initfn = lv1_start, type_special = true,level = 1},  --1
    {boss = "bearger",      postinitfn = bearger_process},
	{boss = "spiderqueen",  postinitfn = spider_process},
	{boss = "antlion",      postinitfn = antlion_process},
	{boss = "deerclops",    postinitfn = deerclops_process,	scenery_postinit = winter_coming},
	},

	{--------------level 2-------------------
	{initfn = lv2_start, type_special = true,level = 2},  --6
	{boss = "eyeofterror",	postinitfn	= eye_process},
	{boss = "sharkboi",		postinitfn	= sharkboi_process},
    {boss = "beequeen",     postinitfn 	= bee_process},
	{boss = "dragonfly",	postinitfn = dragon_process,				scenery_postinit = fire_era},
	{boss = "toadstool_dark",	postinitfn	= toadstool_process},
	},

	{--------------level 3-------------------
	{initfn = lv3_start, 	type_special = true,level = 2},  --12
	{boss = "minotaur",		postinitfn	= minotaur_process,	scenery_postinit= pillar_process},
	{boss = "daywalker",	postinitfn 	= 	daywalker_process},
	{boss = "corrupt_heart",postinitfn = heart_process},
	{boss = "klaus",		initfn	= klaus_process,	type_special = true},
	},

	{--------------level 4-------------------
	{initfn = lv4_start, type_special = true,level= 4},  --17
	{boss = "mutateddeerclops",	scenery_postinit = winter_coming},
	{boss = "mutatedwarg",		postinitfn = mutatedwarg_postinit},
	{boss = "mutatedbearger",	postinitfn = mutatedbearger_postinit},
	{boss = "daywalker2",		postinitfn = daywalker2_postinit},
	},

	{-------------level 5----------------------
	{initfn = lv5_start, type_special = true,level = 5},  --22
	{boss = "ancient_hulk",		postinitfn = ancienthulk_postinit},
	{boss = "ironlord",postinitfn = ironlord_postinit},
	{boss = "stalker_atrium",	postinitfn = stalker_postinit, scenery_postinit = darkworld, onexit = cleardarkworld},
	{boss = "twinofterror",		initfn	= twin_process, type_special = true},
	{boss = "alterguardian",	initfn	= alter_process, type_special = true},
	}
	--{boss = "supreme_shadow"}
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
	local inrange = target ~= nil and inst:IsNear(target, 40 + target:GetPhysicsRadius(0))

	if target ~= nil and target:HasTag("player") then
		local newplayer = inst.components.grouptargeter:TryGetNewTarget()
		return newplayer ~= nil
			and newplayer:IsNear(inst, inrange and 20 + newplayer:GetPhysicsRadius(0) or 30)
			and newplayer
			or nil,
			true
	end

	local nearplayers = {}
	for k in pairs(inst.components.grouptargeter:GetTargets()) do
		if inst:IsNear(k, inrange and 20 + k:GetPhysicsRadius(0) or 40) then
			table.insert(nearplayers, k)
		end
	end
	return #nearplayers > 0 and nearplayers[math.random(#nearplayers)] or nil, true
end
local function KeepTargetFn(inst, target)
	return inst.components.combat:CanTarget(target)
		and target:IsNear(inst, 60)
end

local CREATURE_CLEAR_NOT = {"player","character","companion","shadowminion"}
local CREATURE_CLEAR_ONEOF = {"_health","_combat"}
local INVENTORY_CLEAR_NOT = {"irreplaceable","INLIMBO","_equippable","weapon","book","preparedfood","cs_soul","nosteal",
"forgerepair_lunarplant","forgerepair_voidcloth","forgerepair_wagpunk_bits"}
local OTHER_TAGS = {"antlion_sinkhole","groundspike","blocker","projectile","junk"}

local function ClearLand(inst)
	inst.components.temperatureoverrider:SetTemperature(25)

	local x,y,z = inst.Transform:GetWorldPosition()
	local creatures = TheSim:FindEntities(x, 0, z, 70,nil,CREATURE_CLEAR_NOT,CREATURE_CLEAR_ONEOF)
	for i,v in ipairs(creatures) do
		v:Remove()
	end

	local items = TheSim:FindEntities(x, 0, z, 70,{"_inventoryitem","_stackable"},INVENTORY_CLEAR_NOT)
	for i,v in ipairs(items) do
		v:Remove()
	end

	local others = TheSim:FindEntities(x, 0, z, 70,nil,{"DECOR","irreplaceable"},OTHER_TAGS)
	for i,v in ipairs(others) do
		v:Remove()
	end
end

local commonfn = {
    retarget = RetargetFn,
    keeptarget = KeepTargetFn,
	clearland = ClearLand,
}

return {program = program, commonfn = commonfn}


