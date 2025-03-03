AddClassPostConstruct("screens/playerhud",function(self)
	local PoisonOver = require("widgets/poisonover")
	local old_CreateOverlays = self.CreateOverlays
	function self:CreateOverlays(owner)
		old_CreateOverlays(self, owner)
		self.poisonover = self.overlayroot:AddChild(PoisonOver(owner))
	end	
end)


if GetModConfigData("buff_info") then
	local BuffPanel = require("widgets/newcs_buffpanel")
	AddClassPostConstruct("widgets/statusdisplays", function(self)
		self.newcs_statepanel = self:AddChild(BuffPanel(self.owner))

		local old_Show = self.ShowStatusNumbers
		function self:ShowStatusNumbers()
			old_Show(self)
			self.newcs_statepanel:Show()
		end

		local old_Hide = self.HideStatusNumbers
		function self:HideStatusNumbers()
			old_Hide(self)
			self.newcs_statepanel:Hide()
		end

		local old_ghostMode = self.SetGhostMode
		function self:SetGhostMode(ghostmode)
			if not self.isghostmode == not ghostmode then --force boolean
				return
			end
			old_ghostMode(self,ghostmode)
			if ghostmode then
				self.newcs_statepanel:Hide()
			else
				self.newcs_statepanel:Show()
			end
		end
	end)
end

local EMPTY_FUNC = function ()end
AddClassPostConstruct("widgets/itemtile",function (self,invitem)
	if invitem.itemtile_colour then
		self.tooltipcolour = invitem.itemtile_colour
		self.SetTooltipColour = EMPTY_FUNC
	end
end)