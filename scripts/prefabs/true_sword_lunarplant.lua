local assets =
{
	Asset("ANIM", "anim/sword_lunarplant.zip"),
}

local prefabs =
{
	"sword_lunarplant_blade_fx",
	"hitsparks_fx",
	"lunarplanttentacle",
}

local function SetBuffEnabled(inst, enabled)
	if enabled then
		if not inst._bonusenabled then
			inst._bonusenabled = true
			if inst.components.weapon ~= nil then
				inst.components.weapon:SetDamage(inst.base_damage * TUNING.WEAPONS_LUNARPLANT_SETBONUS_DAMAGE_MULT)
			end
			inst.components.planardamage:AddBonus(inst, TUNING.WEAPONS_LUNARPLANT_SETBONUS_PLANAR_DAMAGE, "setbonus")
		end
	elseif inst._bonusenabled then
		inst._bonusenabled = nil
		if inst.components.weapon ~= nil then
			inst.components.weapon:SetDamage(inst.base_damage)
		end
		inst.components.planardamage:RemoveBonus(inst, "setbonus")
	end
end

local function SetBuffOwner(inst, owner)
	if inst._owner ~= owner then
		if inst._owner ~= nil then
			inst:RemoveEventCallback("equip", inst._onownerequip, inst._owner)
			inst:RemoveEventCallback("unequip", inst._onownerunequip, inst._owner)
			inst._onownerequip = nil
			inst._onownerunequip = nil
			SetBuffEnabled(inst, false)
		end
		inst._owner = owner
		if owner ~= nil then
			inst._onownerequip = function(owner, data)
				if data ~= nil then
					if data.item ~= nil and data.item.prefab == "lunarplanthat" then
						SetBuffEnabled(inst, true)
					elseif data.eslot == EQUIPSLOTS.HEAD then
						SetBuffEnabled(inst, false)
					end
				end
			end
			inst._onownerunequip  = function(owner, data)
				if data ~= nil and data.eslot == EQUIPSLOTS.HEAD then
					SetBuffEnabled(inst, false)
				end
			end
			inst:ListenForEvent("equip", inst._onownerequip, owner)
			inst:ListenForEvent("unequip", inst._onownerunequip, owner)

			local hat = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
			if hat ~= nil and hat.prefab == "lunarplanthat" then
				SetBuffEnabled(inst, true)
			end
		end
	end
end

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

local function PushIdleLoop(inst)
	if inst.components.finiteuses:GetUses() > 0 then
		inst.AnimState:PushAnimation("idle")
	end
end

local function OnStopFloating(inst)
	if inst.components.finiteuses:GetUses() > 0 then
		inst.blade1.AnimState:SetFrame(0)
		inst.blade2.AnimState:SetFrame(0)
		inst:DoTaskInTime(0, PushIdleLoop) --#V2C: #HACK restore the looping anim, timing issues
	end
end

local function onequip(inst, owner)
	local skin_build = inst:GetSkinBuild()
	if skin_build ~= nil then
		owner:PushEvent("equipskinneditem", inst:GetSkinName())
		owner.AnimState:OverrideItemSkinSymbol("swap_object", skin_build, "swap_sword_lunarplant", inst.GUID, "sword_lunarplant")
	else
		owner.AnimState:OverrideSymbol("swap_object", "sword_lunarplant", "swap_sword_lunarplant")
	end
	owner.AnimState:Show("ARM_carry")
	owner.AnimState:Hide("ARM_normal")
	SetFxOwner(inst, owner)
	SetBuffOwner(inst, owner)
end

local function onunequip(inst, owner)
	owner.AnimState:Hide("ARM_carry")
	owner.AnimState:Show("ARM_normal")
	local skin_build = inst:GetSkinBuild()
	if skin_build ~= nil then
		owner:PushEvent("unequipskinneditem", inst:GetSkinName())
	end
	SetFxOwner(inst, nil)
	SetBuffOwner(inst, nil)
end

----

local function doswordshoot(inst,target,doer)
    if target~=nil and target:IsValid() and
		not target:IsInLimbo() then

        local x, y, z = doer.Transform:GetWorldPosition()
		local rot=doer.Transform:GetRotation() * DEGREES
		local x1=x + 10* math.cos(rot)
		local z1=z - 10* math.sin(rot)
		
		local doer_combat = doer.components.combat
    	--doer_combat:EnableAreaDamage(false)

		local p1 = { x = x, y = z }
		local p2 = { x = x1, y = z1 }
		local dx, dy = p2.x - p1.x, p2.y - p1.y
		local dist = dx * dx + dy * dy
		local toskip = {target=true}
		local pv = {}
		local r, cx, cy
		if dist > 0 then
			dist = math.sqrt(dist)
			r = (dist + doer_combat.hitrange * 0.5 + 3) * 0.5
			dx, dy = dx / dist, dy / dist
			cx, cy = p1.x + dx * r, p1.y + dy * r


			local c_hit_targets = TheSim:FindEntities(cx, 0, cy, r, {"_combat","_health"}, {"FX", "DECOR", "INLIMBO","player"} )
			for _, hit_target in ipairs(c_hit_targets) do
				toskip[hit_target] = true
				if hit_target ~= target and doer_combat:CanTarget(hit_target) and not doer_combat:IsAlly(hit_target)
						and not (hit_target.components.health and hit_target.components.health:IsDead()) then
					pv.x, pv._, pv.y = hit_target.Transform:GetWorldPosition()
					local vrange = 2 + hit_target:GetPhysicsRadius(0.5)
					if DistPointToSegmentXYSq(pv, p1, p2) < vrange * vrange then
						local dmg, spdmg = doer_combat:CalcDamage(hit_target, inst)
			        	hit_target.components.combat:GetAttacked(doer, dmg, inst, nil, spdmg)
					end
				end
			end

		end

		local angle = (doer.Transform:GetRotation() + 90) * DEGREES
		local p3 = { x = p2.x + doer_combat.hitrange * math.sin(angle), y = p2.y + doer_combat.hitrange * math.cos(angle) }
		local p2_hit_targets = TheSim:FindEntities(p2.x, 0, p2.y, doer_combat.hitrange + 3,{"_combat","_health"}, {"FX", "DECOR", "INLIMBO","player"})
		for _, hit_target in ipairs(p2_hit_targets) do
			if not toskip[hit_target] and doer_combat:CanTarget(hit_target) and not doer_combat:IsAlly(hit_target)
					and not (hit_target.components.health and hit_target.components.health:IsDead()) then
				pv.x, pv._, pv.y = hit_target.Transform:GetWorldPosition()
				local vradius = hit_target:GetPhysicsRadius(0.5)
				local vrange = doer_combat.hitrange + vradius
				if distsq(pv.x, pv.y, p2.x, p2.y) < vrange * vrange then
					vrange = 2 + vradius
					if DistPointToSegmentXYSq(pv, p2, p3) < vrange * vrange then
						local dmg, spdmg = doer_combat:CalcDamage(hit_target, inst)
			        	hit_target.components.combat:GetAttacked(doer, dmg, inst, nil, spdmg)
					end
				end
			end
		end
	end
end

local function OnAttack(inst, attacker, target)
	if target ~= nil and target:IsValid() then
		SpawnPrefab("hitsparks_fx"):Setup(attacker, target)
		local gestalt = SpawnPrefab("brightshade_projectile")
        gestalt.Transform:SetPosition(attacker.Transform:GetWorldPosition())
        gestalt:ForceFacePoint(target.Transform:GetWorldPosition())
        gestalt.Physics:SetMotorVelOverride(20, 0, 0)
        doswordshoot(inst,target,attacker)
	end
end

local function SetupComponents(inst)
	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(inst._bonusenabled and inst.base_damage * TUNING.WEAPONS_LUNARPLANT_SETBONUS_DAMAGE_MULT or inst.base_damage)
	inst.components.weapon:SetOnAttack(OnAttack)
	inst.components.weapon:SetRange(8, 10)
end

local function DisableComponents(inst)
	inst:RemoveComponent("equippable")
	inst:RemoveComponent("weapon")
end

local FLOAT_SCALE_BROKEN = { 1, 0.7, 1 }
local FLOAT_SCALE = { 1, 0.4, 1 }

local function OnIsBrokenDirty(inst)
	if inst.isbroken:value() then
		inst.components.floater:SetSize("small")
		inst.components.floater:SetVerticalOffset(0.05)
		inst.components.floater:SetScale(FLOAT_SCALE_BROKEN)
	else
		inst.components.floater:SetSize("med")
		inst.components.floater:SetVerticalOffset(0.05)
		inst.components.floater:SetScale(FLOAT_SCALE)
	end
end

local SWAP_DATA_BROKEN = { bank = "sword_lunarplant", anim = "broken" }
local SWAP_DATA = { sym_build = "sword_lunarplant", sym_name = "swap_sword_lunarplant" }

local function SetIsBroken(inst, isbroken)
	if isbroken then
		inst.components.floater:SetBankSwapOnFloat(false, nil, SWAP_DATA_BROKEN)
	else
		inst.components.floater:SetBankSwapOnFloat(true, -17.5, SWAP_DATA)
	end
	inst.isbroken:set(isbroken)
	OnIsBrokenDirty(inst)
end


local function OnBroken(inst)
	if inst.components.equippable ~= nil then
		DisableComponents(inst)
		inst.AnimState:PlayAnimation("broken")
		SetIsBroken(inst, true)
		inst:AddTag("broken")
		inst.components.inspectable.nameoverride = "BROKEN_FORGEDITEM"
	end
end

local function OnRepaired(inst)
	if inst.components.equippable == nil then
		SetupComponents(inst)
		inst.blade1.AnimState:SetFrame(0)
		inst.blade2.AnimState:SetFrame(0)
		inst.AnimState:PlayAnimation("idle", true)
		SetIsBroken(inst, false)
		inst:RemoveTag("broken")
		inst.components.inspectable.nameoverride = nil
	end
end


local function IsEntityInFront(inst, entity, doer_rotation, doer_pos,angle)
    local facing = Vector3(math.cos(-doer_rotation / RADIANS), 0 , math.sin(-doer_rotation / RADIANS))

    return IsWithinAngle(doer_pos, facing, angle, entity:GetPosition())
end


local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)

	inst.AnimState:SetBank("sword_lunarplant")
	inst.AnimState:SetBuild("sword_lunarplant")
	inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:SetSymbolBloom("pb_energy_loop01")
	inst.AnimState:SetSymbolLightOverride("pb_energy_loop01", .5)
	inst.AnimState:SetLightOverride(.1)

	inst:AddTag("sharp")
	inst:AddTag("show_broken_ui")
	inst:AddTag("sword_shoot")

	--weapon (from weapon component) added to pristine state for optimization
	inst:AddTag("weapon")

	inst:AddComponent("floater")
	inst.isbroken = net_bool(inst.GUID, "sword_lunarplant.isbroken", "isbrokendirty")
	SetIsBroken(inst, false)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst:ListenForEvent("isbrokendirty", OnIsBrokenDirty)

		return inst
	end

	local frame = math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1
	inst.AnimState:SetFrame(frame)
	inst.blade1 = SpawnPrefab("sword_lunarplant_blade_fx")
	inst.blade2 = SpawnPrefab("sword_lunarplant_blade_fx")
	inst.blade2.AnimState:PlayAnimation("swap_loop2", true)
	inst.blade1.AnimState:SetFrame(frame)
	inst.blade2.AnimState:SetFrame(frame)
	SetFxOwner(inst, nil)
	inst:ListenForEvent("floater_stopfloating", OnStopFloating)

	-------
	local finiteuses = inst:AddComponent("finiteuses")
	finiteuses:SetMaxUses(TUNING.SWORD_LUNARPLANT_USES)
	finiteuses:SetUses(TUNING.SWORD_LUNARPLANT_USES)

	-------
	inst.base_damage = TUNING.SWORD_LUNARPLANT_DAMAGE

	local planardamage = inst:AddComponent("planardamage")
	planardamage:SetBaseDamage(TUNING.SWORD_LUNARPLANT_PLANAR_DAMAGE)

	local damagetypebonus = inst:AddComponent("damagetypebonus")
	damagetypebonus:AddBonus("shadow_aligned", inst, TUNING.WEAPONS_LUNARPLANT_VS_SHADOW_BONUS)

	inst:AddComponent("inspectable")
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.imagename="sword_lunarplant"

	SetupComponents(inst)

	inst:AddComponent("lunarplant_tentacle_weapon")


    inst.IsEntityInFront = IsEntityInFront
	MakeForgeRepairable(inst, FORGEMATERIALS.LUNARPLANT, OnBroken, OnRepaired)
	MakeHauntableLaunch(inst)

	return inst
end
return Prefab("true_sword_lunarplant", fn, assets, prefabs)
