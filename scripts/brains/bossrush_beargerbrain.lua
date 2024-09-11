require "behaviours/chaseandattack"
require "behaviours/runaway"
require "behaviours/wander"
require "behaviours/doaction"
require "behaviours/chaseandram"

local MAX_CHASE_TIME = 8
local GIVE_UP_DIST = 20
local MAX_CHARGE_DIST = 60
local SEE_FOOD_DIST = 15
local SEE_STRUCTURE_DIST = 30


local function GetHome(inst)
	return inst.components.knownlocations:GetLocation("spawnpoint") or nil
end

local function InRamDistance(inst, target)
    local target_is_close = inst:IsNear(target, 10)
    if target_is_close then
        return false
    elseif target:IsOnValidGround() then
        -- Our target is on land, and we already know we're far enough away because the above test failed!
        return true
    end
end

local BeargerBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function BeargerBrain:OnStart()
	local root = PriorityNode({
		WhileNode(
			function()
				return not (self.inst.sg:HasStateTag("jumping") or
							self.inst.sg:HasStateTag("staggered"))
			end,
			"<busy state guard>",
			PriorityNode({
				WhileNode(
					function()
						if not self.inst.canrunningbutt and self.inst.components.timer:TimerExists("GroundPound") then
							return false
						end
						local target = self.inst.components.combat.target
						return target ~= nil
							and (self.inst.sg:HasStateTag("running") or InRamDistance(self.inst, target))
					end,
					"Charge Behaviours",
					ChaseAndRam(self.inst, MAX_CHASE_TIME, GIVE_UP_DIST, MAX_CHARGE_DIST)),

				ChaseAndAttack(self.inst, nil, nil, nil, nil, true),

				Wander(self.inst,
					GetHome,
					10,
					{
						minwalktime = 2,
						randwalktime = 3,
						minwaittime = .1,
						randwaittime = .6,
					}),
				StandStill(self.inst),
			}, 0.25)),
	}, 0.25)

    self.bt = BT(self.inst, root)
end

function BeargerBrain:OnInitializationComplete()
	self.inst.components.knownlocations:RememberLocation("spawnpoint", self.inst:GetPosition(), true)
end

return BeargerBrain