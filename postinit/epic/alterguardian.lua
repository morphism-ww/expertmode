local ALTERGUARDIAN_PHASE1_HEALTH = 10000*GetModConfigData("health_alter")
TUNING.ALTERGUARDIAN_PHASE1_MINROLLCOUNT = 12
TUNING.ALTERGUARDIAN_PHASE1_SHIELDTRIGGER = 2500+500*GetModConfigData("health_alter")
TUNING.ALTERGUARDIAN_PHASE1_WALK_SPEED = 6
TUNING.ALTERGUARDIAN_PHASE1_TARGET_DIST=28
TUNING.ALTERGUARDIAN_PHASE1_ATTACK_PERIOD = 6


local ALTERGUARDIAN_PHASE2_STARTHEALTH = 13000*GetModConfigData("health_alter")
TUNING.ALTERGUARDIAN_PHASE2_MAXEALTH = 20000*GetModConfigData("health_alter")
TUNING.ALTERGUARDIAN_PHASE2_SPIN_SPEED = 9
TUNING.ALTERGUARDIAN_PHASE2_TARGET_DIST = 30
TUNING.ALTERGUARDIAN_PHASE2_SPIKE_RANGE=25
TUNING.ALTERGUARDIAN_PHASE2_ATTACK_PERIOD=5
TUNING.ALTERGUARDIAN_PHASE2_SPIKE_LIFETIME = 60

local ALTERGUARDIAN_PHASE3_STARTHEALTH = 14000*GetModConfigData("health_alter")
TUNING.ALTERGUARDIAN_PHASE3_MAXHEALTH = 22500*GetModConfigData("health_alter")
TUNING.ALTERGUARDIAN_PHASE3_TARGET_DIST = 30
TUNING.ALTERGUARDIAN_PHASE3_SUMMONRSQ = 625
TUNING.ALTERGUARDIAN_PHASE3_TRAP_MAXRANGE = 5
TUNING.ALTERGUARDIAN_PHASE3_ATTACK_PERIOD=4
TUNING.ALTERGUARDIAN_PHASE3_ATTACK_RANGE=24


TUNING.ALTERGUARDIAN_PHASE3_TRAP_LT = 30

local bossplanardamage=15



local function roll_screenshake(inst)
    ShakeAllCameras(CAMERASHAKE.VERTICAL, .5, 0.05, 0.075, inst, 40)
end
local function SpawnSpell(inst, x, z,name)
    local spell = SpawnPrefab(name)
	if spell.TriggerFX then spell:DoTaskInTime(2, spell.TriggerFX) end
    spell.Transform:SetPosition(x, 0, z)
    spell:DoTaskInTime(20, spell.KillFX)
end

local function spawn_landfx(inst)
    local ix, iy, iz = inst.Transform:GetWorldPosition()
    local sinkhole=SpawnPrefab("daywalker_sinkhole")
    sinkhole.Transform:SetPosition(ix, iy, iz)
	sinkhole:PushEvent("docollapse")
    SpawnPrefab("mining_moonglass_fx").Transform:SetPosition(ix, iy, iz)
    SpawnSpell(inst,ix,iz,"deer_fire_circle")
end



local SEPLL_MUSTHAVE_TAGS = { "_combat","_health" }
local SPELL_CANT_TAGS = { "INLIMBO", "flight", "invisible", "notarget", "noattack","wall" }

local function CastSpell(inst,targets)
	local x, y, z = inst.Transform:GetWorldPosition()

	for i, v in ipairs(TheSim:FindEntities(x, y, z, 30, SEPLL_MUSTHAVE_TAGS, SPELL_CANT_TAGS)) do
		if v ~= inst and
				not (targets ~= nil and targets[v]) and
				v:IsValid() and not v:IsInLimbo()
				and not (v.components.health ~= nil and v.components.health:IsDead())
		then
			local px,py,pz=v.Transform:GetWorldPosition()
			SpawnSpell(inst,px,pz,"deer_ice_circle")
		end
	end
end





--一阶段天体英雄
AddStategraphPostInit("alterguardian_phase1", function(sg)
    sg.states.roll.onenter = function(inst,speed)
            inst:EnableRollCollision(true)

            inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)
            local rollspeed=speed or 12
            inst.Physics:SetMotorVelOverride(rollspeed, 0, 0)
			inst.sg.statemem.rollhits = {}

            inst.AnimState:PlayAnimation("roll_loop", true)

            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())

            if inst.sg.mem._num_rolls == nil then
                inst.sg.mem._num_rolls = TUNING.ALTERGUARDIAN_PHASE1_MINROLLCOUNT + (2*math.random())
            else
                inst.sg.mem._num_rolls = inst.sg.mem._num_rolls - 1
            end

            inst.components.combat:RestartCooldown()
        end
	sg.states.roll.timeline=
	{
            TimeEvent(1*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("moonstorm/creatures/boss/alterguardian1/roll")

                roll_screenshake(inst)

                spawn_landfx(inst)
                local roll_speed=12
                local target = inst.components.combat.target
                if target ~= nil and target:IsValid() and target.components.locomotor ~= nil then
                    roll_speed = math.max(12, target.components.locomotor:GetRunSpeed() * inst.components.locomotor:GetSpeedMultiplier()+3)
                    roll_speed = math.min(roll_speed, 35)
                end
                inst.sg.statemem.roll_speed = roll_speed
            end),
        }
    sg.states.roll.ontimeout=function(inst)
            if not inst.sg.statemem.hitplayer and inst.sg.mem._num_rolls > 0 then
                local final_rotation = nil
                if inst.components.combat.target ~= nil then
                    -- Retarget, and keep rolling!
                    local tx, ty, tz = inst.components.combat.target.Transform:GetWorldPosition()
                    local target_facing = inst:GetAngleToPoint(tx, ty, tz)

                    local current_facing = inst:GetRotation()

                    local target_angle_diff = ((target_facing - current_facing + 540) % 360) - 180

                    if math.abs(target_angle_diff) > 120 then
                        final_rotation = target_facing + GetRandomWithVariance(0, -4)
                    elseif target_angle_diff < 0 then
                        final_rotation = (current_facing + math.max(target_angle_diff, -120)) % 360
                    else
                        final_rotation = (current_facing + math.min(target_angle_diff, 120)) % 360
                    end
                else
                    final_rotation = 360*math.random()
                end

                inst.Transform:SetRotation(final_rotation)

                inst.sg:GoToState("roll",inst.sg.statemem.roll_speed)
            elseif inst.sg.statemem.hitplayer and inst.sg.mem._num_rolls > 0 then
                inst.sg.mem._num_rolls = math.max(inst.sg.mem._num_rolls-2,0)
                inst.sg:GoToState("roll",inst.sg.statemem.roll_speed)
            else
                inst.sg.mem._num_rolls=nil
                inst.sg:GoToState("roll_stop")
            end
    end

	local oldOnEntershield_pre = sg.states.shield_pre.onenter
    sg.states.shield_pre.onenter = function(inst, ...)
        oldOnEntershield_pre(inst, ...)
        local x,y,z=inst.Transform:GetWorldPosition()
        for i=1,5 do
            local tornado = SpawnPrefab("fire_tornado")
            tornado.CASTER = inst
            tornado.Transform:SetPosition(x,y,z)
        end

        inst.components.meteorshower:StopShower()
        inst.components.meteorshower:StartShower()
    end

	local oldOnEntershield_end = sg.states.shield_end.onenter
    sg.states.shield_end.onenter = function(inst, ...)
        oldOnEntershield_end(inst, ...)
		local targets=inst.sg.statemem.targets
        CastSpell(inst,targets)
    end
    local oldOnEntertantrum=sg.states.tantrum.onenter
    sg.states.tantrum.onenter = function(inst, ...)
        oldOnEntertantrum(inst, ...)
		inst.components.groundpounder:GroundPound()
    end


end)
AddPrefabPostInit("alterguardian_phase1",function(inst)
    --inst:AddTag("disablesw2hm")
    inst:AddTag("notraptrigger")
    inst:AddTag("toughworker")
    inst:AddTag("electricdamageimmune")

    if not TheWorld.ismastersim then return end

	if inst.components.freezable then inst:RemoveComponent("freezable") end
	inst:AddComponent("meteorshower")
    inst:AddComponent("groundpounder")

    --inst:AddComponent("planarentity")

    inst:AddComponent("damagetyperesist")
    inst.components.damagetyperesist:AddResist("explosive", inst, 0.1)
    inst.components.damagetyperesist:AddResist("epic", inst, 0.4)
    inst.components.damagetyperesist:AddResist("aoeweapon_leap", inst, 0.4)

    inst.components.health:SetMaxHealth(ALTERGUARDIAN_PHASE1_HEALTH)
    --inst.components.health:SetMaxDamageTakenPerHit(100)


    --inst:AddComponent("planardamage")
	--inst.components.planardamage:SetBaseDamage(bossplanardamage)

    inst.components.groundpounder:UseRingMode()
	inst.components.groundpounder.numRings = 3
	inst.components.groundpounder.initialRadius = 1.5
	inst.components.groundpounder.radiusStepDistance = 2
	inst.components.groundpounder.ringWidth = 2
	inst.components.groundpounder.damageRings = 2
	inst.components.groundpounder.destructionRings = 3
	inst.components.groundpounder.platformPushingRings = 3
	inst.components.groundpounder.fxRings = 2
	inst.components.groundpounder.fxRadiusOffset = 1.5
    inst.components.groundpounder.burner = true
    inst.components.groundpounder.groundpoundfx = "firesplash_fx"
    inst.components.groundpounder.groundpoundringfx = "firering_fx"
end)




--二阶段天体英雄
local icespell_cd=25
local CRABKING_SPELLGENERATOR_TAGS = {"crabking_spellgenerator"}
local function countgems(inst)

    local gems = {
        red = 0,
        blue = 12,
        purple = 0,
        orange = 0,
        yellow = 10,
        green = 0,
        pearl = 0,
		opal = 0,
    }
    return gems
end
local function removecrab(inst)
    inst.crab = nil
    inst:Remove()
end
local function startcastspell(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab("crabking_feeze")
    fx.crab = inst
    fx:ListenForEvent("onremove", function() removecrab(fx) end, inst)
    fx.Transform:SetPosition(x,y,z)
    local scale = 0.75 + Remap(inst.countgems(inst).blue,0,9,0,1.55)
    fx.Transform:SetScale(scale,scale,scale)
end

local function getfreezerange(inst)
    return TUNING.CRABKING_FREEZE_RANGE * (0.75 + Remap(inst.countgems(inst).blue,0,9,0,2.25)) /2
end

local function endcastspell(inst, lastwasfreeze)
    if inst.components.timer:TimerExists("icespell_cd") then
        inst.components.timer:StopTimer("icespell_cd")
    end
    inst.components.timer:StartTimer("icespell_cd",icespell_cd)

    inst.dofreezecast = nil

    local range = getfreezerange(inst)

    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 25, nil, nil, CRABKING_SPELLGENERATOR_TAGS)
    if #ents > 0 then
        for i,ent in pairs(ents)do
            if (not inst.components.freezable or not inst.components.freezable:IsFrozen()) and not inst.components.health:IsDead() then
                ent:PushEvent("endspell")
            else
                ent:Remove()
            end
        end
    end
    if lastwasfreeze then
        inst.dofreezecast = nil

    end
end
local function oncrabfreeze(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 25, nil, nil, CRABKING_SPELLGENERATOR_TAGS)
    if #ents > 0 then
        for i,ent in pairs(ents)do
            ent:Remove()
        end
    end
end

local function OnCollide(inst, other)
    if other ~= nil and
        other:IsValid() and
        other.components.workable ~= nil and
        other.components.workable:CanBeWorked() and
        other.components.workable.action ~= ACTIONS.NET then
        inst:DoTaskInTime(2 * FRAMES, other.components.workable:Destroy(inst))
    end
end

local function spawn_spike_with_pos(inst, pos, angle)
    local spawn_vec = pos

    local spike = SpawnPrefab("alterguardian_phase2spiketrail")
    spike.Transform:SetPosition(spawn_vec.x, 0, spawn_vec.z)
    spike.Transform:SetRotation(angle)
    spike:SetOwner(inst)
end

local function spawnbarrier(inst)
    local angle = 0
    local radius = 12
    local number = 8
    for i=1,number do
        local offset = Vector3(radius * math.cos( angle ), 0, -radius * math.sin( angle ))
        local newpt = inst:GetPosition() + offset

        --local tile = GetWorld().Map:GetTileAtPoint(newpt.x, newpt.y, newpt.z)
        if TheWorld.Map:IsPassableAtPoint(newpt.x, 0,newpt.z) then
            inst:DoTaskInTime(0.3, spawn_spike_with_pos,newpt,angle)
        end
        angle = angle + (360/number)
    end
end

local function Shockness(inst,x,y,z)
    x = x + math.random(-3,3)
	z = z + math.random(-3,3)
	local spark=SpawnPrefab("electricchargedfx")
	spark.Transform:SetPosition(x, 0, z)
    spark.Transform:SetScale(1.4,1.4,1.4)

	local targets = TheSim:FindEntities(x,y,z,5,{"_health","_combat"},{"playerghost","chess","wall","brightmareboss"})

	for k,v in pairs(targets) do
		if v.components.health ~= nil and not v.components.health:IsDead() then
			if not (v.components.inventory ~= nil and v.components.inventory:IsInsulated()) then
				if not v:HasTag("electricdamageimmune") then

					local mult = TUNING.ELECTRIC_DAMAGE_MULT + TUNING.ELECTRIC_WET_DAMAGE_MULT * (v.components.moisture ~= nil and v.components.moisture:GetMoisturePercent() or (v:GetIsWet() and 1 or 0))
						or 1

					local damage = -10 * mult

					if v.sg ~= nil and not v.sg:HasStateTag("nointerrupt")  then
						v.sg:GoToState("electrocute")
					end

					v.components.health:DoDelta(damage, nil, inst.prefab, nil, inst) --From the onhit stuff...
				end
			end
		end
	end
end
local function Spark(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
    SpawnPrefab("sparks").Transform:SetPosition(x-3+6*math.random(), 2 + math.random(), z-3+6*math.random())
	Shockness(inst,x,y,z)
	Shockness(inst,x,y,z)
	Shockness(inst,x,y,z)
end



AddPrefabPostInit("alterguardian_phase2",function(inst)
    --inst:AddTag("disablesw2hm")
    inst:AddTag("toughworker")
    inst:AddTag("notraptrigger")
    inst:AddTag("electricdamageimmune")
    if not TheWorld.ismastersim then return end

    --inst:AddComponent("planarentity")
    inst.components.health:SetMaxHealth(ALTERGUARDIAN_PHASE2_STARTHEALTH)
    --inst:AddComponent("planardamage")
	--inst.components.planardamage:SetBaseDamage(bossplanardamage)
    inst.Physics:SetCollisionCallback(OnCollide)


    inst:AddComponent("damagetyperesist")
    inst.components.damagetyperesist:AddResist("explosive", inst, 0.1)
    inst.components.damagetyperesist:AddResist("epic", inst, 0.4)
    inst.components.damagetyperesist:AddResist("aoeweapon_leap", inst, 0.4)

    if inst.components.freezable then inst:RemoveComponent("freezable") end
	inst.startcastspell = startcastspell
    inst.endcastspell = endcastspell
    inst.countgems = countgems
    inst.SpawnBarrier=spawnbarrier
    inst.spark=Spark


    inst:SetStateGraph("SGalterguardian_phase2_hard")
    inst:ListenForEvent("freeze", oncrabfreeze)
end)



--三阶段激光

local function DoEraser(inst,target,caster)
    if target.components.inventory~=nil then
        for k, v in pairs(target.components.inventory.equipslots) do
            if v.components.finiteuses ~= nil then
                v.components.finiteuses:SetUses(0)
            end
            if v.components.armor ~= nil then
                v.components.armor:SetCondition(0)
            end
            if v.components.fueled~=nil then
                v.components.fueled:MakeEmpty()
            end
            if v.components.perishable~=nil then
                v.components.perishable:Perish()
            end
        end
    end
    if target.components.burnable~=nil then
        target.components.burnable:Ignite()
    end
    target.components.health:DoDelta(-100000,false,caster,true,nil,true)
    --target.components.health:SetVal(0,caster,caster)
    target.components.health:DeltaPenalty(0.2)
end

local DAMAGE_CANT_TAGS = { "brightmareboss", "brightmare", "playerghost", "INLIMBO", "DECOR", "FX" ,"god" }
local DAMAGE_ONEOF_TAGS = { "_combat", "pickable", "NPC_workable", "CHOP_workable", "HAMMER_workable", "MINE_workable", "DIG_workable" }
local LAUNCH_MUST_TAGS = { "_inventoryitem" }
local LAUNCH_CANT_TAGS = { "locomotor", "INLIMBO" }
local function DoDamage(inst, targets, skiptoss, skipscorch)
    local RADIUS = .7
    local LAUNCH_SPEED = .2
    if inst.type~=nil then
        RADIUS=2
        LAUNCH_SPEED = 1
    end
    inst.task = nil

    local x, y, z = inst.Transform:GetWorldPosition()

    -- First, get our presentation out of the way, since it doesn't change based on the find results.
    if inst.AnimState ~= nil then
        inst.AnimState:PlayAnimation("hit_"..tostring(math.random(5)))
        inst:Show()
        inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + 2 * FRAMES, inst.Remove)

        inst.Light:Enable(true)
        inst:DoTaskInTime(4 * FRAMES, SetLightRadius, .5)
        inst:DoTaskInTime(5 * FRAMES, DisableLight)

        if not skipscorch and TheWorld.Map:IsPassableAtPoint(x, 0, z, false) then
            SpawnPrefab("alterguardian_laserscorch").Transform:SetPosition(x, 0, z)
        end

        local fx = SpawnPrefab("alterguardian_lasertrail")
        fx.Transform:SetPosition(x, 0, z)
        fx:FastForward(GetRandomMinMax(.3, .7))
    else
        inst:DoTaskInTime(2 * FRAMES, inst.Remove)
    end

    inst.components.combat.ignorehitrange = true
    for _, v in ipairs(TheSim:FindEntities(x, 0, z, RADIUS + 3, nil, DAMAGE_CANT_TAGS, DAMAGE_ONEOF_TAGS)) do
        if not targets[v] and v:IsValid() and
                not (v.components.health ~= nil and v.components.health:IsDead()) then
            local range = RADIUS + v:GetPhysicsRadius(.5)
            local dsq_to_laser = v:GetDistanceSqToPoint(x, y, z)
            if dsq_to_laser < range * range then
                v:PushEvent("onalterguardianlasered")

                local isworkable = false
                if v.components.workable ~= nil then
                    local work_action = v.components.workable:GetWorkAction()
                    --V2C: nil action for NPC_workable (e.g. campfires)
                    isworkable =
                        (   work_action == nil and v:HasTag("NPC_workable") ) or
                        (   v.components.workable:CanBeWorked() and
                            (   work_action == ACTIONS.CHOP or
                                work_action == ACTIONS.HAMMER or
                                work_action == ACTIONS.MINE or
                                (   work_action == ACTIONS.DIG and
                                    v.components.spawner == nil and
                                    v.components.childspawner == nil
                                )
                            )
                        )
                end
                if isworkable then
                    targets[v] = true
                    v.components.workable:Destroy(inst)

                    -- Completely uproot trees.
                    if v:HasTag("stump") then
                        v:Remove()
                    end
                elseif v.components.pickable ~= nil
                        and v.components.pickable:CanBePicked()
                        and not v:HasTag("intense") then
                    targets[v] = true
                    local num = v.components.pickable.numtoharvest or 1
                    local product = v.components.pickable.product
                    local x1, y1, z1 = v.Transform:GetWorldPosition()
                    v.components.pickable:Pick(inst) -- only calling this to trigger callbacks on the object
                    if product ~= nil and num > 0 then
                        for i = 1, num do
                            local loot = SpawnPrefab(product)
                            loot.Transform:SetPosition(x1, 0, z1)
                            skiptoss[loot] = true
                            targets[loot] = true
                            Launch(loot, inst, LAUNCH_SPEED)
                        end
                    end
                elseif v.components.combat == nil and v.components.health ~= nil then
                    targets[v] = true
                elseif inst.components.combat:CanTarget(v) then
                    targets[v] = true
                    if inst.type=="eraser" and v.components.health~=nil then
                        DoEraser(inst,v,inst.caster)
                    else
                        if inst.caster ~= nil and inst.caster:IsValid() then
                            inst.caster.components.combat.ignorehitrange = true
                            inst.caster.components.combat:DoAttack(v)
                            inst.caster.components.combat.ignorehitrange = false
                        else
                            inst.components.combat:DoAttack(v)
                        end
                    end

                    SpawnPrefab("alterguardian_laserhit"):SetTarget(v)

                    if not v.components.health:IsDead() then
                        if v.components.freezable ~= nil then
                            if v.components.freezable:IsFrozen() then
                                v.components.freezable:Unfreeze()
                            elseif v.components.freezable.coldness > 0 then
                                v.components.freezable:AddColdness(-2)
                            end
                        end
                        if v.components.temperature ~= nil then
                            local maxtemp = math.min(v.components.temperature:GetMax(), 10)
                            local curtemp = v.components.temperature:GetCurrent()
                            if maxtemp > curtemp then
                                v.components.temperature:DoDelta(math.min(10, maxtemp - curtemp))
                            end
                        end
                        if v.components.sanity ~= nil then
                            v.components.sanity:DoDelta(TUNING.GESTALT_ATTACK_DAMAGE_SANITY)
                        end
                    end
                end
            end
        end
    end
    inst.components.combat.ignorehitrange = false

    -- After lasering stuff, try tossing any leftovers around.
    for _, v in ipairs(TheSim:FindEntities(x, 0, z, RADIUS + 3, LAUNCH_MUST_TAGS, LAUNCH_CANT_TAGS)) do
        if not skiptoss[v] then
            local range = RADIUS + v:GetPhysicsRadius(.5)
            if v:GetDistanceSqToPoint(x, y, z) < range * range then
                if v.components.mine ~= nil then
                    targets[v] = true
                    skiptoss[v] = true
                    v.components.mine:Deactivate()
                end
                if not v.components.inventoryitem.nobounce and v.Physics ~= nil and v.Physics:IsActive() then
                    targets[v] = true
                    skiptoss[v] = true
                    Launch(v, inst, LAUNCH_SPEED)
                end
            end
        end
    end

    -- If the laser hit a boat, do boat stuff!
    local platform_hit = TheWorld.Map:GetPlatformAtPoint(x, 0, z)
    if platform_hit then
        local dsq_to_boat = platform_hit:GetDistanceSqToPoint(x, 0, z)
        if dsq_to_boat < TUNING.GOOD_LEAKSPAWN_PLATFORM_RADIUS then
            platform_hit:PushEvent("spawnnewboatleak", {pt = Vector3(x, 0, z), leak_size = "small_leak", playsoundfx = true})
        end
        platform_hit.components.health:DoDelta(-1 * TUNING.ALTERGUARDIAN_PHASE3_LASERDAMAGE / 10)
    end
end
local function Trigger(inst, delay, targets, skiptoss, skipscorch)
    if inst.task ~= nil then
        inst.task:Cancel()
        if (delay or 0) > 0 then
            inst.task = inst:DoTaskInTime(delay, DoDamage, targets or {}, skiptoss or {}, skipscorch)
        else
            DoDamage(inst, targets or {}, skiptoss or {}, skipscorch)
        end
    end
end


AddPrefabPostInit("alterguardian_laser",function(inst)
    inst.type=nil
    inst.Trigger=Trigger
end)


local PHASES =
{
	[1] = {
		hp = 1,
		fn = function(inst)
            inst.candoflame=false
            inst.caneraser=false
            inst.canholylight=false
		end,
	},
	--
	[2] = {
		hp = 0.8,
		fn = function(inst)
            inst.candoflame=true
			inst.cancloud = true
            inst.caneraser=false
            inst.canholylight=false
		end,
	},
	[3] = {
		hp = 0.5,
		fn = function(inst)
			inst.candoflame=true
            inst.cancloud = true
            inst.caneraser=true
            inst.canholylight=true
		end,
	},
}


local SLEEPER_TAGS = { "player", "sleeper" }
local SLEEPER_NO_TAGS = { "playerghost", "epic", "lunar_aligned", "INLIMBO" }
local function OnClearCloudProtection(ent)
	ent._lunargrazercloudprot = nil
end

local function SetCloudProtection(inst, ent, duration)
	if ent:IsValid() then
		if ent._lunargrazercloudprot ~= nil then
			ent._lunargrazercloudprot:Cancel()
		end
		ent._lunargrazercloudprot = ent:DoTaskInTime(duration, OnClearCloudProtection)
	end
end
local function DoCloudTask(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	for i, v in ipairs(TheSim:FindEntities(x, 0, z, 8, nil, SLEEPER_NO_TAGS, SLEEPER_TAGS)) do
		if v._lunargrazercloudprot == nil and
			v:IsValid() and v.entity:IsVisible() and
			not (v.components.health ~= nil and v.components.health:IsDead()) and
			not (v.sg ~= nil and v.sg:HasStateTag("waking"))
			then
			local range = v:GetPhysicsRadius(0) + 2.5
			if v:GetDistanceSqToPoint(x, y, z) < range * range then
				if v.components.grogginess ~= nil then
					if not (v.sg ~= nil and v.sg:HasStateTag("knockout")) then
						v.components.grogginess:AddGrogginess(0.5, 5)
						inst:SetCloudProtection(v, .5)
					end
				elseif v.components.sleeper ~= nil then
					if not (v.sg ~= nil and v.sg:HasStateTag("sleeping")) then
						v.components.sleeper:AddSleepiness(0.5, 5)
						inst:SetCloudProtection(v, .5)
					end
				end
			end
		end
	end
end

local function StartCloudTask(inst)
	if inst.cloudtask == nil and inst.cancloud then
		inst.cloudtask = inst:DoPeriodicTask(1, DoCloudTask, math.random())
	end
end

local function StopCloudTask(inst)
	if inst.cloudtask ~= nil  then
		inst.cloudtask:Cancel()
		inst.cloudtask = nil
	end
end



local function OnLoad(inst, data)
    if data ~= nil then
        inst._loot_dropped = data.loot_dropped
        inst.attackerUSERIDs = data.attackerUSERIDs or {}

    end
    if not inst.components.health:IsDead() then
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



AddPrefabPostInit("alterguardian_phase3",function(inst)
    inst:AddTag("disablesw2hm")
    inst:AddTag("notraptrigger")
    inst:AddTag("toughworker")
    inst:AddTag("electricdamageimmune")
	if not TheWorld.ismastersim then return end

    inst.components.health:SetMaxHealth(ALTERGUARDIAN_PHASE3_STARTHEALTH)
	if inst.components.freezable then inst:RemoveComponent("freezable") end

    inst.components.combat:SetAreaDamage(4, 0.8)

    inst:AddComponent("damagetyperesist")
    inst.components.damagetyperesist:AddResist("explosive", inst, 0.1)
    inst.components.damagetyperesist:AddResist("epic", inst, 0.4)
    inst.components.damagetyperesist:AddResist("aoeweapon_leap", inst, 0.4)
    
    --inst:AddComponent("planardamage")
	--inst.components.planardamage:SetBaseDamage(15)


    inst.OnLoad = OnLoad

    --abilities
    inst.candoflame=false
    inst.canflame=false
    inst.cancloud = false
    inst.caneraser=false


    --雾气
    inst.cloud = SpawnPrefab("lunar_goop_cloud_fx")
    inst.cloud.entity:SetParent(inst.entity)
    inst.StartCloudTask=StartCloudTask
    inst.StopCloudTask=StopCloudTask
    inst.SetCloudProtection=SetCloudProtection



    inst:AddComponent("healthtrigger")
    for i, v in pairs(PHASES) do
		inst.components.healthtrigger:AddTrigger(v.hp, v.fn)
	end


    inst:SetStateGraph("SGalterguardian_phase3_hard")
end)



--AddStategraphState("daywalker", expertslam)


--AddBrainPostInit("daywalker",expertbrain)