local CircleProjectile = Class(function(self, inst)
    self.inst = inst
    self.owner = nil
    self.target = nil
    self.speed = nil
    self.hitdist = 1
    self.onthrown = nil
    self.onhit = nil
    self.onmiss = nil
end)

function CircleProjectile:Shoot(target,owner)
    self.owner = owner
    self.target = target
    
    self.inst.Physics:SetMotorVel(self.speed, 0, 0)
    if self.onthrown ~= nil then
        self.onthrown(self.inst, owner, target)
    end

    self.inst:StartUpdatingComponent(self)
end

function CircleProjectile:OnUpdate(dt)
    local target = self.target
    local pos = self.inst:GetPosition()
    if target ~= nil and target:IsValid() then
        local range = self.hitdist
        if distsq(pos, target:GetPosition()) < range * range then
            self:Hit(target)
            return true
        end
        local target_facing = self.inst:GetAngleToPoint(target.Transform:GetWorldPosition())
        local current_facing = self.inst:GetRotation()

        local anglediff = target_facing - current_facing
        if anglediff > 180 then
            anglediff = anglediff - 360
        elseif anglediff < -180 then
            anglediff = anglediff + 360
        end
        local mult = 1
        if math.abs(anglediff) > 70 then
            anglediff = math.clamp(anglediff, -10, 10)
            mult = 0.5
        elseif math.abs(anglediff) > 30 then
            anglediff = math.clamp(anglediff, -15, 15)
        else
            anglediff = math.clamp(anglediff, -8, 8)
        end    
        local final_rotation = current_facing + anglediff
        self.inst.Transform:SetRotation(final_rotation)   
        self.inst.Physics:SetMotorVel(self.speed*mult,0,0) 
    else
        self.onmiss(self.inst)
    end    
end    

function CircleProjectile:SetOnMissFn(fn)
    self.onmiss = fn
end

function CircleProjectile:SetOnHitFn(fn)
    self.onhit = fn
end

function CircleProjectile:SetHitDist(dist)
    self.hitdist = dist
end

function CircleProjectile:SetOnThrownFn(fn)
    self.onthrown = fn
end

function CircleProjectile:Hit(target)
    local attacker = self.owner
    self.inst:StopUpdatingComponent(self)
    self.inst.Physics:Stop()

    if self.onhit ~= nil then
        self.onhit(self.inst, attacker, target)
    end
end

function CircleProjectile:SetSpeed(speed)
    self.speed = speed
end

return CircleProjectile
