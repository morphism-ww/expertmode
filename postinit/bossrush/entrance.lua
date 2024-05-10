require("worldsettingsutil")
local function Enable_gate(inst,ispowered)
	if ispowered and not TheWorld.components.voidland_manager.bossrush_on and inst.components.charliecutscene:IsGateRepaired()  then
        inst:AddTag("planar_portal")
    else
        inst:RemoveTag("planar_portal")
    end      
end


local function ShowFx(inst, state)
    if inst._gatefx == nil then
        inst._gatefx = SpawnPrefab("atrium_gate_activatedfx")
        inst._gatefx.entity:SetParent(inst.entity)
        table.insert(inst.highlightchildren, inst._gatefx)
    end
    inst._gatefx:SetFX(state)
end

local function HideFx(inst)
    if inst._gatefx ~= nil then
        inst._gatefx:KillFX()
        inst._gatefx = nil
    end
end

local function end_portal(inst)
    inst._powered = false
    if TheWorld.components.voidland_manager:HasPlayer() then
        TheWorld.components.voidland_manager:StartBossRush()
        TheWorld:PushEvent("bossrush")
    end
    HideFx(inst)
    inst.AnimState:PlayAnimation("idle")
    inst.SoundEmitter:KillSound("loop")
    inst.components.teleporter:SetEnabled(false)    
    inst.components.pickable.caninteractwith = true
end

local function OpenPortal(inst)
    inst._powered = true
    inst:RemoveTag("planar_portal")
    inst.components.pickable.caninteractwith = false
    ShowFx(inst, "overload")

    inst.components.teleporter:SetEnabled(true)
    inst.AnimState:PlayAnimation("overload_pulse")
    inst.AnimState:PushAnimation("overload_loop")
    --[[if not inst.components.worldsettingstimer:ActiveTimerExists("bossrush") then
        --inst.components.worldsettingstimer:StartTimer("bossrush", 240)
    end]]
    if not inst.components.timer:TimerExists("bossrush") then
        inst.components.timer:StartTimer("bossrush", 30)
    end
    inst.SoundEmitter:PlaySound("dontstarve/common/together/atrium_gate/destabilize_LP", "loop")
end

local function SpawnLand(inst)
    local voidland_manager =TheWorld.components.voidland_manager
    if voidland_manager~=nil and not voidland_manager:HasLand() then
        voidland_manager:GenerateLand(inst)
    end  
end

local function BossrushFilter(inst, action)
    return action.mount_valid and not (action==ACTIONS.BUILD or actions==ACTIONS.DEPLOY)
end

local function OnActivate(inst, doer)
    if doer.components.talker ~= nil then
        doer.components.talker:ShutUp()
    end
    if doer.components.playercontroller == nil then
        inst.components.playeractionpicker:PushActionFilter(BossrushFilter, 20)
    end
    doer.player_classified.MapExplorer:EnableUpdate(false)
    if doer.components.playercontroller ~= nil then
        doer.components.playercontroller:EnableMapControls(false)
    end
    if doer.components.maprevealable~=nil then
        doer.components.maprevealable:Stop()
    end
    TheWorld.components.voidland_manager:RegisterPlayer(doer)
end

AddPrefabPostInit("atrium_gate",function(inst)
    if not TheWorld.ismastersim then return end

    
   
    inst:AddComponent("teleporter")
    inst.components.teleporter.onActivate = OnActivate
    inst.components.teleporter.offset = 0
    inst.components.teleporter:SetEnabled(false)
    

    
    inst:AddComponent("timer")

    inst.OpenPortal = OpenPortal
    inst:ListenForEvent("timerdone",end_portal)
    inst:ListenForEvent("atriumpowered",function (world,ispowered)
        Enable_gate(inst,ispowered)
    end,  TheWorld)
    inst:ListenForEvent("bossrush_end",function (world)
		inst:StartCooldown(true)
        TheWorld:PushEvent("atriumpowered", false)
        TheWorld:PushEvent("ms_locknightmarephase", nil)
        TheWorld:PushEvent("unpausequakes", { source = inst })
        TheWorld:PushEvent("unpausehounded", { source = inst })
	end,TheWorld)
    inst:DoTaskInTime(0,SpawnLand)
end)


AddPrefabPostInit("alterguardianhatshard",function (inst)
    inst:AddTag("portal_key")
    if not TheWorld.ismastersim then return end

    inst:AddComponent("portal_key")
end)


