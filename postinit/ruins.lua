AddPrefabPostInit("armor_ruins", function(inst)
	inst:AddTag("poison_immune")
	if not TheWorld.ismastersim then
		return inst
	end
	inst.components.equippable.dapperness = TUNING.DAPPERNESS_LARGE
end)



-------------------------------------------------------------
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
    inst.components.parryweapon:EnterParryState(doer, doer:GetAngleToPoint(pos), 5.5)
    inst.components.rechargeable:Discharge(10)
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

local function onequip(inst,owner)
	inst._oldonequipfn(inst,owner)
	if inst.components.rechargeable:GetTimeToCharge() < 2 then
        inst.components.rechargeable:Discharge(2)
    end
end


AddPrefabPostInit("ruins_bat", function(inst)
	--parryweapon (from parryweapon component) added to pristine state for optimization
    inst:AddTag("parryweapon")

    --rechargeable (from rechargeable component) added to pristine state for optimization
    inst:AddTag("rechargeable")

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



	if not TheWorld.ismastersim then
		return inst
	end
	inst._oldonequipfn=inst.components.equippable.onequipfn
	inst.components.equippable:SetOnEquip(onequip)

	inst:AddComponent("aoespell")
    inst.components.aoespell:SetSpellFn(SpellFn)



    inst:AddComponent("parryweapon")
    inst.components.parryweapon:SetParryArc(178)
    --inst.components.parryweapon:SetOnPreParryFn(OnPreParry)
    inst.components.parryweapon:SetOnParryFn(OnParry)

    inst:AddComponent("rechargeable")
    inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
    inst.components.rechargeable:SetOnChargedFn(OnCharged)
end)
