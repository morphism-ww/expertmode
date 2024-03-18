--------------------------------------------------------
--lureplant
--------------------------------------------------------


local function OnCollide(inst, other)
    if other ~= nil and
        other:IsValid() and
        other:HasTag("epic") then
        inst.components.health:Kill()
    end
end
AddPrefabPostInit("lureplant",function(inst)
    if not TheWorld.ismastersim then return end
    inst.Physics:SetCollisionCallback(OnCollide)
end)



--------------------------------------------------------
--rocky
--------------------------------------------------------
TUNING.ROCKY_DAMAGE = 40
require "behaviours/useshield"
local DAMAGE_UNTIL_SHIELD = 1000
local AVOID_PROJECTILE_ATTACKS = false
local HIDE_WHEN_SCARED = true
local SHIELD_TIME = 5

local function ScaredLoseLoyalty(self)
    local t = GetTime()
    if t >= self.scareendtime then
        self.scaredelay = nil
    elseif self.scaredelay == nil then
        self.scaredelay = t + 3
    elseif t >= self.scaredelay then
        self.scaredelay = t + 3
        if math.random() < .2 and
            self.inst.components.follower ~= nil and
            self.inst.components.follower:GetLoyaltyPercent() > 0 and
            self.inst.components.follower:GetLeader() ~= nil then
            self.inst.components.follower:SetLeader(nil)
            if self.inst.components.combat ~= nil then
                self.inst.components.combat:SetTarget(nil)
            end
        end
    end
end


AddBrainPostInit("rockybrain", function(self)
    self.bt.root.children[1]=
    ParallelNode{
            LoopNode{
                ActionNode(function() ScaredLoseLoyalty(self) end),
            },
            UseShield(self.inst, DAMAGE_UNTIL_SHIELD, SHIELD_TIME, AVOID_PROJECTILE_ATTACKS, HIDE_WHEN_SCARED),
        }
end)