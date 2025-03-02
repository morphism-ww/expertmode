require("worldsettingsutil")

local assets =
{
    Asset("ANIM", "anim/spider_mound.zip"),
}

local prefabs =
{
    "spider_hider",
    "spider_spitter",

    --loot
    "rocks",
    "silk",
    "spidergland",
    "silk",
    "fossil_piece",

    --fx
    "rock_break_fx",
}

SetSharedLootTable('hostedspider_hole',
{
    {'rocks',       1.00},
    {'rocks',       1.00},
    {'silk',        1.00},
    {'fossil_piece',1.00},
    {'fossil_piece',0.50},
    {'dreadstone', 0.5},
    {'dreadstone', 0.5},
    {'dreadstone', 0.25},
    {'silk',        0.50},
})


local function rock_onworked(inst, worker, workleft)
    if workleft <= 0 then
        local pos = inst:GetPosition()
        SpawnPrefab("rock_break_fx").Transform:SetPosition(pos:Get())
        inst.components.lootdropper:DropLoot(pos)
        inst:Remove()
    else
        inst.AnimState:PlayAnimation(workleft <= TUNING.SPILAGMITE_ROCK * 0.5 and "low" or "med")
    end
end

local function GoToBrokenState(inst)
    --Remove myself, spawn a rock version in my place.
    SpawnPrefab("spiderhole_rock").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:Remove()
end

local function IsInvestigator(child)
    return child.components.knownlocations:GetLocation("investigate") ~= nil
end

local function SpawnInvestigators(inst, data)
    if not inst.components.health:IsDead() and inst.components.childspawner ~= nil then
        local num_to_release = math.min(2, inst.components.childspawner.childreninside)
        local num_investigators = inst.components.childspawner:CountChildrenOutside(IsInvestigator)
        num_to_release = num_to_release - num_investigators
        local targetpos = data ~= nil and data.target ~= nil and data.target:GetPosition() or nil

        for _ = 1, num_to_release do
            local spider = inst.components.childspawner:SpawnChild()
            if spider ~= nil and targetpos ~= nil then
                spider.components.knownlocations:RememberLocation("investigate", targetpos)
            end
        end
    end
end

local function SummonChildren(inst, data)
    if inst.components.health and not inst.components.health:IsDead() then
        if inst.components.childspawner ~= nil then
            local children_released = inst.components.childspawner:ReleaseAllChildren()

            for i,v in ipairs(children_released) do
                v:AddDebuff("spider_summoned_buff", "spider_summoned_buff")
            end
        end
    end
end

local function spawner_onworked(inst, worker, workleft)
    if inst.components.childspawner ~= nil then
        inst.components.childspawner:ReleaseAllChildren(worker)
    end
end

local function OnGoHome(inst, child)
    -- Drops the hat before it goes home if it has any
    local hat = child.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    if hat ~= nil then
        child.components.inventory:DropItem(hat)
    end
end

local function commonfn(anim, tag, hascreep)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()

    inst.entity:AddNetwork()

    if hascreep then
        inst.entity:AddGroundCreepEntity()
        inst.GroundCreepEntity:SetRadius(5)
    end

    MakeObstaclePhysics(inst, 2)

    inst.AnimState:SetBank("spider_mound")
    inst.AnimState:SetBuild("spider_mound")
    inst.AnimState:PlayAnimation(anim)


    inst:AddTag("cavedweller")
    if tag ~= nil then
        inst:AddTag(tag)
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")
    inst:AddComponent("workable")

    inst.SummonChildren = SummonChildren

    return inst
end

local function OnSpawn(inst,child)
    local manager = TheWorld.components.shadowparasitemanager
    if manager == nil then
        return
    end
    manager:AddParasiteToHost(child)
end


local function OnPreLoad(inst, data)
    WorldSettings_ChildSpawner_PreLoad(inst, data, TUNING.SPIDERHOLE_RELEASE_TIME, TUNING.SPIDERHOLE_REGEN_TIME)
end

local function spawnerfn()
    local inst = commonfn("full", "spiderden", true)

    inst:SetPrefabNameOverride("spiderhole")


    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("health")

    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetWorkLeft(TUNING.SPILAGMITE_SPAWNER)
    inst.components.workable:SetOnWorkCallback(spawner_onworked)
    inst.components.workable:SetOnFinishCallback(GoToBrokenState)

    inst:AddComponent("childspawner")
    inst.components.childspawner:SetRegenPeriod(TUNING.SPIDERHOLE_REGEN_TIME)
    inst.components.childspawner:SetSpawnPeriod(TUNING.SPIDERHOLE_RELEASE_TIME)
    inst.components.childspawner:SetGoHomeFn(OnGoHome)
    inst.components.childspawner:SetSpawnedFn(OnSpawn)

    WorldSettings_ChildSpawner_SpawnPeriod(inst, TUNING.SPIDERHOLE_RELEASE_TIME, TUNING.SPIDERHOLE_ENABLED)
    WorldSettings_ChildSpawner_RegenPeriod(inst, TUNING.SPIDERHOLE_REGEN_TIME, TUNING.SPIDERHOLE_ENABLED)
    inst.components.childspawner:SetMaxChildren(math.random(TUNING.SPIDERHOLE_MIN_CHILDREN, TUNING.SPIDERHOLE_MAX_CHILDREN))

    inst.components.childspawner:StartRegen()
    inst.components.childspawner.childname = "spider_hider"
    inst.components.childspawner:SetRareChild("spider_spitter", TUNING.SPIDERHOLE_SPITTER_CHANCE)
    inst.components.childspawner.emergencychildname = TUNING.SPIDERHOLE_SPITTER_CHANCE > 0 and "spider_spitter" or "spider_hider"
    inst.components.childspawner.emergencychildrenperplayer = 1
    inst.components.childspawner.canemergencyspawn = TUNING.SPIDERHOLE_ENABLED
    inst.components.childspawner:StartSpawning()

    inst:ListenForEvent("creepactivate", SpawnInvestigators)

    MakeHauntableWork(inst)

    inst.OnPreLoad = OnPreLoad

    return inst
end

local function rockfn()
    local inst = commonfn("med")

    inst:SetPrefabNameOverride("spiderhole")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.scrapbook_anim = "full"

    inst.components.workable:SetWorkAction(ACTIONS.MINE)
    inst.components.workable:SetOnWorkCallback(rock_onworked)
    inst.components.workable:SetWorkLeft(TUNING.SPILAGMITE_ROCK)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('spider_hole')

    MakeHauntableWork(inst)

    return inst
end

return Prefab("hosted_spiderhole", spawnerfn, assets, prefabs),
    Prefab("hosted_spiderhole_rock", rockfn, assets, prefabs)
