local UpvalueTracker = require("util/upvaluetracker")
newcs_env.AddComponentPostInit("dynamicmusic", function(self,inst)


    local source = "scripts/components/dynamicmusic.lua"
    local _OnPlayerActivated
    for i, func in ipairs(inst.event_listeners["playeractivated"][inst]) do
        -- We can find the correct func by the function's source since the
        -- event listeners likely won't have two different events of the same source
        if debug.getinfo(func, "S").source == source then
            _OnPlayerActivated = inst.event_listeners["playeractivated"][inst][i]
            break
        end
    end

    if _OnPlayerActivated == nil then
        print("WARNING: Unable to find _OnPLayerActivated.")
        return
    end


    local TRIGGERED_DANGER_MUSIC = UpvalueTracker.GetUpvalue(_OnPlayerActivated, "StartPlayerListeners","StartTriggeredDanger","TRIGGERED_DANGER_MUSIC")
    TRIGGERED_DANGER_MUSIC["calamitas_clone"] = {
        "calamita_sound/Calamity/RawCalamity"
    }
end)