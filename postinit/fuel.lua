AddPrefabPostInit("purebrilliance",function(inst)
    if not TheWorld.ismastersim then return end
    inst:AddComponent("fuel")
    inst.components.fuel.fueltype = FUELTYPE.PURE
    inst.components.fuel.fuelvalue = 3*TUNING.HUGE_FUEL
end)

AddPrefabPostInit("moonglass_charged",function(inst)
    if not TheWorld.ismastersim then return end
    inst:AddComponent("fuel")
    inst.components.fuel.fueltype = FUELTYPE.PURE
    inst.components.fuel.fuelvalue = TUNING.HUGE_LARGE
end)


AddPrefabPostInit("lunarplant_husk",function(inst)
    if not TheWorld.ismastersim then return end
    inst:AddComponent("fuel")
    inst.components.fuel.fueltype = FUELTYPE.PURE
    inst.components.fuel.fuelvalue = 2*TUNING.HUGE_FUEL
end)




