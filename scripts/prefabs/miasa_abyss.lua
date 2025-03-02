local TEXTURE = "fx/miasma.tex"
local SHADER = "shaders/vfx_particle.ksh"



local COLOUR_ENVELOPE_NAME = "miasma_cloud_colourenvelope_ab"
local SCALE_ENVELOPE_NAME = "miasma_cloud_scaleenvelope_ab"
local function InitEnvelopes()
    EnvelopeManager:AddColourEnvelope(
        COLOUR_ENVELOPE_NAME,
        {
            { 0,    { 139/255, 0, 0, 0.4 } },
            { .5,   { 139/255, 0, 0, 0.6 } },
            { 1,    { 139/255, 0, 0, 0.4 } },
        }
    )

    local max_scale = 5
    EnvelopeManager:AddVector2Envelope(
        SCALE_ENVELOPE_NAME,
        {
            { 0,    { 4, 4 } },
            { 1,    { max_scale, max_scale } },
        }
    )

    InitEnvelopes = nil
end

local MAX_LIFETIME = 12
local GROUND_HEIGHT = 0.3
local EMITTER_RADIUS = 25

local function fn()
    local inst = CreateEntity()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    if TheNet:GetIsClient() then
        inst.entity:AddClientSleepable()
    end

    inst.persists = false

    inst.entity:AddTransform()

    -----------------------------------------------------

    if InitEnvelopes ~= nil then
        InitEnvelopes()
    end

    local config =
    {
        texture = TEXTURE,
        shader = SHADER,
        max_num_particles = MAX_LIFETIME + 1,
        max_lifetime = MAX_LIFETIME,
        SV =
        {
            { x = -1, y = 0, z = 1 },
            { x = 1, y = 0, z = 1 },
        },
        sort_order = 2,
        colour_envelope_name = COLOUR_ENVELOPE_NAME,
        scale_envelope_name = SCALE_ENVELOPE_NAME
    }

    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters(1)
    effect:SetRenderResources(0, config.texture, config.shader)
    effect:SetMaxNumParticles(0, config.max_num_particles)
    effect:SetMaxLifetime(0, config.max_lifetime)
    --[[effect:SetSpawnVectors(0,
        config.SV[1].x, config.SV[1].y, config.SV[1].z,
        config.SV[2].x, config.SV[2].y, config.SV[2].z
    )]]
    effect:SetSortOffset(0, 0)
    --effect:SetUVFrameSize(0, 0.5, 1)
	--effect:SetBlendMode(0, BLENDMODE.AlphaBlended)
    effect:SetSortOrder(0, config.sort_order)
    effect:SetColourEnvelope(0, config.colour_envelope_name)
    effect:SetScaleEnvelope(0, config.scale_envelope_name)
    effect:SetRadius(0, EMITTER_RADIUS)

    -----------------------------------------------------

    inst:AddComponent("emitter")
    inst.components.emitter.config = config
    inst.components.emitter.max_lifetime = MAX_LIFETIME
    inst.components.emitter.ground_height = GROUND_HEIGHT
    inst.components.emitter.particles_per_tick = 1

    return inst
end

--[[local function spanerfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
    inst.entity:AddNetwork()

    
    inst.entity:SetPristine()

    inst:AddTag("NOBLOCK")
    inst:AddTag("CLASSIFIED")

    if not TheNet:IsDedicated() then
        inst:DoTaskInTime(0, function(inst)
            local x,y,z = inst.Transform:GetWorldPosition()
            local node = TheWorld.Map:FindVisualNodeAtPoint(x, y, z)
            if node~=nil and node.area_emitter == nil then
                if node.area == nil then
                    node.area = 1
                end
    
                local mist = SpawnPrefab("miasama_abyss_fx")
                mist.Transform:SetPosition(node.cent[1], 0, node.cent[2])
                mist.components.emitter.area_emitter = CreateAreaEmitter(node.poly, node.cent)

                local ext = ResetextentsForPoly(node.poly)
                mist.entity:SetAABB(ext.radius, 2)
                mist.components.emitter.density_factor = math.ceil(node.area / 8) / MAX_LIFETIME
                mist.components.emitter:Emit()
            end
        end)
    end
	

	return inst
end]]
local function SpawnRaindropAtXZ(inst, x, z)
	local raindrop = SpawnPrefab("acidraindrop")
	raindrop.Transform:SetPosition(x, 0, z)
end

local function CreateAcidFx(inst,x,z)
    local px, pz = inst.area_emitter()
    --[[if TheWorld.Map:IsPassableAtPoint(px, 0, pz) then
        SpawnRaindropAtXZ(inst, px,pz)
    end]]
    SpawnRaindropAtXZ(inst, px,pz)
    local x, z = inst.area_emitter()
    SpawnRaindropAtXZ(inst, x,z)
end

local function onentitysleep(inst)
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end
end

local function onentitywake(inst)
    inst:DoTaskInTime(0,function ()
         
         --[[local x,y,z = inst.Transform:GetWorldPosition()
         local node = TheWorld.Map:FindVisualNodeAtPoint(x, y, z)
        if inst.area_emitter==nil then
            inst.area_emitter = FindRandomPointInNode(node.poly, node.cent)
        end]]
        if inst.task == nil then
            inst.task = inst:DoPeriodicTask(FRAMES,CreateAcidFx)
        end
    end)
end


local function spawnerfn()
    local inst = CreateEntity()
	inst:AddTag("FX")
    --[[Non-networked entity]]
    if TheNet:GetIsClient() then
        inst.entity:AddClientSleepable()
    end

    inst.persists = false

    inst.entity:AddTransform()
    
    
    --inst.acid_fx = SpawnPrefab("caveacidrain")
    --inst.acid_fx.entity:SetParent(inst.entity)

    inst.OnEntitySleep = onentitysleep
    inst.OnEntityWake = onentitywake

    return inst
end

return Prefab("miasama_abyss_fx",fn),
    Prefab("local_acid_spawner",spawnerfn)
    --Prefab("mist_spawner", spanerfn) 