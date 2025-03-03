local assets =
{
    Asset("ANIM", "anim/sword_constant.zip"),
    Asset("ANIM", "anim/swap_sword_constant.zip"),
}

local function onequip(inst, owner)

    owner.AnimState:OverrideSymbol("swap_object", "swap_sword_constant", "swap_sword_constant")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")

    if inst.skin_equip_sound and owner.SoundEmitter then
        owner.SoundEmitter:PlaySound(inst.skin_equip_sound)
    end
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")

end

local function AOEReticuleTargetFn(radius)
	return function ()
		local player = ThePlayer
		local ground = TheWorld.Map
		local pos = Vector3()
		--Cast range is 8, leave room for error
		--4 is the aoe range
		for r = radius, 0, -.25 do
			pos.x, pos.y, pos.z = player.entity:LocalToWorldSpace(r, 0, 0)
			if ground:IsPassableAtPoint(pos:Get()) and not ground:IsGroundTargetBlocked(pos) then
				return pos
			end
		end
		return pos
	end
end

local function leapspell(inst,doer,pos)
    doer:PushEvent("combat_leap", {targetpos = pos, weapon = inst})
end

local function createfx(inst,doer, startingpos, targetpos)
    if doer.sg~=nil then
        doer.sg:AddStateTag("nointerrupt")
    end
    local x,y,z = targetpos:Get()
    local radius = 5
    local angle = doer.Transform:GetRotation()
    local fx = SpawnPrefab("moonstorm_ground_lightning_fx")
    fx.Transform:SetPosition(x,0,z)
    fx.Transform:SetRotation(angle-90)
    if not inst.components.rechargeable:IsCharged() then
        SpawnPrefab("small_alter_light").Transform:SetPosition(x,0,z)

        for i=1,6 do
            local light = SpawnPrefab("small_alter_light")
            light.CASTER = doer
            --lightning:SetOwner(doer)
            light.Transform:SetPosition(x + radius*math.cos(angle*DEGREES), 0, z - radius* math.sin(angle*DEGREES))
            angle = angle + 60
        end
    end
    --SpawnPrefab("moonstorm_ground_lightning_fx").Transform:SetPosition(targetpos:Get())
end

local function onattack(inst,doer)
    if doer and not doer:HasDebuff("lunar_protect") then
        doer:AddDebuff("lunar_protect","lunar_shield")
	end
    --if inst.components.rechargeable:IsCharged() then
        
    inst.components.rechargeable:Discharge(4)    
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("sword_constant")
    inst.AnimState:SetBuild("sword_constant")
    inst.AnimState:PlayAnimation("idle")

    inst:AddComponent("aoetargeting")
    inst.components.aoetargeting:SetAllowRiding(false)
    inst.components.aoetargeting.reticule.reticuleprefab = "reticuleaoe"
    inst.components.aoetargeting.reticule.pingprefab = "reticuleaoeping"
    inst.components.aoetargeting.reticule.targetfn = AOEReticuleTargetFn(5)
    inst.components.aoetargeting:SetShouldRepeatCastFn(function () return true end)
    --inst.components.aoetargeting.reticule.mousetargetfn = Lightning_ReticuleMouseTargetFn
    --inst.components.aoetargeting.reticule.updatepositionfn = Lightning_ReticuleUpdatePositionFn
    inst.components.aoetargeting:SetRange(18)
    inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
    inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true

    inst:AddTag("aoeweapon_leap")
    inst:AddTag("sharp")
    inst:AddTag("mythical")
    inst:AddTag("pointy")

    local floater_swap_data = {sym_build = "swap_sword_constant"}
    MakeInventoryFloatable(inst, "med", 0.05, {1.21, 0.4, 1.21}, true, -22, floater_swap_data)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("weapon")
	inst.components.weapon:SetOnAttack(onattack)

    inst:AddComponent("rechargeable")


    inst:AddComponent("aoeweapon_leap")
    inst.components.aoeweapon_leap:SetDamage(200)
    inst.components.aoeweapon_leap:SetWorkActions()
    inst.components.aoeweapon_leap:SetAOERadius(5)
    inst.components.aoeweapon_leap:SetStimuli("electric")
    --inst.components.aoeweapon_leap:SetOnHitFn(OnHit)
    inst.components.aoeweapon_leap:SetOnPreLeapFn(createfx)
    inst.components.aoeweapon_leap.tags = {"_combat"}

    inst:AddComponent("aoespell")
    inst.components.aoespell:SetSpellFn(leapspell)

    local planardamage = inst:AddComponent("planardamage")
	planardamage:SetBaseDamage(40)

	local damagetypebonus = inst:AddComponent("damagetypebonus")
	damagetypebonus:AddBonus("shadow_aligned", inst, 1.2)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.GLASSCUTTER.USES)
    inst.components.finiteuses:SetUses(TUNING.GLASSCUTTER.USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("sword_constant", fn, assets)