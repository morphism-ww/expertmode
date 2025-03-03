local AddPlayerPostInit = AddPlayerPostInit
local AddPrefabPostInit = AddPrefabPostInit

GLOBAL.setfenv(1,GLOBAL)

local SourceModifierList = require("util/sourcemodifierlist")

local function AbyssClient(inst,area)
    local enter_abyss = area ~= nil and area.tags and table.contains(area.tags, "Abyss")
    local enter_acid = area~=nil and area.id and string.find(area.id,"Night_Land")
    if enter_acid then
        inst._acidfx.particles_per_tick = 10
        inst._acidfx.splashes_per_tick = 1
    else
        inst._acidfx.particles_per_tick = 0
        inst._acidfx.splashes_per_tick = 0
    end
    if enter_abyss then
        if inst.HUD and inst.HUD.controls.minimap_small then
            local map_w,map_h = inst.HUD.controls.minimap_small.img:GetSize()
            inst.HUD.controls.minimap_small:SetTextureHandle(10)
            inst.HUD.controls.minimap_small.img:SetSize(map_w,map_h,0)
        end
       
        TheWorld:PushEvent("enabledynamicmusic", false)
        if not TheFocalPoint.SoundEmitter:PlayingSound("AbyssPressure") then
            TheFocalPoint.SoundEmitter:PlaySound("calamita_sound/abyss/void","AbyssPressure")
        end
    else
        if inst.HUD and inst.HUD.controls.minimap_small then
            local map_w,map_h = inst.HUD.controls.minimap_small.img:GetSize()
            inst.HUD.controls.minimap_small:UpdateTexture()
            inst.HUD.controls.minimap_small.img:SetSize(map_w,map_h,0)
        end 
        TheWorld:PushEvent("enabledynamicmusic", true)
        if TheFocalPoint.SoundEmitter:PlayingSound("AbyssPressure") then
            TheFocalPoint.SoundEmitter:KillSound("AbyssPressure") 
        end
    end
end


local function RegisterListenerForState(inst)
    local old_onadd_debuff = inst.components.debuffable.ondebuffadded
    inst.components.debuffable.ondebuffadded = function (inst, name, ent, data)
        if old_onadd_debuff~=nil then
            old_onadd_debuff(inst, name, ent, data)
        end
        if ent.newcs_debuff and inst.components.newcs_talisman:TryResist() then
            inst.components.debuffable:RemoveDebuff(name)
            return
        end
        inst.components.statemeter:SetDebuffInfo(ent,name)
    end

    local old_adddebuff = inst.components.debuffable.AddDebuff
    inst.components.debuffable.AddDebuff = function (self,name,prefab,data)
        
        local is_extend = self.enable and self.debuffs[name]
        local ent = old_adddebuff(self,name,prefab,data)
        if is_extend then
            inst.components.statemeter:SetDebuffInfo(ent,name)
        end
    end

    local old_removedebuff = inst.components.debuffable.ondebuffremoved
    inst.components.debuffable.ondebuffremoved = function (inst,name,prefab)
        if old_removedebuff~=nil then
            old_removedebuff(inst,name,prefab)
        end
        inst.components.statemeter:ClearState(name)
    end
    
    local old_temp = inst.components.temperature.SetTemperatureInBelly
    inst.components.temperature.SetTemperatureInBelly = function (self,delta, duration)
        old_temp(self,delta, duration)
        local name = delta>0 and "medal_temperature_up" or "medal_temperature_down"
        inst.components.statemeter:AddState(name,duration)
    end
    --"medal_wormlight"
end

AddPlayerPostInit(function(inst)
    inst:AddTag("IRON_SOUL_upgradeuser")
    inst:AddTag("_statemeter")

    if not TheNet:IsDedicated() and TheWorld:HasTag("cave") then
        inst._acidfx = SpawnPrefab("caveacidrain")
        inst._acidfx.entity:SetParent(inst.entity)
        inst:ListenForEvent("changearea", AbyssClient) 
    end

    if not TheWorld.ismastersim then
        return
    end

    inst:RemoveTag("__statemeter")

    inst:AddComponent("statemeter")

    RegisterListenerForState(inst)    

    if TheWorld:HasTag("cave") then
        inst:AddComponent("abysscurse")
        inst:AddComponent("transformlimit")
    end


    inst._stunprotecter = SourceModifierList(inst, false, SourceModifierList.boolean)


    inst:AddComponent("newcs_talisman")
end)

if not TheNet:GetIsMasterSimulation() then
    return
end

AddPrefabPostInit("wolfgang",function (inst)
    inst.components.sanity.soul_loss_rate = 2
end)

AddPrefabPostInit("wanda",function (inst)
    inst.components.sanity.soul_loss_rate = 0.5
end)

AddPrefabPostInit("waxwell",function (inst)
    inst.components.sanity.soul_loss_rate = 0.5
end)