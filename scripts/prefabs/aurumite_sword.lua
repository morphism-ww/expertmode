local assets =
{
	Asset("ANIM", "anim/sword_aurumite.zip"),
}

local function SetFxOwner(inst, owner)
	if inst._fxowner ~= nil and inst._fxowner.components.colouradder ~= nil then
		inst._fxowner.components.colouradder:DetachChild(inst.blade1)
		inst._fxowner.components.colouradder:DetachChild(inst.blade2)
	end
	inst._fxowner = owner
	if owner ~= nil then
		inst.blade1.entity:SetParent(owner.entity)
		inst.blade2.entity:SetParent(owner.entity)
		inst.blade1.Follower:FollowSymbol(owner.GUID, "swap_object", nil, nil, nil, true, nil, 0, 3)
		inst.blade2.Follower:FollowSymbol(owner.GUID, "swap_object", nil, nil, nil, true, nil, 5, 8)
		inst.blade1.components.highlightchild:SetOwner(owner)
		inst.blade2.components.highlightchild:SetOwner(owner)
		if owner.components.colouradder ~= nil then
			owner.components.colouradder:AttachChild(inst.blade1)
			owner.components.colouradder:AttachChild(inst.blade2)
		end
	else
		inst.blade1.entity:SetParent(inst.entity)
		inst.blade2.entity:SetParent(inst.entity)
		--For floating
		inst.blade1.Follower:FollowSymbol(inst.GUID, "swap_spear", nil, nil, nil, true, nil, 0, 3)
		inst.blade2.Follower:FollowSymbol(inst.GUID, "swap_spear", nil, nil, nil, true, nil, 5, 8)
		inst.blade1.components.highlightchild:SetOwner(inst)
		inst.blade2.components.highlightchild:SetOwner(inst)
	end
end

local function onequip(inst, owner)

    owner.AnimState:ClearOverrideSymbol("swap_object")
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
	SetFxOwner(inst, owner)

end

local function onunequip(inst, owner)
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
	local skin_build = inst:GetSkinBuild()
	if skin_build ~= nil then
		owner:PushEvent("unequipskinneditem", inst:GetSkinName())
	end
	SetFxOwner(inst, nil)

end



local function SetupComponents(inst)
	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("sword_aurumite")
	inst.AnimState:SetBuild("sword_aurumite")
	inst.AnimState:PlayAnimation("idle_x1")
    inst.AnimState:SetSymbolBloom("jsg")
    inst.AnimState:SetSymbolBloom("jtg")
    inst.AnimState:SetSymbolBloom("hs")
	inst.AnimState:SetSymbolLightOverride("jsg", .5)
    inst.AnimState:SetSymbolLightOverride("jtg", .5)
	inst.AnimState:SetLightOverride(.1)

	inst:AddTag("sharp")
	inst:AddTag("show_broken_ui")

	--weapon (from weapon component) added to pristine state for optimization
	inst:AddTag("weapon")

	inst:AddComponent("floater")


	inst.entity:SetPristine()

	if not TheWorld.ismastersim then


		return inst
	end

	local frame = math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1
	inst.AnimState:SetFrame(frame)
	inst.blade1 = SpawnPrefab("sword_aurumite_blade_fx")
	inst.blade2 = SpawnPrefab("sword_aurumite_blade_fx")
	inst.blade2.AnimState:PlayAnimation("swap_x1_loop1", true)
	inst.blade1.AnimState:SetFrame(frame)
	inst.blade2.AnimState:SetFrame(frame)
	SetFxOwner(inst, nil)

	-------
	local finiteuses = inst:AddComponent("finiteuses")
	finiteuses:SetMaxUses(TUNING.SWORD_LUNARPLANT_USES)
	finiteuses:SetUses(TUNING.SWORD_LUNARPLANT_USES)

	-------
	

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")

	SetupComponents(inst)

	MakeHauntableLaunch(inst)

	return inst
end

local function fxfn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddFollower()
	inst.entity:AddNetwork()

	inst:AddTag("FX")

	inst.AnimState:SetBank("sword_aurumite")
	inst.AnimState:SetBuild("sword_aurumite")
	inst.AnimState:PlayAnimation("swap_x1_loop1", true)
	inst.AnimState:SetSymbolBloom("jsg")
    inst.AnimState:SetSymbolBloom("jtg")
    inst.AnimState:SetSymbolBloom("hs")
	inst.AnimState:SetSymbolLightOverride("jsg", .5)
    inst.AnimState:SetSymbolLightOverride("jtg", .5)
	inst.AnimState:SetLightOverride(.1)

    inst.AnimState:SetScale(2,2,2)

	inst:AddComponent("highlightchild")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("colouradder")

	inst.persists = false

	return inst
end

return Prefab("sword_aurumite",fn,assets),
    Prefab("sword_aurumite_blade_fx",fxfn)