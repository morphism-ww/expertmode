TUNING.TOADSTOOL_SPEED_LVL =
        {
            [0] = 1,
            [1] = 2,
            [2] = 3,
            [3] = 4,
        }
TUNING.TOADSTOOL_MUSHROOMBOMB_COUNT_PHASE =
{
    [1] = 6,
    [2] = 7,
    [3] = 8,
}


AddStategraphPostInit("SGtoadstool",function(sg)
    sg.states.roar.timeline[5]=
    TimeEvent(20 * FRAMES, function(inst)
        local duration= (inst.dark and 120) or 90
        for k, v in pairs(inst.components.grouptargeter.targets) do
            if k:IsValid() and not k.components.health:IsDead() 
                and k:DebuffsEnabled() and inst:GetDistanceSqToInst(k)<100  then
                k:AddDebuff("toad_weak","weak",{duration=duration,speed=0.5})
                k:AddDebuff("life_break","exhaustion",{duration=30})
                local inventory = k.components.inventory
                if inventory~=nil then
                    for _, v in pairs(inventory.equipslots) do
                        if not (v:HasTag("nosteal") or v.components.equippable:ShouldPreventUnequipping()) then
                            inventory:DropItem(v, true, true)
                        end
                    end
                end
            end
        end
    end)
end)

local function PoisonOther2(inst, data)
    if data.target ~= nil and data.target:HasTag("player") then
		data.target:AddDebuff("toad_poison","poison_2",{upgrade=true,duration=40})
        data.target:AddDebuff("toad_weak","weak",{duration=60,speed=0.7})
    end
end



AddPrefabPostInit("mushroombomb",function(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("onhitother", PoisonOther2)
end)

AddPrefabPostInit("mushroombomb_dark",function(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("onhitother", PoisonOther2)
end)

local function WeakenTarget(inst,data)
    if data.target and data.target:DebuffsEnabled() then
        data.target:AddDebuff("food_sick","food_sickness",{duration=40})
        data.target:AddDebuff("toad_weak","weak",{duration=60,speed=0.7})
    end
end

AddPrefabPostInit("sporecloud",function(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("onareaattackother", WeakenTarget)
end)


