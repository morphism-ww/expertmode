local assets =
{
	Asset("ANIM", "anim/hat_dragonhead.zip"),
}

local hat_util = require"util.newcs_hat_util"

local function onequip(inst, owner)
    hat_util.simple_onequip(inst,owner)

    if owner.components.health ~= nil then
        owner.components.health.externalfiredamagemultipliers:SetModifier(inst, 0)
    end
end

local function onunequip(inst, owner)
    hat_util.simple_onunequip(inst,owner)

    if owner.components.health ~= nil then
        owner.components.health.externalfiredamagemultipliers:RemoveModifier(inst)
    end
end

local function SelfRepair(inst,data)
    if inst.components.armor:IsDamaged() then
        local last = data.last
        local new = data.new
        local delta = new-last
        if new>25 and delta>0 then
            local tempbonus = new>50 and 0.1 or 0
            inst.components.armor:Repair(math.max(tempbonus,4*delta))
        end
    end
end

local function fn()
	local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("dragonheadhat")
    inst.AnimState:SetBuild("hat_dragonhead")
    inst.AnimState:PlayAnimation("anim")

    inst:AddTag("hat")

    inst.fname = "hat_dragonhead"

    local swap_data = { bank = "dragonheadhat", anim = "anim" }
    MakeInventoryFloatable(inst)
    inst.components.floater:SetBankSwapOnFloat(false, nil, swap_data) --Hats default animation is not "idle", so even though we don't swap banks, we need to specify the swap_data for re-skinning to reset properly when floating
    inst.components.floater:SetSize("med")
    inst.components.floater:SetScale(0.65)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("tradable")

    inst:AddComponent("inventoryitem")
    inst.components.inventoryitem:ChangeImageName("dragonheadhat")
   
    inst:AddComponent("armor")
    inst.components.armor:InitCondition(735, 0.8)

    inst:AddComponent("temperature")
    inst.components.temperature.current = TheWorld.state.temperature
    inst.components.temperature.inherentinsulation = TUNING.INSULATION_MED

    inst:AddComponent("waterproofer")
    inst.components.waterproofer:SetEffectiveness(0.4)

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.HEAD
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.walkspeedmult = 1.15

    inst:ListenForEvent("temperaturedelta",SelfRepair)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("obsidianhat", fn,assets)
