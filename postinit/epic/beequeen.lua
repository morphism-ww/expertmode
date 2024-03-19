local function PoisonOther(inst, data)
    if data.target ~= nil and data.target:HasTag("player") then
		data.target:AddDebuff("beequeen_poison", "poison_2",{upgrade=true,duration=30})
    end
end
AddPrefabPostInit("beequeen",function(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("onattackother", PoisonOther)
end)


