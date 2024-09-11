local function SetLeechAttached(inst, leech)
	
    leech:AttachPlayer(inst)
    local oldhat = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    if oldhat ~= nil then
        inst.components.inventory:DropItem(oldhat)
    end
    --inst.components.inventory:Equip(leech)
end



local function AttachLeech(inst, leech, noreact)
	SetLeechAttached(inst, leech)
	return true
end

local function EnterAbyss(inst, area)
	local enable_abyss = area ~= nil and area.tags and table.contains(area.tags, "Abyss")
    if enable_abyss then
        	
        if TheWorld.ismastersim then
            if inst.player_classified~=nil then
                inst.player_classified.MapExplorer:EnableUpdate(false)
            end
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:EnableMapControls(false)
            end
        else
            TheFocalPoint.SoundEmitter:PlaySound("abyss_sound/abyss_sound/void","AbyssPressure")
            TheFocalPoint.SoundEmitter:SetVolume("AbyssPressure", 0.3)
            
        end    
    else
        
        if TheWorld.ismastersim then
            if inst.player_classified~=nil then
                inst.player_classified.MapExplorer:EnableUpdate(true)
            end
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:EnableMapControls(true)
            end	
        else
            TheFocalPoint.SoundEmitter:KillSound("AbyssPressure")    
        end        
        	
    end    
end


AddPlayerPostInit(function(inst)
    inst:AddTag("IRON_SOUL_upgradeuser")

    inst:ListenForEvent("changearea", EnterAbyss) 

    if not TheWorld.ismastersim then
        return
    end

    inst.AttachLeech = AttachLeech

end)


