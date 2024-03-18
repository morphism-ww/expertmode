UPGRADETYPES.IRON_SOUL="IRON_SOUL"
UPGRADETYPES.INSIGHT_SOUL="INSIGHT_SOUL"
--MATERIALS.OBSIDIAN="obsidan"


--[[local function GetPointSpecialActions(inst, pos, useitem, right)
    if right and useitem == nil then
        return { ACTIONS.TOWNPORTAL }
    end
    return {}
end

local function OnSetOwner(inst)
    if inst.components.playeractionpicker ~= nil then
        inst.components.playeractionpicker.pointspecialactionsfn = GetPointSpecialActions
    end
end]]


AddPlayerPostInit(function (inst)
    inst:AddTag("IRON_SOUL_upgradeuser")
    inst:AddTag("INSIGHT_SOUL_upgradeuser")
    --inst:ListenForEvent("setowner", OnSetOwner)
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.SHADOWHIP,
    function(inst, action)
        return action.invobject == nil and "portal_jumpin_pre" or "quicktele"
    end)
)

AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.SHADOWHIP,
    function(inst, action)
        return action.invobject == nil and "portal_jumpin_pre" or "quicktele"
    end)
)

--[[AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.TOWNPORTAL,
    function(inst, action)
        return action.invobject == nil and "portal_jumpin_pre" or "quicktele"
    end)
)

AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.TOWNPORTAL,
    function(inst, action)
        return action.invobject == nil and "portal_jumpin_pre" or "quicktele"
    end)
)]]