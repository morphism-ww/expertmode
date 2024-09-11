require "behaviours/leash"
require "behaviours/chaseandattack"
require "behaviours/waitloop"

local CalamityEyeBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

local RUN_AWAY_DIST = 10


local function GetTargetPos(inst)
	local target =inst.components.combat.target
	return target ~= nil and target:GetPosition() or nil
end

local function ShouldRangeAttack(inst)
    return inst.mode~=2 and inst.components.combat.target~=nil
end


local function GetFormationPos(inst)
    
    if inst.formation ~= nil then
        local pos = GetTargetPos(inst)
        if pos ~= nil then
            local angle = inst.formation * DEGREES
            pos.x = pos.x + math.cos(angle) * inst.formationradius
            pos.z = pos.z - math.sin(angle) * inst.formationradius
            return pos
        end
    end   
end

local function TryChargeAttack(inst)
    
    local target = inst.components.combat.target
    if target ~= nil then
        local dsq_to_target = inst:GetDistanceSqToInst(target)
        if dsq_to_target > TUNING.EYEOFTERROR_CHARGEMINDSQ and dsq_to_target < 400 then
            return "charge"
        end
    end
    
    return false
end


function CalamityEyeBrain:ShouldUseSpecialMove()
    self._special_move = self.inst.mode~=2 and not self.inst.hastwins and 
        TryChargeAttack(self.inst)
        or nil
    if self._special_move then
        return true
    else
        return false
    end
end

function CalamityEyeBrain:OnStart()
	local root = PriorityNode({
        WhileNode(function() return not self.inst.sg:HasStateTag("charge") end, "Not Charging",
        PriorityNode({
            WhileNode(function() return ShouldRangeAttack(self.inst) end, "RangeAttack",
            NotDecorator(SequenceNode{
                ActionNode(function ()
                    self.inst:PlotRangeAttack()     
                end),
                WaitLoopNode(10,
                {
                    ActionNode(function ()
                        self.inst.components.combat:TryAttack()
                    end),
                    Leash(self.inst, GetFormationPos, 0, 0, false)
                }),
            })),
           
            SequenceNode{
                ConditionNode(function () 
                    if self.inst.mode == 2 then
                        self.inst.components.locomotor.walkspeed = 14
                        return true
                    end 
                end, "Bullet Hell"),
                WaitLoopNode(20,{   
                    ActionNode(function ()
                        self.inst:TryWave()
                    end),
                    Leash(self.inst, GetFormationPos, 0, 0, false)
                }),
                ActionNode(function ()
                    self.inst:KillWave()
                    self.inst.components.locomotor.walkspeed = 8
                end),
            },
            WhileNode(function() return self:ShouldUseSpecialMove() end, "Special Moves",
                ActionNode(function() self.inst:PushEvent(self._special_move) end)
            ),
            SequenceNode{
                WaitNode(10),
                ActionNode(function() self.inst.sg:GoToState("flyaway") end),
            },
        },0.5)
    )
		--Wander(self.inst, GetHome, WANDER_DIST),
    }, 0.5)

	self.bt = BT(self.inst, root)
end

return CalamityEyeBrain