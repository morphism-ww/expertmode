local function CanBeUpgraded(inst, item)
    return inst.components.equippable~=nil and not inst.components.equippable:IsEquipped()
end

local function OnUpgraded(inst, upgrader, item)
    local skin_build, skin_id = inst:GetSkinBuild(), inst.skin_id
    if skin_build == nil or skin_build == "" or skin_id == 0 then
        skin_build, skin_id = nil, nil
    end
    local sword = SpawnPrefab("true_staff_lunarplant", skin_build, skin_id)

    sword.components.finiteuses:SetPercent(inst.components.finiteuses:GetPercent())

    local container = inst.components.inventoryitem:GetContainer()
    if container ~= nil then
        local slot = inst.components.inventoryitem:GetSlotNum()
        inst:Remove()
        container:GiveItem(sword, slot)
    else
        local x, y, z = inst.Transform:GetWorldPosition()
        inst:Remove()
        sword.Transform:SetPosition(x, y, z)
    end
end
AddPrefabPostInit("staff_lunarplant",function (inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst:AddComponent("upgradeable")
    inst.components.upgradeable.upgradetype = UPGRADETYPES.INSIGHT_SOUL
    inst.components.upgradeable:SetOnUpgradeFn(OnUpgraded)
    inst.components.upgradeable:SetCanUpgradeFn(CanBeUpgraded)
end)