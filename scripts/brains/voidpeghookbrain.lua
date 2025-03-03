require "behaviours/chaseandattack"
require "behaviours/wander"
require "behaviours/chaseandram"



local WANDER_DIST = 8
local MAX_CHASE_TIME = 30

local function GetHome(inst)
    return  inst.components.homeseeker~=nil and inst.components.homeseeker:GetHomePos()
end


local VoidPegHookBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)


function VoidPegHookBrain:OnStart()

    local root =  
        PriorityNode({
            ChaseAndAttack(self.inst, MAX_CHASE_TIME),
            ParallelNode{
                Wander(self.inst, GetHome, WANDER_DIST),
                SequenceNode{
                    WaitNode(15),
                    ActionNode(function() self.inst:MakeFossilized() end),
                },
                }
        },0.5)
    
    self.bt = BT(self.inst, root)
end


return VoidPegHookBrain