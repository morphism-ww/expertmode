require("stategraphs/commonstates")

local events =
{
    CommonHandlers.OnLocomote(false, true),
}

local function return_to_idle(inst)
    inst.sg:GoToState("idle")
end

local function targetinrange(inst)
    local SCAN_DIST = 5
    if inst.components.entitytracker:GetEntity("scantarget") then
        local pos = inst.components.entitytracker:GetEntity("scantarget"):GetPosition()
        return inst:GetDistanceSqToPoint(pos) < SCAN_DIST * SCAN_DIST
    end
end

local states =
{
    State {
        name = "idle",
        tags = {"idle"},

        onenter = function(inst)
            inst.components.locomotor:Stop()

            if targetinrange(inst) then
                inst.AnimState:PlayAnimation("scan_loop", true)
            else
                inst.AnimState:PlayAnimation("idle", true)
            end
        end,

        events =
        {
            EventHandler("animover", return_to_idle),
        },
    },

    State {
        name = "turn_on",
        tags = {"busy"},

        onenter = function(inst)
            inst.components.locomotor:Stop()

            inst.AnimState:PlayAnimation("turn_on", false)
        end,

        timeline =
        {
            TimeEvent(0, function(inst)
                -- Since this is the scanner's deploy state, pushing on_landed on the first frame
                -- can cause bad behaviour if 0,0,0 is an ocean position.
                inst:PushEvent("on_landed")
            end),
            TimeEvent(9*FRAMES, function(inst)
                inst:PushEvent("on_no_longer_landed")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst:PushEvent("turn_on_finished")

                inst.sg:GoToState("idle")
            end),
        },
    },
    State {
        name = "turn_off",
        tags = {"busy", "scanned"},

        onenter = function(inst)


            inst.components.locomotor:Stop()

            inst.AnimState:PlayAnimation("turn_off_pre")
            inst.SoundEmitter:PlaySound("WX_rework/scanner/deactivate")

            -- Stuff that might be on due to scanning
            inst:StopScanFX()
            inst.AnimState:Hide("bottom_light")
        end,

        timeline =
        {
            TimeEvent(14*FRAMES, function(inst)
                inst:PushEvent("on_landed")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("turn_off_idle")
            end),
        },
    },
    State {
        name = "turn_off_idle",
        tags = {"busy","scanned"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("turn_off_idle", true)

            inst:stoploopingsound()
        end,

        timeline =
        {
            TimeEvent(0, function(inst)
                inst:PushEvent("on_landed") -- For float FX.
            end),
        },

        onexit = function(inst)
            if inst.sg.statemem.flashtask ~= nil then
                inst.sg.statemem.flashtask:Cancel()
                inst.sg.statemem.flashtask = nil
            end
            inst.sg.statemem.flashon = nil
            inst:startloopingsound()

            inst:PushEvent("on_no_longer_landed")
        end,
    },

    State {
        name = "scan_success",
        tags = {"busy","scanned"},

        onenter = function(inst)
            inst.components.locomotor:Stop()
        
            inst.AnimState:PlayAnimation("success")
        end,

        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                 inst.SoundEmitter:PlaySound("WX_rework/scanner/print")
            end),
            TimeEvent(21 * FRAMES, function(inst)
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("turn_off")
            end),
        },
    },  
}

--states, timelines, anims, softstop, delaystart, fns
CommonStates.AddWalkStates(
    states,
    nil,
    {
        startwalk = function(inst)
            if targetinrange(inst) then
                return "scan_loop"
            else
                return "walk_pre"
            end
        end,
        walk = function(inst)
            if targetinrange(inst) then
                return "scan_loop"
            else
                return "walk_loop"
            end
        end,
        stopwalk = function(inst)
            if targetinrange(inst) then
                return "scan_loop"
            else
                return "walk_pst"
            end
        end,
    }
)

return StateGraph("ancient_scanner", states, events, "turn_on")
