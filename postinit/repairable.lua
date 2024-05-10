AddPrefabPostInit("purebrilliance",function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst:AddComponent("repairer")
	inst.components.repairer.repairmaterial = "pure"
	inst.components.repairer.finiteusesrepairvalue = 10
end)

AddPrefabPostInit("ice",function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst.components.repairer.finiteusesrepairvalue = 20
end)