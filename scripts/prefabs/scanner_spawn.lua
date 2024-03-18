require("worldsettingsutil")
local prefabs =
{
    "ancient_scanner",
}

local function OnPreLoad(inst, data)
    WorldSettings_ChildSpawner_PreLoad(inst, data, TUNING.SPIDERDEN_RELEASE_TIME, TUNING.SPIDERDEN_REGEN_TIME)
end
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst:AddTag("NOCLICK")


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -------------------
    inst:AddComponent("childspawner")
    inst.components.childspawner.childname = "ancient_scanner"
    inst.components.childspawner:SetRegenPeriod(TUNING.TOTAL_DAY_TIME)
    inst.components.childspawner:SetSpawnPeriod(10)
    inst.components.childspawner:SetMaxChildren(2)
    WorldSettings_ChildSpawner_SpawnPeriod(inst, TUNING.SPIDERDEN_RELEASE_TIME, true)
    WorldSettings_ChildSpawner_RegenPeriod(inst, TUNING.SPIDERDEN_REGEN_TIME, true)
    --inst.components.childspawner:SetSpawnedFn( onspawnchild )

    inst.components.childspawner:StartSpawning()
    inst.components.childspawner:StartRegen()
    inst.components.childspawner.childreninside = 2

    inst.OnPreLoad = OnPreLoad
    return inst
end


return Prefab("scanner_spawn", fn, nil, prefabs)
