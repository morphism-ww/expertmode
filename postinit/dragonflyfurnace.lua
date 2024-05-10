local function OnUpgrade(inst)
	inst.components.upgradeable.upgradetype = nil

    inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.OBSIDIAN_THREE
	inst.SoundEmitter:PlaySound("dontstarve/common/together/dragonfly_furnace/place")
	inst.AnimState:PlayAnimation("incinerate")
    inst.AnimState:PushAnimation("hi", true)
end


local function OnLoad(inst, data)
    if inst.components.upgradeable ~= nil and inst.components.upgradeable.numupgrades > 0 then
        inst:OnUpgrade(inst)
    end
end


AddPrefabPostInit("dragonflyfurnace",function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	local upgradeable = inst:AddComponent("upgradeable")
    upgradeable.upgradetype = UPGRADETYPES.IRON_SOUL
    upgradeable:SetOnUpgradeFn(OnUpgrade)

	inst:AddComponent("prototyper")
	inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.OBSIDIAN_TWO

	inst.OnUpgrade=OnUpgrade

	inst.OnLoad=OnLoad
end)

AddPrefabPostInit("lava_pond",function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst:AddComponent("prototyper")
	inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.OBSIDIAN_ONE
end)