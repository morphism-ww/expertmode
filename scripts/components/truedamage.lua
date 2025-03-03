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

local function TrueSetVal(self, val, cause, afflicter)
    local old_health = self.currenthealth
    local max_health = self:GetMaxWithPenalty()
    local min_health = math.min(self.minhealth or 0, max_health)

    self.inst:PushEvent("pre_health_setval", {val=val, old_health=old_health})

    if val > max_health then
        val = max_health
    end

    if val <= min_health then
        self.currenthealth = min_health
        self.inst:PushEvent("minhealth", { cause = cause, afflicter = afflicter })
    else
        self.currenthealth = val
    end

    if old_health > 0 and self.currenthealth <= 0 then
        -- NOTES(JBK): Make sure to keep the events fired up to date with the explosive component.
        --Push world event first, because the entity event may invalidate itself
        --i.e. items that use .nofadeout and manually :Remove() on "death" event
        TheWorld:PushEvent("entity_death", { inst = self.inst, cause = cause, afflicter = afflicter })
        self.inst:PushEvent("death", { cause = cause, afflicter = afflicter })
        
        --V2C: If "death" handler removes ourself, then the prefab should explicitly set nofadeout = true.
        --     Intentionally NOT using IsValid() here to hide those bugs.
        if not self.nofadeout then
            self.inst:AddTag("NOCLICK")
            self.inst.persists = false
            self.inst.erode_task = self.inst:DoTaskInTime(self.destroytime or 2, ErodeAway)
        end
    end
end

function TrueDamage:DoAttack(target)
    if self.basedamage<=0 then
        return false
    end
   
    local damage = self.basedamage
    if self.onattack~=nil then  ---don't change target's health here! 
        self.onattack(self.inst,target)
    end
    if target.components.inventory ~= nil then
        damage = target.components.inventory:ApplyTrueDamage(damage)
    end

    local health = target.components.health

    
    if health~= nil then
        local cause = self.inst.prefab
        local afflicter = self.inst
        local old_percent = health:GetPercent()
        if health.redirect ~= nil then
            health.redirect(target, -damage, nil, cause, true, afflicter, true)
        end
        if health.deltamodifierfn ~= nil then
            health.deltamodifierfn(target, -damage, nil, cause, true, afflicter, true)
        end

        TrueSetVal(health,health.currenthealth-damage,cause,afflicter)

        target:PushEvent("healthdelta", { oldpercent = old_percent, newpercent = health:GetPercent(), cause = cause, afflicter = afflicter, amount = -damage })

        if health.ondelta ~= nil then
            -- Re-call GetPercent on the slight chance that "healthdelta" changed it.
            health.ondelta(self.inst, old_percent, health:GetPercent(), nil, cause, afflicter, -damage)
        end
    end
end

return TrueDamage