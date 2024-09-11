require "behaviours/chaseandattack"
require "behaviours/doaction"
require "behaviours/leash"
require "behaviours/wander"
require "behaviours/runaway"

local RUN_START_DIST = 12
local RUN_STOP_DIST = 15

local function GetWanderHome(inst)
    return inst.components.knownlocations:GetLocation("spawnpoint")
end

local function GetTarget(inst)
	return inst.components.combat.target
end

local function IsTarget(inst, target)
	return inst.components.combat:TargetIs(target)
end



local function ShouldUseAbility(self)

    if self.inst.components.combat.target==nil then
        return false
    end
    local target = self.inst.components.combat.target
    local dsq_to_target = self.inst:GetDistanceSqToInst(target)
    self.abilityname = dsq_to_target<200 and 
        (dsq_to_target<625 and not self.inst.components.timer:TimerExists("leapattack_cd") and "leap_pre")
     or nil
    return self.abilityname ~= nil
end
  

local IronThrallBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function IronThrallBrain:OnStart()


    local root =
        PriorityNode(
        { 
            WhileNode(function() return  not self.inst.sg:HasStateTag("busy") end, "Should Attack",
                PriorityNode({
                    WhileNode(function() return ShouldUseAbility(self) end, "Ability",
                    ActionNode(function()
                        self.inst:PushEvent(self.abilityname)
                        self.abilityname=nil
                    end)),
                    ChaseAndAttack(self.inst),
                    Wander(self.inst, GetWanderHome, 15),
                }, .5)
            ),
        },0.5)
    
    self.bt = BT(self.inst, root)


end

function IronThrallBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("spawnpoint", self.inst:GetPosition())
end

return IronThrallBrain