require "behaviours/chaseandattack"
require "behaviours/leash"
require "behaviours/wander"
require "behaviours/doaction"

local DragonflyBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local function HomePoint(inst)
    return inst.components.knownlocations:GetLocation("spawnpoint")
end


local LAVA_TAGS = { "lava" }
local function ShouldSpawnFn(self)
    if self.inst.components.rampingspawner:GetCurrentWave() <= 0 then
        self._spawnpos = nil
    elseif self._spawnpos == nil then
        local pos = self.inst.components.knownlocations:GetLocation("spawnpoint")
        local lavae_ponds = TheSim:FindEntities(pos.x, pos.y, pos.z, TUNING.DRAGONFLY_RESET_DIST, LAVA_TAGS)
        local target = #lavae_ponds > 0 and lavae_ponds[math.random(#lavae_ponds)] or self.inst
        self._spawnpos = target:GetPosition()
    end
    self.inst.sg.mem.flyover = self._spawnpos ~= nil
    return self.inst.sg.mem.flyover
end

function DragonflyBrain:OnSpawnLavae()
    self._spawnpos = nil
    self.inst.components.rampingspawner:SpawnEntity()
end

function DragonflyBrain:OnStart()
    local root =
        PriorityNode(
        {
            WhileNode(function() return ShouldSpawnFn(self) end, "Spawn Lavae",
				ParallelNode{
					PriorityNode({
						Leash(self.inst, function() return self._spawnpos end, 5, 5),
						ActionNode(function() self.inst:PushEvent("spawnlavae") end),
					}, .25),
					LoopNode{
						ActionNode(function()
							if self.inst.sg:HasStateTag("busy") and not self.inst.sg:HasStateTag("hit") then
								self.inst.components.stuckdetection:Reset()
							elseif self.inst.components.stuckdetection:IsStuck() and not self.inst.components.combat:InCooldown() then
								self.inst.components.combat:TryAttack()
							end
						end),
					},
				}),
            ChaseAndAttack(self.inst),
            Leash(self.inst, HomePoint, 20, 10),
            Wander(self.inst, HomePoint, 15)
        }, .25)
    self.bt = BT(self.inst, root)
end

function DragonflyBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("spawnpoint", self.inst:GetPosition())
end

return DragonflyBrain
