require "behaviours/wander"
require "behaviours/faceentity"
require "behaviours/chaseandattack"
require "behaviours/follow"

local KEEP_FACE_DIST = 20

local MAX_CHASE_TIME = 20

local MAX_BEAM_ATTACK_RANGE = 10


local function GetFaceTargetFn(inst)
    return inst.components.combat.target
end

local function KeepFaceTargetFn(inst, target)
    return inst:GetDistanceSqToInst(target) <= KEEP_FACE_DIST*KEEP_FACE_DIST 
end


--[[local function shouldbeamattack(inst)
    local target = inst.components.combat.target
    if target and not inst.components.timer:TimerExists("laserbeam_cd") then
        local distsq = inst:GetDistanceSqToInst(target)    
        if distsq < MAX_BEAM_ATTACK_RANGE * MAX_BEAM_ATTACK_RANGE then
            return true
        end
    end
    return false
end]]

local function GetWanderPos(inst)
	return inst.components.knownlocations:GetLocation("home") 
end

local AncientRobotBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)


function AncientRobotBrain:OnStart()
    local root = PriorityNode(
    {
        WhileNode(function() return not self.inst:HasTag("dormant") end, "activate",
            PriorityNode(
            {                                                   
                ChaseAndAttack(self.inst, MAX_CHASE_TIME),
                FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
                Wander(self.inst,GetWanderPos,30)
            }, .5)
        )

    }, .25)
    
    self.bt = BT(self.inst, root)
    
end

return AncientRobotBrain