require "behaviours/chaseandattack"
require "behaviours/wander"
require "behaviours/chaseandram"


local GOHOMEDSQ = 1600
local WANDER_DIST = 8
local MAX_CHASE_TIME = 5
local MAX_CHARGE_DIST = 25
local CHASE_GIVEUP_DIST = 20

local function GetHome(inst)
	return inst.components.knownlocations:GetLocation("spawnpoint")
end

  

local AbyssHopLiteBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)


function AbyssHopLiteBrain:OnStart()

    local root =  
        PriorityNode({
            ChaseAndRam(self.inst, MAX_CHASE_TIME, CHASE_GIVEUP_DIST, MAX_CHARGE_DIST),
            Wander(self.inst, GetHome, WANDER_DIST),

        },0.5)
    
    self.bt = BT(self.inst, root)
end

function AbyssHopLiteBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("spawnpoint", self.inst:GetPosition())
end

return AbyssHopLiteBrain