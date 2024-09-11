--[[local function ForceDarkWorld(inst,state)
    inst:PushEvent("world_lightcontrol",state)
	inst.ForceDark = state
	--inst:PushEvent("overrideambientlighting", state and Point(0, 0, 0) or nil)
end]]    

AddPrefabPostInit("cave",function(inst)
   
    if not TheNet:GetIsServer() then return end

    inst:AddComponent("ancient_defender")
    inst:AddComponent("voidland_manager")
    inst:AddComponent("abysshand_spawner")
end)

AddPrefabPostInit("forest",function(inst)

    if not TheNet:GetIsServer() then return end

    inst:AddComponent("firerain_manager")
    inst:AddComponent("lunarthrall_queen_spawner")
end)