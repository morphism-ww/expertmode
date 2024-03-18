local function OnTimerDone(inst, data)
    if data.name == "buffover" then
        inst.components.debuff:Stop()
    end
end


--生成buff
local function MakeBuff(defs)
    --附加Buff函数
	local function OnAttached(inst, target,followsymbol, followoffset, data)
        inst.entity:SetParent(target.entity)
        inst.Transform:SetPosition(0, 0, 0) --in case of loading
        inst:ListenForEvent("death", function()
            inst.components.debuff:Stop()
        end, target)
        inst.duration=data and data.duration or 10
        inst.components.timer:StartTimer("buffover", inst.duration)
        if defs.TICK_RATE then
            inst.task = inst:DoPeriodicTask(defs.TICK_RATE,inst.tickfn, nil, target, data)
        end
        if defs.onattachedfn ~= nil then
            defs.onattachedfn(inst, target,data)
        end
        if defs.buff_fx ~= nil then
            local fx = SpawnPrefab(defs.buff_fx)
            fx.entity:SetParent(target.entity)
        end
    end

    --延长buff函数
	local function OnExtended(inst, target,followsymbol, followoffset, data)
        --local extend_duration = inst.duration
        --local timer_left=inst.components.timer:GetTimeLeft("buffover")--获取定时器剩余时间
		--[[if data and timer_left then
			--延长时间而不是直接用原来的固定时间替换
            if data.extend_duration then
                local max_duration_mult = data.max_duration_mult or 2--最大时长倍数，默认2倍
                extend_duration = data.extend_duration + math.ceil(timer_left * (1 - 1 / max_duration_mult))
            --消耗时间
            elseif data.consume_duration then
                extend_duration = math.max(0, timer_left - data.consume_duration)
            --或者自定义一个计算函数？是增是减随便咯
            elseif data.extend_durationfn then
                extend_duration = data.extend_durationfn(timer_left)
            end
		end]]
        local duration=data and data.duration or inst.duration
        inst.components.timer:StopTimer("buffover")
        inst.components.timer:StartTimer("buffover", duration)
        if defs.onextendedfn ~= nil then
            defs.onextendedfn(inst, target, data)
        end
        if defs.TICK_RATE and inst.task ~= nil then
            inst.task:Cancel()
            inst.task = inst:DoPeriodicTask(defs.TICK_RATE,inst.tickfn, nil, target,data)
        end

        if defs.buff_fx ~= nil then
            local fx = SpawnPrefab(defs.buff_fx)
            fx.entity:SetParent(target.entity)
        end

    end

    --解除buff函数
	local function OnDetached(inst, target)
        if inst.task ~= nil then
            inst.task:Cancel()
            inst.task = nil
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
        inst.components.debuff:SetAttachedFn(OnAttached)--设置附加Buff时执行的函数
        inst.components.debuff:SetDetachedFn(OnDetached)--设置解除buff时执行的函数
        inst.components.debuff:SetExtendedFn(OnExtended)--设置延长buff时执行的函数
        inst.components.debuff.keepondespawn = true


        defs.postinit(inst)
        inst.tickfn=defs.TICK_FN
        inst:AddComponent("timer")--添加定时器
        --inst.components.timer:StartTimer("buffover", defs.duration)
        inst:ListenForEvent("timerdone", OnTimerDone)--监听定时器结束并触发结束

        return inst
    end

    return Prefab(defs.name, fn, nil, defs.prefabs)
end

local buffs={}
for k, v in pairs(require("standard_defs/constant_debuffs")) do
    table.insert(buffs, MakeBuff(v))
end

return unpack(buffs)
