local function base_onequip(inst, owner, symbol_override, swap_hat_override)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol(swap_hat_override or "swap_hat", skin_build, symbol_override or "swap_hat", inst.GUID, inst.fname)
    else
        owner.AnimState:OverrideSymbol(swap_hat_override or "swap_hat", inst.fname, symbol_override or "swap_hat")
    end

    if inst.skin_equip_sound and owner.SoundEmitter then
        owner.SoundEmitter:PlaySound(inst.skin_equip_sound)
    end
end

local function OnEquip(inst, owner)
    if owner:HasTag("player") then
        base_onequip(inst, owner, nil, "headbase_hat")

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
        base_onequip(inst, owner)

        owner.AnimState:Show("HAT")
        owner.AnimState:Hide("HAIR_HAT")
        owner.AnimState:Hide("HAIR_NOHAT")
        owner.AnimState:Hide("HAIR")
    end

    if inst.fx ~= nil then
        inst.fx:Remove()
    end

    inst.fx = SpawnPrefab("nightmarehat_fx")
    inst.fx:AttachToOwner(owner)
    owner.AnimState:SetSymbolLightOverride("swap_hat", .1)
end

local function OnUnequip(inst, owner)
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


    if owner:HasTag("player") then
        owner.AnimState:ShowSymbol("face")
        owner.AnimState:ShowSymbol("swap_face")
        owner.AnimState:ShowSymbol("beard")
        owner.AnimState:ShowSymbol("cheeks")

        owner.AnimState:UseHeadHatExchange(false)
    end

    if inst.fx ~= nil then
        inst.fx:Remove()
        inst.fx = nil
    end
    owner.AnimState:SetSymbolLightOverride("swap_hat", 0)
end


local function MakeHat(name)
    local fname = "hat_"..name
    local symname = name.."hat"
    local prefabname = fname

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
        inst:AddTag("shadow_item")


        MakeInventoryFloatable(inst, "med", 0.25, .75)
        inst.components.floater:SetBankSwapOnFloat(false, nil, swap_data) --Hats default animation is not "idle", so even though we don't swap banks, we need to specify the swap_data for re-skinning to reset properly when floating

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inventoryitem")
        
        --inst:AddComponent("inspectable")

        inst:AddComponent("equippable")
        inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
		inst.components.equippable:SetOnEquip(OnEquip)
		inst.components.equippable:SetOnUnequip(OnUnequip)

        inst.swap_data = swap_data
        inst.fname = fname

        return inst
    end


    return Prefab(prefabname, fn, assets)
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

local function SpawnFollowFxForOwner(inst, owner, createfn, framebegin, frameend, isfullhelm)
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
	inst.components.colouraddersync:SetColourChangedFn(FollowFx_ColourChanged)
	inst.OnRemoveEntity = FollowFx_OnRemoveEntity
end

local function MakeFollowFx(name, data)
	local function OnEntityReplicated(inst)
		local owner = inst.entity:GetParent()
		if owner ~= nil then
			SpawnFollowFxForOwner(inst, owner, data.createfn, data.framebegin, data.frameend, data.isfullhelm)
		end
	end

	local function AttachToOwner(inst, owner)
		inst.entity:SetParent(owner.entity)
		if owner.components.colouradder ~= nil then
			owner.components.colouradder:AttachChild(inst)
		end
		--Dedicated server does not need to spawn the local fx
		if not TheNet:IsDedicated() then
			SpawnFollowFxForOwner(inst, owner, data.createfn, data.framebegin, data.frameend, data.isfullhelm)
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

local function CreateFxFollowFrame(i)
	local inst = CreateEntity()

	--[[Non-networked entity]]
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddFollower()

	inst:AddTag("FX")

	inst.AnimState:SetBank("nightmarehat")
	inst.AnimState:SetBuild("hat_nightmare")
	inst.AnimState:PlayAnimation("idle"..tostring(i), true)
	inst.AnimState:SetSymbolBloom("glow01")
	inst.AnimState:SetSymbolBloom("float_top")
	inst.AnimState:SetSymbolLightOverride("glow01", .5)
	inst.AnimState:SetSymbolLightOverride("float_top", .5)
	inst.AnimState:SetSymbolMultColour("float_top", 1, 1, 1, .6)
	inst.AnimState:SetLightOverride(.1)

	inst:AddComponent("highlightchild")

	inst.persists = false

	return inst
end

return MakeHat("nightmare"),
    MakeFollowFx("nightmarehat_fx", {
        createfn = CreateFxFollowFrame,
        framebegin = 1,
        frameend = 3,
        isfullhelm = true,
        assets = { Asset("ANIM", "anim/hat_nightmare.zip") },
    })
