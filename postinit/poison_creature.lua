--spider,spider_warrior,spider_dropper,spider_water,spiderqueen



newcs_env.AddPrefabPostInit("spider_warrior",function(inst)
    if not TheWorld.ismastersim then return end
    inst.components.combat.onhitotherfn = function (inst,target, damage, stimuli, weapon, damageresolved, spdamage, damageredirecttarget)
        if target:IsPoisonable() and not target.entity:HasAnyTag("spiderwhisperer","spider") and damageredirecttarget==nil then
            target:AddDebuff("spider_poison","buff_poison")
        end
    end    
    
end)


local dead_poison_spider = {"spiderqueen","spider_dropper","spider_hider","spider_moon"}

for i,v in ipairs(dead_poison_spider) do
    newcs_env.AddPrefabPostInit(v,function(inst)
        if not TheWorld.ismastersim then return end
        inst.components.combat.onhitotherfn = function (inst,target, damage, stimuli, weapon, damageresolved, spdamage, damageredirecttarget)
            if target:IsPoisonable() and not target.entity:HasAnyTag("spiderwhisperer","spider")  and damageredirecttarget==nil then
                target:AddDebuff("spider_poison","buff_poison")
                target:AddDebuff("spider_dead_poison","buff_deadpoison")
            end
        end
    end)
end


newcs_env.AddPrefabPostInit("spider_spitter",function (inst)
    if not TheWorld.ismastersim then return end
    inst.components.combat.onhitotherfn = function (inst,target, damage, stimuli, weapon, damageresolved, spdamage, damageredirecttarget)
        if target:IsPoisonable()  and damageredirecttarget==nil then
            target:AddDebuff("buff_weak","buff_weak")
        end
    end    
end)


-----------------------------------------------------------
local function dobeepoison(inst,data)
    if data.target:IsPoisonable() and not data.redirected then
        data.target:AddDebuff("bee_poison","buff_poison")
    end
end


newcs_env.AddPrefabPostInit("killerbee",function (inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("onhitother",dobeepoison)
end)