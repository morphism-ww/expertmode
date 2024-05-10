local function apply_true_damage(inst,data)
    local target = data.target
    if target and target.components.health~=nil and not target.components.health:IsDead() then
        local damage = inst.components.true_damage.basedamage
        if target.components.inventory ~= nil then
			damage = target.components.inventory:ApplyTrueDamage(damage)
        end
        target.components.health:DoDelta(-damage,false,inst.prefab,true,inst,true)        
    end
end


local True_Damage = Class(function(self, inst)
    self.inst = inst
    self.basedamage = 0
    
    if inst.components.combat~=nil then
        inst:ListenForEvent("onattackother",apply_true_damage)
    end
end)


function True_Damage:SetBaseDamage(damage)
	self.basedamage = damage
end


return True_Damage