newcs_env.AddSimPostInit(function ()

    local function LootTableAdd(name,prefab,count)
        table.insert(LootTables[name],{prefab,count})
    end

    LootTableAdd('lightninggoat','lightninggoathorn',0.50)
    LootTableAdd('chargedlightninggoat','lightninggoathorn',0.50)
    LootTableAdd("walrus","walrus_tusk",0.50)
    LootTableAdd("eyeofterror","shieldofterror",1.00)

    SetSharedLootTable("twinofterror1",
    {
        {"yellowgem",       1.00},
        {"yellowgem",       1.00},
        {"yellowgem",       1.00},
        {"yellowgem",       0.50},
        {"gears",           1.00},
        {"gears",           1.00},
        {"gears",           0.50},
        {"purebrilliance",  1.00},
        {"purebrilliance",  1.00},
        {"purebrilliance",  1.00},
        {"purebrilliance",  0.75},
        {"aurumite",         1.00},
        {"aurumite",         0.50},
    })
    SetSharedLootTable("twinofterror2",
    {
        {"greengem",        1.00},
        {"greengem",        1.00},
        {"greengem",        1.00},
        {"greengem",        0.50},
        {"gears",           1.00},
        {"gears",           1.00},
        {"gears",           0.50},
        {"purebrilliance",  1.00},
        {"purebrilliance",  1.00},
        {"purebrilliance",  1.00},
        {"purebrilliance",  0.75},
        {"aurumite",         1.00},
        {"aurumite",         0.50},
    })
end)

local StartOld = Start
Start = function ()
    local ban_list = {"thurible","terrariumchest","dock_kit",}
    local mod = ModManager:GetMod("workshop-2886753796")
    if mod~=nil then
        local PrefabPostInitFns = mod.postinitfns["PrefabPostInit"]
        if PrefabPostInitFns then
            for _,id in ipairs(ban_list) do
                PrefabPostInitFns[id] = nil
            end
        end
    end
    StartOld()
end