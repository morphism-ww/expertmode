local assets =
{
    Asset("ANIM", "anim/poison_antidote.zip"),
}

local CAN_HEAL = {buff_poison = true,buff_deadpoison = true,buff_exhaustion = true,buff_foodsick = true}

local function Neutralize(inst, target)
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

    inst.AnimState:SetBank("poison_antidote")
    inst.AnimState:SetBuild("poison_antidote")
    inst.AnimState:PlayAnimation("idle")
	
	MakeInventoryFloatable(inst, "idle_water", "idle")

    inst:AddTag("healerbuffs")
	
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
	
    inst:AddComponent("stackable")

    inst:AddComponent("healer")
    inst.components.healer:SetOnHealFn(Neutralize)

    MakeHauntableLaunch(inst)

    return inst
end

return Prefab("antidote", fn, assets)
