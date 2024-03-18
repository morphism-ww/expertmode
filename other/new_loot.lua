--local LootTables=GLOBAL.LootTables

AddPrefabPostInit("ruins_statue_head",function(inst)
    if not TheWorld.ismastersim then return end

    inst.components.lootdropper:AddChanceLoot("thulecite", 1)
end)

AddPrefabPostInit("ruins_statue_head_nogem",function(inst)
    if not TheWorld.ismastersim then return end

    inst.components.lootdropper:AddChanceLoot("thulecite", 1)
end)

AddPrefabPostInit("ruins_statue_mage",function(inst)
    if not TheWorld.ismastersim then return end

    inst.components.lootdropper:AddChanceLoot("thulecite", 1)
end)

AddPrefabPostInit("ruins_statue_mage_nogem",function(inst)
    if not TheWorld.ismastersim then return end

    inst.components.lootdropper:AddChanceLoot("thulecite", 1)
end)

AddPrefabPostInit("walrus",function(inst)
    if not TheWorld.ismastersim then return end

    inst.components.lootdropper:AddChanceLoot("walrus_tusk", 1)
end)

AddPrefabPostInit("daywalker_pillar",function(inst)
    if not TheWorld.ismastersim then return end

    inst.components.lootdropper:AddChanceLoot("dreadstone", 1)
    inst.components.lootdropper:AddChanceLoot("dreadstone", 1)
end)