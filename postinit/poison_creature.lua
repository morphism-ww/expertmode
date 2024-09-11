--spider,spider_warrior,spider_dropper,spider_water,spiderqueen



AddPrefabPostInit("spider_warrior",function(inst)
    if not TheWorld.ismastersim then return end
    inst.components.combat.onhitotherfn = function (inst,target, damage, stimuli, weapon, damageresolved, spdamage, damageredirecttarget)
        if target:IsPoisonable() and not target.entity:HasAnyTag("spiderwhisperer","spider") and damageredirecttarget==nil then
            target:AddDebuff("spider_poison","poison")
        end
    end    
    
end)


local dead_poison_spider = {"spiderqueen","spider_dropper","spider_hider","spider_moon"}

for i,v in ipairs(dead_poison_spider) do
    AddPrefabPostInit(v,function(inst)
        if not TheWorld.ismastersim then return end
        inst.components.combat.onhitotherfn = function (inst,target, damage, stimuli, weapon, damageresolved, spdamage, damageredirecttarget)
            if target:IsPoisonable() and not target.entity:HasAnyTag("spiderwhisperer","spider")  and damageredirecttarget==nil then
                target:AddDebuff("spider_poison","poison")
                target:AddDebuff("spider_dead_poison","poison_2")
            end
        end
    end)
end


AddPrefabPostInit("spider_spitter",function (inst)
    if not TheWorld.ismastersim then return end
    inst.components.combat.onhitotherfn = function (inst,target, damage, stimuli, weapon, damageresolved, spdamage, damageredirecttarget)
        if target:IsPoisonable()  and damageredirecttarget==nil then
            target:AddDebuff("weak","weak")
        end
    end    
end)


-----------------------------------------------------------
local function dobeepoison(inst,data)
    if data.target:IsPoisonable() and not data.redirected then
        data.target:AddDebuff("bee_poison","poison")
    end
end


AddPrefabPostInit("killerbee",function (inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("onhitother",dobeepoison)
end)