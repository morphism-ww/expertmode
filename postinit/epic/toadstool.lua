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




local function onspawnfn(inst, spawn)
    local pos = inst:GetPosition()

    local offset = FindWalkableOffset(
        pos,
        math.random() * 2 * PI,
        3 + inst:GetPhysicsRadius(0),
        8
    )
    local off_x = (offset and offset.x) or 0
    local off_z = (offset and offset.z) or 0
    spawn.Transform:SetPosition(pos.x + off_x, 0, pos.z + off_z)
end


AddPrefabPostInit("toadstool",function(inst)
    if not TheWorld.ismastersim then return end
    inst:AddComponent("periodicspawner")
    inst.components.periodicspawner:SetPrefab("spore_poison")
    inst.components.periodicspawner:SetOnSpawnFn(onspawnfn)
    inst.components.periodicspawner:SetRandomTimes(8, 10)
    inst.components.periodicspawner:Start()
end)

AddStategraphPostInit("SGtoadstool",function(sg)
    sg.states.roar.timeline[5]=
    TimeEvent(20 * FRAMES, function(inst)
        local duration= (inst.dark and 120) or 90
        for k, v in pairs(inst.components.grouptargeter.targets) do
            if not k.components.health:IsDead() and k:DebuffsEnabled() then
                k:AddDebuff("toad_weak","weak",{duration=duration,speed=0.5})
                k:AddDebuff("life_break","exhaustion",{duration=30})
            end
            if k.components.inventory then
                k.components.inventory:DropEquipped(true)
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

local function LeaveSpore(inst)
    SpawnPrefab("spore_poison").Transform:SetPosition(inst.Transform:GetWorldPosition())
end


AddPrefabPostInit("mushroombomb",function(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("onhitother", PoisonOther2)
    inst:ListenForEvent("mushroombomb._explode", LeaveSpore)
end)

AddPrefabPostInit("mushroombomb_dark",function(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("onhitother", PoisonOther2)
    inst:ListenForEvent("mushroombomb._explode", LeaveSpore)
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

local function AlignToTarget(inst, target)
    inst.Transform:SetRotation(target.Transform:GetRotation())
end

local function OnChangeFollowSymbol(inst, target, followsymbol, followoffset)
    inst.Follower:FollowSymbol(target.GUID, followsymbol, followoffset.x, followoffset.y, followoffset.z)
end

local function OnAttached(inst, target, followsymbol, followoffset)
    inst.entity:SetParent(target.entity)
    inst._light.entity:SetParent(target.entity)
    OnChangeFollowSymbol(inst, target, followsymbol, followoffset)
    if inst._followtask ~= nil then
        inst._followtask:Cancel()
    end
    inst._followtask = inst:DoPeriodicTask(0, AlignToTarget, nil, target)
    AlignToTarget(inst, target)
    target:AddDebuff("toad_corrupt","corrupt",{duration=60})
    target:AddDebuff("toad_weak","weak",{duration=10,speed=0.7})
end



AddPrefabPostInit("sporebomb",function(inst)
    if not TheWorld.ismastersim then return end
    inst.components.debuff:SetAttachedFn(OnAttached)
end)