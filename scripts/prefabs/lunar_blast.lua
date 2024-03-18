local assets =
{
    Asset("ANIM", "anim/staffs.zip"),
    Asset("ANIM", "anim/swap_staffs.zip"),
}

local prefabs = {
    "small_alter_light",
}
---------YELLOW/OPAL STAFF-------------

local function createlight(staff, target, pos)
    local caster = staff.components.inventoryitem.owner
    if caster ~= nil then
        local light = SpawnPrefab("small_alter_light")
        if target~=nil then
            pos=target:GetPosition()
        end
        light.Transform:SetPosition(pos:Get())
        light.CASTER=caster
        staff.components.finiteuses:Use(1)
        if caster.components.staffsanity then
            caster.components.staffsanity:DoCastingDelta(-TUNING.SANITY_MED)
        elseif caster.components.sanity ~= nil then
            caster.components.sanity:DoDelta(-TUNING.SANITY_MED)
        end
    end
end

local function onfinished(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/gem_shatter")
    inst:Remove()
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
end

local function opal()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("staffs")
    inst.AnimState:SetBuild("staffs")
    inst.AnimState:PlayAnimation("opalstaff")

    local floater_swap_data =
    {
        sym_build = "swap_staffs",
        sym_name = "swap_opalstaff",
        bank = "staffs",
        anim = "opalstaff"
    }

    MakeInventoryFloatable(inst, "med", 0.1, {0.9, 0.4, 0.9}, true, -13, floater_swap_data)

    inst:AddTag("nopunch")
    inst:AddTag("allow_action_on_impassable")




    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetOnFinished(onfinished)

    inst:AddComponent("repairable")
    inst.components.repairable.repairmaterial="pure"
    inst.components.repairable.finiteusesrepairable=true


    inst:AddComponent("inventoryitem")

    inst:AddComponent("equippable")

    inst.fxcolour = {64/255, 64/255, 208/255}
    inst.castsound = "dontstarve/common/staffteleport"

    inst:AddComponent("spellcaster")
    inst.components.spellcaster:SetSpellFn(createlight)
    inst.components.spellcaster.canuseontargets = true
    inst.components.spellcaster.canuseonpoint=true
    inst.components.spellcaster.canonlyuseoncombat = true


    inst.components.finiteuses:SetMaxUses(20)
    inst.components.finiteuses:SetUses(20)

    inst.components.equippable:SetOnEquip(function(inst, owner)
            owner.AnimState:OverrideSymbol("swap_object", "swap_staffs", "swap_opal".."staff")
            owner.AnimState:Show("ARM_carry")
            owner.AnimState:Hide("ARM_normal")
        end)
    inst.components.equippable:SetOnUnequip(onunequip)

    local floater_swap_data1 =
    {
        sym_build = "swap_staffs",
        sym_name = "swap_opalstaff",
        bank = "staffs",
        anim = "opalstaff"
    }
    inst.components.floater:SetBankSwapOnFloat(true, -14, floater_swap_data1)




    return inst
end

return Prefab("lunar_blast", opal, assets, prefabs)
