require("stategraphs/commonstates")

local AREAATTACK_EXCLUDETAGS = { "INLIMBO", "notarget", "invisible", "noattack", "flight", "playerghost", "shadow", "shadowchesspiece", "shadowcreature" }

local events=
{
    --[[EventHandler("locomote", function(inst)
        if not inst.sg:HasStateTag("busy") then
			local is_moving = inst.sg:HasStateTag("moving")
			local wants_to_move = inst.components.locomotor:WantsToMoveForward()
			if is_moving ~= wants_to_move then
				if wants_to_move then
					inst.sg.statemem.wantstomove = true
				else
					inst.sg:GoToState("idle")
				end
			end
        end
    end),]]
    --CommonHandlers.OnLocomote(true,true),
    EventHandler("locomote", function(inst)
        local is_attacking = inst.sg:HasStateTag("attack") 
        local is_busy = inst.sg:HasStateTag("busy")
        local is_idling = inst.sg:HasStateTag("idle")
        local is_moving = inst.sg:HasStateTag("moving")
        local is_running = inst.sg:HasStateTag("running")

        if is_attacking or is_busy then return end

        local should_move = inst.components.locomotor:WantsToMoveForward()
        local should_run = inst.components.locomotor:WantsToRun()

        if is_moving and not should_move then
            if is_running then
                inst.sg:GoToState("run_stop")
            else
                inst.sg:GoToState("walk_stop")
            end
        elseif (not is_moving and should_move) or (is_moving and should_move and is_running ~= should_run) then
            if should_run then
                inst.sg:GoToState("run_start")
            else
                inst.sg:GoToState("walk_start")
            end
        end
    end),
    EventHandler("doattack", function(inst, data)
        if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy")) then
            inst.sg:GoToState("attack", data.target)
        end
    end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
}


local states=
{


    State{
        name = "attack",
        tags = {"busy","attack"},
        onenter = function (inst,target)
            --inst.components.locomotor:RunForward()
           
            inst.components.combat:StartAttack()
            inst.sg.statemem.target = target
            inst.AnimState:PlayAnimation("suck_pre")
            inst.AnimState:PushAnimation("suck",false)
            --inst.components.locomotor:WalkForward()
        end,
        timeline =
        {
            TimeEvent(4*FRAMES, function(inst) 
                inst.components.combat:DoAttack(inst.sg.statemem.target,nil,nil, "darkness")
            end),
        },
        events = 
        {
            EventHandler("animqueueover",function (inst)
                
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle",true)
                end
            end)
        }
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("despawn")
            inst.Physics:Stop()
            inst.components.lootdropper:DropLoot(inst:GetPosition())

            RemovePhysicsColliders(inst)
            inst:AddTag("NOCLICK")
            inst.persists = false
        end,

        timeline =
        {
            TimeEvent(15*FRAMES, function(inst)
                if not inst.newborn then
                    local x, y, z = inst.Transform:GetWorldPosition()
                    local numchunks = math.random(5,6)
                    
                    local theta = math.random() * TWOPI
                    local delta = TWOPI / numchunks
                    for i = 1, numchunks do
                        local dist = 4 + math.random() * 6
                        local angle = theta + delta * (i + math.random() * 0.75)
                        local chunk = SpawnPrefab("dark_energy_small")
                        chunk.Transform:SetPosition(x, 0, z)
                        chunk:Toss(dist, angle)
                    end

                    inst.components.lootdropper:SpawnLootPrefab("shadow_soul")
                end
            end),
        },

        events =
        {
            EventHandler("animover", function(inst) inst:Remove() end)
        },
    },

    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst,nostop)
            if not nostop then
                inst.Physics:Stop()
            end
            
            
            inst.AnimState:PlayAnimation("idle_loop")
            
            inst.sg:SetTimeout( inst.AnimState:GetCurrentAnimationLength() )
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)
        },
    },
    State{  name = "run_start",
            tags = {"moving", "running", "busy", "atk_pre", "canrotate"},

            onenter = function(inst)
                inst.components.locomotor:RunForward()
                --inst.Physics:Stop()
                inst.AnimState:PlayAnimation("idle_loop")
                
            end,
            events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("run")
                end
            end),
        },
        },

    State{  name = "run",
            tags = {"moving", "running"},

            onenter = function(inst)
                inst.components.locomotor:RunForward()

                inst.AnimState:PlayAnimation("idle_loop",true)
                local num_anim = 1 + math.random()
                inst.sg:SetTimeout(num_anim * inst.AnimState:GetCurrentAnimationLength())
				
            end,

            ontimeout = function(inst)
				inst.sg.statemem.running = true
                inst.sg:GoToState("run")
            end,

        },

    State{  name = "run_stop",
            tags = {"canrotate", "idle"},

            onenter = function(inst)
                
                inst.components.locomotor:StopMoving()
                inst.AnimState:PlayAnimation("idle_loop")

            end,

            events=
            {
                EventHandler("animover", function(inst) inst.sg:GoToState("walk_start") end ),
            },
        },

}
CommonStates.AddWalkStates(states,nil,
{
    startwalk = "idle_loop",
    walk = "idle_loop",
    stopwalk = "idle_loop"
})
--[[CommonStates.AddRunStates(states,nil,
{
    startrun = "idle_loop",
    run = "idle_loop",
    stoprun = "idle_loop"
})]]

return StateGraph("dark_energy", states, events, "idle")
