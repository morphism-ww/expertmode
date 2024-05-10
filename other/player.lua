AddPlayerPostInit(function (inst)
    inst:AddTag("IRON_SOUL_upgradeuser")
    inst:AddTag("INSIGHT_SOUL_upgradeuser")
    --inst:ListenForEvent("setowner", OnSetOwner)
end)

--[[AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.SHADOWHIP,
    function(inst, action)
        return action.invobject == nil and "portal_jumpin_pre" or "quicktele"
    end)
)

AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.SHADOWHIP,
    function(inst, action)
        return action.invobject == nil and "portal_jumpin_pre" or "quicktele"
    end)
)]]
