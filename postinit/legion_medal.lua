newcs_env.AddComponentPostInit("projectilelegion",function (self)
    self.inst:AddTag("projectile")
    self.inst:AddTag("s_l_throw")
end)

newcs_env.AddComponentPostInit("medal_delivery",function (self)
    local old_activate = self.Activate
    function self:Activate(deliverier,target)
        if IsEntInAbyss(target) or IsEntInAbyss(self.inst) then
            deliverier.components.health:SetInvincible(false)
            if deliverier.components.combat~=nil then
                deliverier.components.combat:GetAttacked(nil, nil, nil, "darkness",{planar = 1000})
            end
            return false
        end
        return old_activate(self,deliverier,target)
    end
    local old_openscreen = self.OpenScreen
    function self:OpenScreen(doer)
        if IsEntInAbyss(doer) then
            return false
        end
        old_openscreen(self,doer)
    end
    local old_delivery = self.Delivery
    function self:Delivery(deliverier,index)
        if IsEntInAbyss(deliverier) or IsEntInAbyss(self.inst) then
            if deliverier.components.combat~=nil then
                deliverier.components.combat:GetAttacked(nil, nil, nil, "darkness",{planar = 1000})
            end
            return false
        end
        return old_delivery(self,deliverier,index)
    end
    local old_AddMarkPos = self.AddMarkPos
    function self:AddMarkPos()
        if IsEntInAbyss(self.inst) then
            return false
        end
        old_AddMarkPos(self)
    end
    
end)