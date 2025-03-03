require("worldsettingsutil")
local assets =
    {
        Asset("ANIM", "anim/nightmare_crack_upper.zip"),
    }
local prefabs =
{
	"nightmarebeak",
	"crawlingnightmare",
	"nightmarefissurefx",
}	

local MAX_LIGHT_ON_FRAME = 10
local MAX_LIGHT_OFF_FRAME = 5
local build = "nightmare_crack_upper"


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

local function CreateMiasma(inst)
    local miasmamanager = TheWorld.components.miasmamanager
    if miasmamanager then
        local x, y, z = inst.Transform:GetWorldPosition()

		miasmamanager:CreateMiasmaAtPoint(x - TILE_SCALE, 0, z - TILE_SCALE)
		miasmamanager:CreateMiasmaAtPoint(x, 0, z - TILE_SCALE)
		miasmamanager:CreateMiasmaAtPoint(x + TILE_SCALE, 0, z - TILE_SCALE)
		miasmamanager:CreateMiasmaAtPoint(x - TILE_SCALE, 0, z)
		miasmamanager:CreateMiasmaAtPoint(x + TILE_SCALE, 0, z)
		miasmamanager:CreateMiasmaAtPoint(x - TILE_SCALE, 0, z + TILE_SCALE)
		miasmamanager:CreateMiasmaAtPoint(x, 0, z + TILE_SCALE)
		miasmamanager:CreateMiasmaAtPoint(x + TILE_SCALE, 0, z + TILE_SCALE)
    end
end

local function OnChildSpawned(inst, child)
    child:OnSpawnedBy(inst)
end


local function OnPreLoad(inst, data)
    WorldSettings_ChildSpawner_PreLoad(inst, data, TUNING.ABYSS_FISSURE.REGEN_TIME, TUNING.ABYSS_FISSURE.SPAWN_TIME)
end

local function onloadpostpass(inst, newents, data)
	if inst.components.workable.workleft == 0 then
		inst:MakeFinish(true)
	end
end


local function MakeFissure(inst)
	if not (inst:IsAsleep() or inst.SoundEmitter:PlayingSound("loop")) then
		inst.SoundEmitter:PlaySound("dontstarve/cave/nightmare_fissure_open_LP", "loop")
	end

	fade_to(inst, 3, false)
	inst.Light:SetColour(1, 0.3, 0.15)

	inst.fx.AnimState:SetMultColour(1, 0.7, 0.7, 1)
end


local function Grow(inst)
    ChangeToObstaclePhysics(inst)

	inst.components.workable:SetWorkLeft(TUNING.FISSURE_DREADSTONE_WORK)
    inst.components.workable:SetWorkable(true)

    inst.AnimState:PlayAnimation("idle_open_rift", true)
	inst.AnimState:ShowSymbol("stack_under")
    inst.AnimState:ShowSymbol("stack_over")
    inst.AnimState:ShowSymbol("stack_red")
	if not inst.components.inspectable then
        inst:AddComponent("inspectable")
    end
    --inst.components.childspawner:StartRegen()
	inst:DoTaskInTime(FRAMES,CreateMiasma)
end

local function ontimerdonefn(inst, data)
	if data.name=="growth" then
		inst.components.worldsettingstimer:StopTimer("growth")
		Grow(inst)
	end
end

local function returnchildren(inst)
    for k, child in pairs(inst.components.childspawner.childrenoutside) do
        if child._on_portal_removed~=nil then
            child._on_portal_removed()
        end
    end
end

local function killchildren(inst)
    if inst.components.childspawner ~= nil then
        inst.components.childspawner:StopSpawning()
        returnchildren(inst)
    end
end

local function MakeFinish(inst,onload)
    RemovePhysicsColliders(inst)

    inst.components.workable:SetWorkable(false)

    inst.SoundEmitter:KillSound("loop")

	if inst.components.inspectable then
        inst:RemoveComponent("inspectable")
    end

    if onload then
        inst.AnimState:PlayAnimation("idle_closed")
        inst.fx.AnimState:PlayAnimation("idle_closed")
    else
        inst.AnimState:PushAnimation("close_1")
        inst.fx.AnimState:PushAnimation("close_1")
        -- calm
        inst.AnimState:PushAnimation("close_2")
        inst.AnimState:PushAnimation("idle_closed", false)
        inst.fx.AnimState:PushAnimation("close_2")
        inst.fx.AnimState:PushAnimation("idle_closed", false)
    end
    --inst:SetPrefabNameOverride(nil)
    inst.AnimState:HideSymbol("stack_under")
    inst.AnimState:HideSymbol("stack_over")
    inst.AnimState:HideSymbol("stack_red")

    killchildren(inst)
    --inst.components.childspawner:StopRegen()
end

local function ShouldRecoil(inst,worker, tool, numworks)
    if not (worker ~= nil and worker:HasTag("toughworker")) and
		not (tool ~= nil and tool.components.tool ~= nil and tool.components.tool:CanDoToughWork())
		then
		return true, 0
	end
    if worker.isplayer and worker.sg and worker.sg.statemem.action==nil then
        return true, 0
    end
	return false, numworks
end


local function OnFissureMinedFinished(inst, worker)
	inst:MakeFinish()
    local pt = inst:GetPosition()
    for i = 1, 2 do
        inst.components.lootdropper:SpawnLootPrefab("dreadstone", pt)
    end
    inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/fossilized_break")

	local time = TUNING.ABYSS_GROWTH_FREQUENCY + math.random() * TUNING.ABYSS_GROWTH_FREQUENCY_VARIANCE

	inst.components.worldsettingstimer:StartTimer("growth", time)
end

local function CreateTerraformBlocker(parent)
    local inst = CreateEntity()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()

    inst:SetTerraformExtraSpacing(16)

    return inst
end


local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddLight()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, 1)

	inst.AnimState:SetBuild("nightmare_crack_upper")
	inst.AnimState:SetBank("nightmare_crack_upper")
	inst.AnimState:PlayAnimation("idle_open_rift", true)
	
	inst.AnimState:SetSymbolLightOverride("crack01", .5)
	inst.AnimState:SetSymbolLightOverride("fx_beam", 1)
	inst.AnimState:SetSymbolLightOverride("fx_spiral", 1)
	inst.AnimState:SetSymbolLightOverride("stack_red", 1)
	inst.AnimState:SetFinalOffset(1) --on top of spawned .fx

	inst.Light:SetRadius(0)
	inst.Light:SetIntensity(.9)
	inst.Light:SetFalloff(.9)
	inst.Light:SetColour(239/255, 194/255, 194/255)
	inst.Light:Enable(false)
	inst.Light:EnableClientModulation(true)

	inst._lightframe = net_smallbyte(inst.GUID, "fissure._lightframe", "lightdirty")
	inst._lightradius0 = net_tinybyte(inst.GUID, "fissure._lightradius0", "lightdirty")
	inst._lightradius1 = net_tinybyte(inst.GUID, "fissure._lightradius1", "lightdirty")
	inst._lightmaxframe = MAX_LIGHT_OFF_FRAME
	inst._lightframe:set(inst._lightmaxframe)
	inst._lighttask = nil
	
	local blocker = CreateTerraformBlocker(inst)
    blocker.entity:SetParent(inst.entity)

    inst:SetPrefabNameOverride("dreadstone_stack")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst:ListenForEvent("lightdirty", OnLightDirty)

		return inst
	end


	inst.fx = SpawnPrefab("nightmarefissurefx")
	inst.fx.entity:SetParent(inst.entity)

	inst:AddComponent("childspawner")
	inst.components.childspawner:SetRegenPeriod(TUNING.ABYSS_FISSURE.REGEN_TIME)
	inst.components.childspawner:SetSpawnPeriod(TUNING.ABYSS_FISSURE.SPAWN_TIME)
	inst.components.childspawner:SetMaxChildren(3)
	inst.components.childspawner:SetSpawnedFn(OnChildSpawned)
	WorldSettings_ChildSpawner_SpawnPeriod(inst, TUNING.ABYSS_FISSURE.SPAWN_TIME, true)
	WorldSettings_ChildSpawner_RegenPeriod(inst, TUNING.ABYSS_FISSURE.REGEN_TIME, true)
	inst.components.childspawner.childname = "abyss_leech"
	inst.components.childspawner:SetRareChild("fused_shadeling", .4)


	inst.components.childspawner:StartSpawning()
    inst.components.childspawner:StartRegen()
	inst.components.childspawner.childreninside = 2


	inst:AddComponent("lootdropper")

	local workable = inst:AddComponent("workable")
	workable:SetWorkAction(ACTIONS.MINE)
	workable:SetOnFinishCallback(OnFissureMinedFinished)
	workable:SetMaxWork(TUNING.FISSURE_DREADSTONE_WORK)
	workable:SetWorkLeft(TUNING.FISSURE_DREADSTONE_WORK)
	workable:SetRequiresToughWork(true)
    workable:SetShouldRecoilFn(ShouldRecoil)
	workable.savestate = true
	
	--inst:AddComponent("worldsettingstimer")  --already in worldsettings_childspawner
	local maxtime = TUNING.ABYSS_GROWTH_FREQUENCY + TUNING.ABYSS_GROWTH_FREQUENCY_VARIANCE
	inst.components.worldsettingstimer:AddTimer("growth", maxtime, true)
	inst:ListenForEvent("timerdone", ontimerdonefn)

	--inst.OnEntityWake = OnEntityWake
	--inst.OnEntitySleep = OnEntitySleep

	
	inst.MakeFinish = MakeFinish
	inst.OnPreLoad = OnPreLoad
	inst.OnLoadPostPass = onloadpostpass

	MakeFissure(inst)
	Grow(inst)

	return inst
end


local assets2 =
{
    Asset("ANIM", "anim/nightmaregrowth.zip"),
}

local prefabs2 =
{
    "nightmaregrowth_crack",
	"collapse_big"
}

local DESTROY_ON_GROW_TAGS = { "structure", "tree", "boulder" }


local GROW_SOUND_DELAY = 9*FRAMES

local function SpawnCrack(inst)
    local x, y, z = inst.Transform:GetWorldPosition()

    local ents = TheSim:FindEntities(x, y, z, 4, nil, nil, DESTROY_ON_GROW_TAGS)
    for i, v in ipairs(ents) do
        if v:IsValid() and v.components.workable ~= nil and v.components.workable:CanBeWorked() then
            SpawnPrefab("collapse_small").Transform:SetPosition(v.Transform:GetWorldPosition())
            v.components.workable:Destroy(inst)
        end
    end

    if inst._crack == nil or not inst._crack:IsValid() then
        inst._crack = SpawnPrefab("nightmaregrowth_crack")
        inst._crack.Transform:SetPosition(x, y, z)

        if inst._crack_rotation ~= nil then
            inst._crack.Transform:SetRotation(inst._crack_rotation)
            inst._crack_rotation = nil
        end
    end
end

local function PlayGrowSound(inst)
    inst.SoundEmitter:PlaySound("grotto/common/nightmare_growth/grow")
end

local function grow(inst)
    inst.AnimState:PlayAnimation("grow")
    inst.AnimState:PushAnimation("idle", false)

    SpawnCrack(inst)

    inst._crack.AnimState:PlayAnimation("crack")
    inst._crack.AnimState:PushAnimation("crack_idle", false)

    inst.SoundEmitter:PlaySound("grotto/common/nightmare_growth/crack")
    inst:DoTaskInTime(GROW_SOUND_DELAY, PlayGrowSound)
end

local function AlwaysRecoil(inst,worker, tool, numworks)
	if worker ~= nil and worker:HasTag("supertoughworker") or (tool~=nil and tool:HasTag("supertoughworker")) then
        if worker.isplayer and worker.sg and worker.sg.statemem.action==nil then
            return true, 0
        end
        return false
	end
    
	return true,0
end

local function OnNightmaregrowthMinedFinished(inst)
	local pt = inst:GetPosition()
	
	inst.components.lootdropper:SpawnLootPrefab("dreadstone", pt)
	inst.components.lootdropper:SpawnLootPrefab("horrorfuel", pt)
    
    inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/fossilized_break")
	local fx = SpawnPrefab("collapse_big")
	fx.Transform:SetPosition(pt.x, pt.y, pt.z)
    if math.random()<0.7 then
        SpawnAt(math.random() < .6 and "nightmarebeak" or "ruinsnightmare", inst)
    end
	
	inst:Remove()
end

local function OnRemove(inst)
    if inst._crack ~= nil and inst._crack:IsValid() then
        inst._crack:Remove()
    end
end

local function OnSave(inst, data)
    if inst._crack ~= nil and inst._crack:IsValid() then
        data.crack_rotation = inst._crack.Transform:GetRotation()
    end
end

local function OnLoad(inst, data)
    if data ~= nil and data.crack_rotation ~= nil then
        inst._crack_rotation = data.crack_rotation
    end
end

local function fn2()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    --inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("nightmaregrowth")
    inst.AnimState:SetBank("nightmaregrowth")
    inst.AnimState:PlayAnimation("idle")

    --inst.MiniMapEntity:SetIcon("nightmaregrowth.png")

    MakeObstaclePhysics(inst, 1.1, 4)

    --inst.Transform:SetScale(1.5,1.5,1.5)
    inst:AddTag("magic_blocker")
    --inst:SetGroundTargetBlockerRadius(14)

	inst:SetPrefabNameOverride("nightmaregrowth")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -- inst._crack = nil
    -- inst._crack_rotation = nil

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_SUPERHUGE

    inst:AddComponent("inspectable")

	inst:AddComponent("lootdropper")

	local workable = inst:AddComponent("workable")
	workable:SetWorkAction(ACTIONS.MINE)
	workable:SetOnFinishCallback(OnNightmaregrowthMinedFinished)
	workable:SetMaxWork(20)
	workable:SetWorkLeft(20)
	workable:SetRequiresToughWork(true)
	workable:SetShouldRecoilFn(AlwaysRecoil)


    inst.growfn = grow

    inst:DoTaskInTime(0, SpawnCrack)

    inst:ListenForEvent("onremove", OnRemove)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end

local function spawnerfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    --[[Non-networked entity]]

    
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:DoTaskInTime(0, inst.Remove)

    return inst
end


return Prefab("fissure_abyss", fn, assets, prefabs),
	Prefab("nightmaregrowth_abyss",fn2, assets2,prefabs2),
    Prefab("nightmaregrowth_abyss_spawner",spawnerfn)
