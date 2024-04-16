local function onequip_2(inst,data)
	data.owner:AddTag("stun_immune")
end

local function onunequip_2(inst,data)
	data.owner:RemoveTag("stun_immune")
end

AddPrefabPostInit("armordreadstone",function(inst)
	inst:AddTag("heavyarmor")
	if not TheWorld.ismastersim then
		return inst
	end
	inst:ListenForEvent("equipped",onequip_2)
    inst:ListenForEvent("unequipped",onunequip_2)
	
end)