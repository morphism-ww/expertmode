local SourceModifierList = require("util/sourcemodifierlist")


----额外冰冻抗性
AddComponentPostInit("freezable", function(self)
    self._resistance_sources = SourceModifierList(self.inst, 0, SourceModifierList.additive)

    function self:AddResistance(source, resistance)
        self._resistance_sources:SetModifier(source, resistance, "freeze_resist")
    end

    function self:RemoveResistance(source)
        self._resistance_sources:RemoveModifier(source, "freeze_resist")
    end

    function self:ResolveResistance()
        local resistance = self.resistance + self._resistance_sources:Get()
        return self.extraresist ~= nil
            and math.min(resistance * 2.5, self.resistance + self.extraresist)
            or resistance
    end

end)


---火坑机制

AddComponentPostInit("burnable", function(self)
    local function OnHealthErodeAway(inst)
        local self = inst.components.burnable
        self.fastextinguish = true
        self:KillFX()
    end
    local function OnKilled(inst)
        local self = inst.components.burnable
        if self ~= nil and self:IsBurning() and not self.nocharring then
            inst.AnimState:SetMultColour(.2, .2, .2, 1)
        end
    
        --@V2C: #HACK, sync up burn fx to health component's auto-ErodeAway
        if inst.components.health ~= nil and not inst.components.health.nofadeout then
            if self.task ~= nil then
                self.task:Cancel()
            end
            self.task = inst:DoTaskInTime(inst.components.health.destroytime or 2, OnHealthErodeAway)
        end
    end
    function self:Extinguish(resetpropagator, heatpct, smotherer)
        self:StopSmoldering(heatpct)
    
        if smotherer ~= nil then
            if smotherer.components.finiteuses ~= nil then
                smotherer.components.finiteuses:Use()
            elseif smotherer.components.stackable ~= nil then
                smotherer.components.stackable:Get():Remove()
            end
        end
    
        if self.burning then
            if self.task ~= nil then
                self.task:Cancel()
                self.task = nil
            end
    
            self.inst:RemoveEventCallback("death", OnKilled)
    
            if self.inst.components.propagator ~= nil then
                if resetpropagator then
                    self.inst.components.propagator:StopSpreading(true, heatpct)
                else
                    self.inst.components.propagator:StopSpreading()
                end
            end
    
            self.controlled_burn = nil
    
            self.burning = false
            self:KillFX()
            if self.inst.components.fueled ~= nil and not self.ignorefuel then
                self.inst.components.fueled:StopConsuming()
            end
            if self.onextinguish ~= nil then
                self.onextinguish(self.inst,smotherer)
            end
            self.inst:PushEvent("onextinguish",{resetpropagator=resetpropagator,smotherer=smotherer})
        end
    end

end)

---buff状态栏
AddComponentPostInit("debuffable",function (self)
    if self.inst and self.inst:HasTag("player") then
        self.inst:DoPeriodicTask(1, function()
            if self.inst.replica.debuffable then
                self.inst.replica.debuffable.cs_buffinfo:set(self:GetBuffInfo())
            end
        end)
    end
    local function GetBuffTime(inst)
        local timer = inst.components.timer
        if timer ~= nil then
            return timer:GetTimeLeft(next(timer.timers)) or 0
        end
    end
    function self:GetBuffInfo()
        local buff_info={}
        for k, v in pairs(self.debuffs) do
            local name = STRINGS.NAMES[string.upper(v.inst.prefab)]
            if type(name) == "string" then
                table.insert(buff_info,{name = name, time = GetBuffTime(v.inst)})               
            end
        end
        return json.encode(buff_info)
    end
end)


---免控

AddClassPostConstruct("components/rooted",function (self)
    if self.inst:HasTag("no_rooted") then
        self.inst:RemoveTag("rooted")

        if self.inst.Physics ~= nil then
            --Generally, don't call SetTempMass0 outside of here.
            --A prefab's own internal logic should just manage Physics:SetMass.
            --Otherwise, just add and use the "rooted" component where needed.
            self.inst.Physics:SetTempMass0(false)
        end
        if self.inst.components.locomotor ~= nil then
            self.inst.components.locomotor:RemoveExternalSpeedMultiplier(self.inst, "rooted")
        end

    end
end)


---魂的使用
AddComponentPostInit("toggleableitem",function (self)
    function self:ToggleItem(doer)
        if self.onusefn then
            self.onusefn(self.inst,doer)
        end
    end
end)


AddComponentPostInit("aoetargeting",function (self)
    function self:StartTargeting()
        if self.inst.components.reticule == nil then
            local owner = ThePlayer
            if owner.components.playercontroller ~= nil then
                local inventoryitem = self.inst.replica.inventoryitem
                if inventoryitem ~= nil and inventoryitem:IsGrandOwner(owner) then
                    self.inst:AddComponent("reticule")
                    for k, v in pairs(self.reticule) do
                        self.inst.components.reticule[k] = v
                    end
                    owner.components.playercontroller:RefreshReticule(self.inst)
                end
            end
            self.inst:PushEvent("change_aoetarget",true)
        end
    end
    
    function self:StopTargeting()
        if self.inst.components.reticule ~= nil then
            self.inst:RemoveComponent("reticule")
            if ThePlayer.components.playercontroller ~= nil then
                ThePlayer.components.playercontroller:RefreshReticule()
            end
            self.inst:PushEvent("change_aoetarget",false)
        end
    end
end)