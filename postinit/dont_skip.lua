--------------------------------------------------------
--rocky
--------------------------------------------------------
AddStategraphPostInit("rocky",function(sg)
    sg.states.shield.onenter=function (inst)
        inst.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 0.6, "shield")
        inst.AnimState:PlayAnimation("hide_loop")
        inst.components.health:StartRegen(TUNING.ROCKY_REGEN_AMOUNT, TUNING.ROCKY_REGEN_PERIOD)
        inst.sg:SetTimeout(3)
    end
    sg.states.shield.onexit = function(inst)
        inst.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 0, "shield")
        inst.components.health:StopRegen()
    end
end)    