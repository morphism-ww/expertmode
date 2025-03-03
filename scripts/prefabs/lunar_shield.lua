local assets =
{
   Asset("ANIM", "anim/abigail_shield.zip"),
}

local function buff_OnAttached(inst, target)
	inst.entity:SetParent(target.entity)
	inst.Transform:SetPosition(0, 0, 0)
	
	if target.isplayer then
		target._stunprotecter:SetModifier(inst, true)
	end
	if target.components.health ~= nil then
	    target.components.health.externalabsorbmodifiers:SetModifier(inst, 0.8, "lunar_protect")
	end

    inst:ListenForEvent("death", function()
        inst.components.debuff:Stop()
    end, target)
end

local function buff_OnDetached(inst, target)
	if target.isplayer then
		target._stunprotecter:RemoveModifier(inst)
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


	inst:ListenForEvent("animover", expire)
	return inst
end

local function MakeBuffFx(name, anim)
	return Prefab(name, function() return fn(anim) end, assets)
end

return MakeBuffFx("lunar_shield", "shield_retaliation")
