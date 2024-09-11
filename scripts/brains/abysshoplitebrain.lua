require "behaviours/chaseandattack"
require "behaviours/wander"




local WANDER_DIST = 8
local MAX_CHASE_TIME = 20
local CHASE_GIVEUP_DIST = 30

local function GetHome(inst)
	return inst.components.knownlocations:GetLocation("spawnpoint")
end

  

local AbyssHopLiteBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)


function AbyssHopLiteBrain:OnStart()

    local root =  
        PriorityNode({
            ChaseAndAttack(self.inst,MAX_CHASE_TIME, CHASE_GIVEUP_DIST),
            Wander(self.inst, GetHome, WANDER_DIST),

        },0.5)
    
    self.bt = BT(self.inst, root)
end

function AbyssHopLiteBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("spawnpoint", self.inst:GetPosition())
end

return AbyssHopLiteBrain