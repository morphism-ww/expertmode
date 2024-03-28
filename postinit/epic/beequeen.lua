local function PoisonOther(inst, data)
  if data then
    local target=data.target
    if target~=nil and target:HasTag("character") and not target:HasTag("ghost") and
          not(target.components.inventory~=nil and target.components.inventory:EquipHasTag("poison_immune")) then
            target:AddDebuff("beequeen_poison","poison_2",{duration=30,upgrade=true})
    end
  end
end
AddPrefabPostInit("beequeen",function(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("onattackother", PoisonOther)
end)


