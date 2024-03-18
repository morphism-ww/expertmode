local chargestate=State{
        name = "playercharge",
        tags = { "aoe", "doing", "busy", "nointerrupt" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("toolpunch")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, inst.sg.statemem.attackvol, true)

            inst.Physics:ClearCollisionMask()
            inst.Physics:CollidesWith(COLLISION.GROUND)
            inst.Physics:CollidesWith(COLLISION.LAND_OCEAN_LIMITS)
            inst.Physics:SetMotorVelOverride(18, 0, 0)
            inst.components.locomotor:EnableGroundSpeedMultiplier(false)
            inst:PerformBufferedAction()
            inst.sg:SetTimeout(0.5)
        end,
        onexit = function(inst)
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            inst.Physics:Stop()
            inst.Physics:ClearMotorVelOverride()
            inst.Physics:CollidesWith(COLLISION.WORLD)
            inst.Physics:CollidesWith(COLLISION.OBSTACLES)
            inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
            inst.Physics:CollidesWith(COLLISION.CHARACTERS)
            inst.Physics:CollidesWith(COLLISION.GIANTS)
            inst.components.locomotor:Stop()

        end,
       ontimeout = function(inst)
           inst.sg:GoToState("idle")
        end,
    }
local chargestate_client=State{
        name = "playercharge",
        tags = { "aoe", "doing", "busy", "nointerrupt" },
        server_states = { "playercharge" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("toolpunch")
            inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh", nil, inst.sg.statemem.attackvol, true)
            --inst.Physics:SetMotorVelOverride(16, 0, 0)
            inst:PerformPreviewBufferedAction()
            inst.sg:SetTimeout(0.5)
        end,
        onupdate = function(inst)
			if inst.sg:ServerStateMatches() then
                if inst.entity:FlattenMovementPrediction() then
                    inst.sg:GoToState("idle", "noanim")
                end
            elseif inst.bufferedaction == nil then
                inst.sg:GoToState("idle")
            end
        end,

       ontimeout = function(inst)
           inst:ClearBufferedAction()
           inst.sg:GoToState("idle")
        end,
    }
AddStategraphState("wilson",chargestate)
AddStategraphState("wilson_client",chargestate_client)



AddStategraphPostInit("wilson", function(sg)
    sg.actionhandlers[ACTIONS.CASTAOE].deststate=function(inst,action)
        return action.invobject ~= nil
                and (    (action.invobject:HasTag("aoeweapon_charge") and "playercharge") or
                        (action.invobject:HasTag("aoeweapon_lunge") and "combat_lunge_start") or
                        (action.invobject:HasTag("aoeweapon_leap") and (action.invobject:HasTag("superjump") and "combat_superjump_start" or "combat_leap_start")) or
                        (action.invobject:HasTag("blowdart") and "blowdart_special") or
                        (action.invobject:HasTag("throw_line") and "throw_line") or
						(action.invobject:HasTag("book") and (inst:HasTag("canrepeatcast") and "book_repeatcast" or "book")) or
                        (action.invobject:HasTag("parryweapon") and "parry_pre") or
                        (action.invobject:HasTag("willow_ember") and "castspellmind")
                    )
                or "castspell"
    end
end)



AddStategraphPostInit("wilson_client", function(sg)
    sg.actionhandlers[ACTIONS.CASTAOE].deststate=function(inst,action)
        return action.invobject ~= nil
                and (   (action.invobject:HasTag("aoeweapon_charge") and "playercharge") or
                        (action.invobject:HasTag("aoeweapon_lunge") and "combat_lunge_start") or
                        (action.invobject:HasTag("aoeweapon_leap") and (action.invobject:HasTag("superjump") and "combat_superjump_start" or "combat_leap_start")) or
                        (action.invobject:HasTag("blowdart") and "blowdart_special") or
                        (action.invobject:HasTag("throw_line") and "throw_line") or
						(action.invobject:HasTag("book") and (inst:HasTag("canrepeatcast") and "book_repeatcast" or "book")) or
                        (action.invobject:HasTag("parryweapon") and "parry_pre") or
                        (action.invobject:HasTag("willow_ember") and "castspellmind")
                    )
                or "castspell"
    end
end)