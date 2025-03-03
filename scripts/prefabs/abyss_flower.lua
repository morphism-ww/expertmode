require "prefabutil"

local assets=
{
	Asset("ANIM", "anim/lifeplant.zip"),
}

local prefabs =
{
    "cs_waterdrop"
}


local function dig_up(inst)
    if not inst.planted then
        inst.components.lootdropper:SpawnLootPrefab("cs_waterdrop")
    end
	inst:Remove()
end

local function manageidle(inst)
	inst.AnimState:PlayAnimation(math.random() < 0.5  and "idle_gargle" or "idle_vanity")
	inst.AnimState:PushAnimation("idle_loop",false)
end



local function OnActivateResurrection(inst, guy)
    inst.components.cooldown:StartCharging()
    inst.AnimState:PlayAnimation("idle_gargle", false)
    if inst.components.hauntable ~= nil then
        inst:RemoveComponent("hauntable")
    end
end

local function OnCharged(inst)
    inst.AnimState:PlayAnimation("idle_vanity")
    inst.AnimState:PushAnimation("idle_loop", false)
    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_INSTANT_REZ)
end

local function OnSave(inst,data)
    data.planted = inst.planted
end

local function OnLoad(inst,data)
    inst.planted = data and data.planted
end

local function fn()
	local inst = CreateEntity()
	
    inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()
    
    --MakeObstaclePhysics(inst, .3)
    
    inst.AnimState:SetBank("lifeplant")
    inst.AnimState:SetBuild("lifeplant")
    inst.AnimState:PlayAnimation("idle_loop")
    inst.AnimState:SetMultColour(0.9,0.9,0.9,1)	
    inst.AnimState:SetLightOverride(0.2)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh" )
    inst.AnimState:SetScale(1.5,1.5,1.5)
			

    inst:AddTag("plant")
    inst:AddTag("resurrector")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end
    
    inst:AddComponent("inspectable")
	
    inst:AddComponent("lootdropper")
    
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.DIG)
    inst.components.workable:SetWorkLeft(1)
	inst.components.workable:SetOnFinishCallback(dig_up)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = TUNING.SANITYAURA_LARGE

    
	
	
    inst:DoPeriodicTask(8+20*math.random(),manageidle)
    --[[inst:AddComponent("cooldown")
    inst.components.cooldown.cooldown_duration = 30
    inst.components.cooldown.onchargedfn = OnCharged
    inst.components.cooldown.charged = true]]

    inst:AddComponent("hauntable")
    inst.components.hauntable:SetHauntValue(TUNING.HAUNT_INSTANT_REZ)

    --inst:ListenForEvent("activateresurrection", OnActivateResurrection)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    --inst:DoTaskInTime(0.5,CheckForPlanted)
    return inst
end

local dropassets =
{
	Asset("ANIM", "anim/waterdrop.zip"),
    Asset("ANIM", "anim/lifeplant.zip"),
}

local function oneat(inst, eater)
    local debuffable = eater.components.debuffable
    if debuffable~=nil then
        for k, v in pairs(debuffable.debuffs) do
            if v.inst.newcs_debuff then
                debuffable:RemoveDebuff(k)
            end
        end
    end
end

local function ondeploy (inst, pt) 
    local plant = SpawnPrefab("abyss_flower")
    plant.Transform:SetPosition(pt:Get())
    plant.AnimState:PlayAnimation("grow")
    plant.AnimState:PushAnimation("idle_loop")
    plant.planted = true
    inst:Remove()
end



local function dropfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    

    inst.AnimState:SetBank("waterdrop")
    inst.AnimState:SetBuild("waterdrop")
    inst.AnimState:PlayAnimation("idle")
	
    inst:AddTag("waterdrop")	

    MakeInventoryFloatable(inst)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end	
    inst:AddComponent("inspectable")

    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(TUNING.PERISH_SLOW)
    inst.components.perishable:StartPerishing()
    inst.components.perishable:SetOnPerishFn(inst.Remove)

    inst:AddComponent("edible")
    inst.components.edible.foodtype = FOODTYPE.GOODIES  
    inst.components.edible.healthvalue = TUNING.HEALING_SUPERHUGE * 3
    inst.components.edible.hungervalue = TUNING.CALORIES_SUPERHUGE * 3
    inst.components.edible.sanityvalue = TUNING.SANITY_HUGE * 3   
    inst.components.edible:SetOnEatenFn(oneat)

    inst:AddComponent("inventoryitem")
    
    inst:AddComponent("deployable")
    inst.components.deployable:SetDeployMode(DEPLOYMODE.PLANT)
    inst.components.deployable.ondeploy = ondeploy    

    return inst
end

local regenprefabs = {"abyss_flower"}

local function TrackFlower(inst,flower)
    local function onremove()
        inst.flower = nil
        inst.components.worldsettingstimer:StartTimer("regen",TUNING.ABYSS_FLOWER_REGROWTH)
    end
    inst.flower = flower
    inst:ListenForEvent("onremove", onremove, flower)
end

local function spawnflower(inst)
    local flower = SpawnPrefab("abyss_flower")
    flower.Transform:SetPosition(inst.Transform:GetWorldPosition())
    TrackFlower(inst,flower)
end


local function OnSave(inst,data)
    if inst.flower then
        data.flower = inst.flower.GUID
        return {inst.flower.GUID}
    end
end

local function OnLoadPostPass(inst,newents, savedata)
    if savedata~=nil and savedata.flower then
        local flower = newents[savedata.flower]
        if flower~=nil then
            TrackFlower(inst,flower.entity)
        end
    end
end

local function spawnerfn()
    local inst = CreateEntity()

	inst.entity:AddTransform()
    --[[Non-networked entity]]

    inst:AddTag("CLASSIFIED")

    inst:AddComponent("worldsettingstimer")
    inst.components.worldsettingstimer:AddTimer("regen", TUNING.ABYSS_FLOWER_REGROWTH, true)

    inst.OnSave = OnSave
    inst.OnLoadPostPass = OnLoadPostPass

    inst:ListenForEvent("timerdone",spawnflower)

    return inst
end

local function worldspawnerfn()
    local inst = spawnerfn()
    inst:SetPrefabName("abyss_flower_spawner")

    inst:DoTaskInTime(0,spawnflower)

    return inst
end


return Prefab("abyss_flower", fn, assets, prefabs),
    Prefab("cs_waterdrop",dropfn,dropassets),
    Prefab("abyss_flower_spawner",spawnerfn,nil,regenprefabs),
    Prefab("abyss_flower_spawner_worldgen",worldspawnerfn,nil,regenprefabs),
    MakePlacer("cs_waterdrop_placer", "lifeplant", "lifeplant", "idle_loop")
