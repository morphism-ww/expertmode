local assets =
{
    Asset("ANIM", "anim/ia_staffs.zip"),
    Asset("ANIM", "anim/swap_ia_staffs.zip"),
}

local prefabs =
{
    volcano = {
        "fire_projectile",
        "dragoonegg_falling"
    },
}

---------COMMON FUNCTIONS---------

local function onfinished(inst)
    if inst.components.spellcaster then
        inst.SoundEmitter:PlaySound("dontstarve/common/gem_shatter")
    end
    inst:Remove()
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function commonfn(colour, tags, hasskin, equipfn, unequipfn, hasshadowlevel)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    MakeInventoryFloatable(inst)


    inst.AnimState:SetBank("ia_staffs")
    inst.AnimState:SetBuild("ia_staffs")
    inst.AnimState:PlayAnimation(colour.."staff")

    if tags ~= nil then
        for i, v in ipairs(tags) do
            inst:AddTag(v)
        end
    end

    if hasshadowlevel then
        --shadowlevel (from shadowlevel component) added to pristine state for optimization
        inst:AddTag("shadowlevel")
    end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    -------
    inst:AddComponent("inspectable")


    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(function(inst, owner)
        owner.AnimState:OverrideSymbol("swap_object", "swap_ia_staffs", colour .. "staff")
        owner.AnimState:Show("ARM_carry")
        owner.AnimState:Hide("ARM_normal")
        if equipfn then
            equipfn(inst, owner)
        end
    end)
    inst.components.equippable:SetOnUnequip(function(inst, owner)
        onunequip(inst, owner)
        if unequipfn then
            unequipfn(inst, owner)
        end
    end)

    --[[if hasshadowlevel then
        inst:AddComponent("shadowlevel")
        inst.components.shadowlevel:SetDefaultLevel(TUNING.STAFF_SHADOW_LEVEL)
    end]]

    return inst
end

---------VOLCANO STAFF---------

local function createeruption(staff, target, pos)
    local owner = staff.components.inventoryitem:GetGrandOwner() or nil
    if owner then
        staff.components.finiteuses:Use(5)
        local delay = 0.0
        for i = 1, 3 do
            local x, y, z = 2* UnitRand() + pos.x, pos.y,2* UnitRand() + pos.z
            staff:DoTaskInTime(delay, function()
                local firerain = SpawnPrefab("firerain_summon")
                firerain.Transform:SetPosition(x, y, z)
                firerain:StartStep()
            end)
            delay = delay + 0.2
        end
    end    
end

local function onattack_red(inst, attacker, target, skipsanity)
    if not skipsanity and attacker ~= nil then
        if attacker.components.staffsanity then
            attacker.components.staffsanity:DoCastingDelta(-TUNING.SANITY_SUPERTINY)
        elseif attacker.components.sanity ~= nil then
            attacker.components.sanity:DoDelta(-TUNING.SANITY_SUPERTINY)
        end
    end
    attacker.SoundEmitter:PlaySound(inst.skin_sound or "dontstarve/wilson/fireball_explo")

    if not target:IsValid() then
        --target killed or removed in combat damage phase
        return
    elseif target.components.burnable ~= nil and not target.components.burnable:IsBurning() then
        if target.components.freezable ~= nil and target.components.freezable:IsFrozen() then
            target.components.freezable:Unfreeze()
        elseif target.components.fueled == nil
            or (target.components.fueled.fueltype ~= FUELTYPE.BURNABLE and
                target.components.fueled.secondaryfueltype ~= FUELTYPE.BURNABLE) then
            --does not take burnable fuel, so just burn it
            if target.components.burnable.canlight or target.components.combat ~= nil then
                target.components.burnable:Ignite(true, attacker)
            end
        elseif target.components.fueled.accepting then
            --takes burnable fuel, so fuel it
            local fuel = SpawnPrefab("cutgrass")
            if fuel ~= nil then
                if fuel.components.fuel ~= nil and
                    fuel.components.fuel.fueltype == FUELTYPE.BURNABLE then
                    target.components.fueled:TakeFuelItem(fuel)
                else
                    fuel:Remove()
                end
            end
        end
    end
end


local function cancast(doer, target, pos)
    return false and doer:IsValid() and doer:GetDistanceSqToPoint(pos)<7
end


local function volcano()
    local inst = commonfn("meteor", {"nosteal", "nopunch", "allow_action_on_impassable"}, nil, nil, nil, true)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.fxcolour = {223 / 255, 208 / 255, 69 / 255}
    inst.castsound = "dontstarve/common/staffteleport"

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(20)
    inst.components.weapon:SetRange(8, 10)
    inst.components.weapon:SetOnAttack(onattack_red)    
    inst.components.weapon:SetProjectile("fire_projectile")

    inst:AddComponent("spellcaster")
    inst.components.spellcaster:SetSpellFn(createeruption)
    inst.components.spellcaster.canuseonpoint = true
    inst.components.spellcaster.canuseonpoint_water = true
    inst.components.spellcaster:SetCanCastFn(cancast)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetOnFinished(onfinished)
    inst.components.finiteuses:SetMaxUses(50)
    inst.components.finiteuses:SetUses(50)


    inst:AddComponent("repairable")
    inst.components.repairable.repairmaterial="obsidian"
    inst.components.repairable:SetFiniteUsesRepairable(true)

    return inst
end



return Prefab("volcanostaff", volcano, assets, prefabs.volcano)
