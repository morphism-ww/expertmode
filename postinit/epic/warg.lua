local function Ondead(inst)
  SpawnPrefab("houndmound").Transform:SetPosition(inst.Transform:GetWorldPosition())
end

AddPrefabPostInit("warg",function(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("death", Ondead)
end)


