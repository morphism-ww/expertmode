local assets =
{
    Asset("ANIM", "anim/swap_dread_cloak.zip"),
    Asset("ANIM", "anim/swap_dread_cloak2.zip"),
}



local function CheckSwapAnims(inst, owner_unequip)
    if inst.components.equippable:IsEquipped() then
        local owner = inst.components.inventoryitem.owner

        for k, v in pairs(inst.swap_anims) do
            v:Show()
            v.entity:SetParent(owner.entity)

            if v.components.highlightchild then
                v.components.highlightchild:SetOwner(owner)
            end

            if owner.components.colouradder ~= nil then
                owner.components.colouradder:AttachChild(v)
            end
        end

        inst.swap_anims.cloak_down.Follower:FollowSymbol(owner.GUID, "swap_body", nil, nil, nil, true, nil, 9)
        inst.swap_anims.cloak_side.Follower:FollowSymbol(owner.GUID, "swap_body", nil, nil, nil, true, nil, 3, 6)

        local lut = {
            "armor_down_1",
            "armor_down_2",
            "armor_down_3",

            "armor_side_1",
            "armor_side_2",
            "armor_side_3",

            "armor_up_1",
            "armor_up_2",
            "armor_up_3",
        }

        for i, v in pairs(lut) do
            inst.swap_anims[v].Follower:FollowSymbol(owner.GUID, "swap_body", nil, nil, nil, true, nil, i - 1)
        end

        inst.swap_anims.cloak_up.Follower:FollowSymbol(owner.GUID, "swap_body", nil, nil, nil, true, nil, 6, 9)


        -- Static symbol, only contains up body anim
        -- owner.AnimState:OverrideSymbol("swap_body", "swap_dread_cloak2", "swap_body")
    else
        for k, v in pairs(inst.swap_anims) do
            v:Hide()
            v.entity:SetParent(inst.entity)

            v.Follower:FollowSymbol(inst.GUID, "swap_body", nil, nil, nil, true)

            if v.components.highlightchild then
                v.components.highlightchild:SetOwner(inst)
            end

            if owner_unequip and owner_unequip.components.colouradder ~= nil then
                owner_unequip.components.colouradder:DetachChild(v)
            end
        end

        if owner_unequip then
            owner_unequip.AnimState:ClearOverrideSymbol("swap_body")
        end
    end
end

local function onequip(inst, owner)
    CheckSwapAnims(inst)
end

local function onunequip(inst, owner)
    CheckSwapAnims(inst, owner)
    owner.AnimState:ClearOverrideSymbol("swap_body")
end



local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("swap_dread_cloak2")
    inst.AnimState:SetBuild("swap_dread_cloak2")
    inst.AnimState:PlayAnimation("anim")

    inst.foleysound = "dontstarve/movement/foley/logarmour"

    MakeInventoryFloatable(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end


    inst:AddComponent("inventoryitem")    

    inst:AddComponent("equippable")
    inst.components.equippable.equipslot = EQUIPSLOTS.BODY
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)


    MakeHauntableLaunch(inst)


    -- Create swapanims
    inst.swap_anims = {
        cloak_up = inst:SpawnChild("dread_cloak_swapanim_cloak"),
        cloak_side = inst:SpawnChild("dread_cloak_swapanim_cloak"),
        cloak_down = inst:SpawnChild("dread_cloak_swapanim_cloak"),


        armor_down_1 = inst:SpawnChild("dread_cloak_swapanim_armor"),
        armor_down_2 = inst:SpawnChild("dread_cloak_swapanim_armor"),
        armor_down_3 = inst:SpawnChild("dread_cloak_swapanim_armor"),

        armor_side_1 = inst:SpawnChild("dread_cloak_swapanim_armor"),
        armor_side_2 = inst:SpawnChild("dread_cloak_swapanim_armor"),
        armor_side_3 = inst:SpawnChild("dread_cloak_swapanim_armor"),

        armor_up_1 = inst:SpawnChild("dread_cloak_swapanim_armor"),
        armor_up_2 = inst:SpawnChild("dread_cloak_swapanim_armor"),
        armor_up_3 = inst:SpawnChild("dread_cloak_swapanim_armor"),
    }

    for k, v in pairs(inst.swap_anims) do
        v.entity:AddFollower()
    end

    inst.swap_anims.cloak_up.AnimState:PlayAnimation("idle1", true)
    inst.swap_anims.cloak_side.AnimState:PlayAnimation("idle4", true)
    inst.swap_anims.cloak_down.AnimState:PlayAnimation("idle1", true)

    inst.swap_anims.armor_down_1.AnimState:PlayAnimation("idle1", true)
    inst.swap_anims.armor_down_2.AnimState:PlayAnimation("idle2", true)
    inst.swap_anims.armor_down_3.AnimState:PlayAnimation("idle3", true)

    inst.swap_anims.armor_side_1.AnimState:PlayAnimation("idle4", true)
    inst.swap_anims.armor_side_2.AnimState:PlayAnimation("idle5", true)
    inst.swap_anims.armor_side_3.AnimState:PlayAnimation("idle6", true)

    inst.swap_anims.armor_up_1.AnimState:PlayAnimation("idle7", true)
    inst.swap_anims.armor_up_2.AnimState:PlayAnimation("idle8", true)
    inst.swap_anims.armor_up_3.AnimState:PlayAnimation("idle9", true)



    CheckSwapAnims(inst)

    return inst
end

local function cloak_animfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("swap_dread_cloak")
    inst.AnimState:SetBuild("swap_dread_cloak")

    inst:AddComponent("highlightchild")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end

local function armor_animfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("swap_dread_cloak2")
    inst.AnimState:SetBuild("swap_dread_cloak2")

    inst:AddComponent("highlightchild")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    return inst
end



return Prefab("armor_nightmare", fn, assets),
    Prefab("dread_cloak_swapanim_cloak", cloak_animfn, assets),
    Prefab("dread_cloak_swapanim_armor", armor_animfn, assets)
