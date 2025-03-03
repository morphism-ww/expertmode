local assets =
{
    Asset("ANIM", "anim/shadowrift_portal.zip"),
}
local AMBIENT_SOUND_STAGE_TO_INTENSITY = {0.1, 0.4, 0.7}
local AMBIENT_SOUND_PATH = "rifts2/shadow_rift/shadowrift_portal_allstage"
local AMBIENT_SOUND_LOOP_NAME = "shadowrift_portal_ambience"
local AMBIENT_SOUND_PARAM_NAME = "stage"

local function CreateParticleFx(inst)
    local fx = SpawnPrefab("shadowrift_portal_fx")
    inst:AddChild(fx)
    --fx:PlayStage(3, true)
    return fx
end


local function CreateMiasma(inst, initial)
    if inst:HasTag("INLIMBO") then
        return
    end
    local miasmamanager = TheWorld.components.miasmamanager
    if miasmamanager then
        local x, y, z = inst.Transform:GetWorldPosition()

        if initial then
            miasmamanager:CreateMiasmaAtPoint(x - TILE_SCALE, 0, z - TILE_SCALE)
            miasmamanager:CreateMiasmaAtPoint(x, 0, z - TILE_SCALE)
            miasmamanager:CreateMiasmaAtPoint(x + TILE_SCALE, 0, z - TILE_SCALE)
            miasmamanager:CreateMiasmaAtPoint(x - TILE_SCALE, 0, z)
            miasmamanager:CreateMiasmaAtPoint(x + TILE_SCALE, 0, z)
            miasmamanager:CreateMiasmaAtPoint(x - TILE_SCALE, 0, z + TILE_SCALE)
            miasmamanager:CreateMiasmaAtPoint(x, 0, z + TILE_SCALE)
            miasmamanager:CreateMiasmaAtPoint(x + TILE_SCALE, 0, z + TILE_SCALE)
        else
            local theta = math.random() * PI2
            local ox, oz = TILE_SCALE * math.cos(theta), TILE_SCALE * math.sin(theta)

            miasmamanager:CreateMiasmaAtPoint(x + ox, 0, z + oz)
        end
    end
end

local function OnPortalSleep(inst)
    inst.SoundEmitter:KillSound(AMBIENT_SOUND_LOOP_NAME)

    if inst._fx then
        inst._fx:Remove()
        inst._fx = nil
        inst.highlightchildren = nil
    end
end

local function OnPortalWake(inst)
    

    inst.SoundEmitter:PlaySound(AMBIENT_SOUND_PATH, AMBIENT_SOUND_LOOP_NAME)
    inst.SoundEmitter:SetParameter(AMBIENT_SOUND_LOOP_NAME, AMBIENT_SOUND_PARAM_NAME, AMBIENT_SOUND_STAGE_TO_INTENSITY[3])

    if not inst._fx then
        inst._fx = CreateParticleFx(inst)
        inst._fx:PlayStage(3, true)
        inst.highlightchildren = {inst._fx}
    end
end

local function OnRiftAddedToPool(inst, data)
    if data and data.rift ~= nil then
        inst:ReturnToScene()
        inst.AnimState:PlayAnimation("stage_3_pre")
        inst.AnimState:PushAnimation("stage_3_loop",true)
        inst.components.teleporter:SetEnabled(true)
        data.rift.components.teleporter:Target(inst)
        inst.components.teleporter:Target(data.rift)
        inst:DoTaskInTime(0,function ()
            inst:CreateMiasma(true)
        end)
        
    end
end

local function OnRiftClosed(inst)
    inst.components.teleporter:SetEnabled(false)
    inst.components.teleporter:Target(nil)
    inst.AnimState:PlayAnimation("disappear")
    inst:DoTaskInTime(0.2,function ()
        inst:RemoveFromScene()
    end)
end

local function SafeLeave(inst,doer)
    if doer.isplayer then
        doer.components.transformlimit:SetState(false)
    end
    --doer:RemoveDebuff("abyss_curse")
end

local function fn()
    
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 3.2)
    inst.Physics:SetCylinder(3.2, 6)


    local animstate = inst.AnimState
    animstate:SetBank ("shadowrift_portal")
    animstate:SetBuild("shadowrift_portal")
    --animstate:PlayAnimation("stage_3_pre")
    --animstate:PushAnimation("stage_3_loop", true)
    animstate:SetOrientation(ANIM_ORIENTATION.OnGroundFixed)
    animstate:SetLayer(LAYER_BACKGROUND)
    animstate:SetSortOrder(2)

	inst:SetDeploySmartRadius(3.5)

    inst.AnimState:SetSymbolLightOverride("fx_beam",   1)
    inst.AnimState:SetSymbolLightOverride("fx_spiral", 1)
    inst.AnimState:SetLightOverride(0.5)


    inst:AddTag("ignorewalkableplatforms")
    inst:AddTag("scarytoprey")
    inst:AddTag("shadowrift_portal")
    inst:AddTag("abyss_saveteleport")

    inst.entity:SetPristine()

    inst._fx = CreateParticleFx(inst)
    inst.highlightchildren = {inst._fx}    
    inst.highlightoverride = {0.15, 0, 0}
    inst:SetPrefabNameOverride("shadowrift_portal")
  
    if not TheWorld.ismastersim then
        return inst
    end


    inst:AddComponent("inspectable")

    inst:AddComponent("teleporter")
    inst.components.teleporter.offset = 8
    inst.components.teleporter:SetEnabled(false)
    inst.components.teleporter.onActivate = SafeLeave
    inst.components.teleporter.saveenabled = false
    -------------------

    --[[local childspawner = inst:AddComponent("childspawner")
    childspawner.childname = "dark_energy"
    childspawner:SetRegenPeriod(TUNING.ABYSS_RIFT_REPOWER)
    childspawner:SetSpawnPeriod(60)
    childspawner:SetMaxChildren(2)]]

    --
    inst.OnEntitySleep = OnPortalSleep
    inst.OnEntityWake = OnPortalWake

    inst.CreateMiasma = CreateMiasma

    --[[inst:DoTaskInTime(0, function (inst)
        inst:CreateMiasma(true)
    end)]]

    inst:RemoveFromScene()
    inst.OnRiftAddedToPool = function (world,data)
        OnRiftAddedToPool(inst,data)
    end
    inst.OnRiftClosed = function (world,data)
        OnRiftClosed(inst)
    end
    inst:ListenForEvent("ms_riftaddedtopool", inst.OnRiftAddedToPool, TheWorld)
    inst:ListenForEvent("ms_riftremovedfrompool", inst.OnRiftClosed, TheWorld)
   
    return inst
end

return Prefab("abyss_rift",fn,assets)