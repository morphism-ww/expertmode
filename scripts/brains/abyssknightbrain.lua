require "behaviours/chaseandattack"
require "behaviours/wander"
require "behaviours/doaction"


------------------------------------------------------------------------------------------------------------------------------------

local MAX_WANDER_DIST = 12


local function GetWanderPoint(inst)
    return inst.components.knownlocations:GetLocation("home")
end

local function ShouldHide(inst)
    return inst.components.health.currenthealth<1000 and not inst.components.timer:TimerExists("hide_cd")
end


------------------------------------------------------------------------------------------------------------------------------------

local AbyssKnightBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)


function AbyssKnightBrain:ShouldUseSpecialMove()
    self._special_move = self.inst.components.combat:HasTarget() and (
        (ShouldHide(self.inst) and "hide") or 
        (not self.inst.sg.mem.ishiding and not self.inst.components.timer:TimerExists("spin_cd") and "spin")
    )or nil
    return self._special_move~=nil
end


function AbyssKnightBrain:OnStart()
    local root =
        PriorityNode(
        {   
            WhileNode(function() return not self.inst.sg:HasStateTag("spinning") end, "Not Spining",
            PriorityNode({
                WhileNode(function() return self:ShouldUseSpecialMove() end, "Special Moves",
                    ActionNode(function() self.inst:PushEvent(self._special_move) end)
                    ),
                WhileNode(function() return ShouldHide(self.inst) end, "Hide",
                    ActionNode(function() self.inst:PushEvent("hide") end)),
                ChaseAndAttack(self.inst,20,40),
                Wander(self.inst, GetWanderPoint, MAX_WANDER_DIST)
            },0.5)    
            )    
        }, 1)

    self.bt = BT(self.inst, root)
end

function AbyssKnightBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("home", self.inst:GetPosition())
end

return AbyssKnightBrain