local fns = {}


fns.CreateAbilityCooldown = function (inst,cd_map)
	inst:AddComponent("timer")
	inst.StartAbility = function(inst, ability)
		inst.components.timer:StartTimer(ability, cd_map[ability])
	end
	inst.AbleAbility = function (inst,ability)
		return not inst.components.timer:TimerExists(ability)
	end
end


fns.CreateInventoryItem = function(name,anim_data,common_postinit,master_postinit,assets,prefabs)
	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()

		inst.AnimState:SetBank(anim_data.bank)
		inst.AnimState:SetBuild(anim_data.build)
		inst.AnimState:PlayAnimation(anim_data.anim,anim_data.loop)
		--inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

		MakeInventoryPhysics(inst)

		if common_postinit then
			common_postinit(inst)
		end

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		inst:AddComponent("inspectable")

    	inst:AddComponent("inventoryitem")

		if master_postinit then
			master_postinit(inst)
		end

		MakeHauntableLaunch(inst)

		return inst
	end
	return Prefab(name,fn,assets,prefabs)
end

return fns