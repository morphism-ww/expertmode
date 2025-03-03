local UpvalueTracker = require("util/upvaluetracker")
local SourceModifierList = require("util/sourcemodifierlist")


----额外冰冻抗性
--冰冻组件的bug修复

local function OnAttacked(inst, data)
    local self = inst.components.freezable
    if self == nil then
        print("[WARNING !!!] freezable missing on: ",inst)
        if type(data)=="table" then
            print("attacker: ",data.attacker,"damage: ",data.damage,"weapon: ",data.weapon)
        end
        return
    end
    
	--IsValid check because other "attacked" handlers may have removed us
	--NOTE: see how EntityScript:PushEvent caches all listeners; that is why an invalid entity could still reach this event listener
	if self:IsFrozen() and inst:IsValid() then
        self.damagetotal = self.damagetotal + math.abs(data.damage)
        if self.damagetotal >= self.damagetobreak then
            self:Unfreeze()
        end
    end
end

local freezable_hook = require("components/freezable").OnRemoveFromEntity
UpvalueTracker.SetUpvalue(freezable_hook,OnAttacked,"OnAttacked")


newcs_env.AddComponentPostInit("freezable", function(self)
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

newcs_env.AddComponentPostInit("burnable", function(self)
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
--[[newcs_env.AddComponentPostInit("debuffable",function (self)
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
            return math.floor(timer:GetTimeLeft(next(timer.timers)) or 0)
        elseif  inst.prefab=="nightvision_buff" then
            return math.floor(GetTaskRemaining(inst.task))
        end
        return 999
    end
    function self:GetBuffInfo()
        local buff_info={}
        for k, v in pairs(self.debuffs) do
            local name = STRINGS.NAMES[string.upper(v.inst.prefab)] ---只发送STRINGS定义过名称的
            local timeleft = GetBuffTime(v.inst)
            if type(name) == "string" and timeleft>0 then
                table.insert(buff_info,{name = v.inst.prefab, time = timeleft})  --语言系统在本地运行，故发送prefab             
            end
        end
        return json.encode(buff_info)
    end
)]]
newcs_env.AddComponentPostInit("spell",function (self)
    function self:OnStart()
        self.active = true
        if self.onstartfn ~= nil then
            self.onstartfn(self.inst)
        end
        if self.target and self.target.isplayer then
            self.target:PushEvent("onspell",{spell = self.inst, duration = self.duration})
        end
    end
    function self:OnFinish()
        if self.target and self.target.isplayer then
            self.target:PushEvent("endspell",self.inst)
        end
        if self.onfinishfn ~= nil then
            self.onfinishfn(self.inst)
        end
        
        self.inst:StopUpdatingComponent(self)
    
        if self.removeonfinish then
            self.inst:Remove()
        end
    end
    function self:ResumeSpell()
        if self.resumefn ~= nil then
            local timeleft = self.duration - self.lifetime
            self.resumefn(self.inst, timeleft)
            self.inst:StartUpdatingComponent(self)
            if self.target and self.target.isplayer then
                self.target:PushEvent("onspell",{spell = self.inst, duration = self.duration})
            end
        end
    end
end)

---免控

require("components/rooted")._ctor = function (self,inst)
    self.inst = inst
	self.sources = {}
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
    else
        if inst.Physics ~= nil then
            inst.Physics:Stop()
    
            --Generally, don't call SetTempMass0 outside of here.
            --A prefab's own internal logic should just manage Physics:SetMass.
            --Otherwise, just add and use the "rooted" component where needed.
            inst.Physics:SetTempMass0(true)
        end
        if inst.components.locomotor ~= nil then
            inst.components.locomotor:SetExternalSpeedMultiplier(inst, "rooted", 0)
        end
    end
    self._onremovesource = function(src)
		self.sources[src] = nil
		if next(self.sources) == nil then
			inst:RemoveComponent("rooted")
		end
	end

	inst:PushEvent("rooted")
end


---魂的使用
newcs_env.AddComponentPostInit("toggleableitem",function (self)
    function self:ToggleItem(doer)
        if self.onusefn then
            self.onusefn(self.inst,doer)
        end
    end
end)


newcs_env.AddComponentPostInit("colouradder",function (self)
    function self:ForceMultColor(r,g,b,a)
        self.inst.AnimState:SetMultColour(r, g, b, a)
	
        for k, v in pairs(self.children) do
            if k.OnSyncMultColour ~= nil then
                k:OnSyncMultColour(r,g,b,a)
            elseif k.AnimState~=nil then
                k.AnimState:SetMultColour(r, g, b, a)
            end
        end
    end

    function self:ClearMultColor()
        self.inst.AnimState:SetMultColour(1,1,1,1)
	
        for k, v in pairs(self.children) do
            if k.OnSyncMultColour ~= nil then
                k:OnSyncMultColour(1,1,1,1)
            elseif k.AnimState~= nil then
                k.AnimState:SetMultColour(1,1,1,1)
            end
        end
    end
end)