require "behaviours/doaction"
require "behaviours/faceentity"
require "behaviours/leash"
require "behaviours/wander"

-----------------------------------------------------------------------------------------

local AncientScannerBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

-----------------------------------------------------------------------------------------

local function GetLeaderPosition(inst)
    return inst.components.homeseeker:GetHomePos()
        or inst:GetPosition()
end


-----------------------------------------------------------------------------------------
local function ReturnToBaseAfterFinishedScan(inst)
    if not inst._donescanning then
        return nil
    end

    local home = inst.components.homeseeker:GetHome()
    if home==nil then
        inst:OnReturnedAfterSuccessfulScan()
        return
    end

    local flyto_position = home:GetPosition()
    local angle_to_leader = inst:GetAngleToPoint(flyto_position:Get())
    local offset = FindWalkableOffset(flyto_position, angle_to_leader, 4.0)


    if offset then
        flyto_position = flyto_position + offset
    end

    local act = BufferedAction(inst, nil, ACTIONS.WALKTO, nil, flyto_position)
    if act then
        local on_finished = function()
            inst:OnReturnedAfterSuccessfulScan()
        end
        act:AddSuccessAction(on_finished)
        act:AddFailAction(on_finished)
    end
    return act
end
----------------------------------------------------------------
local TARGET_FOLLOW, MAX_TARGET_FOLLOW = 0.5, 4.0

-- If the scantarget's physics radius pushes our dist above this, clamp to this.
-- Clip a hair below the actual scan distance to avoid stop/start wonkiness.
local HIGHEST_ADJUSTED_MAXFOLLOWDIST = 6 - 0.05

local function GetScanTarget(inst)
    return (not inst.sg:HasStateTag("scanned") and inst.components.entitytracker:GetEntity("scantarget"))
        or nil
end

local function GetTargetScanFollowDistance(inst)
    local target = GetScanTarget(inst)
    return (target ~= nil and (target:GetPhysicsRadius(0) + TARGET_FOLLOW))
        or TARGET_FOLLOW
end

local function GetMaxScanFollowDistance(inst)
    local target = GetScanTarget(inst)
    return (target ~= nil and math.min(HIGHEST_ADJUSTED_MAXFOLLOWDIST, target:GetPhysicsRadius(0) + MAX_TARGET_FOLLOW))
        or MAX_TARGET_FOLLOW
end

local function GetScanTargetLocation(inst)
    local target = GetScanTarget(inst)
    return (target ~= nil and target:GetPosition()) or inst:GetPosition()
end

local function KeepFacingScanTarget(inst, target)
    -- If the target is no longer valid, it should have been dropped out of our entitytracker.
    return GetScanTarget(inst) ~= nil
end

-----------------------------------------------------------------------------------------

function AncientScannerBrain:OnStart()
    local root = PriorityNode({
        WhileNode(function() return not self.inst.sg:HasStateTag("scanned") end, "While Not Finished",
            PriorityNode({
                DoAction(self.inst, ReturnToBaseAfterFinishedScan),
                WhileNode(function() return GetScanTarget(self.inst) == nil end, "No Scan Target",
                    LoopNode{
                        DoAction(self.inst, self.inst.TryFindTarget, "Try To Scan Something", false, 3),
                        ConditionWaitNode(function() return self.inst:GetBufferedAction() == nil end),
                    }
                ),
                WhileNode(function() return GetScanTarget(self.inst) ~= nil end, "Has Scan Target",
                    PriorityNode({
                        Leash(self.inst, GetScanTargetLocation, GetMaxScanFollowDistance, GetTargetScanFollowDistance),
                        FaceEntity(self.inst, GetScanTarget, KeepFacingScanTarget),
                    }, 1)
                ),
                Wander(self.inst, GetLeaderPosition, 16),
                --StandStill(self.inst),
            }, 1)
        )
    }, 1)

    self.bt = BT(self.inst, root)
end

return AncientScannerBrain