local function AcceptTest(inst, item, giver)
    return item.prefab=="cave_banana"
end

local function OnGetItemFromPlayer(inst, giver, item)
    TheNet:Announce(giver.name.."的最终试炼开始了")
    local new_inst = ReplacePrefab(inst, "shadow_mfz")
    new_inst:PushEvent("upgrade")
end

--[[ddPrefabPostInit("punchingbag",function(inst)
    inst:AddTag("trader")
	if not TheWorld.ismastersim then
		return inst
	end
    inst:AddComponent("trader")

    inst.components.trader:SetAcceptTest(AcceptTest)
    inst.components.trader.onaccept = OnGetItemFromPlayer
end)]]
