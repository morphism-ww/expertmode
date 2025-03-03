newcs_env.AddPrefabPostInit("redgem",function(inst)

	inst.components.repairer.finiteusesrepairvalue = 80
end)

newcs_env.AddPrefabPostInit("greengem",function(inst)

	inst.components.repairer.finiteusesrepairvalue = 20
end)

newcs_env.AddPrefabPostInit("bluegem",function(inst)

	inst.components.repairer.finiteusesrepairvalue = 80
end)

newcs_env.AddPrefabPostInit("gears",function(inst)


	inst.components.repairer.finiteusesrepairvalue = 100
end)

newcs_env.AddPrefabPostInit("wagpunk_bits",function(inst)

	inst.components.repairer.finiteusesrepairvalue = 150
end)