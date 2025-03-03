require("stategraphs/commonstates")

--local AREAATTACK_EXCLUDETAGS = { "INLIMBO", "notarget", "invisible", "noattack", "flight", "playerghost", "shadow", "shadowthrall", "shadowcreature" }




local events=
{
    CommonHandlers.OnLocomote(false, true),
    CommonHandlers.OnDeath(),
    
    EventHandler("hostileprojectile",function (inst,data)
        if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy")) then
            local attacker = data.attacker or data.thrower
            if attacker and attacker:IsValid() then
                inst:ForceFacePoint(attacker.Transform:GetWorldPosition())
                if not inst:HasTag("parrying") and not inst:IsNear(attacker,3) then
                    inst.sg:GoToState("parry_pre")
                end
            end
        end
        
    end),

    EventHandler("attacked", function(inst,data)
        if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy")) 
             and data.redirected==nil then
            if data.weapon and data.weapon:HasTag("projectile") and not inst:HasTag("parrying") then
                inst.sg:GoToState("parry_pre")
            elseif not CommonHandlers.HitRecoveryDelay(inst,4) then
                inst.sg:GoToState("hit")  
            end    
        end
    end),

    EventHandler("doattack", function(inst, data)
        if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy"))
                and (data.target ~= nil and data.target:IsValid()) then
            --[[if inst:HasTag("parrying") then
                inst.sg:GoToState("parry_pst","attack")
            else
                inst.sg:GoToState("attack",data.target)  
            end    ]]
            inst.sg:GoToState("attack",data.target)  
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
            inst.AnimState:PlayAnimation("idle_sanity_pre")
            inst.AnimState:PushAnimation("idle_sanity_loop")
        end,

    },
      

    State{
        name = "taunt",
        tags = {"busy","canrotate"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("pyrocast_pre") --4 frames
			inst.AnimState:PushAnimation("pyrocast", false)
        end,

        events =
        {
            EventHandler("animqueueover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },

    State{
        name = "hit",
        tags = {"hit","busy"},
        onenter = function (inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("hit")
            
            --inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())

            inst:ExitParry()

            CommonHandlers.UpdateHitRecoveryDelay(inst)

        end,
        events = OnAnimOver("idle")
    },

    State{
        name = "parry_pre",
        tags = {"preparrying", "busy"},
        onenter = function (inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("parry_pre")
            inst.AnimState:PushAnimation("parry_loop", true)
            inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
            --[[if data ~= nil then
                if data.direction ~= nil then
                    inst.Transform:SetRotation(data.direction)
                end
            end]]
        end,
        timeline =
        {
            TimeEvent(3 * FRAMES, function(inst)
                
                inst:EnterParry()
            end),
        },
        
        ontimeout = function(inst)
            --[[if inst.sg:HasStateTag("parrying") then
                inst.sg.statemem.parrying = true
                --Transfer talk task to parry_idle state
                inst.sg:GoToState("parry_idle", { duration = inst.sg.statemem.parrytime, pauseframes = 30})
            else
                inst.AnimState:PlayAnimation("parry_pst")
                inst.sg:GoToState("idle", true)
            end]]
            inst.sg:GoToState("idle")
        end,
    },

    State{
        name = "parry_idle",
        tags = { "parrying","busy"},

        onenter = function(inst, data)
            inst.components.locomotor:Stop()
            if not inst.AnimState:IsCurrentAnimation("parry_loop") then
                inst.AnimState:PlayAnimation("parry_loop", true)
            end
            inst.sg.statemem.parrying = true
        end,
        --[[onupdate = function (inst)
            local target = inst.components.combat.target
            if target~=nil and target:IsValid() then
                local pos = target:GetPosition()
                local rot = inst.Transform:GetRotation()
				local rot1 = inst:GetAngleToPoint(pos)
                local drot = ReduceAngle(rot1 - rot)
				rot1 = rot + math.clamp(drot, -1, 1)
				inst.Transform:SetRotation(rot1)
            end
        end,]]

        onexit = function(inst)           
            inst.components.combat.redirectdamagefn = nil
        end,
    },

    State{
        name = "parry_pst",
        tags = {"idle"},
        onenter = function(inst,nextstate)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("parry_pst")

            inst:ExitParry()
            
            if nextstate then
                inst.sg.statemem.nextstate = nextstate
                inst.sg:AddStateTag("busy")
            end
        end,
        
        events = {
            EventHandler("animover", function(inst) 
                inst.sg:GoToState(inst.sg.statemem.nextstate or "idle")     
            end),
        }
    },

    State{
        name = "attack",
        tags = {"attack", "busy"},

        onenter = function(inst)
            
            inst.components.locomotor:Stop()

            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk", false)
            inst:ExitParry()
            inst.sg:SetTimeout(13*FRAMES)
        end,

        timeline=
        {
            TimeEvent(5*FRAMES, function(inst)
                --inst.components.combat:DoAreaAttack(inst, 4.5, nil, nil, nil, AREAATTACK_EXCLUDETAGS)
                inst.components.combat:DoAttack(inst.sg.statemem.target)
            end)
        },
        ontimeout = function (inst)
            inst.sg:GoToState("idle")
        end
    },

    State{
        name = "death",
        tags = {"busy", "dead"},
        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("death")
            inst.AnimState:Hide("swap_arm_carry")
            inst.SoundEmitter:PlaySound("dontstarve/sanity/creature1/die")
            
            inst.components.lootdropper:DropLoot(inst:GetPosition())

            if math.random()<0.3 then
                local sword = SpawnPrefab("cs_dreadsword")
                sword.components.finiteuses:SetPercent(0.1+0.2*math.random())
                if math.random()<0.7 then
                    sword:AddComponent("itemmimic")
                end
                inst.components.lootdropper:FlingItem(sword)
            end

            inst:AddTag("NOCLICK")
            inst.persists = false
            
        end,
        
        timeline=
        {
            FrameEvent(10, function(inst)
			    SpawnPrefab("shadow_despawn").Transform:SetPosition(inst.Transform:GetWorldPosition())
            end)
        },
    },
}

local function CountWalkAnim(inst)
    return inst:HasTag("parrying") and "parry_loop" or "idle_walk"
end

CommonStates.AddWalkStates(states,
{
    walktimeline =
    {
        TimeEvent(0, PlayFootstep),
        TimeEvent(12 * FRAMES, PlayFootstep),
    },
},{
    startwalk = CountWalkAnim,
    walk = CountWalkAnim,
    stopwalk = "idle_walk_pst"
})


    
return StateGraph("abyss_hoplite", states, events, "idle")