AddClassPostConstruct("screens/playerhud",function(self)
	local PoisonOver = require("widgets/poisonover")
	local fn =self.CreateOverlays
	function self:CreateOverlays(owner)
		fn(self, owner)
		self.poisonover = self.overlayroot:AddChild(PoisonOver(owner))
	end
	
end)


if GetModConfigData("buff_info") then
	AddClassPostConstruct("widgets/redux/craftingmenu_hud", function(self)
		local BuffPanel = require("widgets/cs_buffpanel")
		self.newconstant_BuffPanel = self:AddChild(BuffPanel(self.owner))
		local oldOpen = self.Open
		self.Open = function(self)
			oldOpen(self)
			self.newconstant_BuffPanel:Hide()
		end
	
		local oldClose=self.Close
		self.Close = function(self)
			oldClose(self)
			self.newconstant_BuffPanel:Show()
		end
	end)
end


local function OnPoisonOverDirty(inst)
	if inst._parent and inst._parent.HUD then
		inst._parent.HUD.poisonover:Flash()
	end
end

AddPrefabPostInit("player_classified", function(inst)
	inst.poisonover = net_event(inst.GUID, "cs_poison.poisonover")

	inst:ListenForEvent("cs_poison.poisonover", OnPoisonOverDirty)	
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


