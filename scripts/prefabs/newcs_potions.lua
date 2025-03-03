local assets =
{
    Asset("ANIM", "anim/halloween_potions.zip"),
    Asset("SCRIPT", "scripts/prefabs/halloweenpotion_common.lua"),
}
local function smallfn(inst,target)
    target.components.health:DeltaPenalty(-0.5)
    target:AddDebuff("healthregenbuff", "healthregenbuff")
    target:RemoveDebuff("life_break")
end
local function fearfn(inst,target)
    
end

local function AddPotion(name,anim,onuse,healamount)
    local function fn()
        local inst = CreateEntity()
    
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
    
        MakeInventoryPhysics(inst)
    
        inst.AnimState:SetBank("halloween_potions")
        inst.AnimState:SetBuild("halloween_potions")
        inst.AnimState:PlayAnimation(anim)
    
        --inst:AddTag("potion")  --for warly edible
        inst:AddTag("healerbuffs")
    
        MakeInventoryFloatable(inst)
    
        inst.entity:SetPristine()
    
        if not TheWorld.ismastersim then
            return inst
        end
    
    
        inst:AddComponent("inventoryitem")
        inst:AddComponent("stackable")
        inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM
    
        local healer = inst:AddComponent("healer")
        healer:SetHealthAmount(healamount)
        healer:SetOnHealFn(onuse)

    
        MakeHauntableLaunch(inst)
    
        return inst
    end
    return Prefab(name, fn, assets)
end


return AddPotion("healpotion1","health_small",smallfn,100),
    AddPotion("firepotion","embers",fearfn,10)
