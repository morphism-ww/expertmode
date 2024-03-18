AddComponentPostInit("boatphysics", function(self)
    self.oldOnUpdate=self.OnUpdate
    function self:OnUpdate(dt)
        if not self.super then
            self:oldOnUpdate(dt)
        else
            --local p1_angle = VecUtil_GetAngleInRads(self.rudder_direction_x, self.rudder_direction_z)
            local p2_angle = VecUtil_GetAngleInRads(self.target_rudder_direction_x, self.target_rudder_direction_z)

            self.rudder_direction_x = math.cos(p2_angle)
            self.rudder_direction_z = math.sin(p2_angle)

            local sail_force_modifier = self:GetAnchorSailForceModifier()
            local sail_force = 0
            for k,v in pairs(self.masts) do
                sail_force = sail_force + k:CalcSailForce() * sail_force_modifier
            end
            local velocity_normal_x, velocity_normal_z, cur_velocity = VecUtil_NormalAndLength(self.velocity_x, self.velocity_z)
            local max_velocity = self:GetMaxVelocity()

            local total_anchor_drag = self:GetTotalAnchorDrag()

            if total_anchor_drag > 0 and sail_force > 0 then
                if sail_force > 0 and cur_velocity < max_velocity then
                    local velocity_length =sail_force * dt
                    self.velocity_x, self.velocity_z = VecUtil_Add(self.velocity_x, self.velocity_z, VecUtil_Scale(self.rudder_direction_x, self.rudder_direction_z, 6*velocity_length))
                    cur_velocity = cur_velocity + velocity_length

                    if cur_velocity > max_velocity then
                        local velocity_normal_x1, velocity_normal_z1 = VecUtil_NormalizeNoNaN(self.velocity_x, self.velocity_z)
                        self.velocity_x, self.velocity_z = VecUtil_Scale(velocity_normal_x1, velocity_normal_z1, max_velocity)
                        cur_velocity = max_velocity
                    end
                end
                cur_velocity = self:ApplyDrag(dt, self:GetBoatDrag(cur_velocity, total_anchor_drag), cur_velocity, VecUtil_NormalizeNoNaN(self.velocity_x, self.velocity_z))
            else
                cur_velocity = self:ApplyDrag(dt, self:GetBoatDrag(cur_velocity, total_anchor_drag), cur_velocity, velocity_normal_x, velocity_normal_z)
                if sail_force > 0 and cur_velocity < max_velocity then
                    local velocity_length =sail_force * dt
                    self.velocity_x, self.velocity_z = VecUtil_Add(self.velocity_x, self.velocity_z, VecUtil_Scale(self.rudder_direction_x, self.rudder_direction_z, 6*velocity_length))
                    cur_velocity = cur_velocity + velocity_length

                    if cur_velocity > max_velocity then
                        local velocity_normal_x1, velocity_normal_z1 = VecUtil_NormalizeNoNaN(self.velocity_x, self.velocity_z)
                        self.velocity_x, self.velocity_z = VecUtil_Scale(velocity_normal_x1, velocity_normal_z1, max_velocity)
                        cur_velocity = max_velocity
                    end
                end
            end

            local is_moving = cur_velocity > 0
            if self.was_moving and not is_moving then
                if self.inst.components.boatdrifter then
                    self.inst.components.boatdrifter:OnStopMoving()
                end
                if self.stopmovingfn then
                    self.stopmovingfn(self.inst)
                end
                self.inst:PushEvent("boat_stop_moving")
                self.was_moving = is_moving
            elseif not self.was_moving and is_moving then
                if self.inst.components.boatdrifter then
                    self.inst.components.boatdrifter:OnStartMoving()
                end
                if self.startmovingfn then
                    self.startmovingfn(self.inst)
                end
                self.inst:PushEvent("boat_start_moving")
                self.was_moving = is_moving
            end

            local time = GetTime()
            if self.lastzoomtime == nil or time - self.lastzoomtime > 1.0 then
                local should_zoom_out = sail_force > 0 and total_anchor_drag <= 0
                if self.inst.doplatformcamerazoom then
                    if not self.inst.doplatformcamerazoom:value() and should_zoom_out then
                        self.inst.doplatformcamerazoom:set(true)
                    elseif self.inst.doplatformcamerazoom:value() and not should_zoom_out then
                        self.inst.doplatformcamerazoom:set(false)
                    end
                end

                self.lastzoomtime = time
            end

            if self.steering_rotate then
                self.inst.Transform:SetRotation(-VecUtil_GetAngleInDegrees(self.rudder_direction_x, self.rudder_direction_z) + self.boat_rotation_offset)
            else
                for mast in pairs(self.masts) do
                    mast:SetRudderDirection(self.rudder_direction_x, self.rudder_direction_z)
                end
                --self.inst.Transform:SetRotation(self.boat_rotation_offset)
            end

            local corrected_vel_x, corrected_vel_z = VecUtil_RotateDir(self.velocity_x, self.velocity_z, self.inst.Transform:GetRotation() * DEGREES)
            if self.halting then -- NOTES(JBK): Injecting these here because velocity is edited all over this component.
                corrected_vel_x, corrected_vel_z, cur_velocity = 0, 0, 0
            end
            self.inst.Physics:SetMotorVel(corrected_vel_x, 0, corrected_vel_z)
        end
    end
end)