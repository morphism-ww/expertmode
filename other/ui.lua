AddClassPostConstruct("screens/playerhud",function(inst)
	local PoisonOver = require("widgets/poisonover")
	local fn =inst.CreateOverlays
	function inst:CreateOverlays(owner)
		fn(self, owner)
		self.poisonover = self.overlayroot:AddChild(PoisonOver(owner))
	end
end)

local function OnPoisonOverDirty(inst)
	if inst._parent and inst._parent.HUD then
		if inst.poisonover:value() then
			inst._parent.HUD.poisonover:Flash()
		end
	end
end

AddPrefabPostInit("player_classified", function(inst)
	inst.poisonover = GLOBAL.net_bool(inst.GUID, "poison.poisonover", "poisonoverdirty")
	inst:ListenForEvent("poisonoverdirty", OnPoisonOverDirty)
end)


