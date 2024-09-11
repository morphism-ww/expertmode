local LinearProjectile = Class(function(self, inst)
    self.inst = inst

    self.velocity = Vector3(0, 0, 0)
    

    self.horizontalSpeed = 4
    self.launchoffset = nil
    self.targetoffset = nil

    self.attacker = nil

    self.onlaunchfn = nil
    self.onhitfn = nil
    self.onmissfn = nil
    self.onupdatefn = nil

    --self.mode = nil
    self.startpos = nil

    self.musttags = {"_combat","_health"}
    self.notags = {"FX","INLIMBO","playerghost","invisible","notarget", "noattack"}
	--self.ismeleeweapon = false -- setting to true allows for melee attacks on left lick and toss on right click

    --NOTE: projectile and LinearProjectile components are mutually
    --      exclusive because they share this tag!
    --V2C: Recommended to explicitly add tag to prefab pristine state
    inst:AddTag("projectile")
end)

function LinearProjectile:OnRemoveFromEntity()
    self.inst:RemoveTag("projectile")
end

function LinearProjectile:GetDebugString()
    return tostring(self.velocity)
end

function LinearProjectile:SetHorizontalSpeed(speed)
    self.horizontalSpeed = speed
end

--[[function LinearProjectile:SetMode(mode)
    self.mode = mode
end]]


function LinearProjectile:SetLaunchOffset(offset)
    self.launchoffset = offset -- x is facing, y is height, z is ignored
end

function LinearProjectile:SetTargetOffset(offset)
    self.targetoffset = offset -- x is ignored, y is height, z is ignored
end

function LinearProjectile:SetOnLaunch(fn)
    self.onlaunchfn = fn
end

function LinearProjectile:SetOnHit(fn)
    self.onhitfn = fn
end

function LinearProjectile:SetRange(range)
    self.range = range
end

function LinearProjectile:SetOnUpdate(fn)
    self.onupdatefn = fn
end

function LinearProjectile:SetOnMiss(fn)
    self.onmiss = fn
end

function LinearProjectile:CalculateTrajectory(startPos, endPos, speed)

    --[[local dx = endPos.x - startPos.x
    local dy = endPos.y - startPos.y
    local dz = endPos.z - startPos.z

    local range = math.sqrt(dx * dx + dz * dz)
    local angle = math.atan2(dy,range)

    self.velocity.x = math.cos(angle) * speed  --stupid
    self.velocity.z = 0.0
    self.velocity.y = math.sin(angle) * speed]]
    local dx = endPos.x - startPos.x
    local dy = endPos.y - startPos.y
    local dz = endPos.z - startPos.z
    local vx,vy,vz = Vec3Util_Normalize(dx,dy,dz)
    self.velocity.x = speed*vx
    self.velocity.y = speed*vy
    self.velocity.z = speed*vz
end



function LinearProjectile:Launch(targetPos, attacker)
    local pos = self.inst:GetPosition()
    self.attacker = attacker
	self.inst:ForceFacePoint(targetPos:Get())
   
    local offset = self.launchoffset
    if attacker ~= nil and offset ~= nil then
        local facing_angle = self.inst.Transform:GetRotation() * DEGREES
        pos.x = pos.x + offset.x * math.cos(facing_angle)
        pos.y = pos.y + offset.y
        pos.z = pos.z - offset.x * math.sin(facing_angle)
        -- print("facing", facing_angle)
        -- print("offset", offset)
        if self.inst.Physics ~= nil then
            self.inst.Physics:Teleport(pos:Get())
        else
            self.inst.Transform:SetPosition(pos:Get())
        end
    end
    -- use targetoffset height, otherwise hit when you hit the ground
    targetPos.y = self.targetoffset ~= nil and self.targetoffset.y or 0

    self:CalculateTrajectory(pos, targetPos, self.horizontalSpeed)

	-- if the attacker is standing on a moving platform, then inherit it's velocity too
	local attacker_platform = attacker ~= nil and attacker:GetCurrentPlatform() or nil
	if attacker_platform ~= nil then
		local vx, vy, vz = attacker_platform.Physics:GetVelocity()
	    self.velocity.x = self.velocity.x + vx
	    self.velocity.z = self.velocity.z + vz
	end    
    if self.onlaunchfn ~= nil then
        self.onlaunchfn(self.inst, attacker, targetPos)
    end
    self.inst.Physics:SetVel(self.velocity:Get())
    self.inst:AddTag("activeprojectile")
    self.inst:StartUpdatingComponent(self)
end

function LinearProjectile:LineShoot(targetPos, attacker)
    local pos = self.inst:GetPosition()
    self.startpos = pos
    self.targetPos = targetPos
    self.attacker = attacker
	self.inst:ForceFacePoint(targetPos:Get())
    --[[local offset = self.launchoffset
    if attacker ~= nil and offset ~= nil then
        local facing_angle = self.inst.Transform:GetRotation() * DEGREES
        pos.x = pos.x + offset.x * math.cos(facing_angle)
        pos.y = pos.y + offset.y
        pos.z = pos.z - offset.x * math.sin(facing_angle)
        -- print("facing", facing_angle)
        -- print("offset", offset)
        if self.inst.Physics ~= nil then
            self.inst.Physics:Teleport(pos:Get())
        else
            self.inst.Transform:SetPosition(pos:Get())
        end
    end]]
    targetPos.y = self.targetoffset ~= nil and self.targetoffset.y or 0

    self.inst.Physics:SetMotorVel(self.horizontalSpeed,0,0)
    if self.onlaunchfn ~= nil then
        self.onlaunchfn(self.inst, attacker, targetPos)
    end

    self.inst:AddTag("activeprojectile")
    self.inst:StartUpdatingComponent(self)

end


function LinearProjectile:Cancel()
	self.inst:RemoveTag("activeprojectile")
	self.inst:StopUpdatingComponent(self)
	self.inst.Physics:SetMotorVel(0, 0, 0)
	self.inst.Physics:Stop()
	self.velocity.x, self.velocity.y, self.velocity.z = 0, 0, 0
end

function LinearProjectile:Hit()
	self:Cancel()
    if self.onhitfn ~= nil then
        self.onhitfn(self.inst, self.attacker)
    end
end



local function checkforhit(self)
    local x,y,z =self.inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, 0, z, 3, self.musttags, self.notags,self.oneoftags)
    for _,v in ipairs(ents) do
        -- The owner/attacker is not a valid target.
        if v.entity:IsValid() and v~=self.attacker then
            local hitrange = v:GetPhysicsRadius(0) + 1.5
            if v:GetDistanceSqToPoint(x, y, z) < hitrange * hitrange then
                return true
            end    
        end
    end
end

local function distsq(v1,v2)
    local dx = v1.x-v2.x
    local dz = v1.z-v2.z
    return dx*dx+dz*dz
end    

function LinearProjectile:OnUpdate(dt)
    if self.onupdatefn ~= nil and self.onupdatefn(self.inst) then
        return
    end
    
    local pos = self.inst:GetPosition()
    if checkforhit(self) then
        self:Hit()
    elseif self.range ~= nil and distsq(self.startpos, pos) > self.range * self.range then
        self.onmiss(self.inst,self.attacker)
    end
  
end

return LinearProjectile
