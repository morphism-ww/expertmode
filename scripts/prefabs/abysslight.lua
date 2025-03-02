require("worldsettingsutil")

local assets =
{
    Asset("ANIM", "anim/rock_light.zip"),
}

local prefabs =
{
    "shadowdragon",
    "nightmarelightfx",
    "ruinsnightmare"
}

local MAX_LIGHT_ON_FRAME = 15
local MAX_LIGHT_OFF_FRAME = 30

local function OnUpdateLight(inst, dframes)
    local frame = inst._lightframe:value() + dframes
    if frame >= inst._lightmaxframe then
        inst._lightframe:set_local(inst._lightmaxframe)
        inst._lighttask:Cancel()
        inst._lighttask = nil
    else
        inst._lightframe:set_local(frame)
    end

    local k = frame / inst._lightmaxframe
    inst.Light:SetRadius(inst._lightradius1:value() * k + inst._lightradius0:value() * (1 - k))

    if TheWorld.ismastersim then
        inst.Light:Enable(inst._lightradius1:value() > 0 or frame < inst._lightmaxframe)
    end
end

local function OnLightDirty(inst)
    if inst._lighttask == nil then
        inst._lighttask = inst:DoPeriodicTask(FRAMES, OnUpdateLight, nil, 1)
    end
    inst._lightmaxframe = inst._lightradius1:value() > 0 and MAX_LIGHT_ON_FRAME or MAX_LIGHT_OFF_FRAME
    OnUpdateLight(inst, 0)
end

local function fade_to(inst, rad, instant)
    if inst._lightradius1:value() ~= rad then
        local k = inst._lightframe:value() / inst._lightmaxframe
        local radius = inst._lightradius1:value() * k + inst._lightradius0:value() * (1 - k)
        local minradius0 = math.min(inst._lightradius0:value(), inst._lightradius1:value())
        local maxradius0 = math.max(inst._lightradius0:value(), inst._lightradius1:value())
        if radius > rad then
            inst._lightradius0:set(radius > minradius0 and maxradius0 or minradius0)
        else
            inst._lightradius0:set(radius < maxradius0 and minradius0 or maxradius0)
        end
        local maxframe = rad > 0 and MAX_LIGHT_ON_FRAME or MAX_LIGHT_OFF_FRAME
        inst._lightradius1:set(rad)
        inst._lightframe:set(instant and maxframe or math.max(0, math.floor((radius - inst._lightradius0:value()) / (rad - inst._lightradius0:value()) * maxframe + .5)))
        OnLightDirty(inst)
    end
end

local function ReturnChildren(inst)
    for k, child in pairs(inst.components.childspawner.childrenoutside) do
        if child.components.combat ~= nil then
            child.components.combat:SetTarget(nil)
        end

        if child.components.lootdropper ~= nil then
            child.components.lootdropper:SetLoot({})
            child.components.lootdropper:SetChanceLootTable(nil)
        end

        if child.components.health ~= nil then
            child.components.health:Kill()
        end
    end
end

local states =
{
    calm = function(inst, instant)
        inst.SoundEmitter:KillSound("warnLP")
        inst.SoundEmitter:KillSound("nightmareLP")

        inst.components.sanityaura.aura = 0
        fade_to(inst, 0, instant)

        if instant then
            inst.AnimState:PlayAnimation("idle_closed")
            inst.fx.AnimState:PlayAnimation("idle_closed")
        else
            inst.AnimState:PlayAnimation("close_2")
            inst.AnimState:PushAnimation("idle_closed", false)
            inst.fx.AnimState:PlayAnimation("close_2")
            inst.fx.AnimState:PushAnimation("idle_closed", false)
            inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_close")
        end

        if inst.components.childspawner ~= nil then
            inst.components.childspawner:StopSpawning()
            inst.components.childspawner:StartRegen()
            ReturnChildren(inst)
        end
    end,

    warn = function(inst, instant)
        inst.SoundEmitter:KillSound("nightmareLP")
        if not (inst:IsAsleep() or inst.SoundEmitter:PlayingSound("warnLP")) then
            inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_warning_LP", "warnLP")
        end

        inst.components.sanityaura.aura = -TUNING.SANITY_SMALL
        fade_to(inst, 3, instant)

        inst.AnimState:PlayAnimation("open_1")
        inst.fx.AnimState:PlayAnimation("open_1")

        if not instant then
            inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_open_warning")
        end
    end,

    wild = function(inst, instant)
        inst.SoundEmitter:KillSound("warnLP")
        if not (inst:IsAsleep() or inst.SoundEmitter:PlayingSound("nightmareLP")) then
            inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_open_LP", "nightmareLP")
        end

        inst.components.sanityaura.aura = -TUNING.SANITY_MED
        fade_to(inst, 6, instant)

        if instant then
            inst.AnimState:PlayAnimation("idle_open")
            inst.fx.AnimState:PlayAnimation("idle_open")
        else
            inst.AnimState:PlayAnimation("open_2")
            inst.AnimState:PushAnimation("idle_open", false)
            inst.fx.AnimState:PlayAnimation("open_2")
            inst.fx.AnimState:PushAnimation("idle_open", false)
            inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_open")
        end

        if inst.components.childspawner ~= nil then
            inst.components.childspawner:StartSpawning()
            inst.components.childspawner:StopRegen()
        end
    end,

    dawn = function(inst, instant)
        inst.SoundEmitter:KillSound("warnLP")
        if not (inst:IsAsleep() or inst.SoundEmitter:PlayingSound("nightmareLP")) then
            inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_open_LP", "nightmareLP")
        end

        inst.components.sanityaura.aura = -TUNING.SANITY_SMALL
        fade_to(inst, 3, instant)

        inst.AnimState:PlayAnimation("close_1")
        inst.fx.AnimState:PlayAnimation("close_1")
        if not instant then
            inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_open")
        end

        if inst.components.childspawner ~= nil then
            inst.components.childspawner:StartSpawning()
            inst.components.childspawner:StopRegen()
        end
    end,
}

local function ShowPhaseState(inst, phase, instant)
    inst._phasetask = nil

    local fn = states[phase] or states.calm
    fn(inst, instant)
end

local function OnNightmarePhaseChanged(inst, phase, instant)
    if inst._phasetask ~= nil then
        inst._phasetask:Cancel()
    end
    if instant or inst:IsAsleep() then
        ShowPhaseState(inst, phase, true)
    else
        inst._phasetask = inst:DoTaskInTime(math.random() * 2, ShowPhaseState, phase)
    end
end

local function OnEntitySleep(inst)
    if inst._phasetask ~= nil then
        inst._phasetask:Cancel()
        ShowPhaseState(inst, TheWorld.state.nightmarephase, true)
    end
    inst.SoundEmitter:KillSound("warnLP")
    inst.SoundEmitter:KillSound("nightmareLP")
end

local function OnEntityWake(inst)
    if TheWorld.state.nightmarephase == "warn" then
        if not inst.SoundEmitter:PlayingSound("warnLP") then
            inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_warning_LP", "warnLP")
        end
    elseif (TheWorld.state.nightmarephase == "wild" or TheWorld.state.nightmarephase == "dawn")
        and not inst.SoundEmitter:PlayingSound("nigtmareLP") then
        inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_spawner_open_LP", "nightmareLP")
    end
end
local function OnPreLoad(inst, data)
    WorldSettings_ChildSpawner_PreLoad(inst, data, TUNING.NIGHTMAREFISSURE_RELEASE_TIME, TUNING.NIGHTMAREFISSURE_REGEN_TIME)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.MiniMapEntity:SetIcon("nightmarelight.png")

    inst.AnimState:SetBuild("rock_light")
    inst.AnimState:SetBank("rock_light")
    inst.AnimState:PlayAnimation("idle_closed",false)
    inst.AnimState:SetFinalOffset(1) --on top of spawned .fx


    inst.Light:SetRadius(0)
    inst.Light:SetIntensity(.9)
    inst.Light:SetFalloff(.9)
    inst.Light:SetColour(1, 1, 1)
    inst.Light:Enable(false)
    inst.Light:EnableClientModulation(true)

    inst._lightframe = net_smallbyte(inst.GUID, "nightmarelight._lightframe", "lightdirty")
    inst._lightradius0 = net_tinybyte(inst.GUID, "nightmarelight._lightradius0", "lightdirty")
    inst._lightradius1 = net_tinybyte(inst.GUID, "nightmarelight._lightradius1", "lightdirty")
    inst._lightmaxframe = MAX_LIGHT_OFF_FRAME
    inst._lightframe:set(inst._lightmaxframe)
    inst._lighttask = nil

    MakeObstaclePhysics(inst, 1)

    inst:SetPrefabNameOverride("nightmarelight")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("lightdirty", OnLightDirty)

        return inst
    end

    inst.fx = SpawnPrefab("nightmarelightfx")
    inst.fx.entity:SetParent(inst.entity)

    inst.highlightchildren = { inst.fx }

    inst:AddComponent("sanityaura")

    inst:AddComponent("childspawner")
    inst.components.childspawner:SetRegenPeriod(TUNING.NIGHTMAREFISSURE_RELEASE_TIME)
    inst.components.childspawner:SetSpawnPeriod(TUNING.NIGHTMAREFISSURE_REGEN_TIME)
    inst.components.childspawner:SetMaxChildren(math.random(TUNING.NIGHTMARELIGHT_MINCHILDREN, TUNING.NIGHTMARELIGHT_MAXCHILDREN))
    WorldSettings_ChildSpawner_SpawnPeriod(inst, TUNING.NIGHTMAREFISSURE_RELEASE_TIME, TUNING.NIGHTMARELIGHT_ENABLED)
    WorldSettings_ChildSpawner_RegenPeriod(inst, TUNING.NIGHTMAREFISSURE_REGEN_TIME, TUNING.NIGHTMARELIGHT_ENABLED)

    inst.components.childspawner.childname = "ruinsnightmare"
    inst.components.childspawner:SetRareChild("shadowdragon", .4)

    inst:AddComponent("inspectable")

    inst:WatchWorldState("nightmarephase", OnNightmarePhaseChanged)
    OnNightmarePhaseChanged(inst, TheWorld.state.nightmarephase, true)

    inst.OnEntityWake = OnEntityWake
    inst.OnEntitySleep = OnEntitySleep

    inst.OnPreLoad = OnPreLoad

    return inst
end

local shadowthrall_table = {"shadowthrall_wings","shadowthrall_horns","shadowthrall_hands","shadowthrall_mouth"}

local function GetRareChildFn()
    return shadowthrall_table[math.random(1,4)]
end

local function TryRegisterBiteTarget(inst, target)
	if target then
		if inst._bite_target == target then
		
			return true
		elseif inst._bite_target == nil and target:IsValid() then			
			inst._bite_target = target
			return true
		end
	end
	return false
end

local function ontakeownership(inst,thrall)
    
    if thrall.prefab == "shadowthrall_hands" then
        thrall.sg.mem.lastfootstep = GetTime()
    elseif thrall.prefab == "shadowthrall_mouth" then
        thrall.TryRegisterBiteTarget = TryRegisterBiteTarget
    end
end

local function OnPreLoad(inst, data)
    WorldSettings_ChildSpawner_PreLoad(inst, data, 30, TUNING.ABYSS_THRALLGEN)
end
local function OnSpawned(inst,thrall)
    if thrall.components.knownlocations ~= nil then
		thrall.components.knownlocations:RememberLocation("spawnpoint", inst:GetPosition())
	end
    
    thrall.sg:GoToState("spawndelay",0.1)
end

local function spawnfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()

    inst:AddTag("NOCLICK")
    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOCLICK")

    -------------------
    inst:AddComponent("childspawner")
    inst.components.childspawner:SetRegenPeriod(TUNING.ABYSS_THRALLGEN)
    inst.components.childspawner:SetSpawnPeriod(30)
    inst.components.childspawner:SetMaxChildren(4)
    WorldSettings_ChildSpawner_SpawnPeriod(inst, 30, true)
    WorldSettings_ChildSpawner_RegenPeriod(inst, TUNING.ABYSS_THRALLGEN, true)
    inst.components.childspawner:SetRareChild(GetRareChildFn, 1)
    inst.components.childspawner:SetSpawnedFn(OnSpawned)
    inst.components.childspawner:SetOnTakeOwnershipFn(ontakeownership)
    inst.components.childspawner:StartSpawning()
    inst.components.childspawner:StartRegen()
    inst.components.childspawner.childreninside = 4

    inst.OnPreLoad = OnPreLoad

    return inst
end

local function gelspawnerfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    --[[Non-networked entity]]

    inst:AddTag("gelblobspawningground")
    inst:AddTag("NOBLOCK")
    inst:AddTag("NOCLICK")

    TheWorld:PushEvent("ms_registergelblobspawningground", inst)

    return inst
end


local function OnPreLoad2(inst, data)
    WorldSettings_ChildSpawner_PreLoad(inst, data, 30, TUNING.ABYSS_THRALLGEN)
end
local function mouth_spawnfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()

    inst:AddTag("NOCLICK")
    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOBLOCK")

    -------------------
    inst:AddComponent("childspawner")
    inst.components.childspawner:SetRegenPeriod(TUNING.ABYSS_THRALLGEN)
    inst.components.childspawner:SetSpawnPeriod(30)
    inst.components.childspawner:SetMaxChildren(3)
    WorldSettings_ChildSpawner_SpawnPeriod(inst, 30, true)
    WorldSettings_ChildSpawner_RegenPeriod(inst, TUNING.ABYSS_THRALLGEN, true)
    inst.components.childspawner.childname = "shadowthrall_mouth"

    inst.components.childspawner:StartSpawning()
    inst.components.childspawner:StartRegen()
    inst.components.childspawner.childreninside = 2
    inst.components.childspawner:SetOnTakeOwnershipFn(ontakeownership)

    inst.OnPreLoad = OnPreLoad2

    return inst
end


local function statuspawn()
    local inst = CreateEntity()

    inst.entity:AddTransform()

    inst:AddTag("NOCLICK")
    inst:AddTag("CLASSIFIED")
    inst:AddTag("NOBLOCK")
    -------------------
    inst:AddComponent("childspawner")
    inst.components.childspawner:SetRegenPeriod(TUNING.ABYSS_THRALLGEN)
    inst.components.childspawner:SetSpawnPeriod(30)
    inst.components.childspawner:SetMaxChildren(3)
    WorldSettings_ChildSpawner_SpawnPeriod(inst, 30, true)
    WorldSettings_ChildSpawner_RegenPeriod(inst, TUNING.ABYSS_THRALLGEN, true)
    inst.components.childspawner.spawnradius = {min = 5, max = 22}
    inst.components.childspawner.childname = "void_peghook"

    inst.components.childspawner:StartSpawning()
    inst.components.childspawner:StartRegen()
    inst.components.childspawner.childreninside = 3

    inst.OnPreLoad = OnPreLoad2

    return inst
end


return Prefab("abysslight", fn, assets, prefabs),
    Prefab("shadowthrall_spawner",spawnfn),
    Prefab("gelblobspawning_worldgen", gelspawnerfn),
    Prefab("shadowmouth_spawner",mouth_spawnfn),
    Prefab("void_peghook_spawner",statuspawn)
