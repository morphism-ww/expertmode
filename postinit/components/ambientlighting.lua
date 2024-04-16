local function OnShadowVision(player, enabled)
    _nightvision = enabled
    _overridecolour.currentcolourset = enabled and NIGHTVISION_COLOURS or NORMAL_COLOURS
    ComputeTargetColour(_overridecolour, 0.25)
    PushCurrentColour()
end
AddComponentPostInit("ambientlighting", function(self)
    self.inst:ListenForEvent("shadowvision", OnShadowVision, player)
end)
