
local function OnStartTeleporting(inst, doer)
    if doer:HasTag("player") then
        if doer.components.talker ~= nil then
            doer.components.talker:ShutUp()
        end
        if doer.components.sanity ~= nil then
            doer.components.sanity:DoDelta(-20)
        end
    end
end    
AddPrefabPostInit("townportaltalisman",function(inst)
    inst:AddTag("action_pulls_up_map")
    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.teleporter.onActivate = OnStartTeleporting

end)
--------------------------------------------------------------

AddPrefabPostInit("townportal",function(inst)
    inst.entity:SetCanSleep(false)
end)


local function AcceptGift(self,giver, item, count)
    if not self:AbleToAccept(item, giver, count) then
        return false
    end

    if self:WantsToAccept(item, giver, count) then
        count = count or 1

        if item.components.stackable ~= nil then
            count=math.min(item.components.stackable.stacksize,20)
            item = item.components.stackable:Get(count)
        else
            item.components.inventoryitem:RemoveFromOwner(true)
        end

        item:Remove()

        if self.onaccept ~= nil then
            self.onaccept(self.inst, giver, item, count)
        end

        self.inst:PushEvent("trade", { giver = giver, item = item })

        return true
    end

    if self.onrefuse ~= nil then
        self.onrefuse(self.inst, giver, item)
    end
    return false
end

local ANTLION_RAGE_TIMER = "rage"

local function OnGivenItem(inst, giver, item, count)
    if item.currentTempRange ~= nil then
        -- NOTES(JBK): currentTempRange is only on heatrock and now dumbbell_heat no need to check prefab here.
        local trigger =
            (item.currentTempRange <= 1 and "freeze") or
            (item.currentTempRange >= 4 and "burn") or
            nil
        if trigger ~= nil then
            inst:PushEvent("onacceptfighttribute", { tributer = giver, trigger = trigger })
            return
        end
    end
    count=count or 1
    local function give_manyitem(item,count)
        local item_stack={}
        for i=1,count do
            item_stack[i]=item
        end
        return item_stack
    end

    inst.tributer = giver
    inst.pendingrewarditem =
        (item.prefab == "antliontrinket" and {"townportal_blueprint", "antlionhat_blueprint"}) or
		(item.prefab == "cotl_trinket" and {"turf_cotl_brick_blueprint", "turf_cotl_gold_blueprint", "cotl_tabernacle_level1_blueprint"}) or
        (item.components.tradable.goldvalue > 0 and give_manyitem("townportaltalisman",count)) or
        nil

    local rage_calming = item.components.tradable.rocktribute * TUNING.ANTLION_TRIBUTE_TO_RAGE_TIME
    inst.maxragetime = math.min(inst.maxragetime + rage_calming, TUNING.ANTLION_RAGE_TIME_MAX)

    local timeleft = inst.components.worldsettingstimer:GetTimeLeft(ANTLION_RAGE_TIMER)
    if timeleft ~= nil then
        timeleft = math.min(timeleft + rage_calming, TUNING.ANTLION_RAGE_TIME_MAX)
        inst.components.worldsettingstimer:SetTimeLeft(ANTLION_RAGE_TIMER, timeleft)
        inst.components.worldsettingstimer:ResumeTimer(ANTLION_RAGE_TIMER)
    else
        inst.components.worldsettingstimer:StartTimer(ANTLION_RAGE_TIMER, inst.maxragetime)
    end
    inst.components.sinkholespawner:StopSinkholes()

    inst:PushEvent("onaccepttribute", { tributepercent = (timeleft or 0) / TUNING.ANTLION_RAGE_TIME_MAX })

    if giver ~= nil and giver.components.talker ~= nil and GetTime() - (inst.timesincelasttalker or -TUNING.ANTLION_TRIBUTER_TALKER_TIME) > TUNING.ANTLION_TRIBUTER_TALKER_TIME then
        inst.timesincelasttalker = GetTime()
        giver.components.talker:Say(GetString(giver, "ANNOUNCE_ANTLION_TRIBUTE"))
    end
end

AddPrefabPostInit("antlion",function(inst)
    if not TheWorld.ismastersim then return end
    inst.components.trader.AcceptGift=AcceptGift
    inst.components.trader.onaccept = OnGivenItem
end)


