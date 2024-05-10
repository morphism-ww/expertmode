AddPrefabPostInit("shadowheart",function(inst)
    if not TheWorld.ismastersim then return end
    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.NIGHTMARE
    inst.components.fueled:InitializeFuelLevel(4 * TUNING.LARGE_FUEL)
    inst.components.fueled.accepting = true
end)


local NUM_FORMS = 3
local MAX_MOUND_SIZE = 8
local MOUND_WRONG_START_SIZE = 5
local ATRIUM_RANGE = 8.5

local function ActiveStargate(gate)
    return gate:IsWaitingForStalker()
end

local STARGET_TAGS = { "stargate" }
local STALKER_TAGS = { "stalker" }
local SHADOWHEART_TAGS = {"shadowheart"}
local function ItemTradeTest(inst, item, giver)
    if item == nil or item.prefab ~= "shadowheart" or
        giver == nil or giver.components.areaaware == nil then
        return false
    elseif inst.form ~= 1 then
        return false, "WRONGSHADOWFORM"
    elseif not TheWorld.state.isnight then
        return false, "CANTSHADOWREVIVE"
    elseif giver.components.areaaware:CurrentlyInTag("Atrium")
        and (   FindEntity(inst, ATRIUM_RANGE, ActiveStargate, STARGET_TAGS) == nil or
                GetClosestInstWithTag(STALKER_TAGS, inst, 40) ~= nil  and item.components.fueled:GetPercent()<1 ) then
        return false, "CANTSHADOWREVIVE"
    end

    return true
end
AddPrefabPostInit("fossil_stalker",function (inst)
    inst:AddTag("notraptrigger")
    inst:AddTag("toughworker")
    inst:AddTag("electricdamageimmune")
    if not TheWorld.ismastersim then return end
    inst.components.trader:SetAbleToAcceptTest(ItemTradeTest)
end)

AddStategraphPostInit("SGstalker",function (sg)
    table.insert(sg.states.death3_pst.timeline,
        TimeEvent(305 * FRAMES, function(inst)
                local pos = inst:GetPosition()
                local heart=SpawnPrefab("shadowheart")
                heart.components.fueled:MakeEmpty()
                heart.Transform:SetPosition(pos:Get())
        end))
end)