AddPrefabPostInit("armor_ruins", function(inst)
	inst:AddTag("poison_immune")
	if not TheWorld.ismastersim then
		return inst
	end
	inst.components.equippable.dapperness = TUNING.DAPPERNESS_LARGE
end)