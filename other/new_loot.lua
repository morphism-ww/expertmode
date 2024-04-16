--local LootTables=GLOBAL.LootTables
local function SetGemmed(inst, gem)
    inst.gemmed = gem
    inst.AnimState:OverrideSymbol("swap_gem", inst.small and "statue_ruins_small_gem" or "statue_ruins_gem", gem)
    inst.components.lootdropper:SetLoot({ "thulecite","thulecite", gem })
    inst.components.lootdropper:AddChanceLoot("thulecite", .2)
end

AddPrefabPostInit("ruins_statue_head",function(inst)
    if not TheWorld.ismastersim then return end
    debug.setupvalue(inst.OnLoad,1,SetGemmed)
end)

AddPrefabPostInit("walrus",function(inst)
    if not TheWorld.ismastersim then return end

    inst.components.lootdropper:AddChanceLoot("walrus_tusk", 1)
end)

AddPrefabPostInit("lightninggoat",function(inst)
    if not TheWorld.ismastersim then return end

    inst.components.lootdropper:AddChanceLoot("lightninggoathorn", 0.75)
end)


AddPrefabPostInit("daywalker_pillar",function(inst)
    if not TheWorld.ismastersim then return end

    inst.components.lootdropper:AddChanceLoot("dreadstone", 1)
    inst.components.lootdropper:AddChanceLoot("dreadstone", 1)
end)