local fns = {}

local function _base_onequip(inst, owner, symbol_override, swap_hat_override)
	local skin_build = inst:GetSkinBuild()
	if skin_build ~= nil then
		owner:PushEvent("equipskinneditem", inst:GetSkinName())
		owner.AnimState:OverrideItemSkinSymbol(swap_hat_override or "swap_hat", skin_build, symbol_override or "swap_hat", inst.GUID, inst.fname)
	else
		owner.AnimState:OverrideSymbol(swap_hat_override or "swap_hat", inst.fname, symbol_override or "swap_hat")
	end
end

fns.simple_onequip = function(inst, owner, symbol_override, headbase_hat_override)
	_base_onequip(inst, owner, symbol_override)

	owner.AnimState:ClearOverrideSymbol("headbase_hat") --clear out previous overrides
	if headbase_hat_override ~= nil then
		local skin_build = owner.AnimState:GetSkinBuild()
		if skin_build ~= "" then
			owner.AnimState:OverrideSkinSymbol("headbase_hat", skin_build, headbase_hat_override )
		else 
			local build = owner.AnimState:GetBuild()
			owner.AnimState:OverrideSymbol("headbase_hat", build, headbase_hat_override)
		end
	end

	owner.AnimState:Show("HAT")
	owner.AnimState:Show("HAIR_HAT")
	owner.AnimState:Hide("HAIR_NOHAT")
	owner.AnimState:Hide("HAIR")

	if owner:HasTag("player") then
		owner.AnimState:Hide("HEAD")
		owner.AnimState:Show("HEAD_HAT")
		owner.AnimState:Show("HEAD_HAT_NOHELM")
		owner.AnimState:Hide("HEAD_HAT_HELM")
	end
end

local function _onunequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
    owner.AnimState:ClearOverrideSymbol("headbase_hat") --it might have been overriden by _onequip
    if owner.components.skinner ~= nil then
        owner.components.skinner.base_change_cb = owner.old_base_change_cb
    end

    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Show("HEAD")
        owner.AnimState:Hide("HEAD_HAT")
        owner.AnimState:Hide("HEAD_HAT_NOHELM")
        owner.AnimState:Hide("HEAD_HAT_HELM")
    end
end

fns.simple_onunequip = _onunequip

fns.fullhelm_onequip = function(inst, owner)
    if owner:HasTag("player") then
        _base_onequip(inst, owner, nil, "headbase_hat")

        owner.AnimState:Hide("HAT")
        owner.AnimState:Hide("HAIR_HAT")
        owner.AnimState:Hide("HAIR_NOHAT")
        owner.AnimState:Hide("HAIR")

        owner.AnimState:Hide("HEAD")
        owner.AnimState:Show("HEAD_HAT")
        owner.AnimState:Hide("HEAD_HAT_NOHELM")
        owner.AnimState:Show("HEAD_HAT_HELM")

        owner.AnimState:HideSymbol("face")
        owner.AnimState:HideSymbol("swap_face")
        owner.AnimState:HideSymbol("beard")
        owner.AnimState:HideSymbol("cheeks")

        owner.AnimState:UseHeadHatExchange(true)
    else
        _base_onequip(inst, owner)

        owner.AnimState:Show("HAT")
        owner.AnimState:Hide("HAIR_HAT")
        owner.AnimState:Hide("HAIR_NOHAT")
        owner.AnimState:Hide("HAIR")
    end
end

fns.fullhelm_onunequip = function(inst, owner)
    _onunequip(inst, owner)

    if owner:HasTag("player") then
        owner.AnimState:ShowSymbol("face")
        owner.AnimState:ShowSymbol("swap_face")
        owner.AnimState:ShowSymbol("beard")
        owner.AnimState:ShowSymbol("cheeks")

        owner.AnimState:UseHeadHatExchange(false)
    end
end

local function FollowFx_OnRemoveEntity(inst)
	for i, v in ipairs(inst.fx) do
		v:Remove()
	end
end

local function FollowFx_ColourChanged(inst, r, g, b, a)
	for i, v in ipairs(inst.fx) do
		v.AnimState:SetAddColour(r, g, b, a)
	end
end

local function SpawnFollowFxForOwner(inst, owner, createfn, framebegin, frameend, isfullhelm,OnFollowFx)
	local follow_symbol = isfullhelm and owner:HasTag("player") and owner.AnimState:BuildHasSymbol("headbase_hat") and "headbase_hat" or "swap_hat"
	inst.fx = {}
	local frame
	for i = framebegin, frameend do        
		local fx = createfn(i)
		frame = frame or math.random(fx.AnimState:GetCurrentAnimationNumFrames()) - 1
		fx.entity:SetParent(owner.entity)
		fx.Follower:FollowSymbol(owner.GUID, follow_symbol, nil, nil, nil, true, nil, i - 1)
		fx.AnimState:SetFrame(frame)
		fx.components.highlightchild:SetOwner(owner)
		table.insert(inst.fx, fx)
	end
	if OnFollowFx~=nil then
		OnFollowFx(inst,owner)
	end
	inst.components.colouraddersync:SetColourChangedFn(FollowFx_ColourChanged)
	inst.OnRemoveEntity = FollowFx_OnRemoveEntity
end

--[[

	local fname = "hat_"..name
    local symname = name.."hat"
    local prefabname = symname


	local assets = { Asset("ANIM", "anim/"..fname..".zip") }

    local swap_data = { bank = symname, anim = "anim" }

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddAnimState()
		inst.entity:AddNetwork()

		MakeInventoryPhysics(inst)

		inst.AnimState:SetBank(symname)
		inst.AnimState:SetBuild(fname)
		inst.AnimState:PlayAnimation("anim")

		inst:AddTag("hat")

		inst.fname = fname

		MakeInventoryFloatable(inst)
		inst.components.floater:SetBankSwapOnFloat(false, nil, swap_data) --Hats default animation is not "idle", so even though we don't swap banks, we need to specify the swap_data for re-skinning to reset properly when floating

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end

		--inst._skinfns = _skinfns

		inst:AddComponent("inventoryitem")

		inst:AddComponent("inspectable")

		inst:AddComponent("tradable")

		inst:AddComponent("equippable")
		inst.components.equippable.equipslot = EQUIPSLOTS.HEAD


		MakeHauntableLaunch(inst)
	end

	table.insert(ALL_HAT_PREFAB_NAMES, prefabname)
]]
fns.MakeFollowFx = function (name, data)
	local function OnEntityReplicated(inst)
		local owner = inst.entity:GetParent()
		if owner ~= nil then
			SpawnFollowFxForOwner(inst, owner, data.createfn, data.framebegin, data.frameend, data.isfullhelm,data.OnFollowFx)
		end
	end

	local function AttachToOwner(inst, owner)        
		inst.entity:SetParent(owner.entity)
		if owner.components.colouradder ~= nil then
			owner.components.colouradder:AttachChild(inst)
		end
		--Dedicated server does not need to spawn the local fx
		if not TheNet:IsDedicated() then            
			SpawnFollowFxForOwner(inst, owner, data.createfn, data.framebegin, data.frameend, data.isfullhelm,data.OnFollowFx)
		end
	end

	local function fn()
		local inst = CreateEntity()

		inst.entity:AddTransform()
		inst.entity:AddNetwork()

		inst:AddTag("FX")

		inst:AddComponent("colouraddersync")

		if data.common_postinit ~= nil then
			data.common_postinit(inst)
		end

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			inst.OnEntityReplicated = OnEntityReplicated

			return inst
		end

		inst.AttachToOwner = AttachToOwner
		inst.persists = false

		if data.master_postinit ~= nil then
			data.master_postinit(inst)
		end

		return inst
	end

	return Prefab(name, fn, data.assets, data.prefabs)
end

return fns