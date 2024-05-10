--[[local function BossRush(inst)
    inst:SetEngaged(true)
    inst.DropItem = function ()end
    inst:SetEquip("swing", "object")
    inst:SetEquip("tackle", "spike")
    inst:SetEquip("cannon", "cannon")
end
AddPrefabPostInit("daywalker2",function(inst)
    if not TheWorld.ismastersim then return end
    inst:DoTaskInTime(1,BossRush)
end)]]


