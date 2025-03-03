--------------------------------
---
--------------------------------
---

local function OnTimerDone(inst, data)
    inst.components.debuff:Stop()
end

---server-only
local function MakeBuff(name,def)
    name = "buff_"..name
    local function buff_OnTick(inst, target)
        if target.components.health ~= nil and
            not target.components.health:IsDead() then
            def.TICK_FN(inst, target)
        else
            inst.components.debuff:Stop()
        end
    end
    local function OnAttached(inst, target,followsymbol, followoffset, data)
        inst.entity:SetParent(target.entity)
        inst.Transform:SetPosition(0, 0, 0) --in case of loading

        inst:ListenForEvent("death", function()
            inst.components.debuff:Stop()
        end, target)

        if data and data.duration then
            inst.components.timer:SetTimeLeft("buffover", data.duration)
        end
        
        if def.ONAPPLY ~= nil then
            def.ONAPPLY(inst, target,data)
        end
        
        -----food buff
        if def.priority then  
            target:PushEvent("foodbuffattached", { buff = "ANNOUNCE_ATTACH_"..string.upper(name), priority = def.priority })
        end

        if def.TICK_RATE then
            inst.ticktask = inst:DoPeriodicTask(def.TICK_RATE,buff_OnTick, nil, target)
        end
        
        if def.CreateFx then
            local fx = def.CreateFx(target)
            if fx~=nil then
                inst.fx = fx
                fx.entity:SetParent(target.entity)
                fx.Transform:SetPosition(0,0,0)
            end
            
        end
    end

    
	local function OnExtended(inst, target,followsymbol, followoffset, data)
        inst.components.timer:SetTimeLeft("buffover", data and data.duration or def.DURATION)

        if def.ONEXTEND ~= nil then
            def.ONEXTEND(inst, target, data)
        end
    end

	local function OnDetached(inst, target)
        if inst.ticktask ~= nil then
            inst.ticktask:Cancel()
            inst.ticktask = nil
        end

        if inst.fx~=nil then
            inst.fx:Remove()
            inst.fx = nil
        end
        
        if def.ONDETACH~=nil then
            def.ONDETACH(inst,target)
        end
        inst:Remove()
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()

        --[[Non-networked entity]]
        --inst.entity:SetCanSleep(false)
        inst.entity:Hide()
        inst.persists = false

        inst:AddTag("CLASSIFIED")

        if def.DEBUFF then
            inst.newcs_debuff = true
        end

        inst:AddComponent("debuff")
        inst.components.debuff:SetAttachedFn(OnAttached)
        inst.components.debuff:SetDetachedFn(OnDetached)
        inst.components.debuff:SetExtendedFn(OnExtended)
        inst.components.debuff.keepondespawn = true

        inst:AddComponent("timer")
        inst.components.timer:StartTimer("buffover", def.DURATION)

        inst:ListenForEvent("timerdone", OnTimerDone)

        return inst
    end
    return Prefab(name, fn, nil, def.prefabs)
end

local function MakeNetBuff(name,def)
    name = "buff_"..name
    local function buff_OnTick(inst, target)
        if target.components.health ~= nil and
            not target.components.health:IsDead() then
            def.TICK_FN(inst, target)
        else
            inst.components.debuff:Stop()
        end
    end
    local function OnAttached(inst, target,followsymbol, followoffset, data)
        inst.entity:SetParent(target.entity)
        inst.Transform:SetPosition(0, 0, 0) --in case of loading

        inst:ListenForEvent("death", function()
            inst.components.debuff:Stop()
        end, target)

        inst._enabled:set(true)

        if data and data.duration then
            inst.components.timer:SetTimeLeft("buffover", data.duration)
        end
        
        if def.ONAPPLY ~= nil then
            def.ONAPPLY(inst, target,data)
        end
        
        -----food buff
        if def.priority then  
            target:PushEvent("foodbuffattached", { buff = "ANNOUNCE_ATTACH_"..string.upper(name), priority = def.priority })
        end

        if def.TICK_RATE then
            inst.ticktask = inst:DoPeriodicTask(def.TICK_RATE,buff_OnTick, nil, target)
        end
        if def.CreateFx then
            inst.fx = def.CreateFx(target)
        end
    end

    
	local function OnExtended(inst, target,followsymbol, followoffset, data)
        inst.components.timer:SetTimeLeft("buffover", data and data.duration or def.DURATION)

        if def.ONEXTEND ~= nil then
            def.ONEXTEND(inst, target, data)
        end
    end

	local function OnDetached(inst, target)
        inst._enabled:set(false)

        if inst.ticktask ~= nil then
            inst.ticktask:Cancel()
            inst.ticktask = nil
        end
        
        if def.ONDETACH~=nil then
            def.ONDETACH(inst,target)
        end
        inst:DoTaskInTime(0.4,inst.Remove)
    end

    local function OnEnabledDirty(inst)
        local parent = inst.entity:GetParent()
        if  parent~=nil and parent == ThePlayer then
            
            def.OnEnabledDirty(inst,parent,inst._enabled:value())
        end
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddNetwork()


        inst:AddTag("NOCLICK")

        inst._enabled = net_bool(inst.GUID, name.."_buff._enabled", "enableddirty")

        if not TheNet:IsDedicated() then
            inst:ListenForEvent("enableddirty", OnEnabledDirty)
        end
        inst.entity:SetPristine()

        if not TheWorld.ismastersim then 
            return inst
        end

        inst.entity:Hide()

        if def.DEBUFF then
            inst.newcs_debuff = true
        end

        inst:AddComponent("debuff")
        inst.components.debuff:SetAttachedFn(OnAttached)
        inst.components.debuff:SetDetachedFn(OnDetached)
        inst.components.debuff:SetExtendedFn(OnExtended)
        inst.components.debuff.keepondespawn = true

        inst:AddComponent("timer")
        inst.components.timer:StartTimer("buffover", def.DURATION)

        inst:ListenForEvent("timerdone", OnTimerDone)
        return inst
    end
    return Prefab(name, fn, nil, def.prefabs)
end


local buffs = {}
for name, def in pairs(require("standard_defs/newcs_buffs_def")) do
    if def.net_ent then
        table.insert(buffs, MakeNetBuff(name,def))
    else
        table.insert(buffs, MakeBuff(name,def))
    end
end

return unpack(buffs)