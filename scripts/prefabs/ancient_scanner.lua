local assets =
{
    Asset("ANIM", "anim/wx_scanner.zip"),
    Asset("ANIM", "anim/winona_catapult_placement.zip"),
}
local prefabs={"wx78_scanner_fx"}

local brain = require "brains/ancient_scannerbrain"

local MAX_FLASH_TIME = 2
local MIN_FLASH_TIME = 0.15
local TOP_LIGHT_FLASH_TIMERNAME = "toplightflash_tick"

local function proximityscan(inst, dt)
    local owner = inst.components.follower.leader
    if owner then
        local x,y,z = inst.Transform:GetWorldPosition()

        -- We add a buffer to the search distance to account for physics radii
        local SCAN_DIST = 10

        local new_target = nil
        for i, v in ipairs(AllPlayers) do
            if not v:HasTag("playerghost") and v.entity:IsVisible()
                and v:GetDistanceSqToPoint(x, y, z) < SCAN_DIST*SCAN_DIST then
                new_target = v
                break
            end
        end

        if new_target ~= nil then
            local distsq = inst:GetDistanceSqToInst(new_target)
            local nextpingtime = 2
            for k, v in ipairs(TUNING.WX78_SCANNER_DISTANCES) do
                if v.maxdist*v.maxdist >= distsq then
                    nextpingtime = v.pingtime
                    break
                end
            end

            inst._ping_time_last = inst._ping_time_last or GetTime()
            inst._ping_time_current = (inst._ping_time_current ~= nil and inst._ping_time_current + dt)
                or GetTime()

            if (inst._ping_time_current - inst._ping_time_last) > nextpingtime then
                inst.SoundEmitter:PlaySound("WX_rework/scanner/ping")
                inst:LoopFn(new_target)

                inst.components.entitytracker:ForgetEntity("currentscanlock")
                inst.components.entitytracker:TrackEntity("currentscanlock", new_target)

                inst._ping_time_last = nil
                inst._ping_time_current = nil
            end
        else
            inst.components.entitytracker:ForgetEntity("currentscanlock")

            inst._ping_time_last = nil
            inst._ping_time_current = nil
        end
    end
end

---------------
local function hide_top_light(inst)
    inst.AnimState:Hide("top_light")
end

local function top_light_flash(inst)
    if inst._scantime then
        local calctime = math.max(
            Remap(inst._scantime, 0, TUNING.WX78_SCANNER_MODULETARGETSCANTIME-1, MAX_FLASH_TIME, MIN_FLASH_TIME),
            MIN_FLASH_TIME
        )

        inst.AnimState:Show("top_light")
        inst:DoTaskInTime(math.min(calctime-0.1, 0.3), hide_top_light)

        inst.components.timer:StartTimer(TOP_LIGHT_FLASH_TIMERNAME, calctime)
    else
        hide_top_light(inst)
    end
end

local function can_scan_target(inst)
    local target = inst.components.entitytracker:GetEntity("scantarget")
    local pos = target:GetPosition()
    local DSQ = 25

    if inst:GetDistanceSqToPoint(pos) < DSQ then
        -- WX is prevented from scanning things that have the "noattack" tag, unless they also have the "canwxscan" tag.
        -- See moles as an example.
        return not target:HasTag("playerghost")
    else
        return false
    end
end

local function OnUpdateScanCheck(inst, dt)
    if inst._donescanning or inst._scantime == nil then
        return nil
    end

    local target = inst.components.entitytracker:GetEntity("scantarget")
    if target ~= nil then
        local owner = inst.components.follower.leader
        if owner == nil or target:HasTag("playerghost") or
                (target.components.health ~= nil and target.components.health:IsDead()) then
            inst:StopScanFX()
            inst:OnScanFailed()
        elseif can_scan_target(inst) then
            inst._scantime = inst._scantime + dt

            inst:StartScanFX(target)

            local target_time = 3
            if inst._scantime > target_time then
                inst:OnSuccessfulScan()
                inst:StopScanFX()
            end
        else
            inst:StopScanFX()
        end
    end
end


local function OnTargetFound(inst, scan_target)
    if scan_target ~= nil then
        inst.SoundEmitter:PlaySound("WX_rework/scanner/locked_on")

        inst.AnimState:Hide("bottom_light")
        inst.components.updatelooper:RemoveOnUpdateFn(proximityscan)

        inst._showringfx:set(1)

        inst.components.entitytracker:TrackEntity("scantarget", scan_target)
        inst:ListenForEvent("onremove", inst._OnScanTargetRemoved, scan_target)

        inst._scantime = 0

        inst.components.timer:StartTimer(TOP_LIGHT_FLASH_TIMERNAME, MAX_FLASH_TIME)

        inst.components.updatelooper:AddOnUpdateFn(inst.IsInRangeOfBase)
        inst.components.updatelooper:AddOnUpdateFn(OnUpdateScanCheck)
    end
end

local function TryFindTarget(inst)
    if inst._donescanning then
        return nil
    end

    local owner = inst.components.follower.leader
    if not owner then
        return nil
    end

    if not inst:IsInRangeOfBase() then
        return nil
    end

    local px, py, pz = inst.Transform:GetWorldPosition()

    for _, v in ipairs(AllPlayers) do
        if not v:HasTag("playerghost") and v.entity:IsVisible()
                and v:GetDistanceSqToPoint(px, py, pz) < 144 then
            OnTargetFound(inst, v)
            break
        end
    end

    return nil
end

-- NET_VAR FUNCTIONS
local function CreateRingFX()
    local inst = CreateEntity()

    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst:AddTag("CLASSIFIED")
    inst:AddTag("DECOR")
    inst:AddTag("NOCLICK")

    inst.AnimState:SetBank("winona_catapult_placement")
    inst.AnimState:SetBuild("winona_catapult_placement")
    inst.AnimState:PlayAnimation("idle")

    inst.AnimState:Hide("inner")

    inst.AnimState:SetLightOverride(1)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGroundFixed)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(1)

    local scale = TUNING.WX78_SCANNER_PLAYER_PROX/8.5
    inst.Transform:SetScale(scale,scale,scale)

    inst:AddComponent("fader")

    return inst
end
local function OnShowRingFXDirty(inst)
    local show_ring_fx_value = inst._showringfx:value()

    if show_ring_fx_value == 0 then
        if inst.prox_range ~= nil and inst.prox_range:IsValid() then
            inst.prox_range:Remove()
        end
        inst.prox_range = nil
    elseif show_ring_fx_value == 1 then
        if inst.prox_range == nil then
            inst.prox_range = CreateRingFX()
        end
        inst:AddChild(inst.prox_range)

        inst.prox_range.AnimState:SetAddColour(0, 0.5, 0.2, 0)
    elseif show_ring_fx_value == 2 then
        local fail_prox_range = CreateRingFX()

        if inst.prox_range ~= nil and inst.prox_range:IsValid() then
            fail_prox_range.Transform:SetRotation(inst.prox_range.Transform:GetRotation())

            inst.prox_range:Remove()
            inst.prox_range = nil
        end

        fail_prox_range.Transform:SetPosition(inst.Transform:GetWorldPosition())

        fail_prox_range.components.fader:Fade(1, 0, 1,
            function(alphaval, fx)
                fx.AnimState:SetMultColour(1, 1, 1, alphaval)
                fx.AnimState:SetAddColour(0.5*alphaval, 0.1*alphaval, 0.1*alphaval, 0)
            end,
            function(fx, alphaval)
                fx:Remove()
            end
        )

        inst._showringfx:set_local(0)
    elseif show_ring_fx_value == 3 then
        local matched_rotation = 0

        -- Since we're going to make multiple rings here,
        -- just kill our stored one and make 3 new ones. They're frame delayed anyway.
        if inst.prox_range ~= nil and inst.prox_range:IsValid() then
            matched_rotation = inst.prox_range.Transform:GetRotation()

            inst.prox_range:Remove()
        end
        inst.prox_range = nil

        for i=0,2 do
            inst:DoTaskInTime(i*0.15,function()
                local prox_range = CreateRingFX()
                prox_range.Transform:SetPosition(inst.Transform:GetWorldPosition())
                prox_range.Transform:SetRotation(matched_rotation)
                prox_range.AnimState:SetAddColour(0, 0.5, 0.2, 0)

                prox_range.components.fader:Fade(1 - (i*0.4), 0, 1,
                    function(alphaval, fx)
                        fx.AnimState:SetMultColour(1, 1, 1, alphaval)
                        fx.AnimState:SetAddColour(0, 0.5*alphaval, 0.2*alphaval, 0)
                    end,
                    function(fx, alphaval)
                        fx:Remove()
                    end
                )
                prox_range.components.fader:Fade(1, 1.3, 1,
                    function(scaleval, fx)
                        local scale = (TUNING.WX78_SCANNER_PLAYER_PROX/8.5) * scaleval
                        fx.Transform:SetScale(scale, scale, scale)
                    end
                )
            end)
        end

        inst._showringfx:set_local(0)
    end
end


local function IsInRangeOfBase(inst)
    local DISTANCE = 20

    if inst.components.follower == nil or inst.components.follower.leader == nil or
            inst:GetDistanceSqToInst(inst.components.follower.leader) < DISTANCE*DISTANCE then
        return true
    else
        if inst.components.entitytracker:GetEntity("scantarget") then
            inst:OnScanFailed()
        end

        return false
    end
end


local function OnScanFailed(inst)
    inst:StopAllScanning("fail")
    inst.components.updatelooper:AddOnUpdateFn(proximityscan)
end

local function StopScanFX(inst)
    if inst.scan_fx then
        inst.scan_fx:goAway()
        inst.scan_fx = nil
    end
    inst.SoundEmitter:KillSound("telemetry_lp")
end

local function scanner_loop_fn(inst, target)
    inst:DoTaskInTime(0.1,function() inst.AnimState:Show("bottom_light") end)
    inst:DoTaskInTime(0.6, function() inst.AnimState:Hide("bottom_light") end)
end

local function on_scanner_timer_done(inst, data)
    if data.name == "startproximityscan" then
        inst.components.updatelooper:AddOnUpdateFn(proximityscan)
    elseif data.name == TOP_LIGHT_FLASH_TIMERNAME then
        top_light_flash(inst)
    end
end


--------------
local function start_looping_sound(inst)
    inst.SoundEmitter:PlaySound("WX_rework/scanner/movement_lp", "movement_lp")
end

local function stop_looping_sound(inst)
    inst.SoundEmitter:KillSound("movement_lp")
end
local function ShareTargetFn(dude)
    return dude:HasTag("chess") or dude:HasTag("shadow_aligned")
end
local function DoWarning(inst,target)
    --[[local x,y,z=inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, 32, {"_health"}, {"DECOR", "FX", "INLIMBO", "NOCLICK"}, {"chess","shadoweyeturret"})
    local targets={}
    for i, v in ipairs(ents) do
        if v~=nil and v.components.combat~=nil then
            if v.components.sleeper~=nil then
                v.components.sleeper:WakeUp()
            end
            v.components.combat:SuggestTarget(target)
        end
    end]]
    if target~=nil and target.components.sanity~=nil then
        target.components.sanity:DoDelta(-25)
    end
    inst.components.combat:ShareTarget(target, 24, ShareTargetFn, 10)
end
local function explode(inst)
    inst:StopScanFX()
    local ring = SpawnPrefab("laser_ring")
    ring.Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst.components.explosive:OnBurnt()
    inst:Remove()
end
local function OnSuccessfulScan(inst)
    inst._donescanning = true

    local target = inst.components.entitytracker:GetEntity("scantarget")
    if target ~= nil then

        DoWarning(inst,target)
        inst:RemoveEventCallback("onremove", inst._OnScanTargetRemoved, target)
        inst.components.entitytracker:ForgetEntity("scantarget")
    end
    inst:StopBrain()
    inst:DoTaskInTime(1.2,explode)
end
local function StartScanFX(inst, target)
    if inst.scan_fx == nil and target ~= nil then
        inst.SoundEmitter:PlaySound("WX_rework/scanner/telemetry_lp", "telemetry_lp")

        inst.scan_fx = SpawnPrefab("wx78_scanner_fx")
        target:AddChild(inst.scan_fx)

        local scale = Remap(target:GetPhysicsRadius() or 0, 0, 5, 0.5, 8)
        inst.scan_fx.Transform:SetScale(scale, scale, scale)
    end
end
local function StopAllScanning(inst, status)
    inst.components.updatelooper:RemoveOnUpdateFn(inst.IsInRangeOfPlayer)
    inst.components.updatelooper:RemoveOnUpdateFn(OnUpdateScanCheck)

    local target = inst.components.entitytracker:GetEntity("scantarget")
    if target ~= nil then
        inst:RemoveEventCallback("onremove", inst._OnScanTargetRemoved, target)
        inst.components.entitytracker:ForgetEntity("scantarget")
    end

    inst._scantime = nil

    inst.components.timer:StopTimer(TOP_LIGHT_FLASH_TIMERNAME)

    if status == "fail" then
        inst._showringfx:set(2)
    elseif status == "succeed" then
        inst._showringfx:set(3)
    else
        inst._showringfx:set(0)
    end

    inst.AnimState:Hide("top_light")
    inst.AnimState:Hide("bottom_light")

    inst:StopScanFX()
end
local function DoTurnOff(inst)
    if not inst._turned_off then
        inst:stoploopingsound()

        inst._turned_off = true

        inst:StopBrain()
        inst:SetBrain(nil)
    end
end
local function findleader(inst)
    local x,y,z=inst.Transform:GetWorldPosition()
    if inst.components.follower.leader==nil then
        local ents = TheSim:FindEntities(x,y,z, 12)
        for i, v in ipairs(ents) do
            if v.prefab=="scanner_spawn" then
                inst.components.follower.leader=v
                break
            end
        end
    end
end
local function OnReturnedAfterSuccessfulScan(inst)
    inst.sg:GoToState("scan_success")
end
local function OnExplodeFn(inst)
    local explosive = SpawnPrefab("laser_explosion")
    explosive.Transform:SetPosition(inst.Transform:GetWorldPosition())
end

--[[local function onsave(inst,data)
    data.base = inst.components.follower.leader or nil
end

local function onload(inst,data)
    inst.components.follower.leader=data.base or nil
end]]

local function OnKilled(inst)
    inst:DoTaskInTime(1,explode)
end

local function scannerfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    MakeTinyFlyingCharacterPhysics(inst, 1, 0.5)

    inst.Transform:SetFourFaced()


    inst.DynamicShadow:SetSize(1.2, 0.75)

    inst:AddTag("NOBLOCK")
    inst:AddTag("hostile")
    inst:AddTag("chess")

    inst.AnimState:SetBank("scanner")
    inst.AnimState:SetBuild("wx_scanner")
    inst.AnimState:PlayAnimation("idle",true)
    inst.AnimState:SetAddColour(0,0,0,0.2)
    inst.AnimState:SetMultColour(104/255, 34/255, 139/255,0.4)


    inst.AnimState:Hide("top_light")
    inst.AnimState:Hide("bottom_light")


    inst._showringfx = net_tinybyte(inst.GUID, "showringfx", "OnShowRingFXDirty")
    if not TheNet:IsDedicated() then
        inst:ListenForEvent("OnShowRingFXDirty", OnShowRingFXDirty)
    end
    inst._showringfx:set_local(0)


    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    -------------------------------------------------------------------
    inst:AddComponent("entitytracker")

    -------------------------------------------------------------------
    inst:AddComponent("follower")
    -------------------------------------------------------------------
    inst:AddComponent("locomotor")
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { allowocean = true, ignorecreep = true }
    inst.components.locomotor.walkspeed = 8

    -------------------------------------------------------------------
    inst:AddComponent("timer")
    ----------------------------------------------------------------
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(200)

    inst:AddComponent("combat")
    -------------------------------------------------------------------
    inst:AddComponent("updatelooper")

    -------------------------------------------------------------------
    inst:AddComponent("explosive")
    inst.components.explosive:SetOnExplodeFn(OnExplodeFn)
    inst.components.explosive.explosiverange = 6
    inst.components.explosive.explosivedamage = 50

    -----------
    inst:ListenForEvent("timerdone", on_scanner_timer_done)
    inst:ListenForEvent("onremove", stop_looping_sound)

    -------------------------------------------------------------------
    inst.startloopingsound = start_looping_sound
    inst.stoploopingsound = stop_looping_sound
    inst:startloopingsound()

    -------------------------------------------------------------------
    inst.StartScanFX = StartScanFX
    inst.StopScanFX = StopScanFX

    inst.StopAllScanning = StopAllScanning
    inst.IsInRangeOfBase = IsInRangeOfBase
    inst.OnSuccessfulScan = OnSuccessfulScan
    inst.OnScanFailed = OnScanFailed
    inst.OnReturnedAfterSuccessfulScan = OnReturnedAfterSuccessfulScan

    inst.LoopFn = scanner_loop_fn

    inst.TryFindTarget = TryFindTarget
    inst.DoTurnOff = DoTurnOff

    MakeTinyFreezableCharacter(inst)
    inst.components.freezable:SetResistance(3)

    -------------------------------------------------------------------
    -- For an "onremove" when scan targets get deleted out from under us.
    inst._OnScanTargetRemoved = function(t)
        OnScanFailed(inst)
    end

    -------------------------------------------------------------------
    inst:SetStateGraph("SGancient_scanner")
    inst:SetBrain(brain)
    --inst.OnSave=onsave
    --inst.OnLoad=onload
    -------------------------------------------------------------------

    inst.components.timer:StartTimer("startproximityscan", 0.5)
    inst:DoTaskInTime(0,findleader)
    inst:ListenForEvent("freeze",explode)
    inst:ListenForEvent("death", OnKilled)
    return inst
end


return Prefab("ancient_scanner", scannerfn, assets,prefabs)