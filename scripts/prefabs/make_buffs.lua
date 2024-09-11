-------------------------------------------------------------------------
---------------------- Attach and dettach functions ---------------------
-------------------------------------------------------------------------
local function fast_attach(inst, target)
    if target.components.locomotor ~= nil then
        target.components.locomotor:SetExternalSpeedMultiplier(inst,"fast_buff",1.3)
    end
end

local function fast_detach(inst, target)
    if target.components.locomotor ~= nil then
        target.components.locomotor:RemoveExternalSpeedMultiplier(inst,"fast_buff")
    end
end

local function warm_attach(inst, target)
    if target.components.freezable ~= nil then
		target.components.freezable:AddResistance(inst,8)
	end
end

local function warm_detach(inst, target)
    if target.components.freezable ~= nil then
		target.components.freezable:RemoveResistance(inst)
	end
end

local INSIGHTSOUL_NIGHTVISION_COLOURCUBES = {
    regular = "images/colour_cubes/lunacy_regular_cc.tex",
    full_moon = "images/colour_cubes/purple_moon_cc.tex",
    moon_storm = "images/colour_cubes/moonstorm_cc.tex",
}

local function insight_attach(inst,target)
    if target.isplayer then
        target:AddCameraExtraDistance(inst, TUNING.SCRAP_MONOCLE_EXTRA_VIEW_DIST)
        target.components.playervision:PushForcedNightVision(inst, 2, INSIGHTSOUL_NIGHTVISION_COLOURCUBES,true)
        inst._enabled:set(true)
    end
end

local function insight_detach(inst,target)
    if target.isplayer then
        target:RemoveCameraExtraDistance(inst)
        target.components.playervision:PopForcedNightVision(inst)
        inst._enabled:set(false)
    end
end

local function insightbuff_net(inst)
    if ThePlayer ~= nil and inst.entity:GetParent() == ThePlayer and ThePlayer.components.playervision ~= nil then
        if inst._enabled:value() then
            ThePlayer.components.playervision:PushForcedNightVision(inst, 2, INSIGHTSOUL_NIGHTVISION_COLOURCUBES, true)
        else
            ThePlayer.components.playervision:PopForcedNightVision(inst)
        end
    end
end

local function iron_attach(inst,target)
    if target.isplayer then
        target.components.planardefense:AddBonus(inst, 5, "iron_soul")
        target.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 0.8, "iron_soul")
        if target.prefab~="wx78" then
            target:AddTag("chessfriend")
        end
    end
end

local function iron_detach(inst,target)
    if target.isplayer then
        target.components.planardefense:RemoveBonus(inst, "iron_soul")
        target.components.combat.externaldamagetakenmultipliers:RemoveModifier(inst, "iron_soul")
        if target.prefab~="wx78" then
            target:RemoveTag("chessfriend")
        end
    end
end
-------------------------------------------------------------------------
----------------------- Prefab building functions -----------------------
-------------------------------------------------------------------------

local function OnTimerDone(inst, data)
    if data.name == "buffover" then
        inst.components.debuff:Stop()
    end
end

local function MakeBuff(name, onattachedfn, onextendedfn, ondetachedfn, duration, priority, buff_OnEnabledDirty)
    local function OnAttached(inst, target)
        inst.entity:SetParent(target.entity)
        inst.Transform:SetPosition(0, 0, 0) --in case of loading
        inst:ListenForEvent("death", function()
            inst.components.debuff:Stop()
        end, target)

        target:PushEvent("foodbuffattached", { buff = "ANNOUNCE_ATTACH_BUFF_"..string.upper(name), priority = priority })
        if onattachedfn ~= nil then
            onattachedfn(inst, target)
        end
    end

    local function OnExtended(inst, target)
        inst.components.timer:StopTimer("buffover")
        inst.components.timer:StartTimer("buffover", duration)

        target:PushEvent("foodbuffattached", { buff = "ANNOUNCE_ATTACH_BUFF_"..string.upper(name), priority = priority })
        if onextendedfn ~= nil then
            onextendedfn(inst, target)
        end
    end

    local function OnDetached(inst, target)
        if ondetachedfn ~= nil then
            ondetachedfn(inst, target)
        end

        target:PushEvent("foodbuffdetached", { buff = "ANNOUNCE_DETACH_BUFF_"..string.upper(name), priority = priority })
        inst:DoTaskInTime(10*FRAMES, inst.Remove)
    end

    local function fn()
        local inst = CreateEntity()
        inst.entity:AddTransform()
        inst.entity:AddNetwork()
        inst:AddTag("CLASSIFIED")

        if buff_OnEnabledDirty then
            inst._enabled = net_bool(inst.GUID, name.."_buff._enabled", "enableddirty")
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            if buff_OnEnabledDirty then
                inst:ListenForEvent("enableddirty", buff_OnEnabledDirty)
            end    
            return inst
        end

        inst.entity:Hide()
        inst.persists = false

        

        inst:AddComponent("debuff")
        inst.components.debuff:SetAttachedFn(OnAttached)
        inst.components.debuff:SetDetachedFn(OnDetached)
        inst.components.debuff:SetExtendedFn(OnExtended)
        inst.components.debuff.keepondespawn = true

        inst:AddComponent("timer")
        inst.components.timer:StartTimer("buffover", duration)
        inst:ListenForEvent("timerdone", OnTimerDone)

        return inst
    end

    return Prefab("buff_"..name, fn)
end

return MakeBuff("fast", fast_attach, nil, fast_detach, TUNING.TOTAL_DAY_TIME, 1),
    MakeBuff("warm", warm_attach, nil, warm_detach, 300, 2),
    MakeBuff("insight",insight_attach,nil,insight_detach,2*TUNING.TOTAL_DAY_TIME,3,insightbuff_net),
    MakeBuff("iron",iron_attach,nil,iron_detach,TUNING.TOTAL_DAY_TIME,1)

