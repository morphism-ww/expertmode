require "behaviours/standandattack"


local Corrupt_HeartBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)


function Corrupt_HeartBrain:OnStart()
    local root = PriorityNode(
    {
        StandAndAttack(self.inst),
    }, .25)

    self.bt = BT(self.inst, root)
end

return Corrupt_HeartBrain
