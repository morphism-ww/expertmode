require "behaviours/chaseandattack"
require "behaviours/wander"
require "behaviours/chaseandcharge"
require "behaviours/avoidlight"


local WANDER_DIST = 18
local MAX_CHASE_TIME = 4
local MAX_CHARGE_DIST = 14
local CHASE_GIVEUP_DIST = 8

local function GetHome(inst)
	return inst.components.knownlocations:GetLocation("spawnpoint")
end

local function getdirectionFn(inst)
    local light = inst.LightWatcher:GetLightAngle()
    if light then
        return  180 + light
    end
end
  
local DarkEnergyBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)


function DarkEnergyBrain:OnStart()

    local root =  
        PriorityNode({
            ChaseAndCharge(self.inst, MAX_CHASE_TIME, CHASE_GIVEUP_DIST, MAX_CHARGE_DIST),
            --AvoidLight(self.inst),
            Wander(self.inst, GetHome, WANDER_DIST,nil,getdirectionFn),

        },0.5)
    
    self.bt = BT(self.inst, root)
end

function DarkEnergyBrain:OnInitializationComplete()
    if self.inst.components.knownlocations:GetLocation("spawnpoint")==nil then
        self.inst.components.knownlocations:RememberLocation("spawnpoint", self.inst:GetPosition())
    end
end

return DarkEnergyBrain