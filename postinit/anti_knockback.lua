AddComponentPostInit("saddler",function (self)
    function self:SetKnockbackResistCooldown(cd)
        self.inst:AddTag("knockback_resist")
        self.resist_cd = cd
    end
    --[[function self:CanResist()
        return self.canresisttime~=nil and GetTime()>self.canresisttime
    end
    function self:TryResist()
        if self:CanResist() then
            self.canresisttime = GetTime()+self.resist_cd
            return true
        end
        return false
    end]]
end)



AddComponentPostInit("rider",function (self)
    function self:TryResist()
        if self.saddle and self.saddle:HasTag("knockback_resist") then
            if self:CanResist() then
                self.canresisttime = GetTime()+self.saddle.components.saddler.resist_cd
                return true
            end
            return false
        end
        return false
    end
    function self:CanResist()
        return self.canresisttime==nil or GetTime()>self.canresisttime
    end
end)


AddPrefabPostInit("saddle_war",function (inst)
    inst:AddTag("knockback_resist")
    if not TheWorld.ismastersim then
        return inst
    end
    inst.components.saddler:SetAbsorption(0.3)
    inst.components.saddler:SetKnockbackResistCooldown(5)
end)

AddPrefabPostInit("saddle_race",function (inst)
    inst:AddTag("knockback_resist")
    if not TheWorld.ismastersim then
        return inst
    end
    inst.components.saddler:SetAbsorption(0.2)
    inst.components.saddler:SetKnockbackResistCooldown(10)
end)

AddPrefabPostInit("saddle_wathgrithr",function (inst)
    inst:AddTag("knockback_resist")
    if not TheWorld.ismastersim then
        return inst
    end
    inst.components.saddler:SetKnockbackResistCooldown(5)
end)