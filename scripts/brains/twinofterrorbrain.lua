require "behaviours/faceentity"
require "behaviours/leash"
require "behaviours/chaseandattack"
require "behaviours/follow"
require "behaviours/runaway"
local EyeOfTerrorBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
    --self._special_move = nil
end)

local AVOID_PLAYER_DIST = 4
local AVOID_PLAYER_STOP = 6

local MIN_FOLLOW_LEADER = 2
local MAX_FOLLOW_LEADER = 30
local TARGET_FOLLOW_LEADER = 10


local function GetFaceTargetFn(inst)
    return inst.components.combat.target
end

local function KeepFaceTargetFn(inst, target)
    return inst.components.combat:TargetIs(target)
end

local function GetSpawnPoint(inst)
    return inst.components.knownlocations:GetLocation("spawnpoint")
end

local function TrySpecialAttack(inst)
    if not inst.components.timer:TimerExists("charge_cd") then
        local target = inst.components.combat.target
        if target ~= nil then
            local dsq_to_target = inst:GetDistanceSqToInst(target)
            if dsq_to_target < 256 then
                return "charge"
            end
        end
    end
    return false
end

local function GetLeader(inst)
    return inst.components.follower ~= nil and inst.components.follower.leader or nil
end

function EyeOfTerrorBrain:ShouldUseSpecialMove()
    self._special_move =
         TrySpecialAttack(self.inst)
        or nil
    if self._special_move then
        return true
    else
        return false
    end
end

function EyeOfTerrorBrain:GetLeashPosition()
    if self._leash_pos == nil then
        local my_pos = self.inst:GetPosition()
        local target = self.inst.components.combat.target
        if target then
            local target_pos = target:GetPosition()
            local normal, _ = (my_pos - target_pos):GetNormalizedAndLength()
            local leash_pos = target_pos + (normal * 7)

            self._leash_pos = leash_pos
        else
            self._leash_pos = my_pos
        end

        self.inst.components.timer:StartTimer("leash_cd", 3)
    end

    return self._leash_pos
end


local HUNTERPARAMS =
{
    tags = { "_combat" },
    notags = { "INLIMBO", "playerghost" },
	oneoftags = { "character", "monster", "epic" },
}


function EyeOfTerrorBrain:OnStart()
    local root
    if self.inst.twin1 then
        root= PriorityNode(
                {
                    WhileNode(function() return not self.inst.sg:HasStateTag("charge") end, "Not Charging",
                            PriorityNode({
                                Follow(self.inst, GetLeader, MIN_FOLLOW_LEADER, TARGET_FOLLOW_LEADER, MAX_FOLLOW_LEADER),
                                WhileNode(function() return self:ShouldUseSpecialMove() end, "Special Moves",
                                        ActionNode(function() self.inst:PushEvent(self._special_move) end)
                                ),
                                ChaseAndAttack(self.inst,8),
                                --[[WhileNode(function() return not self.inst.components.timer:TimerExists("runaway_blocker") end, "Run Away",
                                    RunAway(self.inst, HUNTERPARAMS, AVOID_PLAYER_DIST, AVOID_PLAYER_STOP)
                                ),]]
                                ParallelNode {
                                    FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
                                    Wander(self.inst, GetSpawnPoint, 30, {minwaittime = 6}),
                                },
                            }, 0.5)
                    ),
                }, 0.5)
    elseif self.inst.twin2 then
        root= PriorityNode(
                {
                    WhileNode(function() return not self.inst.sg:HasStateTag("charge") end, "Not Charging",
                            PriorityNode({
                                WhileNode(function()
                                    return self:ShouldUseSpecialMove()
                                end, "Special Moves",
                                        ActionNode(function()
                                            self.inst:PushEvent(self._special_move)
                                        end)
                                ),
                                ChaseAndAttack(self.inst, 8),
                                ParallelNode {
                                    FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
                                    Wander(self.inst, GetSpawnPoint, 30, { minwaittime = 6 }),
                                },
                            },0.5)
                    )
                }, 0.5)

    end
    self.bt = BT(self.inst, root)
end

function EyeOfTerrorBrain:OnInitializationComplete()
    local pos = self.inst:GetPosition()
    pos.y = 0

    self.inst.components.knownlocations:RememberLocation("spawnpoint", pos, true)
end

return EyeOfTerrorBrain
