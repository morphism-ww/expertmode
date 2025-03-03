local assets =
{
    Asset("ANIM", "anim/monkey_island_portal.zip"),
}



local function OnNightmarePhaseChanged(inst, phase)
    if phase == "wild"  then
        inst:Show()

        inst.components.trader:Enable()

    else
        inst:Hide()
        inst.components.trader:Disable()
    end
end

local function able_to_accept_trade_test(inst, item, giver,count)
    
    if item:HasTag("gem") or item.prefab == "thulecite" then
        if count==nil or count<3 then
            return false, "NOT_ENOUGH"
        else
            return true
        end    
    end

    return false,"GHOSTHEART"
end


local function on_accept_item(inst, giver, item)
    if next(inst.telePos)~=nil then
        local telepos = inst.telePos[math.random(1,#inst.telePos)]
        if giver.isplayer then
            giver.components.transformlimit:SetState(false)
        end
        giver.sg:GoToState("abyss_fall", telepos)
    end
end

local function ResisterTeleportPos(inst,ent)
    table.insert(inst.telePos,ent:GetPosition())
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()


    inst.AnimState:SetBank ("monkey_island_portal")
    inst.AnimState:SetBuild("monkey_island_portal")
    inst.AnimState:SetMultColour(0,0,0,0.5)
    inst.AnimState:PlayAnimation("out_idle", true)

    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetLightOverride(0.1)


    inst:AddTag("ignorewalkableplatforms")
    inst:AddTag("NOBLOCK")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:Hide()
    inst:AddComponent("inspectable")

    ----------------------------------------------------------
    inst:AddComponent("trader")
    inst.components.trader:SetAcceptStacks()
    inst.components.trader:SetAbleToAcceptTest(able_to_accept_trade_test)
    inst.components.trader.onaccept = on_accept_item

    inst.telePos = {}
    ----------------------------------------------------------


    inst:WatchWorldState("nightmarephase", OnNightmarePhaseChanged)
    OnNightmarePhaseChanged(inst, TheWorld.state.nightmarephase)

    inst:ListenForEvent("ms_registermigrationportal",function (world,ent)
        ResisterTeleportPos(inst,ent)
    end, TheWorld)

    ----------------------------------------------------------


    return inst
end

return Prefab("abyss_leak", fn, assets)