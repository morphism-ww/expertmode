local function OnUpgrade(inst)
	inst.components.upgradeable.upgradetype = nil

    inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.OBSIDIAN_TWO

	inst.SoundEmitter:PlaySound("dontstarve/common/together/dragonfly_furnace/place")
	inst.AnimState:PlayAnimation("incinerate")
    inst.AnimState:PushAnimation("hi", true)
end


local function OnLoad(inst, data)
    if inst.components.upgradeable ~= nil and inst.components.upgradeable.numupgrades > 0 then
        OnUpgrade(inst)
    end
end


newcs_env.AddPrefabPostInit("dragonflyfurnace",function(inst)
	local upgradeable = inst:AddComponent("upgradeable")
    upgradeable.upgradetype = UPGRADETYPES.IRON_SOUL
    upgradeable:SetOnUpgradeFn(OnUpgrade)

	inst:AddComponent("prototyper")
	inst.components.prototyper.trees = TUNING.PROTOTYPER_TREES.OBSIDIAN_ONE

	inst.OnLoad = OnLoad
end)