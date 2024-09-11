local function OnTimerDone(inst, data)
    if data.name == "buffover" then
        inst.components.debuff:Stop()
    end
end


local function MakeBuff(defs)
    
	local function OnAttached(inst, target,followsymbol, followoffset, data)
        inst.entity:SetParent(target.entity)
        inst.Transform:SetPosition(0, 0, 0) --in case of loading
        inst:ListenForEvent("death", function()
            inst.components.debuff:Stop()
        end, target)
        
        if defs.onattachedfn ~= nil then
            defs.onattachedfn(inst, target,data)
        end

        if data and data.duration then
            inst.components.timer:SetTimeLeft("buffover", data.duration)
        end

        if defs.TICK_RATE then
            inst.task = inst:DoPeriodicTask(defs.TICK_RATE,inst.tickfn, nil, target, data)
        end

        if defs.buff_fx ~= nil then
            inst.fx = SpawnPrefab(defs.buff_fx)
            inst.fx.entity:SetParent(target.entity)
        end
    end

    
	local function OnExtended(inst, target,followsymbol, followoffset, data)
        
        inst.components.timer:SetTimeLeft("buffover", data and data.duration or  defs.duration)

        if defs.onextendedfn ~= nil then
            defs.onextendedfn(inst, target, data)
        end

        if defs.TICK_RATE and inst.task ~= nil then
            inst.task:Cancel()
            inst.task = inst:DoPeriodicTask(defs.TICK_RATE,inst.tickfn, nil, target,data)
        end
    end


	local function OnDetached(inst, target)
        if inst.task ~= nil then
            inst.task:Cancel()
            inst.task = nil
        end
        if inst.fx~=nil then
            inst.fx:Remove()
            inst.fx= nil
        end    
        inst:Remove()
    end

    local function fn()
        local inst = CreateEntity()

        if not TheWorld.ismastersim then
            --Not meant for client!
            inst:DoTaskInTime(0, inst.Remove)
            return inst
        end

        inst.entity:AddTransform()

        --[[Non-networked entity]]
        --inst.entity:SetCanSleep(false)
        inst.entity:Hide()
        inst.persists = false

        inst:AddTag("CLASSIFIED")

        inst:AddComponent("debuff")
        inst.components.debuff:SetAttachedFn(OnAttached)
        inst.components.debuff:SetDetachedFn(OnDetached)
        inst.components.debuff:SetExtendedFn(OnExtended)
        inst.components.debuff.keepondespawn = true

        if defs.postinit~=nil then
            defs.postinit(inst)
        end
        inst.tickfn = defs.TICK_FN

        inst:AddComponent("timer")
        inst.components.timer:StartTimer("buffover", defs.duration)

        inst:ListenForEvent("timerdone", OnTimerDone)

        return inst
    end

    return Prefab(defs.name, fn, nil, defs.prefabs)
end

local buffs={}
for k, v in pairs(require("standard_defs/constant_debuffs")) do
    table.insert(buffs, MakeBuff(v))
end

return unpack(buffs)
