local TrueDamage = Class(function(self, inst)
    self.inst = inst
    self.basedamage = 0
end)

function TrueDamage:SetBaseDamage(damage)
	self.basedamage = damage
end

function TrueDamage:SetOnAttack(fn)
    self.onattack = fn
end

function TrueDamage:DoAttack(targ)
    if self.basedamage<=0 then
        return false
    end
    local hp = targ.components.health
    if hp and not hp:IsDead() then
        local damage = self.basedamage
        if self.onattack~=nil then
            self.onattack(self.inst,targ)
        end
        if targ.components.inventory ~= nil then
            damage = targ.components.inventory:ApplyTrueDamage(damage)
        end
        --hp:SetVal(hp.currenthealth-damage, self.inst.prefab, self.inst)
        hp:DoDelta(-damage, nil, self.inst.prefab, true, self.inst, true)
    end
end

return TrueDamage