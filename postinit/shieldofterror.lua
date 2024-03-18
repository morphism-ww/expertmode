local function onequip(inst,owner)
	inst._oldonequipfn(inst,owner)
	owner:AddTag("stun_immune")
end

local function onunequip(inst,owner)
	inst._oldunequipfn(inst,owner)
	owner:RemoveTag("stun_immune")
end

AddPrefabPostInit("shieldofterror",function(inst)
    inst:AddTag("heavyarmor")
	if not TheWorld.ismastersim then
		return inst
	end
	inst._oldonequipfn=inst.components.equippable.onequipfn
	inst._oldunequipfn=inst.components.equippable.onunequipfn
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
end)
--[[local function onequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol("lantern_overlay", skin_build, "swap_shield", inst.GUID, "swap_eye_shield")
    else
        owner.AnimState:OverrideSymbol("lantern_overlay", "swap_eye_shield", "swap_shield")
    end
    owner.AnimState:HideSymbol("swap_object")

    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    owner.AnimState:Show("LANTERN_OVERLAY")
    if inst.components.rechargeable:GetTimeToCharge() < inst._cooldown then
        inst.components.rechargeable:Discharge(inst._cooldown)
    end

    owner:ListenForEvent("onattackother", inst._weaponused_callback)
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end

    owner:RemoveEventCallback("onattackother", inst._weaponused_callback)

    owner.AnimState:ClearOverrideSymbol("lantern_overlay")
    owner.AnimState:Hide("LANTERN_OVERLAY")
    owner.AnimState:ShowSymbol("swap_object")
end

local function Lightning_ReticuleTargetFn()
    --Cast range is 8, leave room for error (6.5 lunge)
    return Vector3(ThePlayer.entity:LocalToWorldSpace(6.5, 0, 0))
end

local function Lightning_ReticuleMouseTargetFn(inst, mousepos)
    if mousepos ~= nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        local dx = mousepos.x - x
        local dz = mousepos.z - z
        local l = dx * dx + dz * dz
        if l <= 0 then
            return inst.components.reticule.targetpos
        end
        l = 6.5 / math.sqrt(l)
        return Vector3(x + dx * l, 0, z + dz * l)
    end
end

local function Lightning_ReticuleUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
    local x, y, z = inst.Transform:GetWorldPosition()
    reticule.Transform:SetPosition(x, 0, z)
    local rot = -math.atan2(pos.z - z, pos.x - x) / DEGREES
    if ease and dt ~= nil then
        local rot0 = reticule.Transform:GetRotation()
        local drot = rot - rot0
        rot = Lerp((drot > 180 and rot0 + 360) or (drot < -180 and rot0 - 360) or rot0, rot, dt * smoothing)
    end
    reticule.Transform:SetRotation(rot)
end]]

--[[local function Lightning_OnLunged(inst, doer, startingpos, targetpos)

    inst.components.rechargeable:Discharge(inst._cooldown)

    inst._lunge_hit_count = nil
end]]

--[[local function Lightning_OnDischarged(inst)
    inst.components.aoetargeting:SetEnabled(false)
end

local function Lightning_OnCharged(inst)
    inst.components.aoetargeting:SetEnabled(true)
end

local function SpellFn(inst, doer, pos)
    inst.components.rechargeable:Discharge(inst._cooldown)
     inst.components.armor:TakeDamage(2)

end]]



--[[AddPrefabPostInit("shieldofterror",function(inst)
    inst:AddTag("aoeweapon_charge")
    -- rechargeable (from rechargeable component) added to pristine state for optimization.
    inst:AddTag("rechargeable")

    inst:AddComponent("aoetargeting")
    inst.components.aoetargeting:SetAllowRiding(false)
    inst.components.aoetargeting.reticule.reticuleprefab = "reticuleline"
    inst.components.aoetargeting.reticule.pingprefab = "reticulelineping"
    inst.components.aoetargeting.allowwater=true
    inst.components.aoetargeting.reticule.targetfn = Lightning_ReticuleTargetFn
    inst.components.aoetargeting.reticule.mousetargetfn = Lightning_ReticuleMouseTargetFn
    inst.components.aoetargeting.reticule.updatepositionfn = Lightning_ReticuleUpdatePositionFn
    inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
    inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true

    if not TheWorld.ismastersim then return end




    inst._cooldown = 2

    inst.components.weapon:SetOnAttack(Lightning_OnAttack)
    inst.components.armor:InitCondition(2000, 1)
	inst.components.armor.ontakedamage = OnTakeDamage

    inst.components.aoetargeting:SetEnabled(true)


    inst:AddComponent("aoespell")
    inst.components.aoespell:SetSpellFn(SpellFn)

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(Lightning_OnDischarged)
    inst.components.rechargeable:SetOnChargedFn(Lightning_OnCharged)

    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)


end)]]