ChaseAndCharge = Class(BehaviourNode, function(self, inst, max_chase_time, give_up_dist, max_charge_dist)
    BehaviourNode._ctor(self, "ChaseAndCharge")
    self.inst = inst
    self.max_chase_time = max_chase_time
    self.give_up_dist = give_up_dist
    self.max_charge_dist = max_charge_dist
    self.numattacks = 0

    -- we need to store this function as a key to use to remove itself later
    self.onattackfn = function(inst, data)
        self:OnAttackOther(data.target)
    end

    self.inst:ListenForEvent("onattackother", self.onattackfn)
    self.inst:ListenForEvent("onmissother", self.onattackfn)
end)

function ChaseAndCharge:__tostring()
    return string.format("target %s", tostring(self.inst.components.combat.target))
end

function ChaseAndCharge:OnStop()
    self.inst:RemoveEventCallback("onattackother", self.onattackfn)
    self.inst:RemoveEventCallback("onmissother", self.onattackfn)
end

function ChaseAndCharge:OnAttackOther(target)
    self.numattacks = self.numattacks + 1
    self.startruntime = nil -- reset max chase time timer
end

function ChaseAndCharge:Visit()
    local combat = self.inst.components.combat
    if self.status == READY then
        if combat.target ~= nil and combat.target.entity:IsValid() then
            --self.inst.components.locomotor:Stop()
            self.inst.components.combat:BattleCry()
            self.startruntime = GetTime()
            self.numattacks = 0
            self.status = RUNNING
            self.startloc = self.inst:GetPosition()

            local hp = Point(combat.target.Transform:GetWorldPosition())
            local pt = Point(self.inst.Transform:GetWorldPosition())
            self.ram_angle = self.inst:GetAngleToPoint(hp)
            self.ram_vector = (hp - pt):GetNormalized()
            self.inst:AddTag("ChaseAndCharge")
        else
            self.inst:RemoveTag("ChaseAndCharge")
            self.status = FAILED
            self.ram_vector = nil
        end
    end

    if self.status == RUNNING then
        if not combat.target or not combat.target.entity:IsValid() then
            self.status = FAILED
            self.ram_vector = nil
            combat:SetTarget(nil)
            self.inst.components.locomotor:Stop()
            self.inst:RemoveTag("ChaseAndCharge")
            return
        elseif combat.target.components.health ~= nil and combat.target.components.health:IsDead() then
            self.status = SUCCESS
            combat:SetTarget(nil)
            self.inst.components.locomotor:Stop()
            self.inst:RemoveTag("ChaseAndCharge")
            return
        else
            local hp = combat.target:GetPosition()
            local pt = self.inst:GetPosition()
            local dsq = distsq(hp, pt) --Distance to target.
            local angle = math.abs(self.inst:GetAngleToPoint(hp)) --Angle to target.

            if self.inst.sg ~= nil and self.inst.sg:HasStateTag("canrotate") then
                --Line up charge here.
                self.ram_angle = self.inst:GetAngleToPoint(hp)
                self.ram_vector = (hp-pt):GetNormalized()
            end

            local offset_angle = math.abs(angle - math.abs(self.ram_angle))
            if offset_angle <= 60 then
                --Running action. This is the actual "Ram"
                self.inst.components.locomotor:RunInDirection(self.ram_angle)
            elseif offset_angle > 60 and (dsq >= (self.give_up_dist * self.give_up_dist)) then
                --You have run past your target. Stop!
                --self.inst.components.locomotor:Stop()
                self.status = FAILED
                self.ram_vector = nil
                if self.inst.sg:HasStateTag("canrotate") then
                    self.inst:FacePoint(hp)
                end
                self.inst.components.combat:ForceAttack()
                self.inst:RemoveTag("ChaseAndCharge")
            end

            if self.inst.sg ~= nil and not self.inst.sg:HasStateTag("atk_pre") and combat:TryAttack() then
                -- If you're not still in the telegraphing stage then try to attack.
                self.inst:RemoveTag("ChaseAndCharge")
            elseif self.startruntime == nil then
                self.startruntime = GetTime()
                self.inst.components.combat:BattleCry()
            end

            if (self.max_charge_dist ~= nil and distsq(self.startloc, self.inst:GetPosition()) >= self.max_charge_dist * self.max_charge_dist)
                    or (self.max_chase_time ~= nil and self.startruntime ~= nil and GetTime() - self.startruntime > self.max_chase_time) then
                self.status = FAILED
                self.ram_vector = nil
                --self.inst.components.locomotor:Stop()
                self.inst.components.combat:ForceAttack()
                self.inst:RemoveTag("ChaseAndCharge")
                return
            end

            self:Sleep(.125)
        end
    end
end
