local assets =
{
   Asset("ANIM", "anim/abigail_shield.zip"),
}

local function buff_OnAttached(inst, target)
    target:AddTag("lunar_protect")
	--target:AddTag("stun_immune")
	if target.components.stunprotecter == nil then
        target:AddComponent("stunprotecter")
    end
    target.components.stunprotecter:AddSource(inst)
	if target.components.health ~= nil then
	    target.components.health.externalabsorbmodifiers:SetModifier(inst, 0.8, "lunar_protect")
	end

	inst.entity:SetParent(target.entity)
	inst.Transform:SetPosition(0, -1, 0)

    inst:ListenForEvent("death", function()
        inst.components.debuff:Stop()
    end, target)
	--local fx = SpawnPrefab("ghostlyelixir_shield_fx")
	--fx.entity:SetParent(target.entity)
end

local function buff_OnDetached(inst, target)
	if target ~= nil and target:IsValid() then
		target:RemoveTag("lunar_protect")
		if target.components.stunprotecter ~= nil then
			target.components.stunprotecter:RemoveSource(inst)
		end
	end
    inst:Remove()
end

local function expire(inst)
	inst.components.debuff:Stop()
end

local function fn(anim)
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("abigail_shield")
	inst.AnimState:SetBuild("abigail_shield")
	inst.AnimState:PlayAnimation(anim)
    inst.AnimState:SetFinalOffset(1)
	inst.AnimState:SetMultColour(0,191/255,1,0.5)

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("debuff")
	inst.components.debuff:SetAttachedFn(buff_OnAttached)
	inst.components.debuff:SetDetachedFn(buff_OnDetached)

	inst.persists = false

	--inst:DoTaskInTime(2,expire)
	inst:ListenForEvent("animover", expire)
	return inst
end

local function MakeBuffFx(name, anim)
	return Prefab(name, function() return fn(anim) end, assets)
end

return MakeBuffFx("lunar_shield", "shield_retaliation")
