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


AddClassPostConstruct("widgets/itemtile",function (self)
	function self:UpdateTooltip()
		local str = self:GetDescriptionString()
		self:SetTooltip(str)
		if self.item:HasTag("pure") then
			self:SetTooltipColour(64/255,224/255,208/255,1)
		elseif self.item:HasTag("ancient") then
			self:SetTooltipColour(218/255,165/255,32/255,1)	
		elseif self.item:GetIsWet() then
			self:SetTooltipColour(unpack(WET_TEXT_COLOUR))
		else
			self:SetTooltipColour(unpack(NORMAL_TEXT_COLOUR))
		end
	end
end)


--[[AddClassPostConstruct("widgets/craftingmenu_details",function (self)
	
end)]]


