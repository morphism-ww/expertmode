require("stategraphs/commonstates")


local events=
{
    EventHandler("locomote", function(inst)
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
    end),
}


local states=
{


    State{
        name = "spawn",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("portal_pre")
        end,

        events = {
            EventHandler("animover",function (inst)
                inst.sg:GoToState("idle")
            end)
        }
    },
    State{
        name = "moving",
        tags = {"moving", "canrotate"},

        onenter = function(inst)
			inst.components.locomotor:WalkForward()
            inst.AnimState:PlayAnimation("portal_loop", true)
        end,
    },

    State{
        name = "disappear",
        tags = {"busy"},

        onenter = function(inst)
            inst.AnimState:PlayAnimation("portal_pst")
            
        end,

        events = {
            EventHandler("animover",function (inst)
                inst:Remove()
            end)
        }
    },

    State{
        name = "idle",
        tags = {"idle", "canrotate"},

        onenter = function(inst)
            inst.Physics:Stop()
            if not inst.AnimState:IsCurrentAnimation("portal_loop") then
                inst.AnimState:PlayAnimation("portal_loop", true)
            end
            inst.sg:SetTimeout( inst.AnimState:GetCurrentAnimationLength() )
        end,

        ontimeout = function(inst)
            if inst.sg.statemem.wantstomove then
                inst.sg:GoToState("moving")
            else
                inst.sg:GoToState("idle")
            end
        end,
    },

}


return StateGraph("darkvortex", states, events, "spawn")
