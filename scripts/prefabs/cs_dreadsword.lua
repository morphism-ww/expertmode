local assets = {
    Asset("ANIM", "anim/dreadsword.zip"),
    Asset("ANIM", "anim/swap_dreadsword.zip")
}

local fx_assets = {
    Asset("ANIM", "anim/dreadsword.zip"),
}

local prefabs =
{
    "hitsparks_fx",
    "dreadsword_fx",
}




local function SetFxOwner(inst, owner)
    if owner ~= nil then
        inst.blade1.entity:SetParent(owner.entity)
        inst.blade2.entity:SetParent(owner.entity)
        inst.blade1.Follower:FollowSymbol(owner.GUID, "swap_object", nil, nil, nil, true, nil, 0, 0)
        inst.blade2.Follower:FollowSymbol(owner.GUID, "swap_object", nil, nil, nil, true, nil, 5, 8)
        inst.blade1.components.highlightchild:SetOwner(owner)
        inst.blade2.components.highlightchild:SetOwner(owner)
    else
        inst.blade1.entity:SetParent(inst.entity)
        inst.blade2.entity:SetParent(inst.entity)
        inst.blade1.Follower:FollowSymbol(inst.GUID, "swap_spear", nil, nil, nil, true, nil, 0, 0)
        inst.blade2.Follower:FollowSymbol(inst.GUID, "swap_spear", nil, nil, nil, true, nil, 5, 8)
        inst.blade1.components.highlightchild:SetOwner(inst)
        inst.blade2.components.highlightchild:SetOwner(inst)
    end
end

local function GetSetBonusEquip(owner)
	local hat = owner.components.inventory ~= nil and owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) or nil
	return hat ~= nil and (hat.prefab == "dreadstonehat" or hat.prefab == "voidclothhat") and 1.5 or 1
end

local function DoRegen(inst, owner)
	if owner.components.sanity ~= nil and owner.components.sanity:IsInsanityMode() then
		local setbonus = GetSetBonusEquip(owner)
		local rate = 1 / Lerp(1 / TUNING.SWORD_DREADSTONE_REGEN_MAXRATE, 1 / TUNING.SWORD_DREADSTONE_REGEN_MINRATE, owner.components.sanity:GetPercent())
		inst.components.finiteuses:Repair(inst.components.finiteuses.total * rate * setbonus)
	end
	if inst.components.finiteuses:GetUses()==inst.components.finiteuses.total then
		inst.regentask:Cancel()
		inst.regentask = nil
	end
end

local function StartRegen(inst, owner)
	if inst.regentask == nil then
		inst.regentask = inst:DoPeriodicTask(TUNING.ARMOR_DREADSTONE_REGEN_PERIOD, DoRegen, nil, owner)
	end
end

local function StopRegen(inst)
	if inst.regentask ~= nil then
		inst.regentask:Cancel()
		inst.regentask = nil
	end
end

local hitsparks_fx_colouroverride = {1, 0, 0}
local function OnAttack(inst, attacker, target)
    if target ~= nil and target:IsValid() then
        local spark = SpawnPrefab("hitsparks_fx")
        spark:Setup(attacker, target, nil, hitsparks_fx_colouroverride)
        spark.black:set(true)
    end
    StartRegen(inst,attacker)
end

local function OnEquip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "dreadsword", "swap_dreadsword")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    SetFxOwner(inst, owner)

    if owner.components.sanity ~= nil and inst.components.finiteuses:GetUses()<inst.components.finiteuses.total then
		StartRegen(inst, owner)
	else
		StopRegen(inst)
	end
    if inst.components.rechargeable:GetTimeToCharge() < 1 then
        inst.components.rechargeable:Discharge(1)
    end
end

local function OnUnEquip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end
    SetFxOwner(inst, nil)
    StopRegen(inst)
end

local function PushIdleLoop(inst)
    inst.AnimState:PushAnimation("idle")
end

local function OnStopFloating(inst)
    inst.blade1.AnimState:SetFrame(0)
    inst.blade2.AnimState:SetFrame(0)
    inst:DoTaskInTime(0, PushIdleLoop)
end

local function ReticuleTargetFn()
    return Vector3(ThePlayer.entity:LocalToWorldSpace(6.5, 0, 0))
end

local function ReticuleMouseTargetFn(inst, mousepos)
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

local function ReticuleUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
    local x, y, z = inst.Transform:GetWorldPosition()
    reticule.Transform:SetPosition(x, 0, z)
    local rot = -math.atan2(pos.z - z, pos.x - x) / DEGREES
    if ease and dt ~= nil then
        local rot0 = reticule.Transform:GetRotation()
        local drot = rot - rot0
        rot = Lerp((drot > 180 and rot0 + 360) or (drot < -180 and rot0 - 360) or rot0, rot, dt * smoothing)
    end
    reticule.Transform:SetRotation(rot)
end


local function SpellFn(inst, doer, pos)
    inst.components.parryweapon:EnterParryState(doer, doer:GetAngleToPoint(pos), 4)
    inst.components.rechargeable:Discharge(6)
end

local function OnParry(inst, doer, attacker, damage)
    doer:ShakeCamera(CAMERASHAKE.SIDE, 0.1, 0.03, 0.3)
    doer.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/trails/hide_hit")
    if inst.components.rechargeable:GetPercent() < 0.7 then
        inst.components.rechargeable:SetPercent(0.7)
    end
end


local function OnDischarged(inst)
    inst.components.aoetargeting:SetEnabled(false)
end

local function OnCharged(inst)
    inst.components.aoetargeting:SetEnabled(true)
end

local function commonfn(common_postinit, master_postinit)
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("dreadsword")
    inst.AnimState:SetBuild("dreadsword")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetSymbolBloom("dreadsword_fx")
    inst.AnimState:SetSymbolLightOverride("dreadsword_fx", .6)
    inst.AnimState:SetLightOverride(.1)

    inst:AddTag("sharp")
    inst:AddTag("weapon")
    inst:AddTag("shadowlevel")
    --inst:AddTag("shadow_item")

    common_postinit(inst)

    local swap_data = { sym_build = "dreadsword", sym_name = "dreadsword" }
    MakeInventoryFloatable(inst, "med", 0.05, { 0.75, 0.4, 0.75 }, true, -13, swap_data)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    local frame = 1
    inst.AnimState:SetFrame(frame)
    inst.blade1 = SpawnPrefab("dreadsword_fx")
    inst.blade2 = SpawnPrefab("dreadsword_fx")
    inst.blade2.AnimState:PlayAnimation("swap_loop2", true)
    inst.blade1.AnimState:SetFrame(frame)
    inst.blade2.AnimState:SetFrame(frame)
    SetFxOwner(inst, nil)
    inst:ListenForEvent("floater_stopfloating", OnStopFloating)


    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(OnEquip)
    inst.components.equippable:SetOnUnequip(OnUnEquip)

    inst:AddComponent("weapon")
    master_postinit(inst)

    return inst
end

local function dread_common_postinit(inst)
	--inst:AddTag("nosteal")
    inst:AddComponent("aoetargeting")
    inst.components.aoetargeting:SetAlwaysValid(true)
    inst.components.aoetargeting:SetAllowRiding(false)
    inst.components.aoetargeting.reticule.reticuleprefab = "reticulearc"
    inst.components.aoetargeting.reticule.pingprefab = "reticulearcping"
    inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
    inst.components.aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn
    inst.components.aoetargeting.reticule.updatepositionfn = ReticuleUpdatePositionFn
    inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
    inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true

    inst:AddTag("parryweapon")
    
    --rechargeable (from rechargeable component) added to pristine state for optimization
    inst:AddTag("rechargeable")

end

local function dread_master_postinit (inst)
	inst:AddComponent("inspectable")

    inst.components.equippable.walkspeedmult = 1.1
    inst.components.weapon:SetDamage(TUNING.DREADSWORD.DAMAGE)
    inst.components.weapon:SetOnAttack(OnAttack)

    inst:AddComponent("planardamage")
    inst.components.planardamage:SetBaseDamage(TUNING.DREADSWORD.PLANAR_DAMAGE)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.DREADSWORD.USES)
    inst.components.finiteuses:SetUses(TUNING.DREADSWORD.USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("shadowlevel")
    inst.components.shadowlevel:SetDefaultLevel(TUNING.VOIDCLOTH_SCYTHE_SHADOW_LEVEL)

    inst:AddComponent("aoespell")
    inst.components.aoespell:SetSpellFn(SpellFn)

    inst:AddComponent("parryweapon")
    inst.components.parryweapon:SetParryArc(178)
    --inst.components.parryweapon:SetOnPreParryFn(OnPreParry)
    inst.components.parryweapon:SetOnParryFn(OnParry)

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
    inst.components.rechargeable:SetOnChargedFn(OnCharged)

    local damagetypebonus = inst:AddComponent("damagetypebonus")
    damagetypebonus:AddBonus("lunar_aligned", inst, TUNING.WEAPONS_VOIDCLOTH_VS_LUNAR_BONUS)

    MakeHauntableLaunch(inst)
end


local function dreadfn()
    return commonfn(dread_common_postinit,dread_master_postinit)
end


local function fxfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.entity:AddNetwork()

    inst:AddTag("FX")

    inst.AnimState:SetBank("dreadsword")
    inst.AnimState:SetBuild("dreadsword")
    inst.AnimState:PlayAnimation("swap_loop1", true)
    inst.AnimState:SetSymbolBloom("dreadsword_fx")
    inst.AnimState:SetSymbolLightOverride("dreadsword_fx", 1.5)
    inst.AnimState:SetLightOverride(.1)

    inst:AddComponent("highlightchild")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

return Prefab("cs_dreadsword", dreadfn, assets, prefabs),
    Prefab("dreadsword_fx", fxfn, fx_assets)
