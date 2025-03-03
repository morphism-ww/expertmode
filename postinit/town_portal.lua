local function OnStartTeleporting(inst, doer)
    if doer:HasTag("player") then
        if doer.components.talker ~= nil then
            doer.components.talker:ShutUp()
        end
        if doer.components.sanity ~= nil then
            doer.components.sanity:DoDelta(-20)
        end
    end
    inst.components.stackable:Get():Remove()
end    




newcs_env.AddPrefabPostInit("townportaltalisman",function(inst)
    inst:AddTag("action_pulls_up_map")

    inst.valid_map_actions = {
        [ACTIONS.DOTOWNPORTAL] = true,
    }

    if not TheWorld.ismastersim then
        return inst
    end

    inst.components.teleporter.onActivate = OnStartTeleporting
    
end)
local function CreateHiddenGlobalIcon(inst)
    if inst.icon ~= nil then
        inst.icon:AddTag("townportaltrackericon")
    end
end
newcs_env.AddPrefabPostInit("townportal",function (inst)
    if not TheWorld.ismastersim then
        return inst
    end
    inst:DoTaskInTime(1, CreateHiddenGlobalIcon)
end)
--------------------------------------------------------------

newcs_env.AddPrefabPostInit("antlion", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    
    inst.components.trader.acceptstacks = true
    inst:DoTaskInTime(0,function ()
        local oldonacceptfn=inst.components.trader.onaccept
        inst.components.trader.onaccept=function(inst,giver,item,count)
            oldonacceptfn(inst,giver,item)
            if count>1 and inst.pendingrewarditem=="townportaltalisman" then
                inst.pendingrewarditem = {}
                for i = 1, count do
                    inst.pendingrewarditem[i] = "townportaltalisman"
                end
            end
        end
    end)
end)