local assets =
{
	Asset("ANIM", "anim/thunderbird_nest.zip"),
}

local prefabs =
{
    "cs_iron",
}

local worktimes = 12



local function DoSpark(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    for i, v in ipairs(AllPlayers) do
        if v.entity:IsVisible() and v:GetDistanceSqToPoint(x, y, z) < 36 then
            v.components.playerlightningtarget:DoStrike()
        end
    end
    local spark = SpawnPrefab("electricchargedfx")
	spark.Transform:SetPosition(x, 0, z)
    spark.Transform:SetScale(1.4,1.4,1.4)
end

local function RemoveSpark(inst)
    if inst.sparktask~=nil then
        inst.sparktask:Cancel()
        inst.sparktask = nil
    end
end


local function CheckSparkTask(inst)
    if inst.components.workable.workleft == 0 then
        RemoveSpark(inst)
    elseif inst.sparktask==nil and inst.entity:IsAwake() then
        inst.sparktask = inst:DoPeriodicTask(2,DoSpark)
    end    
end

local function OnMinedFinished(inst, worker)
	inst.AnimState:PlayAnimation("nest")
    local pt = inst:GetPosition()
    inst.components.lootdropper:SpawnLootPrefab("cs_iron",pt)
    local time = TUNING.ABYSS_GROWTH_FREQUENCY + math.random() * TUNING.ABYSS_GROWTH_FREQUENCY_VARIANCE

    CheckSparkTask(inst)
	inst.components.worldsettingstimer:StartTimer("growth", time)
end

local function Grow(inst)
	inst.AnimState:PlayAnimation("orenest")
    inst.components.workable:SetWorkLeft(worktimes)
    CheckSparkTask(inst)
end

local function ontimerdonefn(inst, data)
	if data.name=="growth" then
		inst.components.worldsettingstimer:StopTimer("growth")
		Grow(inst)
	end
end

local function onloadpostpass(inst, newents, data)
	if inst.components.workable.workleft == 0 then
		inst.AnimState:PlayAnimation("nest")
	end
end


local function OnSleepTask(inst)
	inst.sleeptask = nil
	RemoveSpark(inst)
end

local function OnEntitySleep(inst)
	if inst.sleeptask == nil then
		inst.sleeptask = inst:DoTaskInTime(1, OnSleepTask)
	end
end

local function OnEntityWake(inst)
	if inst.sleeptask ~= nil then
		inst.sleeptask:Cancel()
		inst.sleeptask = nil
	else
		CheckSparkTask(inst)
	end
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    
    inst.AnimState:SetBuild("thunderbird_nest")
    inst.AnimState:SetBank("thunderbird_nest")
    inst.AnimState:PlayAnimation("orenest")

    MakeObstaclePhysics(inst, 0.3)

    inst:AddTag("laser_immune")
	
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    local workable = inst:AddComponent("workable")
	workable:SetWorkAction(ACTIONS.MINE)
	workable:SetOnFinishCallback(OnMinedFinished)
	workable:SetMaxWork(worktimes)
	workable:SetWorkLeft(worktimes)
	workable:SetRequiresToughWork(true)
	workable.savestate = true

    inst:AddComponent("worldsettingstimer")  --already in worldsettings_childspawner
	local maxtime = TUNING.ABYSS_GROWTH_FREQUENCY + TUNING.ABYSS_GROWTH_FREQUENCY_VARIANCE
	inst.components.worldsettingstimer:AddTimer("growth", maxtime, true)
	inst:ListenForEvent("timerdone", ontimerdonefn)

    inst:AddComponent("lootdropper")
    inst:AddComponent("inspectable")

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)
    
    inst:DoTaskInTime(0.1,CheckSparkTask)
    
	inst.OnLoadPostPass = onloadpostpass
    inst.OnEntitySleep = OnEntitySleep
	inst.OnEntityWake = OnEntityWake

    return inst
end

return Prefab("iron_mine", fn, assets, prefabs)