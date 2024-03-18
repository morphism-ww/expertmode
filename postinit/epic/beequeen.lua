local function PoisonOther(inst, data)
    --inst.components.stuckdetection:Reset()

    if data.target ~= nil and data.target:HasTag("player") then
		data.target:AddDebuff("bee_poison", "poison",{upgrade=true,duration=10})
    end
end
AddPrefabPostInit("beequeen",function(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("onattackother", PoisonOther)
end)


