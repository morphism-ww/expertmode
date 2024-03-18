require "behaviours/wander"
require "behaviours/leash"

local FireTornadoBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local wanderTimes =
{
    minwalktime = 40,
    randwalktime = 3,
    minwaittime = 1.5,
    randwaittime = 0.5,
}

function FireTornadoBrain:OnStart()
    local root =
    PriorityNode(
    {
        Leash(self.inst, function() return self.inst.components.knownlocations:GetLocation("target") end, 12, 10, true),
        Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("target") end, 16, wanderTimes),
    }, .25)
    self.bt = BT(self.inst, root)
end

return FireTornadoBrain