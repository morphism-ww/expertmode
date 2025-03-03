newcs_env.AddComponentPostInit("inventory", function(self)
    function self:ApplyTrueDamage(damage)
        
        for k, v in pairs(self.equipslots) do
            --check resistance
            if v.components.true_defence ~= nil then
                damage = v.components.true_defence:GetAbsorption(damage)
            end
        end    
        self:ApplyDamage(damage)
        return damage
    end
end)  


newcs_env.AddComponentPostInit("combat",function (self)
    local old_getatk = self.GetAttacked
    function self:GetAttacked(attacker, damage, weapon, stimuli, spdamage)
        if self.inst.components.health and self.inst.components.health:IsDead() then
            return true
        end
        if attacker and attacker.components.truedamage~=nil then
           attacker.components.truedamage:DoAttack(self.inst) 
        end
        if self.hit_stuntime and self:InHitStun() then
            return false
        end
        return old_getatk(self,attacker, damage, weapon, stimuli, spdamage)
    end    


    --UpvalueTracker.SetUpvalue(self.externaldamagemultipliers.RemoveModifier,RecalculateModifier,"RecalculateModifier")
    self.externaldamagemultipliers = require("util/combatsourcemodifier")(self.inst)
    
    function self:InHitStun()
        return GetTime()<self.hit_stuntime + self.lastwasattackedtime
    end


    ---must be a non-nil entity!!!
    function self:P_AOECheck(target)
        if not (target.entity:IsValid() and target.entity:IsVisible()) then
            return false
        end

        if target.replica.combat == nil or IsEntityDead(target, true) 
        or target:HasTag("noplayertarget") or self:IsAlly(target) then
            return false
        end

        --TODO  PVP???
        local sanity = self.inst.replica.sanity

        if sanity ~= nil and sanity:IsCrazy() or self.inst:HasTag("crazy") then
            --Insane attacker can pretty much attack anything
            return true
        end

        if target:HasAnyTag("shadowcreature", "nightmarecreature") and target:HasTag("locomotor") then
            local victim = target.replica.combat:GetTarget()

            if victim == nil or (victim~=self.inst and target.HostileToPlayerTest ~= nil 
            and not target:HostileToPlayerTest(victim)) then
                return false
            end
        end

        return true
    end
end)

newcs_env.AddComponentPostInit("sanity",function (self)
    self.soul_loss_rate = 1
    function self:GetSoulAttacked(attacker, damage)
        local old_san = self.current
        damage = damage * self.soul_loss_rate
        self:DoDelta(-damage)
        local new_san = self.current
        if new_san<=0 then
            self.inst.components.health:DoDelta(old_san-damage,nil,"SOUL_BREAK",nil,attacker,true)
        end
    end    
    
end)