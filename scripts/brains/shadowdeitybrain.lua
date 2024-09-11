require "behaviours/chaseandattack"
require "behaviours/chaseandattackandavoid"
require "behaviours/findclosest"
require "behaviours/leash"
require "behaviours/faceentity"
require "behaviours/wander"

local SKULLACHE_CD = 18
local FALLAPART_CD = 11
local SEE_LURE_DIST = 20
local SAFE_LURE_DIST = 5

local COMBAT_FEAST_DELAY = 3
local CHECK_MINIONS_PERIOD = 2

local RESET_COMBAT_DELAY = 10

local LOITER_GATE_DIST = 5.5
local LOITER_GATE_RANGE = 1.5

local IDLE_GATE_TIME = 10
local IDLE_GATE_MAX_DIST = 4
local IDLE_GATE_DIST = 3

local AVOID_GATE_DIST = 6 --stargate radius + stalker radius + some breathing room

local StalkerBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
    self.abilityname = nil
    self.abilitydata = nil
    self.snaretargets = nil
    self.hasfeast = nil
    self.hasminions = nil
    self.checkminionstime = nil
    self.wantstoecho = nil
end)




local STALKERMINION_TAGS = { "stalkerminion" }
local function CheckMinions(self)
    local t = GetTime()
    if t > (self.checkminionstime or 0) then
        local x, y, z = self.inst.Transform:GetWorldPosition()
        self.hasminions = #TheSim:FindEntities(x, y, z, 8, STALKERMINION_TAGS) > 0
        self.checkminionstime = t + CHECK_MINIONS_PERIOD
    end
end

local function ShouldSnare(self)
    if not self.inst.components.timer:TimerExists("snare_cd") then
        local targets = self.inst:FindSnareTargets()
        if targets ~= nil then
            self.abilitydata = { targets = targets }
            return true
        end
        self.inst.components.timer:StartTimer("snare_cd", TUNING.STALKER_ABILITY_RETRY_CD)
    end
    return false
end

local SPIKE_TARGET_MUST_TAGS = { "_combat", "_health" }
local SPIKE_TARGET_CANT_TAGS = { "fossil", "playerghost", "shadow", "INLIMBO" }
local function ShouldEcho(self)
    if not self.inst.components.timer:TimerExists("echo_cd") then
        if not self.hasminions then
            
            local x, y, z = self.inst.Transform:GetWorldPosition()
            if #TheSim:FindEntities(x, y, z, 12, SPIKE_TARGET_MUST_TAGS, SPIKE_TARGET_CANT_TAGS) > 0 then
                self.wantstoecho = true
                return true
            end
        end
    end
    return false
end

local function ShouldSummonChannelers(self)
    return 
         self.inst.components.commander:GetNumSoldiers() <= 0
        and not self.inst.components.timer:TimerExists("channelers_cd")
end

local function ShouldSummonMinions(self)
    return not self.hasminions
        and not self.inst.components.timer:TimerExists("minions_cd")
end

local function ShouldVortex(self)
	return next(self.inst._vortexes)==nil
end

local function ShouldShadowBall(self)
    return not self.inst.components.timer:TimerExists("shadowball_cd")
end

local function ShouldMindControl(self)
    if not self.inst.components.timer:TimerExists("mindcontrol_cd") then
        if self.inst:HasMindControlTarget() then
            return true
        end
        self.inst.components.timer:StartTimer("mindcontrol_cd", TUNING.STALKER_ABILITY_RETRY_CD)
    end
    return false
end

local function ShouldFeast(self)
    if self.hasfeast == nil then
        self.hasfeast = self.inst.components.health:IsHurt() and #self.inst:FindMinions(1) > 0
    end
    return self.hasfeast
end

local function ShouldCombatFeast(self)
    if not self.inst.components.combat:InCooldown() then
        local target = self.inst.components.combat.target
        if target ~= nil and target:IsNear(self.inst, TUNING.STALKER_ATTACK_RANGE + target:GetPhysicsRadius(0)) then
            return false
        end
    end
    if not self.inst.hasshield and self.inst.components.combat:GetLastAttackedTime() + COMBAT_FEAST_DELAY >= GetTime() then
        return false
    end
    return ShouldFeast(self)
end

local function ShouldMeteor(self)
    return not self.inst.components.timer:TimerExists("meteors_cd") 
end

local function ShouldShadowBall(self)
    return not self.inst.components.timer:TimerExists("shadowball_cd") 
end


local function Level1(self)
    return (ShouldMeteor(self) and "meteors") or
    (not self.wantstoecho and ShouldSnare(self) and "fossilsnare") or
    (ShouldShadowBall(self) and "shadowball") or 
    (ShouldEcho(self) and "roar")
end

local function Level2(self)
    return (ShouldVortex(self) and "vortex") or 
    (ShouldMindControl(self) and "mindcontrol") or
    (not self.wantstoecho and ShouldSnare(self) and "fossilsnare") or
    (ShouldSummonChannelers(self) and "shadowchannelers") or
        (ShouldCombatFeast(self) and "fossilfeast") or
        CheckMinions(self) or
        (ShouldSummonMinions(self) and "fossilminions") or
        (ShouldEcho(self) and "roar")
end

local function ShouldUseAbility(self)
    self.wantstoecho = nil
    self.hasfeast = nil
    self.inst.returntogate = nil
    self.abilityname = self.inst.components.combat:HasTarget() 
    and (self.inst.level2 and Level2(self)
    or Level1(self))
    or nil
    return self.abilityname ~= nil
end

local function GetLoiterStargatePos(inst)
    local stargate = inst.components.entitytracker:GetEntity("stargate")
    if stargate ~= nil then
        local x, y, z = stargate.Transform:GetWorldPosition()
        local x1, y1, z1 = inst.Transform:GetWorldPosition()
        if x == x1 and z == z1 then
            return Vector3(x, 0, z)
        end
        local dx, dz = x1 - x, z1 - z
        local normalize = LOITER_GATE_DIST / math.sqrt(dx * dx + dz * dz)
        return Vector3(x + dx * normalize, 0, z + dz * normalize)
    end
end

local function GetIdleStargate(inst)
    local stargate = inst.components.entitytracker:GetEntity("stargate")
    if stargate ~= nil then
        inst.returntogate = true
        return stargate
    end
end

local function KeepIdleStargate(inst)
    inst.returntogate = true
    return true
end

local function GetPillar(inst)
    return inst.components.entitytracker:GetEntity("pillar")
end


function StalkerBrain:OnStart()
    local root = PriorityNode({
            --[[WhileNode(function() return not self.inst:IsNearAtrium() end, "LostAtrium",
                ActionNode(function() self.inst:OnLostAtrium() end)),]]
            WhileNode(function() return ShouldUseAbility(self) end, "Ability",
                ActionNode(function()
                    self.inst:PushEvent(self.abilityname, self.abilitydata)
                    self.abilityname = nil
                    self.abilitydata = nil
                end)),
            WhileNode(function() return ShouldFeast(self) end, "FossilFeast",
                ActionNode(function() self.inst:PushEvent("fossilfeast") end)),
            ChaseAndAttackAndAvoid(self.inst, GetPillar, AVOID_GATE_DIST),
            Wander(self.inst),
        }, .5)


    self.bt = BT(self.inst, root)
end

return StalkerBrain
