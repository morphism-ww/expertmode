require "behaviours/chaseandattack"
require "behaviours/doaction"
require "behaviours/leash"
require "behaviours/wander"

local function GetWanderHome(inst)
    return inst.components.knownlocations:GetLocation("spawnpoint")
end

local BASEDESTROY_CANT_TAGS = {"wall"}

local function TempDestroy(inst)
    local target = FindEntity(inst, 30, function(item)
            if item.components.workable and item:HasTag("tent") then
                return true
            end
        end, nil, BASEDESTROY_CANT_TAGS)
    if target then
        inst:EquipLeap()
        inst.sg.mem.leapcount=3
        return BufferedAction(inst, target, ACTIONS.CASTAOE)
    end
end



local function ShouldUseAbility(self)

    if self.inst.components.combat.target==nil then
        return false
    end
    local target=self.inst.components.combat.target
    local dsq_to_target = self.inst:GetDistanceSqToInst(target)
    self.abilityname = (dsq_to_target<144 and 
        not self.inst.components.timer:TimerExists("killer_cd") and "killer_laser") or
        (dsq_to_target<625 and not self.inst.components.timer:TimerExists("leapattack_cd") and "leap_pre")
     or nil
    return self.abilityname ~= nil
end
  

local MFZBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function MFZBrain:OnStart()


    local root =
        PriorityNode(
        { 
            WhileNode(function() return self.inst.is_boss and  not self.inst.sg:HasStateTag("leap") end, "Should Attack",
                PriorityNode({
                    WhileNode(function() return ShouldUseAbility(self) end, "Ability",
                    ActionNode(function()
                        self.inst:PushEvent(self.abilityname)
                        self.abilityname=nil
                    end)),
                    ChaseAndAttack(self.inst),
                    DoAction(self.inst, TempDestroy, "DestroyTemp", true),
                    Wander(self.inst, GetWanderHome, 15),
                }, .5)
            ),
        },0.5)
    
    self.bt = BT(self.inst, root)


end

function MFZBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("spawnpoint", self.inst:GetPosition())
end

return MFZBrain