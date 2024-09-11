require("stategraphs/commonstates")


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
    CommonHandlers.OnLocomote(true,true),
    EventHandler("doattack", function(inst, data)
        if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy"))
                and (data.target ~= nil and data.target:IsValid()) then
            
            inst.sg:GoToState("attack", data.target)
        end
    end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
}


local states=
{

    --[[State{
        name = "moving",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
			inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("idle_loop", true)
        end,
    },]]
    State{
        name = "attack",
        tags = {"busy","attack"},
        onenter = function (inst,target)
            inst.components.combat:StartAttack()
            inst.sg.statemem.target = target
            inst.AnimState:PlayAnimation("suck_pre")
            inst.AnimState:PushAnimation("suck",false)
            --inst.components.locomotor:WalkForward()
            
        end,
        timeline =
        {
            TimeEvent(4*FRAMES, function(inst) 
                inst.components.combat:DoAttack(inst.sg.statemem.target,nil,nil,"darkness")
            end),
        },
        events = 
        {
            EventHandler("animqueueover",function (inst)
                --inst.Physics:ClearMotorVelOverride()
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("idle")
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

        onenter = function(inst)
            inst.Physics:Stop()
            
            inst.AnimState:PlayAnimation("idle_loop")
            
            inst.sg:SetTimeout( inst.AnimState:GetCurrentAnimationLength() )
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)
        },
    },

}
CommonStates.AddWalkStates(states,nil,
{
    startwalk = "idle_loop",
    walk = "idle_loop",
    stopwalk = "idle_loop"
})
CommonStates.AddRunStates(states,nil,
{
    startrun = "idle_loop",
    run = "idle_loop",
    stoprun = "idle_loop"
})

return StateGraph("dark_energy", states, events, "idle")
