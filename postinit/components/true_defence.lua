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