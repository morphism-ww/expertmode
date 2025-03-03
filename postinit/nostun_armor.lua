newcs_env.AddPrefabPostInit("armordreadstone",function(inst)

	inst:AddTag("heavyarmor")

	if not TheWorld.ismastersim then
		return inst
	end
	
	MakeStunProtectArmor(inst)
end)

newcs_env.AddPrefabPostInit("shieldofterror",function(inst)

	inst:AddTag("heavyarmor")

	if not TheWorld.ismastersim then
		return inst
	end

	MakeStunProtectArmor(inst)
end)
