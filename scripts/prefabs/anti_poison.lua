local assets =
{
    Asset("ANIM", "anim/poison_antidote.zip"),
}

local CAN_HEAL = {poison = true,poison_2 = true,exhaustion = true,food_sick = true}

local function Resolve_poison(inst, target)
    local debuffable = target.components.debuffable
    if debuffable~=nil then
        for k, v in pairs(debuffable.debuffs) do
            if CAN_HEAL[v.inst.prefab] then
                debuffable:RemoveDebuff(k)
            end
        end
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    MakeInventoryFloatable(inst)

    inst.AnimState:SetBank("poison_antidote")
    inst.AnimState:SetBuild("poison_antidote")
    inst.AnimState:PlayAnimation("idle")
	
	inst:AddTag("aquatic")
	
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    MakeSmallBurnable(inst, TUNING.TINY_BURNTIME)

    ---------------------

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    --inst.components.inventoryitem.atlasname = "images/inventoryimages/volcanoinventory.xml"
	
    inst:AddComponent("stackable")

    inst:AddComponent("healer")
    inst.components.healer.onhealfn=Resolve_poison

    return inst
end

return Prefab("antidote", fn, assets)
