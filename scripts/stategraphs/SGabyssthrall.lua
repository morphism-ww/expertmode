require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.HAMMER, "meteor"),
}
local function SpawnInRange(inst, prefabs, count, player)
	
	local x,y,z = inst.Transform:GetWorldPosition()

	local function getrandomoffset()
	    local theta = math.random() * PI2
        local radius = 4 + 8*math.random()
		return Vector3(x+radius*math.cos(theta), 0, z-radius*math.sin(theta))
	end

    local types = #prefabs

	for i=1, count do
		local spawn_pt = getrandomoffset()
			
        local ent = SpawnPrefab(prefabs[math.random(1, types)])

        
        ent.Transform:SetPosition(spawn_pt.x, 0, spawn_pt.z)
        

        ent:AddTag("nosinglefight_l")
        ent:AddTag("notaunt")
        
        if player~=nil then
            ent.components.combat:SetTarget(player)
        end

        ent.persists =  false

        ent.components.lootdropper:SetLoot({})
        ent.components.lootdropper:SetChanceLootTable(nil)
	end
end


local function SpawnNightmares(inst, player)
	local num = math.random(2,3)
    local x, y, z = inst.Transform:GetWorldPosition()
    for i, v in ipairs(AllPlayers) do
        if not v:HasTag("playerghost") and
            v.entity:IsVisible() and
            v:GetDistanceSqToPoint(x, y, z) < 400 then
            num = num + 1
        end
    end
    SpawnInRange(inst,{"shadowdragon","nightmarebeak","ruinsnightmare"},num,player)
end


local AOE_RANGE_PADDING = 3
local AOE_TARGET_MUSTHAVE_TAGS = { "_combat" }
local AOE_TARGET_CANT_TAGS = { "INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost","shadowcreature","shadowthrall","shadow","laser_immune" }

local function AOEAttack(inst, dist, radius, targets, mult)
    inst.components.combat.ignorehitrange = true

    local x, y, z = inst.Transform:GetWorldPosition()
    local cos_theta, sin_theta

    if dist ~= 0 then
        local theta = inst.Transform:GetRotation() * DEGREES
        cos_theta = math.cos(theta)
        sin_theta = math.sin(theta)

        x = x + dist * cos_theta
        z = z - dist * sin_theta
    end

    for i, v in ipairs(TheSim:FindEntities(x, y, z, radius + AOE_RANGE_PADDING, AOE_TARGET_MUSTHAVE_TAGS, AOE_TARGET_CANT_TAGS)) do
        if v ~= inst and
            not (targets and targets[v]) and
            v:IsValid() and not v:IsInLimbo() and
            not (v.components.health and v.components.health:IsDead())
        then
            local range = radius + v:GetPhysicsRadius(0)
            local x1, y1, z1 = v.Transform:GetWorldPosition()
            local dx = x1 - x
            local dz = z1 - z

            if dx * dx + dz * dz < range * range and inst.components.combat:CanTarget(v) then
                inst.components.combat:DoAttack(v)
                if targets then
                    targets[v] = true
                end
                if mult then
                    v:PushEvent("knockback", { knocker = inst, radius = radius + dist, strengthmult = mult })
                end
            end
        end
    end

    inst.components.combat.ignorehitrange = false
end

local MAIN_SHIELD_CD = 1.2
local function PickShield(inst)
    local t = GetTime()
    if (inst.sg.mem.lastshieldtime or 0) + .2 >= t then
        return
    end

    inst.sg.mem.lastshieldtime = t

    --variation 3 or 4 is the main shield
    local dt = t - (inst.sg.mem.lastmainshield or 0)
    if dt >= MAIN_SHIELD_CD then
        inst.sg.mem.lastmainshield = t
        return math.random(3, 4)
    end

    local rnd = math.random()
    if rnd < dt / MAIN_SHIELD_CD then
        inst.sg.mem.lastmainshield = t
        return math.random(3, 4)
    end

    return rnd < dt / (MAIN_SHIELD_CD * 2) + .5 and 2 or 1
end

local events=
{
    CommonHandlers.OnLocomote(false, true),
    CommonHandlers.OnDeath(),
    EventHandler("attacked", function(inst)
        if not inst.components.health:IsDead() then
            if inst.hasshield then
                local shieldtype = PickShield(inst)
                if shieldtype ~= nil then
                    local fx = SpawnPrefab("stalker_shield"..tostring(shieldtype))
                    fx.entity:SetParent(inst.entity)
                    if shieldtype < 3 and math.random() < .5 then
                        fx.AnimState:SetScale(-2.36, 2.36, 2.36)
                    end
                end
            elseif not inst.sg:HasStateTag("busy") and not  not CommonHandlers.HitRecoveryDelay(inst, 5) then
                inst.sg:GoToState("hit")  
            end        
        end
    end),
    EventHandler("doattack", function(inst, data)
        if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy"))
                and (data.target ~= nil and data.target:IsValid()) then
            inst.sg:GoToState("attack")    
        end            
    end),
    EventHandler("summon", function(inst)
        if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy")) then
            inst.sg:GoToState("summon")            
        end
    end),
    EventHandler("meteor", function(inst)
        if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy")) then
            inst.sg:GoToState("meteor")            
        end
    end),
    EventHandler("shield", function(inst)
        if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy")) then
            inst.sg:GoToState("shield")            
        end
    end),
}

local function OnAnimOver(state)
    return {
        EventHandler("animover", function(inst) inst.sg:GoToState(state) end),
    }
end


local states =
{
    State{
        name = "idle",

        tags = {"idle", "canrotate"},
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("idle", true)
        end,

        events = OnAnimOver("idle"),
    },
    
    State{
        name = "appear",
        tags = {"busy"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("appear")
            inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_howl")
            TheMixer:PushMix("shadow")

        end,
        
        timeline=
        {
            FrameEvent(1, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/appear") end),
        },
        
        events = OnAnimOver("idle")
        
    },    

    State{
        name = "taunt",
        tags = {"busy"},
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
        end,

        timeline=
        {
            FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/taunt") end),
        },
        
        events = OnAnimOver("idle")
    },

    State{
        name = "hit",
        tags = {"hit"},
        onenter = function (inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/hit")
            CommonHandlers.UpdateHitRecoveryDelay(inst)
        end,
        events = OnAnimOver("idle")
    },

    State{
        name = "attack",
        tags = {"attack", "busy"},

        onenter = function(inst, target)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("attack")
            inst.components.combat:StartAttack()
            
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/attack")
            
        end,

        timeline=
        {
            FrameEvent(1, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/attack_2d") end),
            FrameEvent(20, function(inst)
                local ring = SpawnPrefab("newcs_laser_ring")
                ring.Transform:SetPosition(inst.Transform:GetWorldPosition())
                ring.Transform:SetScale(1.1, 1.1, 1.1)
                AOEAttack(inst,0,6,nil,1.2)
            end)
        },
        events = OnAnimOver("idle"),
    },

    State{
        name = "meteor",
        tags = {"attack", "busy", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("taunt")

            inst.components.combat:StartAttack()
            
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/summon")
            
            
            if inst.bufferedaction ~= nil and inst.bufferedaction.action == ACTIONS.HAMMER then
                inst.sg.statemem.target = inst.bufferedaction.target
                
            else
                inst.components.timer:StartTimer("meteor_cd",TUNING.ABYSS_THRALL_CD*0.75)
                inst.sg.statemem.target = inst.components.combat.target
            end

        end,

        timeline=
        {   
            FrameEvent(1, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/summon_2d") end),
            FrameEvent(30, function (inst)
                if inst.sg.statemem.target ~= nil and inst.sg.statemem.target:IsValid() then
                    
                    local tx, y, tz = inst.sg.statemem.target.Transform:GetWorldPosition()
                    local firerain = SpawnPrefab("shadowfireball")
                    firerain.Transform:SetPosition(tx, 0, tz)
                    local delay = 0
                    for i = 1, 2 do
            
                        local x, z = 4* UnitRand() + tx, 4* UnitRand() + tz
                        inst:DoTaskInTime(delay, function()
                            local firerain = SpawnPrefab("shadowfireball")
                            firerain.Transform:SetPosition(x, 0, z)
                        end)
                        delay = delay + 0.3
                    end
                end
            end),
        },
        onexit = function (inst)
            inst:ClearBufferedAction()
        end,
        events = OnAnimOver("idle"),
    },

    State{
        name = "shoot_attack",
        tags = {"attack", "busy", "canrotate"},

        onenter = function(inst, target)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("taunt")
            inst.SoundEmitter:PlaySound("dontstarve/ghost/ghost_howl")
            inst.components.combat:StartAttack()
            
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/attack")
            
            inst.sg.statemem.target = target
        end,

        timeline=
        {
            FrameEvent(1, function (inst)
                if inst.sg.statemem.target ~= nil and inst.sg.statemem.target:IsValid() then
                    local x, y, z = inst.Transform:GetWorldPosition()
                    inst:ForceFacePoint(inst.sg.statemem.target.Transform:GetWorldPosition())
                    local facing_angle = inst.Transform:GetRotation()*DEGREES
                    local tx ,tz = x + 2*math.cos(facing_angle), z - 2*math.sin(facing_angle)
                    local proj = SpawnPrefab("darkball_projectile")
                    proj.components.weapon:SetDamage(75)
                    proj.AnimState:PlayAnimation("portal_pre")
                    proj.AnimState:PushAnimation("portal_loop")
                    proj.Transform:SetPosition(tx, 0, tz)
                    proj:DoTaskInTime(10,function (inst2)
                        inst2:Remove()
                    end)
                    inst.sg.statemem.proj = proj
                end
            end),
            FrameEvent(30,function (inst)
                if inst.sg.statemem.target ~= nil and inst.sg.statemem.target:IsValid() then
                    inst.SoundEmitter:PlaySound("dontstarve/creatures/eyeballturret/shoot")
                    inst.sg.statemem.proj.components.projectile:Throw(inst, inst.sg.statemem.target, inst)
                end        
            end)
        },
        events = OnAnimOver("idle"),
    },

    State{
        name = "shield",
        tags = {"shield", "busy"},

        onenter = function(inst, target)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("attack")

            inst:DoTaskInTime(20, function (inst2)
                inst2.hasshield = false
                
            end)
            --inst.components.timer:StartTimer("shield_end",30)
            inst.components.timer:StartTimer("shield_cd",TUNING.ABYSS_SHIELD_CD)
        end,

        timeline=
        {
            FrameEvent(1, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/attack_2d") end),
            FrameEvent(20, function(inst)
                local ring = SpawnPrefab("newcs_laser_ring")
                ring.Transform:SetPosition(inst.Transform:GetWorldPosition())
                ring.Transform:SetScale(1.1, 1.1, 1.1)
                inst.hasshield = true
                local fx = SpawnPrefab("stalker_shield4")
                fx.entity:SetParent(inst.entity)
            end)
        },
        events = OnAnimOver("idle"),
    },

    State{
        name = "summon",
        tags = {"busy", "summon","attack","canrotate"},
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("summon")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/summon")
            inst.components.timer:StartTimer("summon_cd",TUNING.ABYSS_THRALL_CD)
        end,
        
        timeline=
        {
            FrameEvent(1, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/summon_2d") end),
            FrameEvent(30, function(inst)
			    SpawnNightmares(inst,inst.components.combat.target)
            end)
        },

        events = OnAnimOver("idle")
    },
}


CommonStates.AddDeathState(states,
{
    FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/death") end),
})

CommonStates.AddWalkStates(states,
{
    walktimeline = 
    {
        FrameEvent(0, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/breath_in") end),
        FrameEvent(17, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/ancient_herald/breath_out") end),   
    }
})
    
return StateGraph("abyss_thrall", states, events, "idle",actionhandlers)