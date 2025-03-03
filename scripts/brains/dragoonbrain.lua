require "behaviours/wander"
require "behaviours/chaseandattack"
require "behaviours/doaction"


local DragoonBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

local SEE_DIST = 30
local HOUSE_MAX_DIST = 30



local DRAGONFLY_VOMIT_TARGETS_FOR_SATISFIED = 40
local DRAGOON_CHASE_TIME = 8


local function ShouldSpitFn(inst)
	
	if inst.sg:HasStateTag("sleeping") or inst.num_targets_vomited >= DRAGONFLY_VOMIT_TARGETS_FOR_SATISFIED or inst.hassleepdestination then return false end
	if not inst.recently_frozen and not inst.flame_on then
		if not inst.last_spit_time then 
			if inst:GetTimeAlive() > 5 then
				return true
			end
		else
			return (GetTime() - inst.last_spit_time) >= inst.spit_interval
		end
	end
	
	return false
end

local function LavaSpitAction(inst)
	--print("LavaSpitAction", inst.target, inst.target ~= inst, not inst.target:HasTag("fire"))
	if not inst.target or (inst.target ~= inst and not inst.target:HasTag("fire")) then
		inst.last_spit_time = GetTime()
		inst.spit_interval = math.random(20,30)
		if not inst.target then
			inst.target = inst
		end
		-- print("LavaSpitAction", inst, inst.target)
		return BufferedAction(inst, inst.target, ACTIONS.LAVASPIT)
	end
end

local function EatFoodAction(inst)
	if inst.sg:HasStateTag("busy") and not inst.sg:HasStateTag("wantstoeat") then
		return
	end
    local target = FindEntity(inst, SEE_DIST, function(item) return inst.components.eater:CanEat(item) and item:IsOnPassablePoint(true) end)
    return target ~= nil and BufferedAction(inst, target, ACTIONS.EAT) or nil
end


function DragoonBrain:OnStart()
	
	local root = PriorityNode(
	{
		ChaseAndAttack(self.inst, DRAGOON_CHASE_TIME),

		WhileNode(function() return ShouldSpitFn(self.inst) end, "Spit",
			DoAction(self.inst, LavaSpitAction)),
		AttackWall(self.inst),
		DoAction(self.inst, EatFoodAction, "eat food", true),		
		Wander(self.inst, nil, HOUSE_MAX_DIST),
	}, .5)
	
	self.bt = BT(self.inst, root)
	
end

return DragoonBrain

