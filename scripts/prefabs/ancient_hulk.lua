local RuinsRespawner = require "prefabs/ruinsrespawner"
local brain=require("brains/ancient_hulkbrain")
local SHAKE_DIST = 40
--local easing=require("easing")


local assets =
{
    Asset("ANIM", "anim/metal_hulk_build.zip"),
	Asset("ANIM", "anim/metal_hulk_basic.zip"),
    Asset("ANIM", "anim/metal_hulk_attacks.zip"),
    Asset("ANIM", "anim/metal_hulk_actions.zip"),
    Asset("ANIM", "anim/metal_hulk_barrier.zip"),
    Asset("ANIM", "anim/metal_hulk_explode.zip"),    
    Asset("ANIM", "anim/metal_hulk_bomb.zip"),    
    Asset("ANIM", "anim/metal_hulk_projectile.zip"),    

    Asset("ANIM", "anim/laser_explode_sm.zip"),  
    Asset("ANIM", "anim/smoke_aoe.zip"),
    Asset("ANIM", "anim/laser_explosion.zip"),
    --Asset("ANIM", "anim/ground_chunks_breaking.zip"),
    Asset("ANIM", "anim/ground_chunks_breaking_brown.zip"),

    --Asset("SOUND", "sound/bearger.fsb"),
}

local prefabs =
{
    "groundpound_fx",
    "groundpoundring_fx",
    "ancient_hulk_orb_small",
}

SetSharedLootTable('ancient_hulk',
{
    {'gears',           1.0},
    {'gears',           1.0},
    {'gears',           1.0},
    {'gears',           1.0},
    {'opalpreciousgem', 1.0},
    {'iron_soul', 1.0},
})


local many_ruins={}
for i=1,30 do
    table.insert(many_ruins,"thulecite")
end
local PHASES =
{
	[1] = {
		hp = 1,
		fn = function(inst)
            print("???")
		end,
	},
	--
	[2] = {
		hp = 0.7,
		fn = function(inst)
            inst.angry=true
            inst.canspark=true
            inst.cancharge=false
            inst.canbarrier=false
		end,
	},
	[3] = {
		hp = 0.4,
		fn = function(inst)
            inst.angry=true
            inst.canspark=true
            inst.cancharge=true
            inst.canbarrier=true
		end,
	},
}

local INTENSITY = .75
local function SetLightValue(inst, val1, val2, time)
    print("LIGHT VALUE", val1, val2, time)
    inst.components.fader:StopAll()
    if val1 and val2 and time then
        inst.Light:Enable(true)
        inst.components.fader:Fade(val1, val2, time, function(v) inst.Light:SetIntensity(v) end)
--[[
        if inst.Light ~= nil then
            inst.Light:Enable(true)
            inst.Light:SetIntensity(.6 * val)
            inst.Light:SetRadius(5 * val)
            inst.Light:SetFalloff(3 * val)
        end
        ]]
    else    
        inst.Light:Enable(false)
    end
end

local function setfires(x,y,z, rad)
    for i, v in ipairs(TheSim:FindEntities(x, 0, z, rad,nil, { "laser", "DECOR", "INLIMBO" ,"FX","chess"})) do
        if v.components.burnable then
            v.components.burnable:Ignite()
        end
    end
end

local function applydamagetoent(inst,ent, targets, rad, hit)
    local x, y, z = inst.Transform:GetWorldPosition()
    if hit then 
        targets = {}
    end    
    if not rad then 
        rad = 0
    end
    local v = ent
    if not targets[v] and v:IsValid() and not v:IsInLimbo() and not (v.components.health ~= nil and v.components.health:IsDead()) and not v:HasTag("laser_immune") then            
        local vradius = 0
        if v.Physics then
            vradius = v.Physics:GetRadius()
        end

        local range = rad + vradius
        if hit or v:GetDistanceSqToPoint(Vector3(x, y, z)) < range * range then
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
                    local vx,vy,vz = v.Transform:GetWorldPosition()
                    v:DoTaskInTime(0.3, function() setfires(vx,vy,vz,1) end)
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
                            targets[loot] = true
                        end
                    end

            elseif v.components.health~=nil then
                inst.components.combat.ignorehitrange = true
                inst.components.combat:DoAttack(v)
                inst.components.combat.ignorehitrange = false
                if v:IsValid() then
                    if not v.components.health or not v.components.health:IsDead() then
                        if v.components.freezable ~= nil then
                            if v.components.freezable:IsFrozen() then
                                v.components.freezable:Unfreeze()
                            elseif v.components.freezable.coldness > 0 then
                                v.components.freezable:AddColdness(-2)
                            end
                        end
                        if v.components.temperature ~= nil then
                            local maxtemp = math.min(v.components.temperature:GetMax(), 20)
                            local curtemp = v.components.temperature:GetCurrent()
                            if maxtemp > curtemp then
                                v.components.temperature:DoDelta(math.min(20, maxtemp - curtemp))
                            end
                        end
                    end
                end                   
            end
            if v:IsValid() and v.AnimState then
                SpawnPrefab("laserhit"):SetTarget(v)
            end
        end
    end 
    return targets   
end

local DAMAGE_ONEOF_TAGS = { "_combat", "pickable", "NPC_workable", "CHOP_workable", "HAMMER_workable", "MINE_workable", "DIG_workable" }

local function DoDamage(inst, rad, startang, endang, spawnburns)
    local targets = {}
    local x, y, z = inst.Transform:GetWorldPosition()
    local angle = nil
    if startang and endang then
        startang = startang + 90
        endang = endang + 90
        
        local down = TheCamera:GetDownVec()             
        angle = math.atan2(down.z, down.x)/DEGREES
    end

    setfires(x,y,z, rad)
    for i, v in ipairs(TheSim:FindEntities(x, 0, z, rad, nil, { "laser", "DECOR", "INLIMBO" ,"FX","nightmarecreature"},DAMAGE_ONEOF_TAGS)) do  --  { "_combat", "pickable", "campfire", "CHOP_workable", "HAMMER_workable", "MINE_workable", "DIG_workable" }
        local dodamage = true
        if startang and endang then
            local dir = inst:GetAngleToPoint(Vector3(v.Transform:GetWorldPosition())) 

            local dif = angle - dir         
            while dif > 450 do
                dif = dif - 360 
            end
            while dif < 90 do
                dif = dif + 360
            end                       
            if dif < startang or dif > endang then                
                dodamage = nil
            end
        end
        if dodamage then
            targets = applydamagetoent(inst,v, targets, rad)
        end
    end
end

---------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------

local function dropparts(inst,x,z)

    local parts = {
        "ancient_robot_claw",
        "ancient_robot_claw",
        "ancient_robot_leg",
        "ancient_robot_leg",
        "ancient_robot_ribs",
    }

    for i, part in ipairs(parts) do        
        local partprop = SpawnPrefab(part)
        partprop.spawntask:Cancel()
        partprop.spawntask = nil
        partprop.spawned = true
        partprop:AddTag("dormant")                                                    
        partprop.sg:GoToState("idle_dormant")


        partprop.Transform:SetPosition(x,0,z)
        
        inst.DoDamage(partprop, 5)        
    end
end

local TARGET_DIST = 30

local function CalcSanityAura(inst, observer)
    if inst.components.combat:HasTarget() then
        return -TUNING.SANITYAURA_HUGE
    end

    return -TUNING.SANITYAURA_LARGE
end

local RETARGET_MUST_TAGS = { "_combat" }
local RETARGET_CANT_TAGS = { "chess", "INLIMBO" ,"shadow_aligned","ancient_hulk_mine"}
local RETARGET_ONEOF_TAGS = { "character","monster"}

local function RetargetFn(inst)
    local homePos = inst.components.knownlocations:GetLocation("home")
    return not (homePos ~= nil and
                inst:GetDistanceSqToPoint(homePos:Get()) >= 1600)
        and FindEntity(
            inst,
            28,
            function(guy)
                return inst.components.combat:CanTarget(guy)
            end,
            RETARGET_MUST_TAGS,
            RETARGET_CANT_TAGS,
            RETARGET_ONEOF_TAGS
        )
        or nil
end

local function KeepTargetFn(inst, target)

    local homePos = inst.components.knownlocations:GetLocation("home")
    return homePos ~= nil and inst:GetDistanceSqToPoint(homePos:Get()) < 900
end


--[[local function OnLoadPostPass(inst, newents, data)
    if not inst.spawnlocation then
        for i,v in pairs(Ents) do
            if v.prefab == "ancient_hulk_ruinsrespawner_inst" then
                inst.spawnlocation = Vector3(v.Transform:GetWorldPosition())

                break
            end
        end
    end
end]]

local function onload(inst)
    local healthpct = inst.components.health:GetPercent()
	for i = #PHASES, 1, -1 do
		local v = PHASES[i]
		if healthpct <= v.hp then
			v.fn(inst)
			break
		end
	end
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
end

local function OnCollide(inst, other)
    if other ~= nil and other:IsValid() then
        if other:HasTag("smashable") and other.components.health ~= nil then
            other.components.health:Kill()
        elseif other.components.workable ~= nil
                and other.components.workable:CanBeWorked()
                and other.components.workable.action ~= ACTIONS.NET then
            SpawnPrefab("collapse_small").Transform:SetPosition(other.Transform:GetWorldPosition())
            other.components.workable:Destroy(inst)

        elseif other.components.combat ~= nil
                and other.components.health ~= nil and not other.components.health:IsDead()
                and (other:HasTag("wall") or other:HasTag("structure") or other.components.locomotor == nil) then
            other.components.health:Kill()
        end
    end
end

local function LaunchProjectile(inst, targetpos)
    local x, y, z = inst.Transform:GetWorldPosition()

    local projectile = SpawnPrefab("ancient_hulk_mine")

    projectile.primed = false
    projectile.components.creatureprox:SetEnabled(false)
    projectile.AnimState:PlayAnimation("spin_loop",true)
    projectile.Transform:SetPosition(x, 1, z)

    --V2C: scale the launch speed based on distance
    --     because 15 does not reach our max range.
    local dx = targetpos.x - x
    local dz = targetpos.z - z
    --local rangesq = dx * dx + dz * dz
    --local maxrange = 15  --FIRE_DETECTOR_RANGE
    --local speed = 60
    projectile.components.complexprojectile:SetHorizontalSpeed(60)
    projectile.components.complexprojectile:SetGravity(25)
    projectile.components.complexprojectile:Launch(targetpos, inst, inst)
    projectile.owner = inst
end


local function ShootProjectile(inst, targetpos)
    local x, y, z = inst.Transform:GetWorldPosition()

    local projectile = SpawnPrefab("ancient_hulk_orb")

    projectile.primed = false
    projectile.AnimState:PlayAnimation("spin_loop",true)

    local pt = inst.shotspawn:GetPosition()
    projectile.Transform:SetPosition(pt.x, pt.y, pt.z)
    --projectile.Transform:SetPosition(x, 4, z)

   -- inst.shotspawn:Remove()
   -- inst.shotspawn = nil
    --local dx = targetpos.x - x
    --local dz = targetpos.z - z
    --local rangesq = dx * dx + dz * dz
    --local maxrange = 24  --FIRE_DETECTOR_RANGE
    local speed =    65--easing.linear(rangesq, 15, 3, maxrange * maxrange)
    projectile.components.linearprojectile:SetHorizontalSpeed(speed)
    --projectile.components.linearprojectile:SetGravity(25)
    projectile.components.linearprojectile:Launch(targetpos, inst, inst)
    projectile.owner = inst
    --projectile.components.projectile:Throw(inst, target, inst)
end

local function spawnbarrier(inst,pt)
    local angle = 0
    local radius = 10
    local number = 8
    for i=1,number do        
        local offset = Vector3(radius * math.cos( angle ), 0, -radius * math.sin( angle ))
        local newpt = pt + offset
        --local tile = GetWorld().Map:GetTileAtPoint(newpt.x, newpt.y, newpt.z)
        local ground=TheWorld.Map
        if ground:IsPassableAtPoint(newpt.x, 0,newpt.z) then
            inst:DoTaskInTime(0.3, function()
                local spell = SpawnPrefab("deer_fire_circle")
	            if spell.TriggerFX then spell:DoTaskInTime(2, spell.TriggerFX) end
                spell.Transform:SetPosition(newpt.x, 0, newpt.z)
                spell:DoTaskInTime(15, spell.KillFX)
            end)
        end
        angle = angle + (PI*2/number)
    end
end

--[[local function checkforAttacks(inst)
    local pct=inst.components.health:GetPercent()
    if pct<0.5 then
        inst.crazy=true
    end
    -- mine
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z,20,{"ancient_hulk_mine"})
    if #ents < 12 then
        inst.wantstomine = true
    else
        inst.wantstomine = nil
    end
    -- lob
    if inst.orbs > 0 then
        if inst.components.combat.target and inst.components.combat.target:IsValid() then
            local dist = inst:GetDistanceSqToInst(inst.components.combat.target)
            if dist > 12*12  and dist < 25*25 then
                inst.wantstolob = true
            else
                inst.wantstolob = nil
            end
        end
    else
        inst.orbtime = inst.orbtime -1
        if inst.orbtime <= 0 then
            inst.orbtime = nil
            inst.orbs = 4
        end
    end

    -- teleport
    if inst.components.combat.target and inst.components.combat.target:IsValid() then
        local dist = inst:GetDistanceSqToInst(inst.components.combat.target)
        if dist < 6*6 then
            if not inst.teleporttime then
                inst.teleporttime = 0
            end
            inst.teleporttime = inst.teleporttime + 1
            if inst.teleporttime > 3 then
                inst.wantstoteleport = true
            end
        else
            inst.teleporttime =  nil
        end
    end

    -- spin
    if inst.components.combat.target and inst.components.combat.target:IsValid() and pct < 0.8  then
        if not inst.spintime or inst.spintime <=0 then
            local dist = inst:GetDistanceSqToInst(inst.components.combat.target)
            if dist < 6*6 then
                inst.wantstospin = true
            else            
                inst.wantstospin = nil
            end
        else
            inst.spintime = inst.spintime - 1            
        end
    end

    -- barrier?
    if inst.components.combat.target and inst.components.combat.target:IsValid() and pct < 0.3  then
        if not inst.barriertime or inst.barriertime <=0 then
            local dist = inst:GetDistanceSqToInst(inst.components.combat.target)
            if dist < 6*6 then
                inst.wantstobarrier = true
            else            
                inst.wantstobarrier = nil
            end
        else
            inst.barriertime = inst.barriertime - 1            
        end
    end    
end]]
local function EnterShield(inst)
    inst._is_shielding = true

    inst.components.health:SetAbsorptionAmount(1)

    if inst._shieldfx ~= nil then
        inst._shieldfx:kill_fx()
    end
    inst._shieldfx = SpawnPrefab("forcefieldfx")
    inst._shieldfx.Transform:SetScale(1.8,1.8,1.8)
    inst._shieldfx.entity:SetParent(inst.entity)
    inst._shieldfx.Transform:SetPosition(0, 0.5, 0)
end

local function ExitShield(inst)
    inst._is_shielding = nil
    if inst._shieldfx ~= nil then
        inst._shieldfx:kill_fx()
        inst._shieldfx = nil
    end
    inst.components.health:SetAbsorptionAmount(0)
end



local function rememberhome(inst)
    --[[local x,y,z=inst.Transform:GetWorldPosition()
    local pos=inst:GetPosition()
    for i, v in ipairs(TheSim:FindEntities(x, 0, z,40, {"CLASSIFIED"})) do
        if v.prefab=="ancient_hulk_ruinsrespawner_inst" then
            pos=v:GetPosition()
        end
    end
    inst.components.knownlocations:RememberLocation("home",pos)]]
    inst.components.knownlocations:RememberLocation("home", inst:GetPosition())
end
local function OnSave(inst, data)

end
local function CanSpark(inst)
    return inst.canspark
end
local function SparkOnSpawned(inst, poop)
    local heading_angle = inst.Transform:GetRotation()*DEGREES

    local pos = Vector3(inst.Transform:GetWorldPosition())
    pos.x = pos.x + 4*math.cos(heading_angle)
    pos.z = pos.z + 4*math.sin(heading_angle)
    poop.Transform:SetPosition(pos.x, 2, pos.z)
end

local function OnNewTarget(inst, data)
    if data.target ~= nil then
        inst:SetEngaged(true)
    end
end

local function SetEngaged(inst, engaged)
    --NOTE: inst.engaged is nil at instantiation, and engaged must not be nil
    if inst.engaged ~= engaged then
        inst.engaged = engaged
        if engaged then
            inst.components.health:StopRegen()
            inst:RemoveEventCallback("newcombattarget", OnNewTarget)
        else
            inst.components.health:StartRegen(30, 1)
            inst:ListenForEvent("newcombattarget", OnNewTarget)
        end
    end
end
local function fn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddDynamicShadow()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetSixFaced()

	inst.DynamicShadow:SetSize(6, 3.5)

    MakeGiantCharacterPhysics(inst, 1000, 1.5)
    --MakeCharacterPhysics(inst, 1000, 1.5)
    inst.AnimState:SetBank("metal_hulk")
    inst.AnimState:SetBuild("metal_hulk_build")
    inst.AnimState:PlayAnimation("idle", true)

    inst.Physics:SetCollisionCallback(OnCollide)



    inst.AnimState:AddOverrideBuild("laser_explode_sm")
    inst.AnimState:AddOverrideBuild("smoke_aoe")
    inst.AnimState:AddOverrideBuild("laser_explosion")
    inst.AnimState:AddOverrideBuild("ground_chunks_breaking")
    --inst.Transform:SetScale(1.2,1.2,1.2)


    inst:AddTag("epic")
    inst:AddTag("hostile")
    inst:AddTag("scarytoprey")
    inst:AddTag("largecreature")
    inst:AddTag("ancient_hulk")
    inst:AddTag("dontteleporttointerior")
    inst:AddTag("laser_immune")
    inst:AddTag("mech")
    inst:AddTag("chess")

    inst:AddComponent("fader")
    inst.glow = inst.entity:AddLight()
    inst.glow:SetIntensity(.6)
    inst.glow:SetRadius(5)
    inst.glow:SetFalloff(3)
    inst.glow:SetColour(1, 0.3, 0.3)
    inst.glow:Enable(false)



    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
     
    ----------------------------------------
    inst.angry=false
    inst.canspark=false
    inst.cancharge=false
    inst.canbarrier=false

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aurafn = CalcSanityAura

    ------------------
    
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(20000)
    inst.components.health.destroytime = 5
    inst.components.health.fire_damage_scale = 0

    ----------------------
    inst:AddComponent("timer")
    -----------------
    inst:AddComponent("healthtrigger")
    for i, v in pairs(PHASES) do
		inst.components.healthtrigger:AddTrigger(v.hp, v.fn)
	end
    inst:AddComponent("knownlocations")
    -----------------
    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(200)
    inst.components.combat.playerdamagepercent = .5
    inst.components.combat:SetRange(18, 5.5)
    inst.components.combat:SetAreaDamage(5.5, 0.8)
    inst.components.combat.hiteffectsymbol = "segment01"
    inst.components.combat:SetAttackPeriod(3)
    inst.components.combat:SetRetargetFunction(2, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    --inst.components.combat:SetHurtSound("dontstarve_DLC001/creatures/bearger/hurt")
    inst:ListenForEvent("killed", function(inst2, data)
        if inst.components.combat and data and data.victim == inst.components.combat.target then
            inst.components.combat.target = nil
        end 
    end)

    inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(10)

    inst:AddComponent("explosiveresist")
    inst:AddComponent("drownable")
    --inst:AddComponent("epicscare")
    --inst.components.epicscare:SetRange(TUNING.STALKER_EPICSCARE_RANGE)
    local stunnable = inst:AddComponent("stunnable")
    stunnable.stun_threshold = 1000
    stunnable.stun_period = 5
    stunnable.stun_duration = 10
    stunnable.stun_resist = 0
    stunnable.stun_cooldown = 5

    inst:AddComponent("periodicspawner")
    inst.components.periodicspawner:SetPrefab("laser_spark")
    inst.components.periodicspawner:SetRandomTimes(6, 8)
    inst.components.periodicspawner:SetDensityInRange(10, 4)
	inst.components.periodicspawner:SetSpawnTestFn(CanSpark)
    inst.components.periodicspawner:SetOnSpawnFn(SparkOnSpawned)
    inst.components.periodicspawner:Start()


    inst._shieldfx=nil
    inst._is_shielding = nil
    inst.EnterShield = EnterShield
    inst.ExitShield = ExitShield
    ------------------------------------------

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("ancient_hulk")
    inst.components.lootdropper:SetLoot(many_ruins)
    ------------------------------------------

    inst:AddComponent("inspectable")

    ------------------------------------------

    inst:AddComponent("groundpounder")
    inst.components.groundpounder.destroyer = true
    inst.components.groundpounder.damageRings = 4
    inst.components.groundpounder.destructionRings = 5
    inst.components.groundpounder.numRings = 3
    --inst.components.groundpounder.groundpoundfx = "groundpound_fx_hulk"

    ------------------------------------------

    inst.OnSave = OnSave
    inst.OnLoad = onload
    --inst.OnLoadPostPass = OnLoadPostPass
    inst.LaunchProjectile = LaunchProjectile
    inst.ShootProjectile = ShootProjectile
    inst.DoDamage = DoDamage
    inst.spawnbarrier = spawnbarrier
    --inst.dropparts = dropparts
    inst.SetLightValue = SetLightValue
    inst.SetEngaged = SetEngaged

    inst:ListenForEvent("attacked", OnAttacked)
    --inst:DoPeriodicTask(1,function() checkforAttacks(inst) end)
    inst:ListenForEvent( "onremove", function() inst.SoundEmitter:KillSound("gears") print("KILLLL GEARS!!!!!!!!!")  end, inst )
    
    ------------------------------------------

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 6
    inst.components.locomotor.runspeed = 12
    inst.components.locomotor:SetShouldRun(true)




    inst:SetStateGraph("SGancient_hulk")
    inst:SetBrain(brain)
    inst:DoTaskInTime(0, rememberhome)


    if not inst.shotspawn then
        inst.shotspawn = SpawnPrefab( "ancient_hulk_marker" )
        inst.shotspawn:Hide()
        inst.shotspawn.persists = false
        local follower = inst.shotspawn.entity:AddFollower()
        follower:FollowSymbol( inst.GUID, "hand01", 0,0,0 )
    end
    SetEngaged(inst, false)


    return inst
end

--[[local function OnMineCollide(inst, other)
    -- may want to do some charging damage?
end]]

local function OnHit(inst, dist)    
    inst.AnimState:PlayAnimation("land")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step_wires")
    --inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/step_wires")
    inst.AnimState:PushAnimation("open")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust")
    inst:ListenForEvent("animover", function()
        inst.components.creatureprox:SetEnabled(true)
        if inst.AnimState:IsCurrentAnimation("open") then
            inst.primed  = true
            inst.AnimState:PlayAnimation("green_loop",true)
        end
    end)
end

local function minetrigger(inst)
            --explode, end beep
    inst.SoundEmitter:KillSound("boom_loop")
    inst:Hide()
    local ring = SpawnPrefab("laser_ring")
    ring.Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:DoTaskInTime(0.4,function() DoDamage(inst, 5) inst:Remove() end)

    local explosion = SpawnPrefab("laser_explosion")
    explosion.Transform:SetPosition(inst.Transform:GetWorldPosition())
    --inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/smash_3")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/smash")
end

local function onnearmine(inst, ents)    
    local detonate = false
    for i,ent in ipairs(ents)do
        if not ent:HasTag("ancient_hulk") then
            detonate = true
            break
        end
    end
    if inst.primed and detonate then
        inst:SetLightValue(0,0.75,0.2 )
        inst.AnimState:PlayAnimation("red_loop", true)
        --start beep
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/active_LP","boom_loop")
        inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
        inst:DoTaskInTime(0.5,minetrigger)
    end
end

local function minefn()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    local sound = inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst, 75, 0.5)

    --inst.Physics:SetCollisionCallback(OnMineCollide)

    anim:SetBank("metal_hulk_mine")
    anim:SetBuild("metal_hulk_bomb")
    anim:PlayAnimation("green_loop", true)
    inst:AddTag("ancient_hulk_mine")

    inst.primed =true


    inst.glow = inst.entity:AddLight()
    inst.glow:SetIntensity(.6)
    inst.glow:SetRadius(2)
    inst.glow:SetFalloff(1)
    inst.glow:SetColour(1, 0.3, 0.3)
    inst.glow:Enable(false)

    inst:AddComponent("fader")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end



    inst:AddComponent("locomotor")
    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetOnHit(OnHit)
    --inst.components.complexprojectile.yOffset = 2.5

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(100)  --ANCIENT_HULK_MINE_DAMAGE
    inst.components.combat.playerdamagepercent = .5

    inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(10)

    inst.SetLightValue = SetLightValue

    inst:AddComponent("creatureprox")
    inst.components.creatureprox.period = 0.02
    inst.components.creatureprox:SetDist(4,5)
    inst.components.creatureprox:SetOnPlayerNear(onnearmine)

    inst:DoTaskInTime(60,minetrigger)
    return inst
end

local function OnHitOrb(inst, dist)    
    --[[local player = GetClosestInstWithTag("player", inst, SHAKE_DIST)
    if player then
        player.components.playercontroller:ShakeCamera(inst, "VERTICAL", 0.4, 0.03, 1.5, SHAKE_DIST)
    end]]
    --ShakeAllCameras(CAMERASHAKE.FULL, .7, .02, 1, inst, 40)
    inst.AnimState:PlayAnimation("impact")  
    inst:ListenForEvent("animover", function() 
        if inst.AnimState:IsCurrentAnimation("impact") then
           inst:Remove()
        end
    end)
    local ring = SpawnPrefab("laser_ring")
    ring.Transform:SetPosition(inst.Transform:GetWorldPosition())     
    inst:DoTaskInTime(0.3,function() DoDamage(inst, 3.5) end)
    --inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/smash_2")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/smash")
end

local function orbfn()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    local sound = inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    MakeInventoryPhysics(inst, 75, 0.5)

    anim:SetBank("metal_hulk_projectile")
    anim:SetBuild("metal_hulk_projectile")
    anim:PlayAnimation("spin_loop", true)

    inst:AddComponent("fader")
    inst.glow = inst.entity:AddLight()
    inst.glow:SetIntensity(.6)
    inst.glow:SetRadius(3)
    inst.glow:SetFalloff(1)
    inst.glow:SetColour(1, 0.3, 0.3)
    inst.glow:Enable(true)
    inst:AddTag("ancient_hulk_orb")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end




    inst.persists = false

    inst:AddComponent("locomotor")

    inst:AddComponent("linearprojectile")
    inst.components.linearprojectile:SetOnHit(OnHitOrb)
    

    --[[inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(28)
    inst.components.projectile:SetHoming(false)
    inst.components.projectile:SetHitDist(1.5)
    inst.components.projectile.yOffset=2.5
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:SetOnMissFn(inst.Remove)]]



    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(100)--ANCIENT_HULK_MINE_DAMAGE
    inst.components.combat.playerdamagepercent = 0.5

     inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(10)




    inst.SetLightValue = SetLightValue

    return inst
end

local function OnCollidesmall(inst,owner,target)
    if target~=nil and target.components.health~=nil and not target.components.health:IsDead() then
        target.components.health:DoDelta(-20,false,owner,true,nil,true)
        target.components.health:DeltaPenalty(0.05)
    end
    -- DANY SOUND          inst.SoundEmitter:PlaySound( smallexplosion )  
    inst:Remove()
end

local function orbsmallfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)
	--[[inst.Physics:CollidesWith(COLLISION.WAVES)
    inst.Physics:CollidesWith(COLLISION.INTWALL)]]
    
    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("metal_hulk_projectile")
    inst.AnimState:SetBuild("metal_hulk_projectile")
    inst.AnimState:PlayAnimation("spin_loop")    
    inst.AnimState:SetMultColour(0,0,0,0.5)
    inst:AddTag("projectile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end


    inst.persists = false

    --inst:AddComponent("locomotor")
    inst:AddComponent("weapon")
    
    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(40)
    inst.components.projectile:SetHoming(false)
    inst.components.projectile:SetHitDist(2)
    inst.components.projectile:SetOnHitFn(OnCollidesmall)
    inst.components.projectile:SetOnMissFn(inst.Remove)


    inst:DoTaskInTime(4,inst.Remove)

    --[[inst:AddComponent("fader")
    inst.glow = inst.entity:AddLight()    
    inst.glow:SetIntensity(.6)
    inst.glow:SetRadius(3)
    inst.glow:SetFalloff(1)
    inst.glow:SetColour(1, 0.3, 0.3)
    inst.glow:Enable(true)]]

    --inst.SetLightValue = SetLightValue

    

    return inst
end

local function OnCollidecharge(inst,other)
    inst.Physics:SetMotorVelOverride(0,0,0)
    --[[local player = GetClosestInstWithTag("player", inst, SHAKE_DIST)
    if player then
        player.components.playercontroller:ShakeCamera(inst, "VERTICAL", 0.4, 0.03, 1.5, SHAKE_DIST)
    end ]]
    ShakeAllCameras(CAMERASHAKE.FULL, .7, .02, 1, inst, 40)
    inst.AnimState:PlayAnimation("impact")  
    inst:ListenForEvent("animover", function() 
        if inst.AnimState:IsCurrentAnimation("impact") then
           inst:Remove()
        end
    end)
    local ring = SpawnPrefab("laser_ring")
    ring.Transform:SetPosition(inst.Transform:GetWorldPosition())     
    inst:DoTaskInTime(0.3,function() DoDamage(inst, 3.5) end)
    --inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/smash_2")
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/smash")
end

local function orbchargefn(Sim)

    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    local sound = inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    MakeCharacterPhysics(inst, 1, 0.5)
    
    inst.Physics:SetCollisionCallback(OnCollidecharge)

    anim:SetBank("metal_hulk_projectile")
    anim:SetBuild("metal_hulk_projectile")
    anim:PlayAnimation("spin_loop", true)    

    inst:AddTag("projectile")
    inst:AddComponent("fader")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false



    inst:AddComponent("locomotor")


    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(100)  --ANCIENT_HULK_MINE_DAMAGE
    inst.components.combat.playerdamagepercent = 0.5
 
    inst.Physics:SetMotorVelOverride(40,0,0)

    inst:DoTaskInTime(2,function() inst:Remove() end)


    --[[inst.glow = inst.entity:AddLight()
    inst.glow:SetIntensity(.6)
    inst.glow:SetRadius(3)
    inst.glow:SetFalloff(1)
    inst.glow:SetColour(1, 0.3, 0.3)
    inst.glow:Enable(true)]]

    inst.SetLightValue = SetLightValue

    return inst
end

local function markerfn()
    local inst = CreateEntity()
    local trans = inst.entity:AddTransform()
    inst.entity:AddNetwork()
    if not TheWorld.ismastersim then
        return inst
    end
    inst.persists = false
    return inst
end


return Prefab( "ancient_hulk", fn, assets, prefabs),
       Prefab( "ancient_hulk_mine", minefn, assets, prefabs),
       Prefab( "ancient_hulk_orb", orbfn, assets, prefabs),
       Prefab( "ancient_hulk_orb_small", orbsmallfn, assets, prefabs),
       Prefab( "ancient_hulk_orb_charge", orbchargefn, assets, prefabs),
       Prefab( "ancient_hulk_marker", markerfn, assets, prefabs),
    RuinsRespawner.Inst("ancient_hulk"), RuinsRespawner.WorldGen("ancient_hulk")