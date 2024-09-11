require "behaviours/faceentity"
require "behaviours/leash"
require "behaviours/chaseandattack"
require "behaviours/follow"
require "behaviours/runaway"

local EyeOfTerrorBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
    --self._special_move = nil
end)

local RUN_AWAY_DIST = 12
local STOP_RUN_AWAY_DIST = 16
local MIN_STALKING_TIME = 6

local MIN_FOLLOW_LEADER = 0
local MAX_FOLLOW_LEADER = 22
local TARGET_FOLLOW_LEADER = 18

local HUNTER_PARAMS =
{
	tags = { "_combat" },
	notags = { "INLIMBO", "playerghost", "invisible", "hidden", "flight", "shadowcreature" },
	oneoftags = { "character", "monster", "largecreature", "shadowminion" },
	fn = function(ent, inst)
		--Don't run away from non-hostile animals unless they are attacking us
		return ent.components.combat:TargetIs(inst)
			or ent:HasTag("character")
			or ent:HasTag("monster")
	end,
}

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

local function GetTwin(inst)
    return inst.components.entitytracker:GetEntity("twin")
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

local function ShouldDodge(inst)
	return inst.sg.mem.transformed and inst.components.combat:HasTarget() and not inst:IsStalking()
end

local function ShouldStalk(inst)
	return inst:IsStalking()
end

local function IsStalkingFar(inst)
	local target =  inst.components.combat.target
    --[[if target~=nil then
        local x1, y1, z1 = target.Transform:GetWorldPosition()
        local dir = inst:GetAngleToPoint(x1, 0, z1)
        inst.components.locomotor:OnStrafeFacingChanged(dir)
        return not inst:IsNear(target, 30)
    end]]
	return target and not inst:IsNear(target, 30)
end

local function IsStalkingTooClose(inst)
	local target = inst.components.combat.target
	return target ~= nil and inst:IsNear(target, 5)
end


local function DoStalking(inst)
	local target = inst.components.combat.target
	if target ~= nil then
		local x, y, z = inst.Transform:GetWorldPosition()
		local x1, y1, z1 = target.Transform:GetWorldPosition()
		local dx = x1 - x
		local dz = z1 - z
		local dist = math.sqrt(dx * dx + dz * dz)
		local strafe_angle = Remap(math.clamp(dist, 6, RUN_AWAY_DIST), 6, RUN_AWAY_DIST, 135, 75)
		local rot = inst.Transform:GetRotation()
		local rot1 = math.atan2(-dz, dx) * RADIANS

       

		local rota = rot1 - strafe_angle
		local rotb = rot1 + strafe_angle

        rot1 = inst.cycle and rota or rotb
        --rot1 = math.random() < 0.5 and rota or rotb
		rot1 = rot1 * DEGREES
		return Vector3(x + math.cos(rot1) * 15, 0, z - math.sin(rot1) * 15)
	end
end

local function DoStalking2(inst)
    local target = inst.components.combat.target
	if target ~= nil then
        local my_pos = inst:GetPosition()
        local target_pos = target:GetPosition()
        local normal, _ = (my_pos - target_pos):GetNormalizedAndLength()
        return target_pos + (normal * 16)
    end
end




function EyeOfTerrorBrain:OnStart()
    local root
    if self.inst.twin1 then
        root= PriorityNode(
                {
                    WhileNode(function() return not self.inst.sg:HasStateTag("charge") end, "Not Charging",
                            PriorityNode({
                                Follow(self.inst, GetTwin, MIN_FOLLOW_LEADER, TARGET_FOLLOW_LEADER, MAX_FOLLOW_LEADER),
                                WhileNode(function() return self:ShouldUseSpecialMove() end, "Special Moves",
                                        ActionNode(function() 
                                            self.inst:PushEvent(self._special_move) 
                                            self._special_move = nil
                                        end)
                                ),
                                WhileNode(function() return ShouldDodge(self.inst) end, "Kiting",
                                    PriorityNode({
                                        RunAway(self.inst, HUNTER_PARAMS, RUN_AWAY_DIST, STOP_RUN_AWAY_DIST),
                                        NotDecorator(ActionNode(function()
                                            if not self.inst.components.timer:TimerExists("stalk_cd") then
                                                self.inst:SetStalking(self.inst.components.combat.target)
                                            end
                                            self.inst.components.combat:ResetCooldown()
                                        end)),
                                    }, 0.5)),
                                WhileNode(function() return ShouldStalk(self.inst) end, "Stalking",
                                    ParallelNode{
                                        SequenceNode{
                                            ParallelNodeAny{
                                                WaitNode(MIN_STALKING_TIME),
                                                ConditionWaitNode(function() return IsStalkingFar(self.inst) end),
                                            },
                                            ParallelNodeAny{
                                                WaitNode(15),
                                                ConditionWaitNode(function() return IsStalkingTooClose(self.inst) end),
                                            },
                                            ActionNode(function() 
                                                self.inst.components.combat:ResetCooldown()
                                                self.inst:SetStalking(nil) 
                                            end),
                                        },
                                        Leash(self.inst, DoStalking, 0, 0, false),
                                    }),
                                ChaseAndAttack(self.inst),
                                FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
                                Wander(self.inst, GetSpawnPoint, 20, { minwaittime = 6 }),
                                
                            }, 0.5)
                    ),
                }, 0.5)
    elseif self.inst.twin2 then
        root= PriorityNode(
                {
                    WhileNode(function() return not self.inst.sg:HasStateTag("charge") end, "Not Charging",
                            PriorityNode({
                                Follow(self.inst, GetTwin, MIN_FOLLOW_LEADER, TARGET_FOLLOW_LEADER, MAX_FOLLOW_LEADER),
                                WhileNode(function()
                                    return self:ShouldUseSpecialMove()  end, "Special Moves",
                                        ActionNode(function()
                                            self.inst:PushEvent(self._special_move)
                                            self._special_move = nil
                                        end)
                                ),
                                ChaseAndAttack(self.inst),
                                FaceEntity(self.inst, GetFaceTargetFn, KeepFaceTargetFn),
                                Wander(self.inst, GetSpawnPoint, 20, { minwaittime = 6 }),
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
