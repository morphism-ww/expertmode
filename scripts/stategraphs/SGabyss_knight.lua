require("stategraphs/commonstates")

------------------------------------------------------------------------------------------------------------------------------------

local AOE_RANGE_PADDING = 3
local AOE_TARGET_MUSTHAVE_TAGS = { "_combat" }
local AOE_TARGET_CANT_TAGS = { "INLIMBO", "noattack", "flight", "invisible", "playerghost","shadowcreature","shadow","shadowthrall","laser_immune" }

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
                if targets then
                    targets[v] = true
                end
                if mult then
                    v:PushEvent("knockback", { knocker = inst, radius = radius + dist, strengthmult = mult })
                end
                inst.components.combat:DoAttack(v)
            end
        end
    end

    inst.components.combat.ignorehitrange = false
end

local function FindTeleportPos(inst)
    local pt
    local target = inst.components.combat.target
    if target~=nil and target:IsValid() then
        pt = target:GetPosition()
    else
        pt = inst:GetPosition()
    end    

    local trap = SpawnPrefab("shadow_trap")
    trap.Transform:SetPosition(pt:Get())
    trap.sg:GoToState("trigger")

    return pt
end

local function ToggleOffPhysics(inst)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
    inst.Physics:CollidesWith(COLLISION.SANITY)
end

local function ToggleOnPhysics(inst)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
end

------------------------------------------------------------------------------------------------------------------------------------



------------------------------------------------------------------------------------------------------------------------------------

local events =
{
    --[[EventHandler("attacked", function(inst)
        if not inst.components.health:IsDead() then
            if not inst.sg:HasAnyStateTag("attack", "moving") then
                inst.sg:GoToState("hit")
            end
        end
    end),]]

    EventHandler("doattack", function(inst, data)
        if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy"))
                and (data.target ~= nil and data.target:IsValid()) then
            if inst.sg.mem.ishiding then
                inst.sg:GoToState("appear")
            else
                inst.sg:GoToState("attack",data.target)
            end              
        end            
    end),

    EventHandler("locomote", function(inst)
        if not inst.sg:HasStateTag("busy") then
            local is_moving = inst.sg:HasStateTag("moving")
            local wants_to_move = inst.components.locomotor:WantsToMoveForward()
            if not inst.sg:HasStateTag("attack") and is_moving ~= wants_to_move then
                if wants_to_move then
                    inst.sg:GoToState("premoving")
                else
                    inst.sg:GoToState("idle")
                end
            end
        end
    end),
    EventHandler("hide",function (inst)
        if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy")) then
            inst.sg:GoToState("dive")
        end
    end),
    EventHandler("spin",function (inst)
        if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy")) then
            inst.sg:GoToState("spin_attack",inst.components.combat.target)
        end
    end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
}

------------------------------------------------------------------------------------------------------------------------------------

local function PlaySound(inst, event)
    inst:PlaySound(event)
end

local function OnAnimOver(state)
    return {
        EventHandler("animover", function(inst) inst.sg:GoToState(state) end),
    }
end

------------------------------------------------------------------------------------------------------------------------------------

local states =
{
    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("death")
            

            inst.Physics:Stop()

            RemovePhysicsColliders(inst)
            
            inst:PlaySound("death_vocal")
            inst:PlaySound("death_fx")            
            SpawnPrefab("shadow_despawn").Transform:SetPosition(inst.Transform:GetWorldPosition())
            inst.components.lootdropper:DropLoot()
        end,
    },

    State{
        name = "premoving",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("walk_pre")
        end,

        timeline=
        {
            --SoundFrameEvent(3, "dontstarve/creatures/spider/walk_spider"),
        },

        events = OnAnimOver("moving"),
    },

    State{
        name = "moving",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
            inst.components.locomotor:RunForward()
            inst.AnimState:PushAnimation("walk_loop")
        end,

        timeline=
        {
            --SoundFrameEvent(0, "dontstarve/creatures/spider/walk_spider"),
            --SoundFrameEvent(3,  "dontstarve/creatures/spider/walk_spider"),
            --SoundFrameEvent(7,  "dontstarve/creatures/spider/walk_spider"),
            --SoundFrameEvent(12, "dontstarve/creatures/spider/walk_spider"),
        },

        events = OnAnimOver("moving"),
    },

    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst, start_anim)
            if math.random() < 0.3 then
                inst.sg:SetTimeout(math.random()*2 + 2)
            end

            inst.components.locomotor:Stop()

            if inst.wantstoshow then
                inst.sg:GoToState("appear")
            else
                if start_anim then
                    inst.AnimState:PlayAnimation(start_anim)
                    inst.AnimState:PushAnimation("idle", true)
                else
                    inst.AnimState:PlayAnimation("idle", true)
                end
            end    
            
        end,

        ontimeout = function(inst)
            
            inst.sg:GoToState("idle")
        end,
    },

    State{
        name = "taunt",
        tags = {"busy"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("taunt")
        end,
        timeline=
        {
            FrameEvent(14, function(inst)  inst:PlaySound("taunt_fx_f14") end),
        },
        events = OnAnimOver("idle"),
    },

    State{
        name = "attack",
        tags = {"attack", "busy"},

        onenter = function(inst, target)
            --inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("atk1")
            inst:PlaySound("atk_vocal")
            
            inst.components.combat:StartAttack()
            --ToggleOnPhysics(inst)
            inst.sg.statemem.target = target
        end,

        timeline=
        {
            --SoundFrameEvent(10, "dontstarve/creatures/spider/attack"),
            --SoundFrameEvent(10, "dontstarve/creatures/spider/attack_grunt"),
            FrameEvent(8,function (inst)
                inst.components.locomotor:Stop()
            end),
            FrameEvent(18, function(inst) 
                inst:PlaySound("f18_atk_fx")
                AOEAttack(inst,0,5,nil,1)
                --inst.components.combat:DoAttack(inst.sg.statemem.target) 
            end),
        },
        events = OnAnimOver("idle"),
    },

    State{
        name = "charge_attack",
        tags = {"attack", "canrotate", "busy", "jumping"},

        onenter = function(inst,target) 
            inst.components.locomotor:Stop()

            inst.AnimState:PushAnimation("walk_loop")
            inst.Physics:SetMotorVelOverride(16, 0, 0)
            
            if target and target:IsValid() then
                inst:ForceFacePoint(target.Transform:GetWorldPosition())
            end            
            inst.sg.statemem.targets = {}
            
            inst.sg:SetTimeout(0.3)

        end,
        onupdate = function(inst, dt)
            AOEAttack(inst, -0.4, 2, inst.sg.statemem.targets)
        end,
        ontimeout = function(inst)
            inst.sg:GoToState("idle")
        end,
        onexit = function(inst)
            --ToggleOffPhysics(inst)
            inst.components.locomotor:Stop()
            inst.Physics:ClearMotorVelOverride()
        end,    
    },

    State{
        name = "spin_attack",
        tags = {"attack", "busy", "spinning", "jumping"},

        onenter = function(inst, target)
            inst.components.locomotor:Stop()
            

            inst.AnimState:PlayAnimation("atk_pre")

            inst.components.timer:StartTimer("spin_cd",TUNING.ABYSS_KNIGHT_SPIN_CD)

            if target and target:IsValid() then
                inst:ForceFacePoint(target.Transform:GetWorldPosition())
            end
            inst.sg.mem.spincount = math.random(4,6)
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
        end,

        onexit = function(inst)
            inst.components.locomotor:Stop()
            inst.Physics:ClearMotorVelOverride()
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("spin_attack_loop")
        end,
    },

    State{
        name = "spin_attack_loop",
        tags = {"attack", "canrotate", "busy", "spinning", "jumping"},

        onenter = function(inst)
            
            inst.components.locomotor:Stop()
            
            inst.Physics:SetMotorVelOverride(7,0,0)    ---acutally 8*2.5 = 20
            
            inst.AnimState:PlayAnimation("atk_loop",true)
            inst.sg.statemem.loop_len = inst.AnimState:GetCurrentAnimationLength()
            local num_loops = 3
            inst.sg:SetTimeout(inst.sg.statemem.loop_len * num_loops)

            inst.SoundEmitter:PlaySound("meta4/crabcritter/atk2_spin_lp","spin")
            
            local target = inst.components.combat.target
            if target and target:IsValid() then
                inst:ForceFacePoint(target.Transform:GetWorldPosition())
            end
            
            inst.sg.statemem.targets = {}
        end,

        onupdate = function(inst, dt)
            AOEAttack(inst, -0.4, 2.5, inst.sg.statemem.targets)
        end,

        onexit = function(inst)
            inst.components.locomotor:Stop()
            inst.Physics:ClearMotorVelOverride()
            inst.SoundEmitter:KillSound("spin")
        end,

        ontimeout = function(inst)
            
            local target = inst.components.combat.target
            if inst.sg.mem.spincount>0 and target then
                inst.sg.mem.spincount = inst.sg.mem.spincount-1
                inst.sg:GoToState("spin_attack_loop")
            else
                inst.sg.mem.spincount = 0
                inst.sg:GoToState("spin_attack_pst")
            end    
        end,
    },

    State{
        name = "spin_attack_pst",
        tags = {"attack", "canrotate", "busy", "spinning"},

        onenter = function(inst, target)
            inst.AnimState:PlayAnimation("atk_pst")
        end,

        events = OnAnimOver("idle"),
    },

    State{
        name = "hit",

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("hit")
            inst:PlaySound("hit_vocal")
            inst:PlaySound("hit")            
        end,

        events = OnAnimOver("idle"),
    },

    State{
        name = "break",
        tags = { "busy", "nosleep", "nofreeze", "noattack" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("break")
            inst.Physics:Stop()
        end,

        events=
        {
            EventHandler("animover", function(inst)
                local is_ocean = TheWorld.Map:IsOceanAtPoint(inst.Transform:GetWorldPosition())

                inst.sg:GoToState(is_ocean and "break_water" or "break_land")
            end ),
        },
    },

    State{
        name = "dive",
        tags = {"busy", "nomorph", "noattack"},

        onenter = function(inst)

            inst:PlaySound("dive_vocal")
            inst:PlaySound("dive_fx")

            inst.sg.mem.ishiding = true

            inst.AnimState:PlayAnimation("dive")
            inst.components.locomotor:Stop()
            
            inst.components.timer:StartTimer("hide_cd",TUNING.ABYSS_KNIGHT_HIDE_CD)
        end,

        timeline =
        {
            TimeEvent(10*FRAMES, function(inst)
                inst:Hide()
                SpawnPrefab("shadow_despawn").Transform:SetPosition(inst.Transform:GetWorldPosition())
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "appear",
        tags = {"busy","attack"},

        onenter = function (inst)
            inst.components.locomotor:Stop()
            inst.components.combat:StartAttack()
            inst.sg:SetTimeout(2.2)
            
            inst.sg.mem.wantstoshow = false
            inst.components.combat:SetDefaultDamage(TUNING.ABYSS_KNIGHT_DAMAGE*2)
        end,

        timeline = {
            
            TimeEvent(0.5,function (inst)
                inst.sg.statemem.teleportpos = FindTeleportPos(inst)
            end),
            TimeEvent(1.5,function (inst)
                inst:Show()
                inst.sg.mem.ishiding = false
                inst.AnimState:PlayAnimation("dive_appear")
                inst.Physics:Teleport(inst.sg.statemem.teleportpos.x,0,inst.sg.statemem.teleportpos.z)
                AOEAttack(inst,0,6,nil,3)

            end),
        },
        ontimeout = function (inst)
            
            inst.components.combat:SetDefaultDamage(TUNING.ABYSS_KNIGHT_DAMAGE)
            inst.sg:GoToState("idle")
        end
    }
}



return StateGraph("abyss_knight", states, events, "idle")
