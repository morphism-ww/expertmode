AddPrefabPostInit("cave",function(inst)
    if not TheNet:GetIsServer() then return end
    inst:AddComponent("ancient_defender")
end)

AddPrefabPostInit("forest",function(inst)
    if not TheNet:GetIsServer() then return end
    inst:AddComponent("firerain_manager")
    inst:AddComponent("lunarthrall_queen_spawner")
end)