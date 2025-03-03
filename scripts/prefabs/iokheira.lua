local SpDamageUtil = require("components/spdamageutil")
local assets =
{
    Asset("ANIM", "anim/iokheira.zip"),   
}

local prefabs =
{
    "iokheira_proj",
    "iokheira_swap_fx",
}

local CHARGE_TIME = 1.8

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

local MAX_SPEED = 25

local function iokheira_SpellFn(inst, doer, pos)
    local percent = inst.components.rechargeable:GetPercent()

    if percent < 0.3 then
        return
    end
    
    inst.components.finiteuses:Use(1)

    local x, y, z = doer.Transform:GetWorldPosition()
    local proj = SpawnPrefab("iokheira_proj")
    proj.Transform:SetPosition(x,y,z)

    if doer.components.electricattacks ~= nil then
        proj.stimuli = "electric"
    end

    proj.components.linearprojectile:LineShoot(pos,doer)
    proj.components.linearprojectile:SetHorizontalSpeed(MAX_SPEED*percent*percent)

    proj.components.planardamage:AddBonus(inst,300*percent*percent,"charge")
    proj.components.weapon:SetDamage(300*percent*percent)

    inst.SoundEmitter:PlaySound("hookline_2/creatures/boss/crabking/ice_attack")
    inst.components.rechargeable:Discharge(CHARGE_TIME)
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


local function on_equipped(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "iokheira", "swap_iokheira")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    SetFxOwner(inst, owner)
    owner:AddTag("canrepeatcast")

    inst.components.rechargeable:Discharge(CHARGE_TIME)
end

local function on_unequipped(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    SetFxOwner(inst, nil)
    owner:RemoveTag("canrepeatcast")
end



local function SetupComponents(inst)
	inst:AddComponent("equippable")
	inst.components.equippable:SetOnEquip(on_equipped)
    inst.components.equippable:SetOnUnequip(on_unequipped)
end

local function DisableComponents(inst)
	inst:RemoveComponent("equippable")
end

local function OnBroken(inst)
	if inst.components.equippable ~= nil then
		DisableComponents(inst)
		inst.AnimState:PlayAnimation("broken")
		
		inst:AddTag("broken")
		inst.components.inspectable.nameoverride = "BROKEN_FORGEDITEM"
	end
end

local function OnRepaired(inst)
	if inst.components.equippable == nil then
		SetupComponents(inst)
		inst.blade1.AnimState:SetFrame(0)
		inst.blade2.AnimState:SetFrame(0)
		inst.AnimState:PlayAnimation("idle")
		
		inst:RemoveTag("broken")
		inst.components.inspectable.nameoverride = nil
	end
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("iokheira")
    inst.AnimState:SetBuild("iokheira")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetSymbolBloom("head")
	inst.AnimState:SetSymbolLightOverride("head", .5)
	inst.AnimState:SetLightOverride(.1)

    inst:AddTag("mythical")
    inst:AddTag("throw_line")
    inst:AddTag("sharp")
    inst:AddTag("rangedweapon")
    inst:AddTag("show_broken_ui")

    -- Rechargeable (from rechargeable component) added to pristine state for optimization.
    inst:AddTag("rechargeable")

    inst:AddComponent("aoetargeting")
	inst.components.aoetargeting:SetAlwaysValid(true)
    inst.components.aoetargeting:SetAllowRiding(true)
    inst.components.aoetargeting:SetShouldRepeatCastFn(function () return true end)
	inst.components.aoetargeting.reticule.reticuleprefab = "reticulelong"
	inst.components.aoetargeting.reticule.pingprefab = "reticulelongping"
	inst.components.aoetargeting.reticule.targetfn = ReticuleTargetFn
	inst.components.aoetargeting.reticule.mousetargetfn = ReticuleMouseTargetFn
	inst.components.aoetargeting.reticule.updatepositionfn = ReticuleUpdatePositionFn
	inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
	inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
	inst.components.aoetargeting.reticule.ease = true
	inst.components.aoetargeting.reticule.mouseenabled = true

    inst.itemtile_colour = DEFAULT_MYTHICAL_COLOUR

    MakeInventoryFloatable(inst, "med", 0.07, { 0.53, 0.5, 0.5 })


    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

	inst.blade1 = SpawnPrefab("iokheira_swap_fx")
	inst.blade2 = SpawnPrefab("iokheira_swap_fx")
	inst.blade2.AnimState:PlayAnimation("swap_loop2")

	SetFxOwner(inst, nil)

    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
    ----------------------------------------------
    SetupComponents(inst)
    ----------------------------------------------

    inst:AddComponent("aoespell")
	inst.components.aoespell:SetSpellFn(iokheira_SpellFn)

    inst:AddComponent("rechargeable")

    ------------------------------------------------

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(300)
    inst.components.finiteuses:SetUses(300)
    
    MakeForgeRepairable2(inst,OnBroken,OnRepaired)
    --inst.components.repairable.checkmaterialfn = test_for_bluegem
    
    return inst
end


local function CalcDamage(self,target,weapon)
    if target:HasTag("alwaysblock") then
        return 0
    end
    local multiplier = self.inst.stimuli == "electric" and 2 or 1
    local basedamage
    local basemultiplier = self.damagemultiplier
	local damagetypemult = 1
    local bonus = self.damagebonus --not affected by multipliers
	local mount = nil
	local spdamage
    

    --NOTE: playermultiplier is for damage towards players
    --      generally only applies for NPCs attacking players

    if weapon ~= nil then
        --No playermultiplier when using weapons
		basedamage, spdamage = weapon.components.weapon:GetDamage(self.inst, target)
        
		--#V2C: entity's own damagetypebonus stacks with weapon's damagetypebonus
		if self.inst.components.damagetypebonus ~= nil then
			damagetypemult = self.inst.components.damagetypebonus:GetBonus(target)
		end

        --#DiogoW: entity's own SpDamage stacks with weapon's SpDamage
        spdamage = SpDamageUtil.CollectSpDamage(self.inst, spdamage)
    else
        basedamage = self.defaultdamage
    end

	local damage = (basedamage or 0)
        * (basemultiplier or 1)
		* damagetypemult
        + (bonus or 0)

	if spdamage ~= nil then
		local spmult = damagetypemult

        if self.customspdamagemultfn then
            spmult = spmult * (self.customspdamagemultfn(self.inst, target, weapon, multiplier, mount) or 1)
        end
		if spmult ~= 1 then
			spdamage = SpDamageUtil.ApplyMult(spdamage, spmult)
		end
	end
	return damage, spdamage
end

local function onhit(inst, attacker, target)
    local damage,spdamage = CalcDamage(attacker.components.combat,target,inst)

    if target.components.combat:GetAttacked(attacker,damage,inst,nil,spdamage)
        and target:IsValid() 
        and target.components.health~=nil and not target.components.health:IsDead() then
        target:AddDebuff("buff_eclipse_radiance","buff_eclipse_radiance")
    end

    inst:Remove()
end


local function projfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeProjectilePhysics(inst)
    
    inst.AnimState:SetBank("iokheira")
	inst.AnimState:SetBuild("iokheira")
	inst.AnimState:PlayAnimation("thrown")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    --inst.AnimState:SetScale(1.4,1.4,1.4)

    inst.AnimState:SetAddColour(1,1,1,1)
    inst.AnimState:SetSortOrder(5)

    inst:AddTag("FX")
    inst:AddTag("projectile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    --伤害在发射时确定
    inst:AddComponent("weapon")
    inst:AddComponent("planardamage")

    inst:AddComponent("damagetypebonus")
	inst.components.damagetypebonus:AddBonus("shadow_aligned", inst, 1.2)
    
    inst:AddComponent("linearprojectile")
    inst.components.linearprojectile:SetRange(24)
    inst.components.linearprojectile:SetHitDist(1)
    inst.components.linearprojectile:SetHorizontalSpeed(25)
    inst.components.linearprojectile:SetOnHit(onhit)
    inst.components.linearprojectile:SetOnMiss(inst.Remove)
    inst.components.linearprojectile:AddNoHitTag("player")
    inst.components.linearprojectile:AddNoHitTag("companion")

    return inst
end


local function fxfn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddFollower()
	inst.entity:AddNetwork()

	inst:AddTag("FX")

	inst.AnimState:SetBank("iokheira")
	inst.AnimState:SetBuild("iokheira")
	inst.AnimState:PlayAnimation("swap_loop1")
	inst.AnimState:SetSymbolBloom("head")
	inst.AnimState:SetSymbolLightOverride("head", .5)
	inst.AnimState:SetLightOverride(.1)

	inst:AddComponent("highlightchild")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("colouradder")

	inst.persists = false

	return inst
end



return Prefab("iokheira", fn, assets, prefabs),
    Prefab("iokheira_proj",projfn,assets),
    Prefab("iokheira_swap_fx", fxfn, assets)