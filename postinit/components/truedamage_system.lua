AddComponentPostInit("inventory", function(self)
    function self:ApplyTrueDamage(damage)
        
        for k, v in pairs(self.equipslots) do
            --check resistance
            if v.components.true_defence ~= nil then
                damage = v.components.true_defence:GetAbsorption(damage)
            end
        end    
    
        return damage
    end
end)  



AddComponentPostInit("combat",function (self)
    local old_getatk = self.GetAttacked
    function self:GetAttacked(attacker, damage, weapon, stimuli, spdamage)
        if attacker and attacker.components.truedamage~=nil then
           attacker.components.truedamage:DoAttack(self.inst) 
        end
        return old_getatk(self,attacker, damage, weapon, stimuli, spdamage)
    end    
    if DAMAGEMULTIPLIER_CHANGE then
        self.externaldamagemultipliers = require("util/combatsourcemodifier")(self.inst)
    end
    
end)

AddComponentPostInit("sanity",function (self)
    
    function self:GetSoulAttacked(cause, damage)
        local old_san = self.current
        self:DoDelta(-damage)
        local new_san = self.current
        if new_san<=0 then
            self.inst.components.health:DoDelta(old_san-damage,nil,cause,nil,nil,true)
        end
    end    
    
end)