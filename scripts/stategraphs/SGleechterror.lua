local events=
{
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    EventHandler("newcombattarget", function(inst,data)
            if inst.sg:HasStateTag("idle") and data.target then
                inst.sg:GoToState("attack")
            end
        end)
}

local function DoAttack(inst)
	local target = inst.components.combat.target
	inst.components.combat:DoAttack()
	if inst.owner ~= nil and
		target ~= nil and
		target.components.combat ~= nil and
		target.components.combat:TargetIs(inst) and
		target.components.combat:CanTarget(inst.owner)
	then
		--forward aggro back to our owner
		target.components.combat:SetTarget(inst.owner)
	end
end

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
        tags = {"attack"},
        onenter = function(inst)
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk", false)
        end,
        timeline =
        {
            TimeEvent(7*FRAMES,DoAttack),
            TimeEvent(17*FRAMES,DoAttack),
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

