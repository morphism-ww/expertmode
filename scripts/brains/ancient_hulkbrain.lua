require "behaviours/chaseandattack"
require "behaviours/doaction"
require "behaviours/leash"
require "behaviours/wander"


local GO_HOME_DIST = 40

local CHASE_GIVEUP_DIST = 10


local BASE_TAGS = {"structure"}
local FOOD_TAGS = {"edible"}
local STEAL_TAGS = {"structure"}
local NO_TAGS = {"FX", "NOCLICK", "DECOR","INLIMBO", "burnt"}

local function HomePoint(inst)
    return inst.components.knownlocations:GetLocation("home")
end

local function GoHomeAction(inst)
    local homePos = inst.components.knownlocations:GetLocation("home")
    local dx, dy, dz = inst.Transform:GetWorldPosition()
    local dist_sq = inst:GetDistanceSqToPoint(homePos:Get())
    if inst.components.combat.target ~= nil and dist_sq<GO_HOME_DIST*GO_HOME_DIST then
        return
    end
    if not inst:IsOnValidGround() or dist_sq> 1024 then
        inst.sg.mem.teleporthome=true
        return BufferedAction(inst, nil, ACTIONS.GOHOME)
    end
    return homePos ~= nil
        and BufferedAction(inst, nil, ACTIONS.WALKTO, nil, homePos, nil, .2)
        or nil
end
local function ShouldGoHome(inst)
    local homePos = inst.components.knownlocations:GetLocation("home")
    if homePos == nil then
        return false
    end
    local dx, dy, dz = inst.Transform:GetWorldPosition()
    local dist_sq = inst:GetDistanceSqToPoint(homePos:Get())
    return
    dist_sq > GO_HOME_DIST * GO_HOME_DIST
        or (dist_sq > CHASE_GIVEUP_DIST * CHASE_GIVEUP_DIST and
            inst.components.combat.target == nil)
        or (TheWorld.Map:IsSurroundedByWater(dx, dy, dz, 2))
end
local Ancient_hulkBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

function Ancient_hulkBrain:OnStart()


    local root =
        PriorityNode(
        { WhileNode(function() return ShouldGoHome(self.inst) end, "ShouldGoHome",
                    DoAction(self.inst, GoHomeAction, "Go Home", false)),
            ChaseAndAttack(self.inst, 10, 30, nil, nil, true),    --60,120
          Leash(self.inst, HomePoint, 20, 16),
          Wander(self.inst, HomePoint, 15)
        }, .5)
    
    self.bt = BT(self.inst, root)
         
end

function Ancient_hulkBrain:OnInitializationComplete()
    --self.inst.components.knownlocations:RememberLocation("spawnpoint", Point(self.inst.Transform:GetWorldPosition()))
end

return Ancient_hulkBrain