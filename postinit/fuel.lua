newcs_env.AddPrefabPostInit("purebrilliance",function(inst)

    inst:AddComponent("fuel")
    inst.components.fuel.fueltype = FUELTYPE.PURE
    inst.components.fuel.fuelvalue = 1.5*TUNING.HUGE_FUEL
end)

newcs_env.AddPrefabPostInit("moonglass_charged",function(inst)

    inst:AddComponent("fuel")
    inst.components.fuel.fueltype = FUELTYPE.PURE
    inst.components.fuel.fuelvalue = TUNING.HUGE_FUEL
end)


newcs_env.AddPrefabPostInit("lunarplant_husk",function(inst)

    inst:AddComponent("fuel")
    inst.components.fuel.fueltype = FUELTYPE.PURE
    inst.components.fuel.fuelvalue = TUNING.HUGE_FUEL
end)




