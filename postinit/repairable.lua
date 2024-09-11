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

AddPrefabPostInit("redgem",function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst.components.repairer.finiteusesrepairvalue = 80
end)

AddPrefabPostInit("bluegem",function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst.components.repairer.finiteusesrepairvalue = 80
end)

AddPrefabPostInit("gears",function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst.components.repairer.finiteusesrepairvalue = 100
end)

AddPrefabPostInit("wagpunk_bits",function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst.components.repairer.finiteusesrepairvalue = 150
end)