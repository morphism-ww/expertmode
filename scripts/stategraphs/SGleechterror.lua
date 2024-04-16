local events=
{
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    EventHandler("doattack", function(inst)

        if not inst.sg:HasStateTag("busy") then
            inst.sg:GoToState("attack")
        end
    end),
}


local states=
{
    State{
        name = "idle",
        tags = {"idle", "invisible"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("idle_loop")
        end,
        events=
        {
            EventHandler("animover", function(inst)
                if inst.components.combat.target and inst.components.combat:TryAttack() then
                    inst.sg:GoToState("attack")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },


    State{
        name ="attack",
        tags = {"busy"},
        onenter = function(inst)
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk", false)
            inst.sg.statemem.target=inst.components.combat.target
        end,
        timeline =
        {
            TimeEvent(10*FRAMES,function (inst)
                inst.components.combat:DoAttack(inst.sg.statemem.target)
            end),
            TimeEvent(17*FRAMES,function (inst)
                inst.components.combat:DoAttack(inst.sg.statemem.target)
            end),
        },
        events =
        {
            EventHandler("animqueueover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },


    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("disappear")
            inst:AddTag("NOCLICK")
            inst.persists = false
        end,
    },

}


return StateGraph("leechterror", states, events, "idle")

