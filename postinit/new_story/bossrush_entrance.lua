require("worldsettingsutil")



--------------------------------------------------------------
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
---------------------------------------------------------------

local function OpenPortal(inst)
    inst._isopen = true
    inst:RemoveTag("klaussacklock")
    ShowFx(inst, "overload")
    inst.AnimState:PlayAnimation("overload_pulse")
    inst.AnimState:PushAnimation("overload_loop")
    inst.SoundEmitter:PlaySound("dontstarve/common/together/atrium_gate/destabilize_LP", "loop")
    inst.components.teleporter:SetEnabled(true)
    
end

local function ClosePortal(inst)
    inst._isopen = false
    inst:AddTag("klaussacklock")
    HideFx(inst)
    inst.AnimState:PlayAnimation("idle")
    inst.SoundEmitter:KillSound("loop")
    inst.components.teleporter:SetEnabled(false)    
end

--[[local function BossrushFilter(inst, action)
    return action.mount_valid and not (action==ACTIONS.BUILD or actions==ACTIONS.DEPLOY)
end]]

local function OnDoneTeleporting(inst, doer)
    if doer:HasTag("player") then
        if doer.player_classified~=nil then
			doer.player_classified.MapExplorer:EnableUpdate(true)
		end
		if doer.components.playercontroller ~= nil then
			doer.components.playercontroller:EnableMapControls(true)
		end
        
        TheWorld.components.voidland_manager:UnregisterPlayer(doer)
    end
end

local function OnActivate(inst, doer)

	--doer:RemoveDebuff("abyss_curse")
	if doer.isplayer then
        if doer.components.talker ~= nil then
            doer.components.talker:ShutUp()
        end
        if doer.player_classified~=nil then
			doer.player_classified.MapExplorer:EnableUpdate(false)
		end
		if doer.components.playercontroller ~= nil then
			doer.components.playercontroller:EnableMapControls(false)
		end
		doer.components.transformlimit:SetState(true)
	end
end

local function ForbiddenPortal(inst)
    inst._islocked = true
    inst:RemoveTag("klaussacklock")
    inst.components.teleporter:SetEnabled(false)    
    HideFx(inst)

    inst.AnimState:PlayAnimation("idle_active")
    inst.SoundEmitter:KillSound("loop")
end

local function RestartPortal(inst)
    inst._islocked = false
    inst:AddTag("klaussacklock")
end

local function OnUseKey(inst, key, doer)
	if not key:IsValid() or key.components.klaussackkey == nil or inst._islocked or inst._isopen then
		return false, nil, false
    elseif inst.components.trader.enabled then
        return false, "NOPOWER" , false
	elseif key.components.klaussackkey.keytype ~= inst.keyid then
		return false, "QUAGMIRE_WRONGKEY", false
	end

    OpenPortal(inst)
	return true, nil, false
end

local function OnPoweredFn(inst,ispowered)
    if not ispowered then
        ClosePortal(inst)
    end
end    

local function OnBossrushEnd(inst)
    local key = SpawnPrefab("atrium_key")
    LaunchAt(key, inst, nil, 1.5, 1, 1)
    RestartPortal(inst) 
    inst:OnKeyTaken() 
end

local function OnSave(inst,data)
    --data._isopen = inst._isopen
    data._islocked = inst._islocked
end

local function OnLoad(inst,data)
    if data~=nil then
        --inst._isopen = data._isopen
        inst._islocked = data._islocked
    end
end

newcs_env.AddPrefabPostInit("atrium_gate",function(inst)
    inst:AddTag("klaussacklock")
    inst:AddTag("abyss_saveteleport")
    
    if not TheWorld.ismastersim then return end

    inst:AddComponent("teleporter")
    inst.components.teleporter.onActivate = OnActivate
    inst.components.teleporter.OnDoneTeleporting = OnDoneTeleporting
    inst.components.teleporter.offset = 4
    inst.components.teleporter:SetEnabled(false)

    inst.keyid = "planar_key"
    inst:AddComponent("klaussacklock")
	inst.components.klaussacklock:SetOnUseKey(OnUseKey)

    inst.OpenPortal = OpenPortal
    inst.OnKeyTaken = inst.components.pickable.onpickedfn
    local oldOnEntitySleep = inst.OnEntitySleep
    inst.OnEntitySleep = function (inst)
        if not inst._islocked and not inst._isopen then
            oldOnEntitySleep(inst)
        end
    end
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst.ForbiddenPortal = ForbiddenPortal
    
    inst:ListenForEvent("atriumpowered", function(_, ispowered) OnPoweredFn(inst, ispowered) end, TheWorld)
    inst:ListenForEvent("bossrush_start",function(_)    ForbiddenPortal(inst)   end,TheWorld)
    inst:ListenForEvent("bossrush_end",function (_)  OnBossrushEnd(inst) end,TheWorld)

    inst:DoTaskInTime(0,function ()
        local land_manager = TheWorld.components.voidland_manager
        if land_manager~=nil and not land_manager.has_land then
            land_manager:GenerateLand(inst)
        end
    end)
end)
