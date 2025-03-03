local assets =
{
	Asset("ANIM", "anim/aurumite_mine.zip"),
}

local worktimes = 30

local function RemoveSpark(inst)
    if inst.sparktask~=nil then
        inst.sparktask:Cancel()
        inst.sparktask = nil
    end
end

local function MakeFull(inst)
    inst:RemoveTag("NOCLICK")
    inst.Light:Enable(true)
    ChangeToObstaclePhysics(inst,0.5)
    inst.AnimState:PlayAnimation("full")
    
    inst:AddComponent("inspectable")
    
    inst.components.workable:SetWorkable(true)
    inst.components.workable:SetWorkLeft(worktimes)
    
    if inst.entity:IsAwake() then
        inst:OnEntityWake()
    end

    inst.workstage = 2
    inst.workstageprevious = inst.workstage
end

local function MakeEmpty(inst)
    inst:AddTag("NOCLICK")
    inst:RemoveTag("blocker")
    inst.Light:Enable(false)
    RemovePhysicsColliders(inst)
    inst.AnimState:PlayAnimation("empty")
    inst:RemoveComponent("inspectable")
    inst.components.workable:SetWorkable(false)
    RemoveSpark(inst)
end



local function OnWork(inst, worker, workleft)
    inst.workstage = (workleft > 10 and 2)
    or (workleft > 0 and 1)
    or 0
    if inst.workstage<inst.workstageprevious then
        inst.workstageprevious = inst.workstage

        local fx = SpawnPrefab("dreadstone_spawn_fx")
        fx.entity:SetParent(inst.entity)
        local pt = inst:GetPosition()

        if inst.workstage == 1 then
            inst.AnimState:PlayAnimation("med")
            inst.components.lootdropper:SpawnLootPrefab("dreadstone",pt)
            inst.components.lootdropper:SpawnLootPrefab("aurumite",pt)
        elseif inst.workstage == 0 then
            if math.random()<0.6 then
                inst.components.lootdropper:SpawnLootPrefab("aurumite",pt)
            end
            inst.components.lootdropper:SpawnLootPrefab("aurumite",pt)
            local growth_time = TUNING.ABYSS_GROWTH_FREQUENCY + math.random() * TUNING.ABYSS_GROWTH_FREQUENCY_VARIANCE
            inst.components.worldsettingstimer:StartTimer("growth", growth_time)
            MakeEmpty(inst)
        end
    end
end

local function ShouldRecoil(inst, worker, tool, numworks)
    numworks = math.min(numworks,10)
    if worker.isplayer and worker.sg and worker.sg.statemem.action==nil then
        return true,0
    end
	if inst.components.workable:GetWorkLeft() > math.max(1, numworks) and
		not (worker ~= nil and worker:HasTag("explosive")) and
		not (tool ~= nil and tool:HasTag("supertoughworker"))
		then
        
		local chance = 0.35-0.05*numworks
		if math.random()<chance then
			return true, numworks * .1 --recoil and only do a tiny bit of work
		end
	end
	return false, numworks
end

local function ontimerdonefn(inst, data)
	if data.name=="growth" then
		inst.components.worldsettingstimer:StopTimer("growth")
		MakeFull(inst)
	end
end

local function DoPluse(inst)
    inst.charge = inst.charge + 1


    inst.AnimState:SetSymbolLightOverride("shine", 0.04*inst.charge)
    local rad = Lerp(0, 4, inst.charge/16)
    inst.Light:SetRadius(rad)

    if inst.charge >=10 then
        inst.charge = 0
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
end

local function OnLoadPostPass(inst)
    local workleft = inst.components.workable:GetWorkLeft()
    inst.workstage = (workleft > 10 and 2)
    or (workleft > 0 and 1)
    or 0
    inst.workstageprevious = inst.workstage
    if inst.workstage == 1 then
        inst.AnimState:PlayAnimation("med")
    elseif inst.workstage == 0 then
        MakeEmpty(inst)
    end
end

local function OnEntitySleep(inst)
	RemoveSpark(inst)
end

local function OnEntityWake(inst)
	if inst.components.workable:GetWorkLeft()>0 then
		inst.sparktask = inst:DoPeriodicTask(1,DoPluse,2*math.random())
	end
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddLight()

    
    inst.AnimState:SetBuild("aurumite_mine")
    inst.AnimState:SetBank("aurumite_mine")
    inst.AnimState:PlayAnimation("full")
    inst.AnimState:SetSymbolBloom("shine")
	inst.AnimState:SetSymbolLightOverride("shine", .5)


    inst.Light:SetRadius(0)
    inst.Light:SetIntensity(.6)
    inst.Light:SetFalloff(.6)
    inst.Light:SetColour(1,215/255,0)
    inst.Light:Enable(true)
    --inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    MakeObstaclePhysics(inst, 0.5)

    inst:AddTag("laser_immune")
	
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.charge = 0
    inst.workstage = 2
    inst.workstageprevious = inst.workstage

    local workable = inst:AddComponent("workable")
	workable:SetWorkAction(ACTIONS.MINE)
    workable:SetOnWorkCallback(OnWork)
	workable:SetMaxWork(worktimes)
	workable:SetWorkLeft(worktimes)
	workable:SetRequiresToughWork(true)
    workable:SetShouldRecoilFn(ShouldRecoil)
	workable.savestate = true

    inst:AddComponent("worldsettingstimer")  --already in worldsettings_childspawner
	local maxtime = TUNING.ABYSS_GROWTH_FREQUENCY + TUNING.ABYSS_GROWTH_FREQUENCY_VARIANCE
	inst.components.worldsettingstimer:AddTimer("growth", maxtime, true)
    inst:ListenForEvent("timerdone", ontimerdonefn)

    inst:AddComponent("lootdropper")
    inst:AddComponent("inspectable")

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_TINY)

    inst.OnLoadPostPass = OnLoadPostPass
    inst.OnEntitySleep = OnEntitySleep
	inst.OnEntityWake = OnEntityWake
    

    return inst
end



return Prefab("aurumite_mine", fn, assets)