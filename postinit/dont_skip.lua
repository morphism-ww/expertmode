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

local function ShouldSleep(inst)
    return inst.components.sleeper:GetTimeAwake() > 0.6*TUNING.TOTAL_DAY_TIME
end

local function ShouldWake(inst)
    return inst.components.sleeper:GetTimeAsleep() > 3*TUNING.TOTAL_DAY_TIME
end

AddPrefabPostInit("rocky",function(inst)
    if not TheWorld.ismastersim then return end
    inst.components.sleeper:SetWakeTest(ShouldWake)
    inst.components.sleeper:SetSleepTest(ShouldSleep)
end)