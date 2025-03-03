require "behaviours/wander"
require "behaviours/chaseandattack"
require "behaviours/follow"

local MIN_FOLLOW = 5
local MED_FOLLOW = 15
local MAX_FOLLOW = 30

local HARASS_MIN = 0
local HARASS_MED = 4
local HARASS_MAX = 5



local function ShouldUseAbility(self)
    if self.inst.components.combat.target==nil then
        return false
    end
    local target = self.inst.components.combat.target
    local dsq_to_target = self.inst:GetDistanceSqToInst(target)
    self.abilityname = dsq_to_target<64 and (
        (not self.inst.components.timer:TimerExists("wave_cd") and "wave_atk") or
        (not self.inst.components.timer:TimerExists("fire_cd") and "fire_atk") 
    ) or (dsq_to_target<20*20 and dsq_to_target>13*13 and "teleport_atk") or nil
    return self.abilityname ~= nil
end

local function ShoulScream(self)
    local x,y,z = self.inst.Transform:GetWorldPosition()
    for _, player in ipairs(AllPlayers) do
        if player:IsValid() and not player:HasTag("playerghost") and player.sg:HasStateTag("sleeping") then
            local distsq = player:GetDistanceSqToPoint(x, y, z)
            if distsq < 400 then
                return true
            end
        end
    end
end

local NightmareCreatureBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
    self.abilityname = nil
end)

function NightmareCreatureBrain:OnStart()
    local root = PriorityNode(
    {   
        WhileNode(function() return ShouldUseAbility(self) end, "Ability",
            ActionNode(function()
                self.inst:PushEvent(self.abilityname)
                self.abilityname = nil
            end)),
        ChaseAndAttack(self.inst, 30),
        WhileNode(function() return ShoulScream(self) end, "Harass",
            ActionNode(function ()
                self.inst.components.combat:BattleCry()
            end)),
        Wander(self.inst),
    }, .25)

    self.bt = BT(self.inst, root)
end

return NightmareCreatureBrain
