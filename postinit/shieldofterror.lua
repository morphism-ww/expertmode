local function onequip(inst,owner)
	inst._oldonequipfn(inst,owner)
	owner:AddTag("stun_immune")
end

local function onunequip(inst,owner)
	inst._oldunequipfn(inst,owner)
	owner:RemoveTag("stun_immune")
end

newcs_env.AddPrefabPostInit("shieldofterror",function(inst)
    inst:AddTag("heavyarmor")
	if not TheWorld.ismastersim then
		return inst
	end
	inst._oldonequipfn=inst.components.equippable.onequipfn
	inst._oldunequipfn=inst.components.equippable.onunequipfn
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
end)