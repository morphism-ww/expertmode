AddPrefabPostInit("cave",function(inst)
   
    inst:AddComponent("ancient_defender")
    inst:AddComponent("voidland_manager")
    inst:AddComponent("abysshand_spawner")
    inst:AddComponent("retrofitmap_temp")

end)

AddPrefabPostInit("forest",function(inst)

    inst:AddComponent("firerain_manager")
    inst:AddComponent("lunarthrall_queen_spawner")
end)