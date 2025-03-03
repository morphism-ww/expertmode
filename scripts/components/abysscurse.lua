local function WeakenArmor(item,level)
    local planar_loss = -1.5*level
    local armor_loss = 1+level*0.1
    if item.components.planardefense~=nil then
        item.components.planardefense.externalbonuses:SetModifier(item, planar_loss,"abyss")
    end
    if item.components.armor~=nil then
        item.components.armor.conditionlossmultipliers:SetModifier(item, armor_loss,"abyss")
    end 
end


local function RemoveWeaken(item)
    if item.components.planardefense~=nil then
        item.components.planardefense.externalbonuses:RemoveModifier(item,"abyss")
    end
    if item.components.armor~=nil then
        item.components.armor.conditionlossmultipliers:RemoveModifier(item,"abyss")
    end
end


local function ArmorBrokeAbyss(inst,level)
    if level==1 then         
        if inst.components.sanity ~= nil then
            inst.components.sanity.externalmodifiers:SetModifier(inst, -TUNING.DAPPERNESS_MED,"abyss")
        end
    elseif level==2 then
        if inst.components.sanity ~= nil then
            inst.components.sanity.externalmodifiers:SetModifier(inst, -TUNING.DAPPERNESS_MED_LARGE,"abyss")
        end
        if inst.components.inventory~=nil then
            inst.components.inventory:ForEachEquipment(WeakenArmor,2)
        end
    elseif level==3 then
        
        if inst.components.sanity ~= nil then
            inst.components.sanity.externalmodifiers:SetModifier(inst, -TUNING.DAPPERNESS_HUGE,"abyss")
        end
        if inst.components.inventory~=nil then
            inst.components.inventory:ForEachEquipment(WeakenArmor,3)
        end
    end
end

local function LostInAbyss(inst)
    if inst.player_classified~=nil then
        inst.player_classified.MapExplorer:EnableUpdate(false)
    end
    if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:SetCanUseMap(false)
    end
    inst.components.statemeter:AddState("abyss_curse")
end

local function LeaveAbyss(self,inst)
    if inst.player_classified~=nil then
        inst.player_classified.MapExplorer:EnableUpdate(true)
    end
    if inst.components.playercontroller ~= nil then
        inst.components.playercontroller:SetCanUseMap(true)
    end
    
    inst.components.statemeter:ClearState("abyss_curse")

    self.level = 0
    if inst.components.sanity ~= nil then
        inst.components.sanity.externalmodifiers:RemoveModifier(inst,"abyss")
    end
    if inst.components.inventory~=nil then
        inst.components.inventory:ForEachEquipment(RemoveWeaken)
    end
    inst:RemoveEventCallback("equip",self.WeakenArmor)
    inst:RemoveEventCallback("unequip",self.ClearWeaken)
end


local function OnDarknessTile(inst,enable)
    local target_val = enable and inst.LightWatcher:GetLightValue() < 0.3
    local current_val = inst._parasiteoverlay:value()
    if  target_val~=current_val then
        inst._parasiteoverlay:set(target_val)
    end
end

local shadowthrall_parasite_onkilledsomething = function(inst)
    if TheWorld.components.shadowparasitemanager == nil then
        return
    end


    if inst.sg == nil or not (inst.sg:HasState("parasite_revive") or inst.sg:HasState("death_hosted")) then
        return
    end

    inst.shadowthrall_parasite_hosted_death = true
end

-----由于findnode对于边缘的噪声区无效，不得不使用areaaware

local AbyssCurse = Class(function(self, inst)
    self.inst = inst
    
    self.enter_abyss = false
    self.level = 0  ---no curse

    
    self.WeakenArmor = function (inst,data)
        if data.item~=nil then
            WeakenArmor(data.item,self.level)
        end
    end

    self.ClearWeaken = function (inst,data)
        if data.item~=nil then
            RemoveWeaken(data.item)
        end
    end

    self.voidland_manager = TheWorld.components.voidland_manager
    
    inst:ListenForEvent("respawnfromghost", function (player)
        if self.enter_abyss then
            LostInAbyss(player)
        end
    end)
    
    
    inst:ListenForEvent("changearea",function (player,area)
        self:UpdatePosition(area) 
    end)

    inst.components.areaaware:StartWatchingTile(WORLD_TILES.ABYSS_DARKNESS)
    inst:ListenForEvent("on_ABYSS_DARKNESS_tile", OnDarknessTile)

    
end)

function AbyssCurse:UpdatePosition(area)
    if area==nil then
        return
    end
    local node_index = self.inst.components.areaaware.current_area
    
    local in_abyss = self.voidland_manager.level_list[node_index]~=nil

    self.enter_abyss = in_abyss

    if in_abyss then
        
        local level = self.voidland_manager.level_list[node_index]
        local in_acid  = self.voidland_manager.acid_list[node_index]==true
        
        self.level = level

        LostInAbyss(self.inst)  ---迷失地图

        self.inst.components.acidlevel:OnAcidArea(in_acid)   ---酸雨
        
        ----碎甲
        self.inst:ListenForEvent("equip",self.WeakenArmor)
        self.inst:ListenForEvent("unequip",self.ClearWeaken)
        self.inst:ListenForEvent("death",shadowthrall_parasite_onkilledsomething)
        ArmorBrokeAbyss(self.inst,level)
    else
        LeaveAbyss(self,self.inst)
        self.inst:RemoveEventCallback("death",shadowthrall_parasite_onkilledsomething)
    end
end


return AbyssCurse