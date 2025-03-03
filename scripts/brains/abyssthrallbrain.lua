require "behaviours/chaseandattack"
require "behaviours/wander"
require "behaviours/doaction"



local MAX_WANDER_DIST = 24
local CHASE_DIST = 32
local CHASE_TIME = 60


local function GetWanderPoint(inst)
    return inst.components.knownlocations:GetLocation("spawnpoint")
end

local function CountShadow(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    return TheSim:CountEntities(x,y,z,20,{"nightmarecreature"})<8
end

local function CanSummon(inst)
    return inst.components.combat.target.isplayer
            and not inst.components.timer:TimerExists("summon_cd")
            and CountShadow(inst)
end



local AbyssThrallBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function AbyssThrallBrain:ShouldUseSpecialMove()
    self._special_move = self.inst.components.combat:HasTarget() and (
        (CanSummon(self.inst) and "summon") or 
        (not self.inst.components.timer:TimerExists("meteor_cd") and "meteor") or
        (not self.inst.hasshield and not self.inst.components.timer:TimerExists("shield_cd") and "shield")
    )or nil
    return self._special_move~=nil
end

local BASEDESTROY_CANT_TAGS = {"wall","shadow"}

local function BaseDestroy(inst)
    
    local target = FindEntity(inst, 30, function(item)
            if item.components.workable and item:HasTag("structure")
                    and item.components.workable.tough
                    and item.components.workable.action == ACTIONS.HAMMER
                    and item:IsOnValidGround() then
                return true
            end
        end, nil, BASEDESTROY_CANT_TAGS)
    if target then
        local action = BufferedAction(inst, target, ACTIONS.HAMMER)
        action.distance = 12
        return action
    end
    
end

function AbyssThrallBrain:OnStart()

    local root =
        PriorityNode(
        {
            WhileNode(function() return self:ShouldUseSpecialMove() end, "Special Moves",
                ActionNode(function() self.inst:PushEvent(self._special_move) end)
                ),    

            ChaseAndAttack(self.inst, CHASE_TIME, CHASE_DIST),
            DoAction(self.inst, BaseDestroy, "DestroyBase"),
            Wander(self.inst, GetWanderPoint, MAX_WANDER_DIST)
        },0.5)
    
    self.bt = BT(self.inst, root)
end

function AbyssThrallBrain:OnInitializationComplete()
    if self.inst.components.knownlocations:GetLocation("spawnpoint")==nil then
        self.inst.components.knownlocations:RememberLocation("spawnpoint", self.inst:GetPosition())
    end
    
end

return AbyssThrallBrain