AddPrefabPostInit("dragonflyfurnace",function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst:AddComponent("prototyper")
	inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.OBSIDIAN_TWO
end)

AddPrefabPostInit("lava_pond",function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst:AddComponent("prototyper")
	inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.OBSIDIAN_ONE
end)