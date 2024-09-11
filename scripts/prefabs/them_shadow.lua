local assets =
{
    Asset("ANIM", "anim/stalker_basic.zip"),
    Asset("ANIM", "anim/stalker_action.zip"),
    Asset("ANIM", "anim/stalker_atrium.zip"),
    Asset("ANIM", "anim/stalker_shadow_build.zip"),
    Asset("ANIM", "anim/stalker_atrium_build.zip"),
}

local prefabs =
{
    "shadowheart",
    "fossil_piece",
    "fossilspike",
    "fossilspike2",
    "stalker_shield",
    "stalker_minion",
    "shadowchanneler",
    "mindcontroller",
    "nightmarefuel",
    "thurible",
    "armorskeleton",
    "skeletonhat",
	"chesspiece_stalker_sketch",
    "shadowfireball"
}

local easing = require("easing")
local brain = require("brains/shadowdeitybrain")
-----------------------------------------------------
local function CreateShadowLightningFx()
    local inst = CreateEntity()

    --[[Non-networked entity]]
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    
    inst:AddTag("FX")
    inst.persists = false

    inst.AnimState:SetBank("elec_charged_fx")
    inst.AnimState:SetBuild("elec_charged_fx")
    inst.AnimState:PlayAnimation("discharged",true)
    inst.AnimState:SetScale(1.5,1.5,1.5)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetMultColour(169/255, 36/255, 30/255, 1)

    return inst
end

local function CreateFlameFx()
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()

    inst.AnimState:SetMultColour(1,1,1,0.5)
    --inst.AnimState:SetScale(1.3,1.3,1.3)

    inst.AnimState:SetBank("pigman")
    inst.AnimState:SetBuild("merm_actions_skills")
    inst.AnimState:PlayAnimation("alternateeyes", true)

    --inst.AnimState:SetSymbolLightOverride("fx_flame_red", 1)
    --inst.AnimState:SetSymbolLightOverride("fx_red", 1)

    return inst
end


--local fossil_symbols = {"fossil_chest","fossil_armupper","fossil_leg","fossil_torso"}
local function MakeShadowDeity(inst)
    local electric_fx = CreateShadowLightningFx()
    electric_fx.entity:SetParent(inst.entity)
    electric_fx.Follower:FollowSymbol(inst.GUID, "swap_heart")
    local hand_fx  = CreateFlameFx()
    hand_fx.entity:SetParent(inst.entity)
    hand_fx.Follower:FollowSymbol(inst.GUID, "shadow_hand",-100,30,0,true)
    
    --[[for k,v in pairs(fossil_symbols) do
        inst.AnimState:SetSymbolMultColour(v, 169/255, 36/255, 30/255, 1)
    end]]
    inst.AnimState:SetSymbolMultColour("fossil_torso",167/255,75/255,50/255,0.5)
    inst.AnimState:SetSymbolMultColour("fossil_chest", 169/255, 36/255, 30/255, 1)


end

local function OnDoneTalking(inst)
    if inst.talktask ~= nil then
        inst.talktask:Cancel()
        inst.talktask = nil
    end
    inst.SoundEmitter:KillSound("talk")
end

local function OnTalk(inst)
    OnDoneTalking(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/talk_LP", "talk")
    inst.talktask = inst:DoTaskInTime(1.5 + math.random() * .5, OnDoneTalking)
end
local function AtriumBattleChatter(inst, id, forcetext)
    local strtbl = "STALKER_ATRIUM_"..string.upper(id)

    inst.components.talker:Chatter(strtbl, math.random(#STRINGS[strtbl]), 2, forcetext, CHATPRIORITIES.LOW)
end
--------------------------------------------------------

local SHADOWLURE_TAGS = {"shadowlure"}
local function IsNearShadowLure(target)
    return GetClosestInstWithTag(SHADOWLURE_TAGS, target, TUNING.THURIBLE_AOE_RANGE) ~= nil
end
local STALKER_DEAGGRO_DIST = 50
local function UpdatePlayerTargets(inst)
    local toadd = {}
    local toremove = {}
    local x, y, z = inst.Transform:GetWorldPosition()

    for k, v in pairs(inst.components.grouptargeter:GetTargets()) do
        toremove[k] = true
    end
    for i, v in ipairs(FindPlayersInRange(x, y, z, STALKER_DEAGGRO_DIST, true)) do
        
        if toremove[v] then
            toremove[v] = nil
        else
            table.insert(toadd, v)
        end
        
    end

    for k, v in pairs(toremove) do
        inst.components.grouptargeter:RemoveTarget(k)
    end
    for i, v in ipairs(toadd) do
        inst.components.grouptargeter:AddTarget(v)
    end
end


local function AtriumRetargetFn(inst)
    UpdatePlayerTargets(inst)
    local target = inst.components.combat.target
    local inrange = target ~= nil and inst:IsNear(target, TUNING.STALKER_ATTACK_RANGE + target:GetPhysicsRadius(0))

    if target ~= nil and target:HasTag("player") then
        local newplayer = inst.components.grouptargeter:TryGetNewTarget()
        return newplayer ~= nil
            and newplayer:IsNear(inst, inrange and TUNING.STALKER_ATTACK_RANGE + newplayer:GetPhysicsRadius(0) or TUNING.STALKER_KEEP_AGGRO_DIST)
            and newplayer
            or nil,
            true
    end

    local nearplayers = {}
    for k, v in pairs(inst.components.grouptargeter:GetTargets()) do
        if inst:IsNear(k, inrange and TUNING.STALKER_ATTACK_RANGE + k:GetPhysicsRadius(0) or TUNING.STALKER_AGGRO_DIST) then
            table.insert(nearplayers, k)
        end
    end
    return #nearplayers > 0 and nearplayers[math.random(#nearplayers)] or nil, true
end

local function AtriumKeepTargetFn(inst, target)
    return inst.components.combat:CanTarget(target)
end
----------------------------------------------------------
local function OnNewTarget(inst, data)
    if data.target ~= nil then
        inst:SetEngaged(true)
        inst:PushEvent("roar")
    end
end


local function AtriumSetEngaged(inst, engaged)
    --NOTE: inst.engaged is nil at instantiation, and engaged must not be nil
    if inst.engaged ~= engaged then
        inst.engaged = engaged
        inst.components.timer:StopTimer("snare_cd")
        inst.components.timer:StopTimer("spikes_cd")
        inst.components.timer:StopTimer("channelers_cd")
        inst.components.timer:StopTimer("minions_cd")
        inst.components.timer:StopTimer("mindcontrol_cd")
        if engaged then
            inst.components.timer:StartTimer("snare_cd", TUNING.STALKER_FIRST_SNARE_CD)
            inst.components.timer:StartTimer("spikes_cd", TUNING.STALKER_FIRST_SPIKES_CD)
            inst.components.timer:StartTimer("channelers_cd", TUNING.STALKER_FIRST_CHANNELERS_CD)
            inst.components.timer:StartTimer("minions_cd", TUNING.STALKER_FIRST_MINIONS_CD)
            inst.components.timer:StartTimer("mindcontrol_cd", TUNING.STALKER_FIRST_MINDCONTROL_CD)
            inst:RemoveEventCallback("newcombattarget", OnNewTarget)
        else
            inst:ListenForEvent("newcombattarget", OnNewTarget)
        end
    end
end

local function crazyfallofffn(inst,observer,distsq)
    return (distsq>14*14 and 4) or (distsq>8*8 and 2) or 1
end
----------------------------------------------------------

local function StartAbility(inst, ability)
    inst.components.timer:StartTimer(ability.."_cd", TUNING.STALKER_ABILITY_RETRY_CD)
end

--For searching:
-- "snare_cd", "spikes_cd", "channelers_cd", "minions_cd"
-- TUNING.STALKER_SNARE_CD
-- TUNING.STALKER_SPIKES_CD
-- TUNING.STALKER_CHANNELERS_CD
-- TUNING.STALKER_MINIONS_CD
local function ResetAbilityCooldown(inst, ability)
    local id = ability.."_cd"
    local remaining = TUNING["STALKER_"..string.upper(id)] - (inst.components.timer:GetTimeElapsed(id) or TUNING.STALKER_ABILITY_RETRY_CD)
    inst.components.timer:StopTimer(id)
    if remaining > 0 then
        inst.components.timer:StartTimer(id, remaining)
    end
end

local SHARED_COOLDOWNS =
{
    "snare",
    "spikes",
    "mindcontrol",
}
local function DelaySharedAbilityCooldown(inst, ability)
    local todelay = {}
    local maxdt = 0
    for i, v in ipairs(SHARED_COOLDOWNS) do
        if v ~= ability then
            local id = v.."_cd"
            local remaining = inst.components.timer:GetTimeLeft(id) or 0
            maxdt = math.max(maxdt, TUNING["STALKER_"..string.upper(id)] * .5 - remaining)
            todelay[id] = remaining
        end
    end
    for id, remaining in pairs(todelay) do
        inst.components.timer:StopTimer(id)
        inst.components.timer:StartTimer(id, remaining + maxdt)
    end
end

--------------------------------------------------------------
local SNARE_OVERLAP_MIN = 1
local SNARE_OVERLAP_MAX = 3
local SNAREOVERLAP_TAGS = { "fossilspike", "groundspike" }
local function NoSnareOverlap(x, z, r)
    return #TheSim:FindEntities(x, 0, z, r or SNARE_OVERLAP_MIN, SNAREOVERLAP_TAGS) <= 0
end

--Hard limit target list size since casting does multiple passes it
local SNARE_MAX_TARGETS = 20
local SNARE_TAGS = { "_combat", "locomotor" }
local SNARE_NO_TAGS = { "flying", "ghost", "playerghost", "tallbird", "fossil", "shadow", "shadowminion", "INLIMBO", "epic", "smallcreature" }
local function FindSnareTargets(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local targets = {}
    local priorityindex = 1
    local priorityindex2 = 1

    local ents = TheSim:FindEntities(x, y, z, 18, SNARE_TAGS, SNARE_NO_TAGS)
    for i, v in ipairs(ents) do
        if not (v.components.health ~= nil and v.components.health:IsDead()) then
            if v:HasTag("player") then
                
                table.insert(targets, priorityindex, v)
                priorityindex = priorityindex + 1
                priorityindex2 = priorityindex2 + 1
                
            elseif v.components.combat:TargetIs(inst) then
                table.insert(targets, priorityindex2, v)
                priorityindex2 = priorityindex2 + 1
            else
                table.insert(targets, v)
            end
            if #targets >= SNARE_MAX_TARGETS then
                return targets
            end
        end
    end
    return #targets > 0 and targets or nil
end

local function SpawnSnare(inst, x, z, r, num, target)
    local vars = { 1, 2, 3, 4, 5, 6, 7 }
    local used = {}
    local queued = {}
    local count = 0
    local dtheta = TWOPI / num
    local delaytoggle = 0
    local map = TheWorld.Map
    for theta = math.random() * dtheta, TWOPI, dtheta do
        local x1 = x + r * math.cos(theta)
        local z1 = z + r * math.sin(theta)
        if map:IsPassableAtPoint(x1, 0, z1) and not map:IsPointNearHole(Vector3(x1, 0, z1)) then
            local spike = SpawnPrefab("fossilspike")
            spike.Transform:SetPosition(x1, 0, z1)

            local delay = delaytoggle == 0 and 0 or .2 + delaytoggle * math.random() * .2
            delaytoggle = delaytoggle == 1 and -1 or 1

            local duration = GetRandomWithVariance(TUNING.STALKER_SNARE_TIME, TUNING.STALKER_SNARE_TIME_VARIANCE)

            local variation = table.remove(vars, math.random(#vars))
            table.insert(used, variation)
            if #used > 3 then
                table.insert(queued, table.remove(used, 1))
            end
            if #vars <= 0 then
                local swap = vars
                vars = queued
                queued = swap
            end

            spike:RestartSpike(delay, duration, variation)
            count = count + 1
        end
    end
    if count <= 0 then
        return false
    else
        -- NOTES(JBK): This is for controllers to escape out of the prison without teleporting across the entire arena.
        local duration = TUNING.STALKER_SNARE_TIME + TUNING.STALKER_SNARE_TIME_VARIANCE + 1
        local blinkfocus = SpawnPrefab("blinkfocus_marker")
        blinkfocus.Transform:SetPosition(x, 0, z)
        blinkfocus:MakeTemporary(duration)
        blinkfocus:SetMaxRange(r + 4)

        if target:IsValid() then
            target:PushEvent("snared", { attacker = inst })
        end
    end
    return true
end

local STALKER_MAX_SNARES = 8

local function SpawnSnares(inst, targets)
    ResetAbilityCooldown(inst, "snare")

    local count = 0
    local nextpass = {}
    for i, v in ipairs(targets) do
        if v:IsValid() and
            v:IsNear(inst, 30) then
            local x, y, z = v.Transform:GetWorldPosition()
            local islarge = v:HasTag("largecreature")
            local r = v:GetPhysicsRadius(0) + (islarge and 1.5 or .5)
            local num = islarge and 12 or 6
            if NoSnareOverlap(x, z, r + SNARE_OVERLAP_MAX) then
                if SpawnSnare(inst, x, z, r, num, v) then
                    count = count + 1
                    if count >= TUNING.STALKER_MAX_SNARES then
                        DelaySharedAbilityCooldown(inst, "snare")
                        return
                    end
                end
            else
                table.insert(nextpass, { x = x, z = z, r = r, n = num, inst = v })
            end
        end
    end

    if #nextpass > 0 then
        for range = SNARE_OVERLAP_MAX - 1, SNARE_OVERLAP_MIN, -1 do
            local i = 1
            while i <= #nextpass do
                local v = nextpass[i]
                if NoSnareOverlap(v.x, v.z, v.r + range) then
                    if SpawnSnare(inst, v.x, v.z, v.r, v.n, v.inst) then
                        count = count + 1
                        if count >= STALKER_MAX_SNARES or #nextpass <= 1 then
                            DelaySharedAbilityCooldown(inst, "snare")
                            return
                        end
                    end
                    table.remove(nextpass, i)
                else
                    i = i + 1
                end
            end
        end
    end

    if count > 0 then
        DelaySharedAbilityCooldown(inst, "snare")
    end
end
-----------------------------------------------------------
local CHANNELER_SPAWN_RADIUS = 12
local CHANNELER_SPAWN_PERIOD = 1

local function DoSpawnChanneler(inst)
    if inst.components.health:IsDead() then
        inst.channelertask = nil
        inst.channelerparams = nil
        return
    end

    local x = inst.channelerparams.x + CHANNELER_SPAWN_RADIUS * math.cos(inst.channelerparams.angle)
    local z = inst.channelerparams.z + CHANNELER_SPAWN_RADIUS * math.sin(inst.channelerparams.angle)
    if TheWorld.Map:IsAboveGroundAtPoint(x, 0, z) then
        local channeler = SpawnPrefab("shadowchanneler")
        channeler.Transform:SetPosition(x, 0, z)
        channeler:ForceFacePoint(Vector3(inst.channelerparams.x, 0, inst.channelerparams.z))
        inst.components.commander:AddSoldier(channeler)
    end

    if inst.channelerparams.count > 1 then
        inst.channelerparams.angle = inst.channelerparams.angle + inst.channelerparams.delta
        inst.channelerparams.count = inst.channelerparams.count - 1
        inst.channelertask = inst:DoTaskInTime(CHANNELER_SPAWN_PERIOD, DoSpawnChanneler)
    else
        inst.channelertask = nil
        inst.channelerparams = nil
    end
end

local function SpawnChannelers(inst)
    ResetAbilityCooldown(inst, "channelers")

    local count = 12
    if inst.channelertask ~= nil then
        return
    end

    local x, y, z = inst.Transform:GetWorldPosition()
    inst.channelerparams =
    {
        x = x,
        z = z,
        angle = math.random() * TWOPI,
        delta = -TWOPI / count,
        count = count,
    }
    DoSpawnChanneler(inst)
end

local function DespawnChannelers(inst)
    if inst.channelertask ~= nil then
        inst.channelertask:Cancel()
        inst.channelertask = nil
        inst.channelerparams = nil
    end
    for i, v in ipairs(inst.components.commander:GetAllSoldiers()) do
        if not v.components.health:IsDead() then
            v.components.health:Kill()
        end
    end
end

local function nodmgshielded(inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    return inst.hasshield and amount <= 0 and not ignore_absorb
end

local function OnlyPlayer(inst,target)
    return target and target.isplayer
end

local function HealthDoDelta(self,amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    local old_percent = self:GetPercent()

    if amount <= 0 and (self.inst.hasshield or (cause~="debuff" and not OnlyPlayer(self.inst,afflicter))) then
        return 0
    end

    if amount < -300 then
        amount = -300
    end

    self:SetVal(self.currenthealth + amount, cause, afflicter)

    self.inst:PushEvent("healthdelta", { oldpercent = old_percent, newpercent = self:GetPercent(), overtime = overtime, cause = cause, afflicter = afflicter, amount = amount })

    return amount
end    

local function OnSoldiersChanged(inst)
    if inst.hasshield ~= (inst.components.commander:GetNumSoldiers() > 0) then
        inst.hasshield = not inst.hasshield
		--inst._hasshield:set(inst.hasshield)
        if not inst.hasshield then
            inst.components.timer:StopTimer("channelers_cd")
            inst.components.timer:StartTimer("channelers_cd", TUNING.STALKER_CHANNELERS_CD)
        end
    end
end
--------------------------------------------------------------------
local MINION_RADIUS = .3
local MINION_SPAWN_PERIOD = .75
local NUM_RINGS = 3
local RING_SIZE = 7.5 / NUM_RINGS
local RING_TOTAL = 1
for i = 2, NUM_RINGS do
    RING_TOTAL = RING_TOTAL + i * i
end

local function SpawnInRange(inst, count)
	
	local x,y,z = inst.Transform:GetWorldPosition()

	local function getrandomoffset()
	    local theta = math.random() * PI2
        local radius = 4 + 8*math.random()
		return Vector3(x+radius*math.cos(theta), 0, z-radius*math.sin(theta))
	end

    local target = inst.components.combat.target

	for i=1, count do
		local spawn_pt = getrandomoffset()
			
        local ent = SpawnPrefab(math.random()<0.3 and "dreaddragon" or "shadowdragon")

        if ent.Physics then
            ent.Physics:Teleport(spawn_pt:Get())
        else
            ent.Transform:SetPosition(spawn_pt.x, 0, spawn_pt.z)
        end

        ent:AddTag("nosinglefight_l")
        ent:AddTag("notaunt")

        if target then
            ent.components.combat:SetTarget(target)
        end

        ent.persists =  false

        ent.components.lootdropper:SetLoot({})
        ent.components.lootdropper:SetChanceLootTable(nil)
	end
end


local function SpawnNightmares(inst)
	local num = math.random(2,3)
    local x, y, z = inst.Transform:GetWorldPosition()
    for i, v in ipairs(AllPlayers) do
        if not v:HasTag("playerghost") and
            v.entity:IsVisible() and
            v:GetDistanceSqToPoint(x, y, z) < 400 then
            num = num + 1
        end
    end
    SpawnInRange(inst,num)
end

local function DoSpawnMinion(inst)
    local pt = table.remove(inst.minionpoints, math.random(#inst.minionpoints))
    local minion = SpawnPrefab("stalker_minion")
    minion.Transform:SetPosition(pt:Get())
    minion:ForceFacePoint(pt)
    minion:OnSpawnedBy(inst)
    if #inst.minionpoints <= 0 then
        inst.miniontask:Cancel()
        inst.miniontask = nil
        inst.minionpoints = nil
    end
end

--count is specified on load only
local function SpawnMinions(inst, count)
    if count == nil then
        ResetAbilityCooldown(inst, "minions")
        count = TUNING.STALKER_MINIONS_COUNT
    end

    if count <= 0 or inst.miniontask ~= nil then
        return
    end

    --SetMusicLevel(inst, 2)

    local stargate = inst.components.entitytracker:GetEntity("stargate")
    local x, y, z = (stargate or inst).Transform:GetWorldPosition()
    local map = TheWorld.Map
    inst.minionpoints = {}
    for ring = 1, NUM_RINGS do
        local ringweight = ring * ring / RING_TOTAL
        local ringcount = math.floor(count * ringweight + .5)
        if ringcount > 0 then
            local delta = TWOPI / ringcount
            local radius = ring * RING_SIZE
            for i = 1, ringcount do
                local angle = delta * i
                local x1 = x + radius * math.cos(angle) + math.random() - .5
                local z1 = z + radius * math.sin(angle) + math.random() - .5
                if map:IsAboveGroundAtPoint(x1, 0, z1) then
                    table.insert(inst.minionpoints, Vector3(x1, 0, z1))
                end
            end
        end
    end
    if #inst.minionpoints > 0 then
        inst.miniontask = inst:DoPeriodicTask(MINION_SPAWN_PERIOD, DoSpawnMinion, 0)
    else
        inst.minionpoints = nil
    end
    SpawnNightmares(inst)
end

local FINDMINIONS_MUST_TAGS = { "stalkerminion" }
local FINDMINIONS_CANT_TAGS = { "NOCLICK" }
local function FindMinions(inst, proximity)
    local x, y, z = inst.Transform:GetWorldPosition()
    return TheSim:FindEntities(x, y, z, MINION_RADIUS + inst:GetPhysicsRadius(0) + (proximity or .5), FINDMINIONS_MUST_TAGS, FINDMINIONS_CANT_TAGS)
end

local function EatMinions(inst)
    local minions = FindMinions(inst)
    local num = math.min(3, #minions)
    for i = 1, num do
        minions[i]:PushEvent("stalkerconsumed")
    end
    if not inst.components.health:IsDead() then
        inst.components.health:DoDelta(1000 * num)
    end
    return num
end

local function OnMinionDeath(inst)
    inst.components.timer:StopTimer("minions_cd")
    inst.components.timer:StartTimer("minions_cd", TUNING.STALKER_MINIONS_CD)
end
-----------------------------------------------------------------------------------------

local function DoSpawnSpikes(inst, pts, level, cache)
    if not inst.components.health:IsDead() then
        for i, v in ipairs(pts) do
            local variation = table.remove(cache.vars, math.random(#cache.vars))
            table.insert(cache.used, variation)
            if #cache.used > 3 then
                table.insert(cache.queued, table.remove(cache.used, 1))
            end
            if #cache.vars <= 0 then
                local swap = cache.vars
                cache.vars = cache.queued
                cache.queued = swap
            end

            local spike = SpawnPrefab("fossilspike2")
            spike.Transform:SetPosition(v:Get())
            spike:RestartSpike(0, variation, level)
            spike.components.combat:SetDefaultDamage(200)

            spike:AddComponent("planardamage")
            spike.components.planardamage:SetBaseDamage(30)

        end
    end
end

local function GenerateSpiralSpikes(inst)
    local spawnpoints = {}
    local x, y, z = inst.Transform:GetWorldPosition()
    local spacing = 2
    local radius = 2
    local deltaradius = .2
    local angle = TWOPI * math.random()
    local deltaanglemult = (inst.reversespikes and -2 or 2) * PI * spacing
    inst.reversespikes = not inst.reversespikes
    local delay = 0
    local deltadelay = 2 * FRAMES
    local num = 40
    local map = TheWorld.Map
    for i = 1, num do
        local oldradius = radius
        radius = radius + deltaradius
        local circ = PI * (oldradius + radius)
        local deltaangle = deltaanglemult / circ
        angle = angle + deltaangle
        local x1 = x + radius * math.cos(angle)
        local z1 = z + radius * math.sin(angle)
        if map:IsPassableAtPoint(x1, 0, z1) then
            table.insert(spawnpoints, {
                t = delay,
                level = i / num,
                pts = { Vector3(x1, 0, z1) },
            })
            delay = delay + deltadelay
        end
    end
    return spawnpoints
end

local function PlayFlameSound(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/flame")
end

local function SpawnSpikes(inst)
    ResetAbilityCooldown(inst, "spikes")

    local spikes = GenerateSpiralSpikes(inst)
    if #spikes > 0 then
        local cache =
        {
            vars = { 1, 2, 3, 4, 5, 6, 7 },
            used = {},
            queued = {},
        }
        local flames = {}
        local flameperiod = .8
        for i, v in ipairs(spikes) do
            flames[math.floor(v.t / flameperiod)] = true
            inst:DoTaskInTime(v.t, DoSpawnSpikes, v.pts, v.level, cache)
        end
        
        for k, v in pairs(flames) do
            inst:DoTaskInTime(k, PlayFlameSound)
        end
        

        DelaySharedAbilityCooldown(inst, "spikes")
    end
end
--------------------------------------------------------------------
local duration = 20

local function SpawnMeteor(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local theta = math.random() * PI2
        -- Do some easing fanciness to make it less clustered around the spawner prefab
    local radius = easing.linear(math.random(), math.random() * 6, 20, 1)
    local met = SpawnPrefab("shadowfireball")
    met.Transform:SetPosition(x + radius*math.cos(theta), 0, z - radius*math.sin(theta))

    if GetTime() >= inst.meteormanager.tasktotime then
        inst.meteormanager.task:Cancel()
        inst.meteormanager.tasktotime = nil
    end
end

local function SpawnMeteors(inst)
    inst.meteormanager.tasktotime = GetTime() + duration
    if inst.meteormanager.task~=nil then
        inst.meteormanager.task:Cancel()
    end
    inst.meteormanager.task = inst:DoPeriodicTask(0.5,SpawnMeteor)
end
---------------------------------------------------------------------
local function DoEcho(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 24, {"_combat","_health"}, {"playerghost","INLIMBO","shadow_aligned"}, {"character","monster","animal"})
    for i, v in ipairs(ents) do
        if v.entity:IsVisible() and not (v.components.health ~= nil and v.components.health:IsDead()) then
            if v.components.combat:GetAttacked(inst,75,nil,nil,{["planar"] = 35}) then
                v:AddDebuff("exhaustion","exhaustion",{duration = 20})
            end
        end
    end
end
local function DoScream(inst)
    local delay = 10*FRAMES
    for i = 0, 7 do
        inst:DoTaskInTime(i*delay,DoEcho)
    end
end
---------------------------------------------------------------------
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
---------------------------------------------------------------------
local MAX_ICESPIKE_SFX = 6
local ICESPAWNTIME = 0.25
local DARKSPIKE_ATTACK_RANGE = 14
local function DoSpawnShadowSpike(inst, target, rot, info, data, hitdelay, shouldsfx)

	local fx = SpawnPrefab("dark_spike")
	--fx:SetFXOwner(inst)
	fx.Transform:SetPosition(info.x, 0, info.z)
	fx.Transform:SetRotation(rot)
end
local function SpawnDarkSpikes(inst, target)
	local data = { targets = {}, count = 0 }

	local AOEarc = 35

    local x, y, z = inst.Transform:GetWorldPosition()
    local angle = inst.Transform:GetRotation()
	local spikeinfo = {}

	local theta = angle * DEGREES
	local cos_theta = math.cos(theta)
	local sin_theta = math.sin(theta)
    local num = 4
	data.count = data.count + num
	for i = 1, num do
		local radius = DARKSPIKE_ATTACK_RANGE / num * i
		table.insert(spikeinfo,
		{
			x = x + radius * cos_theta,
			z = z - radius * sin_theta,
			radius = radius,
		})
    end

	num = 15
	data.count = data.count + num
	for i = 1, num do
        local theta =  ( angle + math.random(AOEarc *2) - AOEarc ) * DEGREES
        local radius = DARKSPIKE_ATTACK_RANGE * math.sqrt(math.random())
		table.insert(spikeinfo,
		{
			x = x + radius * math.cos(theta),
			z = z - radius * math.sin(theta),
			radius = radius,
		})
    end

	num = 8
	data.count = data.count + num
	local newarc = 180 - AOEarc
	for i = 1, num do
        local theta =  ( angle -180 + math.random(newarc *2) - newarc ) * DEGREES
        local radius = 2 * math.random() +1
		table.insert(spikeinfo,
		{
			x = x + radius * math.cos(theta),
			z = z - radius * math.sin(theta),
			radius = radius,
		})
	end

	table.sort(spikeinfo, function (a, b)   return a.radius<b.radius   end)

	num = data.count
	local nextbig = 1
	local delayvar = ICESPAWNTIME / (num - 1) * 0.3
	local cursfxinstance = 0
	for i = 1, num do
		local rnd = math.random()
		rnd = math.floor(rnd * rnd * #spikeinfo * 0.6) + 1
		local info = table.remove(spikeinfo, rnd)
		local delay =
			(i == 1 and 0) or
			(i == num and ICESPAWNTIME) or
			(i - 1) / (num - 1) * ICESPAWNTIME + delayvar * (math.random() - 0.5)
		local hitdelay = math.max(0, 3 * FRAMES - delay)
		local soundidx = math.floor((i - 1) / (num - 1) * (MAX_ICESPIKE_SFX - 1))
		local shouldsfx = soundidx >= cursfxinstance
		if shouldsfx then
			cursfxinstance = soundidx + 1
		end
		if math.floor(i * 4 / num) == nextbig then
			info.big = true
			info.variation = nextbig
			nextbig = nextbig + 1
		end
		inst:DoTaskInTime(delay, DoSpawnShadowSpike, target, angle, info, data, hitdelay, shouldsfx)
	end
end
---------------------------------------------------------------------
local function IsValidMindControlTarget(inst, guy)
    if not inst:IsNear(guy, TUNING.STALKER_MINDCONTROL_RANGE) then
        return false
    end
    return not (guy.components.health:IsDead() or guy:HasTag("playerghost"))
        and (guy:DebuffsEnabled())
        and guy.entity:IsVisible()
end

local function IsCrazyGuy(guy)
    local sanity = guy ~= nil and guy.replica.sanity or nil
    return sanity ~= nil and sanity:GetPercentNetworked() <= (guy:HasTag("dappereffects") and TUNING.DAPPER_BEARDLING_SANITY or TUNING.BEARDLING_SANITY)
end

local function HasMindControlTarget(inst)
    local insanecount = 0
    local sanecount = 0
    for i, v in ipairs(AllPlayers) do
        if IsValidMindControlTarget(inst, v) then
            --Use fully crazy check for initiating mind control
            --Use IsCrazyGuy check for effect to actually stick
            if v.components.sanity:IsCrazy() then
                insanecount = insanecount + 1
            else
                sanecount = sanecount + 1
            end
        end
    end
    return insanecount >= math.ceil((insanecount + sanecount) / 3)
end

local function MindControl(inst)
    ResetAbilityCooldown(inst, "mindcontrol")

    local count = 0
    for i, v in ipairs(AllPlayers) do
        if IsValidMindControlTarget(inst, v) and IsCrazyGuy(v) then
            count = count + 1

            v:AddDebuff("mindcontroller", "mindcontroller")
        end
    end

    if count > 0 then
        DelaySharedAbilityCooldown(inst, "mindcontrol")
    end
    return count
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
local function DoLevelUp(inst,data)
    inst.level2 = data.newpercent<0.6
    inst.level3 = data.newpercent<0.4
end
local function IsNearAtrium(inst, other)
    return true
end

local function AtriumOnDeath(inst,data)

    if inst.miniontask ~= nil then
        inst.miniontask:Cancel()
        inst.miniontask = nil
        inst.minionpoints = nil
    end
   
end

local function AtriumOnSave(inst, data)
    data.decay = inst.atriumdecay or nil
    data.channelers = inst.channelerparams
    data.minions = inst.minionpoints ~= nil and #inst.minionpoints or nil
end

local function AtriumOnLoad(inst, data)
    --overwrite atriumdecay if there's any data, otherwise leave it
    if data ~= nil then
        if inst.components.health:IsDead() then
            inst.atriumdecay = data.decay == true
        else
            inst.atriumdecay = nil
            if inst.channelertask == nil and
                data.channelers ~= nil and
                data.channelers.x ~= nil and
                data.channelers.z ~= nil and
                data.channelers.angle ~= nil and
                data.channelers.delta ~= nil and
                (data.channelers.count or 0) > 0 then
                inst.channelerparams =
                {
                    x = data.channelers.x,
                    z = data.channelers.z,
                    angle = data.channelers.angle,
                    delta = data.channelers.delta,
                    count = data.channelers.count,
                }
                inst.channelertask = inst:DoTaskInTime(0, DoSpawnChanneler)
            end
        end
    end
end

local function AtriumOnLoadPostPass(inst, ents, data)
    if data ~= nil and
        not inst.components.health:IsDead() and
        inst.miniontask == nil and
        (data.minions or 0) > 0 then
        SpawnMinions(inst, data.minions)
    end
    inst.components.health:DoDelta(1)
end
----------------------------------------------------------


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()

    inst.Transform:SetScale(1.5,1.5,1.5)

    --MakeGiantCharacterPhysics(inst, 1000, .75)
    MakeCharacterPhysics(inst, 5000, 2)
    RemovePhysicsColliders(inst)
    inst.Physics:SetCollisionGroup(COLLISION.SANITY)
    inst.Physics:CollidesWith(COLLISION.SANITY)


    inst.AnimState:SetBank("stalker")
    inst.AnimState:SetBuild("stalker_shadow_build")
    inst.AnimState:AddOverrideBuild("stalker_atrium_build")
    inst.AnimState:PlayAnimation("idle", true)
    --inst.AnimState:SetBloomEffectHandle(resolvefilepath("shaders/spell_haste.ksh"))
    MakeShadowDeity(inst)

    inst:AddTag("epic")
    inst:AddTag("hostile")
    inst:AddTag("scarytoprey")
    inst:AddTag("largecreature")
    inst:AddTag("stalker")
    inst:AddTag("fossil")
    inst:AddTag("deity")
    inst:AddTag("shadow_aligned")
    inst:AddTag("no_rooted")
    inst:AddTag("notraptrigger")

    --stupid
    

    
    inst:AddTag("noepicmusic")

    --inst._camerafocus = net_bool(inst.GUID, "stalker._camerafocus", "camerafocusdirty")
    --inst._camerafocustask = nil
    --inst._music = net_tinybyte(inst.GUID, "stalker._music", "musicdirty")
    


    local talker = inst:AddComponent("talker")
    talker.fontsize = 40
    talker.font = TALKINGFONT
    talker.colour = Vector3(238 / 255, 69 / 255, 105 / 255)
    talker.offset = Vector3(0, -700, 0)
    talker.symbol = "fossil_chest"
    talker.name_colour = Vector3(233/256, 85/256, 107/256)
    talker.chaticon = "npcchatflair_stalker"
    talker:MakeChatter()
    

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
       
            --inst:ListenForEvent("camerafocusdirty", OnCameraFocusDirty)          
        return inst
    end

    inst.recentlycharged = {}
    --inst.Physics:SetCollisionCallback(OnCollide)

    inst:AddComponent("inspectable")
    --inst.components.inspectable:RecordViews()

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("stalker")

    inst:AddComponent("locomotor")
    inst.components.locomotor.pathcaps = { ignorewalls = true }
    inst.components.locomotor.walkspeed = TUNING.STALKER_SPEED

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(50000)
    inst.components.health.redirect = nodmgshielded
    inst.components.health.DoDelta = HealthDoDelta
    inst.components.health.nofadeout = true

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.max_distsq = 400
    inst.components.sanityaura.fallofffn = crazyfallofffn
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_HUGE*5

    inst:AddComponent("drownable")

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(250)
    inst.components.combat:SetAttackPeriod(TUNING.STALKER_ATRIUM_ATTACK_PERIOD)
    inst.components.combat:SetRange(5, 8)
    inst.components.combat.hiteffectsymbol = "torso"
    inst.components.combat.shouldavoidaggrofn = OnlyPlayer
    inst.components.combat:SetAreaDamage(TUNING.STALKER_AOE_RANGE)
    inst.components.combat:SetRetargetFunction(2, AtriumRetargetFn)
    inst.components.combat:SetKeepTargetFunction(AtriumKeepTargetFn)
    inst.components.combat.battlecryinterval = 10
    --inst.components.combat.GetBattleCryString = AtriumBattleCry

    inst:AddComponent("grouptargeter")

    inst:AddComponent("timer")

    inst:AddComponent("epicscare")
    inst.components.epicscare:SetRange(TUNING.STALKER_EPICSCARE_RANGE)

   -- inst:ListenForEvent("attacked", OnAttacked)

    inst.StartAbility = StartAbility
    inst.FindSnareTargets = FindSnareTargets
    inst.SpawnSnares = SpawnSnares
    inst.SetEngaged = AtriumSetEngaged
    inst:SetEngaged(false)

    inst:AddComponent("entitytracker")

    inst:AddComponent("planarentity")

    inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(45)
    
    inst:AddComponent("commander")

    inst.meteormanager = {
        tasktotime = nil,
        task = nil
    }
    inst._vortexes = {}
    

    --inst.EnableCameraFocus = EnableCameraFocus
    inst.BattleChatter = AtriumBattleChatter
    inst.IsNearAtrium = IsNearAtrium
    --inst.OnLostAtrium = OnLostAtrium
    --inst.IsAtriumDecay = CheckAtriumDecay
    inst.SpawnChannelers = SpawnChannelers
    inst.DespawnChannelers = DespawnChannelers
    inst.SpawnMinions = SpawnMinions
    inst.FindMinions = FindMinions
    inst.EatMinions = EatMinions
    inst.SpawnSpikes = SpawnSpikes
    inst.SpawnMeteors = SpawnMeteors
    inst.SpawnDarkSpikes = SpawnDarkSpikes
    inst.SpawnVortexes = SpawnVortexes
    inst.StartScream = DoScream
    inst.HasMindControlTarget = HasMindControlTarget
    inst.MindControl = MindControl
    inst.OnRemoveEntity = DespawnChannelers
    --inst.OnEntityWake = AtriumOnEntityWake
    --inst.OnEntitySleep = AtriumOnEntitySleep
    inst.OnSave = AtriumOnSave
    inst.OnLoad = AtriumOnLoad
    inst.OnLoadPostPass = AtriumOnLoadPostPass

    inst.hasshield = false
    

    inst:SetStateGraph("SGsuperstalker")
    inst:SetBrain(brain)

    inst:ListenForEvent("ontalk", OnTalk)
    inst:ListenForEvent("donetalking", OnDoneTalking)
    inst:ListenForEvent("soldierschanged", OnSoldiersChanged)
    inst:ListenForEvent("miniondeath", OnMinionDeath)
    inst:ListenForEvent("death", AtriumOnDeath)

    inst:ListenForEvent("healthdelta", DoLevelUp)
    

    return inst
end

return Prefab("supreme_shadow", fn, assets, prefabs)


