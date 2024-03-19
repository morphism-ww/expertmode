--spider,spider_warrieor,spider_dropper,spider_water,spiderqueen

local poison_spider={"spider","spider_warrieor","spider_water"}
local total_day_time=TUNING.TOTAL_DAY_TIME

local function dospiderpoison1(inst,data)
    if data then
        local target=data.target
        if target~=nil and target:HasTag("character") and not target:HasTag("ghost") and
             not(target.components.inventory~=nil and target.components.inventory:EquipHasTag("poison_immune")) then
            target:AddDebuff("spider_poison","poison",{duration=total_day_time})
        end
    end
end

for i,v in ipairs(poison_spider) do
    AddPrefabPostInit(v,function(inst)
        if not TheWorld.ismastersim then return end
        inst:ListenForEvent("onhitother",dospiderpoison1)
    end)
end

local dead_poison_spider={"spiderqueen","spider_dropper","spider_hider","spider_moon"}


local function dospiderpoison2(inst,data)
    if data then
        local target=data.target
        if target~=nil and target:HasTag("character") and not target:HasTag("ghost") and
             not(target.components.inventory~=nil and target.components.inventory:EquipHasTag("poison_immune")) then
                target:AddDebuff("spider_poison","poison",{duration=total_day_time})
                target:AddDebuff("spider_dead_poison","poison_2",{duration=20})
        end
    end
end

for i,v in ipairs(dead_poison_spider) do
    AddPrefabPostInit(v,function(inst)
        if not TheWorld.ismastersim then return end
        inst:ListenForEvent("onhitother",dospiderpoison2)
    end)
end

local function dospiderweak(inst,data)
    if data then
        local target=data.target
        if target~=nil and target:HasTag("character") and not target:HasTag("ghost") and
             not(target.components.inventory~=nil and target.components.inventory:EquipHasTag("poison_immune")) then
                target:AddDebuff("spider_weak","weak",{duration=40,speed=0.6})
        end
    end
end

AddPrefabPostInit("spider_spitter",function (inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("onhitother",dospiderweak)
end)



-----------------------------------------------------------
local function dobeepoison(inst,data)
    if data then
        local target=data.target
        if target~=nil and target:HasTag("character") and not target:HasTag("ghost") and
             not(target.components.inventory~=nil and target.components.inventory:EquipHasTag("poison_immune")) then
                target:AddDebuff("bee_poison","poison",{duration=total_day_time})
        end
    end
end

AddPrefabPostInit("bee",function (inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("onhitother",dobeepoison)
end)


AddPrefabPostInit("killerbee",function (inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("onhitother",dobeepoison)
end)
----------------------------------------------------------