local ICE_COLOUR = { 148/255, 0, 211/255 }

local function OnUpdateFade(inst)
    local k
    if inst._fade:value() <= inst._fadeframes then
        inst._fade:set_local(math.min(inst._fade:value() + inst._fadeinspeed, inst._fadeframes))
        k = inst._fade:value() / inst._fadeframes
    else
        inst._fade:set_local(math.min(inst._fade:value() + inst._fadeoutspeed, inst._fadeframes * 2 + 1))
        k = (inst._fadeframes * 2 + 1 - inst._fade:value()) / inst._fadeframes
    end

    inst.Light:SetIntensity(inst._fadeintensity * k)
    inst.Light:SetRadius(inst._faderadius * k)
    inst.Light:SetFalloff(1 - (1 - inst._fadefalloff) * k)

    if TheWorld.ismastersim then
        inst.Light:Enable(inst._fade:value() > 0 and inst._fade:value() <= inst._fadeframes * 2)
    end

    if inst._fade:value() == inst._fadeframes or inst._fade:value() > inst._fadeframes * 2 then
        inst._fadetask:Cancel()
        inst._fadetask = nil
    end
end

local function OnFadeDirty(inst)
    if inst._fadetask == nil then
        inst._fadetask = inst:DoPeriodicTask(FRAMES, OnUpdateFade)
    end
    OnUpdateFade(inst)
end

local function FadeOut(inst)
    inst._fade:set(inst._fadeframes + 1)
    if inst._fadetask == nil then
        inst._fadetask = inst:DoPeriodicTask(FRAMES, OnUpdateFade)
    end
end

local function OnFXKilled(inst)
    if inst.fxcount > 0 then
        inst.fxcount = inst.fxcount - 1
    else
        inst:Remove()
    end
end



local function KillFX(inst, anim)
    if not inst.killed then
        if inst.OnKillFX ~= nil then
            inst:OnKillFX(anim)
        end
        inst.killed = true
        inst.AnimState:PlayAnimation(anim or "pst")
        inst:DoTaskInTime(inst.AnimState:GetCurrentAnimationLength() + .25, inst.fx ~= nil and OnFXKilled or inst.Remove)
        if inst.task ~= nil then
            inst.task:Cancel()
            inst.task = nil
        end
        if inst._fade ~= nil then
            FadeOut(inst)
        end
    end
end

--------------------------------------------------------------------------

local RANDOM_SEGS = 8
local SEG_ANGLE = 360 / RANDOM_SEGS
local ANGLE_VARIANCE = SEG_ANGLE * 2 / 3
local function GetRandomAngle(inst)
    if inst.angles == nil then
        inst.angles = {}
        local offset = math.random() * 360
        for i = 0, RANDOM_SEGS - 1 do
            table.insert(inst.angles, offset + i * SEG_ANGLE)
        end
    end
    local rnd = math.random()
    rnd = rnd * rnd
    local angle = table.remove(inst.angles, math.max(1, math.ceil(rnd * rnd * RANDOM_SEGS)))
    table.insert(inst.angles, angle)
    return (angle + math.random() * ANGLE_VARIANCE) * DEGREES
end
local function TriggerFX(inst)
    local x,y,z=inst.Transform:GetWorldPosition()
    for i=1,3 do
        local soul = SpawnPrefab("klaus_soul_spawn")
        local theta = GetRandomAngle(inst)
        local rad = GetRandomMinMax(1, 4)
        soul.Transform:SetPosition(x + rad * math.cos(theta), 0, z + rad * math.sin(theta))
    end
end


-------------------------------------------------------------------------

local ICE_CIRCLE_RADIUS = 3
local NOTAGS = { "playerghost", "INLIMBO", "flight", "invisible","deergemresistance","deer" }


local FREEZETARGET_ONEOF_TAGS = { "locomotor", "character","monster"}
local function OnUpdateIceCircle(inst, x, z)
    local tick=false
    inst._rad:set(inst._rad:value() * .98 + ICE_CIRCLE_RADIUS * .02)
    
    inst._track1 = inst._track2 or {}
    inst._track2 = {}
    inst.burstdelay = (inst.burstdelay or 6) - 1
    if inst.burstdelay < 0 then
        inst.burstdelay = math.random(5, 6)
        tick=true
    end
    for i, v in ipairs(TheSim:FindEntities(x, 0, z, inst._rad:value(), nil, NOTAGS, FREEZETARGET_ONEOF_TAGS)) do
        if v:IsValid() and not (v.components.health ~= nil and v.components.health:IsDead()) then
            if v.components.locomotor ~= nil then
                v.components.locomotor:PushTempGroundSpeedMultiplier(0.3)
            end
            if tick and v.components.sanity ~= nil then
                v.components.sanity:DoDelta(-5)
            end
            if tick and v.components.mightiness~=nil then
                v.components.mightiness:DoDelta(-3)
            end
            if v.components.grogginess ~= nil and not v.components.grogginess:IsKnockedOut() then
                local curgrog = v.components.grogginess.grog_amount
                if curgrog < TUNING.DEER_ICE_FATIGUE then
                    v.components.grogginess:AddGrogginess(TUNING.DEER_ICE_FATIGUE)
                end
            end
        end
    end
end

local function OnUpdateIceCircleClient(inst, x, z)
    local rad = inst._rad:value()
    if rad > 0 then
        local player = ThePlayer
        if player ~= nil and
            player.components.locomotor ~= nil and
            not player:HasTag("playerghost") and
            player:GetDistanceSqToPoint(x, 0, z) < rad * rad then
            player.components.locomotor:PushTempGroundSpeedMultiplier(TUNING.DEER_ICE_SPEED_PENALTY)
        end
    end
end

local function OnInitIceCircleClient(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    inst:DoPeriodicTask(0, OnUpdateIceCircleClient, nil, x, z)
    OnUpdateIceCircleClient(inst, x, z)
end

local function OnInitIceCircle(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    inst._rad:set(.25)
    inst.task = inst:DoPeriodicTask(0, OnUpdateIceCircle, nil, x, z)
    OnUpdateIceCircle(inst, x, z)
end

local function OnAnimOverIceCircle(inst)
    inst.SoundEmitter:KillSound("loop")
end

local function deer_ice_circle_common_postinit(inst)

    inst._rad = net_float(inst.GUID, "deer_ice_circle._rad")

    if not TheWorld.ismastersim then
        inst:DoTaskInTime(0, OnInitIceCircleClient)
    end
end

local function deer_ice_circle_master_postinit(inst)
    inst.task = inst:DoTaskInTime(0, OnInitIceCircle)
    inst:ListenForEvent("animover", OnAnimOverIceCircle)
end

local function deer_ice_circle_onkillfx(inst, anim)
    inst._rad:set(0)
end

--------------------------------------------------------------------------

local function MakeFX(name, data)
    local assets =
    {
        Asset("ANIM", "anim/deer_ice_circle.zip"),
    }

    local prefabs = {}
    if data.fxprefabs ~= nil then
        for i, v in ipairs(data.fxprefabs) do
            table.insert(prefabs, v)
        end
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        if data.sound ~= nil or data.soundloop ~= nil then
            inst.entity:AddSoundEmitter()
        end
        inst.entity:AddNetwork()

        inst.AnimState:SetBank("deer_ice_circle")
        inst.AnimState:SetBuild("deer_ice_circle")
        inst.AnimState:PlayAnimation(data.oneshotanim or "pre")
        inst.AnimState:SetLightOverride(1)
        inst.AnimState:SetFinalOffset(1)
        inst.AnimState:SetMultColour(138/255,43/255,226/255,0.6)
        if data.bloom then
            inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        end

        if data.onground then
            inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
            inst.AnimState:SetLayer(LAYER_BACKGROUND)
            inst.AnimState:SetSortOrder(3)
        end

        if data.soundloop ~= nil then
            inst.SoundEmitter:PlaySound(data.soundloop, "loop")
        end

        if data.light then
            if data.onground then
                inst._fadeframes = 30
                inst._fadeintensity = .8
                inst._faderadius = 3
                inst._fadefalloff = .9
                inst._fadeinspeed = 1
                inst._fadeoutspeed = 2
            else
                inst._fadeframes = 15
                inst._fadeintensity = .8
                inst._faderadius = 2
                inst._fadefalloff = .7
                inst._fadeinspeed = 3
                inst._fadeoutspeed = 1
            end

            inst.entity:AddLight()
            inst.Light:SetColour(unpack(data.light))
            inst.Light:SetRadius(inst._faderadius)
            inst.Light:SetFalloff(inst._fadefalloff)
            inst.Light:SetIntensity(inst._fadeintensity)
            inst.Light:Enable(false)
            inst.Light:EnableClientModulation(true)

            inst._fade = net_smallbyte(inst.GUID, "deer_fx._fade", "fadedirty")

            inst._fadetask = inst:DoPeriodicTask(FRAMES, OnUpdateFade)
        end

        inst:AddTag("FX")

        if data.common_postinit ~= nil then
            data.common_postinit(inst)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            if data.light then
                inst:ListenForEvent("fadedirty", OnFadeDirty)
            end

            return inst
        end

        inst.persists = false

        if data.sound ~= nil then
            inst.SoundEmitter:PlaySound(data.sound)
        end

        inst.fxprefabs = data.fxprefabs
        inst.TriggerFX = TriggerFX


        if data.looping then
            inst.AnimState:PushAnimation("loop")
        end

        inst.KillFX = KillFX
        inst.OnKillFX = data.onkillfx

        if data.master_postinit ~= nil then
            data.master_postinit(inst)
        end

        return inst
    end

    return Prefab(name, fn, assets, #prefabs > 0 and prefabs or nil)
end

return     --
MakeFX("deer_soul_circle", {
    light = ICE_COLOUR,
    onground = true,
    soundloop = "dontstarve/creatures/together/deer/fx/ice_circle_LP",
    fxprefabs = { "deer_fire_flakes" },
    common_postinit = deer_ice_circle_common_postinit,
    master_postinit = deer_ice_circle_master_postinit,
    onkillfx = deer_ice_circle_onkillfx,
})
