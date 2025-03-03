local assets =
{
    Asset("ANIM", "anim/willow_embers.zip"),
}

local function insight_givebuff(inst,doer)
    doer:AddDebuff("buff_insight","buff_insight")
    inst.components.rechargeable:Discharge(3*TUNING.TOTAL_DAY_TIME)
end


local function iron_postinit(inst)
    inst:AddComponent("upgrader")
    inst.components.upgrader.upgradetype = "IRON_SOUL"
end

local function iron_givebuff(inst,doer)
    doer:AddDebuff("buff_iron","buff_iron")
    inst.components.rechargeable:Discharge(2*TUNING.TOTAL_DAY_TIME)
end

local function shadow_postinit(inst)
    inst.components.inventoryitem.canbepickedup = false
end

local function shadow_onuse(inst,doer)
    doer:AddDebuff("shadow_attack","buff_attack")
    inst.components.rechargeable:Discharge(TUNING.TOTAL_DAY_TIME)
    if doer.isplayer then
        for k, v in pairs(doer.components.inventory.itemslots) do
            if v:HasAnyTag("shadowmagic","shadow_item") then
                if v:HasTag("NIGHTMARE_fueled") then
                    v.components.fueled:SetPercent(1)
                end
            end
            if v:HasTags("rechargeable","pocketwatch") then
                v.components.rechargeable:SetPercent(1)
            end
        end
    end
end

local function OnDischarged(inst)
    inst:RemoveComponent("toggleableitem")
end

local function makesoul(name,colour,postinitfn,givebuff)
    local function SetUpToggleable(inst)
        inst:AddComponent("toggleableitem")
        inst.components.toggleableitem:SetOnToggleFn(givebuff)
    end
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        RemovePhysicsColliders(inst)

        inst.AnimState:SetBank("willow_embers")
        inst.AnimState:SetBuild("willow_embers")
        inst.AnimState:PlayAnimation("idle_loop", true)
        inst.AnimState:SetMultColour(colour[1],colour[2],colour[3],1)

        inst:AddTag("nosteal")
        inst:AddTag("cs_soul")
        --waterproofer (from waterproofer component) added to pristine state for optimization
        inst:AddTag("waterproofer")

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end
        inst:AddComponent("tradable")

        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")

        if postinitfn~=nil then
            postinitfn(inst)
        end

        inst:AddComponent("waterproofer")
        inst.components.waterproofer:SetEffectiveness(0)

        inst:AddComponent("rechargeable")
        inst.components.rechargeable:SetOnDischargedFn(OnDischarged)
        inst.components.rechargeable:SetOnChargedFn(SetUpToggleable)
        SetUpToggleable(inst)
        

    
        return inst
    end
    return Prefab(name.."_soul", fn, assets)
end

return makesoul("insight",{127/255,1,0},nil,insight_givebuff),
        makesoul("iron",{1, 20/255 ,147/255},iron_postinit,iron_givebuff),
        makesoul("shadow",{75/255,0,130/255},shadow_postinit,shadow_onuse)
