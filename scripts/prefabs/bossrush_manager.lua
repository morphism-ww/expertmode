local assets =
{	
	Asset("ANIM", "anim/lavaarena_portal.zip"),
    Asset("ANIM", "anim/lavaarena_portal_fx.zip"),
}




----------------------------------------------------------------
local function OpenPortal(inst)
	inst.components.teleporter:SetEnabled(true)
	--inst.portalfx:Show()
	inst.portalfx.AnimState:PlayAnimation("portal_pre")
	inst.portalfx.AnimState:PushAnimation("portal_loop")
end

local function ClosePortal(inst)
	inst.components.teleporter:SetEnabled(false)
	--inst.portalfx:Show()
	inst.portalfx.AnimState:PlayAnimation("portal_pst")
end


local function IsEntInLand(x,z,ent)
	local px,py,pz = ent.Transform:GetWorldPosition()
	return math.abs(x-px)<16 and math.abs(z-pz)<16
end

local function togglebossrush(inst,restart)
	if not restart then
		local x,y,z = inst.Transform:GetWorldPosition()
		local mode = 1
		for i, v in ipairs(AllPlayers) do
			if v.entity:IsVisible() and
				IsEntInLand(x,z,v) then
				TheWorld.components.voidland_manager:RegisterPlayer(v)
				if v:HasTag("strongman") or MODCHARACTERMODES[v] then
					mode = mode + 0.7
				elseif i~=1 then
					mode = mode + (i>4 and 0.3 or 0.2)
				end
			end
		end
		inst.components.battlemanager:Init(mode)	
	end
	ClosePortal(inst)	
	inst.components.battlemanager:Start()
end

local function KillProgram(inst)

	inst.components.battlemanager:KillProgram()
	
	inst._musicdirty:set(0)

	OpenPortal(inst)
	TheWorld:PushEvent("bossrush_end")
end	

local function togglevictory(inst)
	local x,y,z = inst.Transform:GetWorldPosition()

    SpawnPrefab("sword_ancient").Transform:SetPosition(x+3,0,z)
	
	inst._talkerdirty:set(6)
	
	KillProgram(inst)
end


local function OnActivate(inst, doer)

    --[[if doer.components.playercontroller == nil then
        inst.components.playeractionpicker:PushActionFilter(PlayerActionFilter, -99)
    end]]
	if doer:HasTag("player") then
		if doer.player_classified~=nil then
			doer.player_classified.MapExplorer:EnableUpdate(false)
		end
		if doer.components.playercontroller ~= nil then
			doer.components.playercontroller:EnableMapControls(false)
		end
		
		--TheWorld.components.voidland_manager:RegisterPlayer(doer)
	end
	
end

local function CheckForPlayer(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	for i, v in ipairs(AllPlayers) do
        if not IsEntityDeadOrGhost(v) and
            v.entity:IsVisible() and
            IsEntInLand(x,z,v) then
			if inst.resettask~=nil then
				inst.resettask:Cancel()
				inst.resettask = nil
			end
			return
        end
    end
	if inst.resettask==nil then
		inst.resettask = inst:DoTaskInTime(30,KillProgram)
	end	
end

local function CheckForPlayerAlive(inst)
	CheckForPlayer(inst)
	inst:DoTaskInTime(3,CheckForPlayer)
end

--------------music-----------------------
local function PushMusic(inst,value)
	local SoundEmitter = TheFocalPoint.SoundEmitter
    if ThePlayer ~= nil and ThePlayer:IsNear(inst, 50) then
		TheWorld:PushEvent("enabledynamicmusic", false)
		if value==1 then
			SoundEmitter:PlaySound("bossrush/bossrush1/Stained, Brutal Calamity","bossrush")
		elseif value==2 then
			SoundEmitter:PlaySound("bossrush/bossrush1/bossrush2","bossrush")
		elseif value==3 then
			SoundEmitter:PlaySound("bossrush/bossrush1/bossrush3","bossrush")
		end
		SoundEmitter:SetVolume("bossrush", 0.5)
		SoundEmitter:KillSound("AbyssPressure")	
    end
end

local function OnMusicDirty(inst)
	
	if inst._musictask ~= nil then
		inst._musictask:Cancel()
	end
	TheFocalPoint.SoundEmitter:KillSound("bossrush")
	if inst._musicdirty:value()>=1 then
		inst._musictask = inst:DoPeriodicTask(2, PushMusic,0.5,inst._musicdirty:value())
	else
		if ThePlayer ~= nil and not ThePlayer:HasTag("playerghost") then
			TheWorld:PushEvent("enabledynamicmusic", true)
		end
	end				
	
end

local function OnTalkDirty(inst)
	Networking_Announcement(STRINGS.BOSSRUSH[inst._talkerdirty:value()], {238 / 255, 69 / 255, 105 / 255,1})
end


local function OnMiasDirty(inst)
	if inst._miastrigger:value() then
		TheWorld:PushEvent("overrideambientlighting", Point(0, 0, 0))
		
		
		--[[inst.mist = SpawnPrefab("miasama_abyss_fx")
		inst.mist.Transform:SetPosition(inst.Transform:GetWorldPosition())
		inst.mist.components.emitter.area_emitter = CreateRingEmitter2()

		inst.mist.components.emitter.density_factor = 6
		inst.mist.components.emitter:Emit()]]
	else
		TheWorld:PushEvent("overrideambientlighting", nil)
		--[[if inst.mist then
			inst.mist:Remove()
			inst.mist = nil
		end]]
	end
end

-----------------------------------
local function CreateDropShadow(parent)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    --[[Non-networked entity]]

    inst.AnimState:SetBuild("lavaarena_portal")
    inst.AnimState:SetBank("lavaarena_portal")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(1)
    inst.AnimState:OverrideSymbol("lavaarena_portal01", "lavaarena_portal", "shadow")

    inst.Transform:SetEightFaced()

    inst:AddTag("DECOR")
    inst:AddTag("NOCLICK")

    inst.persists = false
    inst.entity:SetParent(parent.entity)

    return inst
end

local TERRAFORM_BLOCKER_RADIUS = 16

local function CreateTerraformBlocker(parent)
    local inst = CreateEntity()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()

    inst:SetTerraformExtraSpacing(TERRAFORM_BLOCKER_RADIUS)

    return inst
end

local function AddTerraformBlockers(inst)
    local diameter = 2 * TERRAFORM_BLOCKER_RADIUS
    local rowoffset = 2 * TERRAFORM_BLOCKER_RADIUS
    for row = -rowoffset, rowoffset, diameter do
        for col = -diameter, diameter, diameter do
            local blocker = CreateTerraformBlocker(inst)
            blocker.entity:SetParent(inst.entity)
            blocker.Transform:SetPosition(row, 0, col)

            blocker = CreateTerraformBlocker(inst)
            blocker.entity:SetParent(inst.entity)
            blocker.Transform:SetPosition(col, 0, row)
        end
    end
end

local function TrySpawnKeyhole(inst)
	if inst.components.entitytracker:GetEntity("keyhole")==nil then
		local x,y,z = inst.Transform:GetWorldPosition()
		local keyhole = SpawnPrefab("voidkeyhole")
		keyhole.Transform:SetPosition(x,0,z+6)
		inst.components.entitytracker:TrackEntity("keyhole",keyhole)
	end
end
------------------------------------
local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddNetwork()
	inst.entity:AddAnimState()

	inst.entity:SetCanSleep(false)

	
	inst.Transform:SetEightFaced()
	inst.AnimState:SetBuild("lavaarena_portal")
    inst.AnimState:SetBank("lavaarena_portal")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(1)
    inst.AnimState:SetFinalOffset(2)
	inst.AnimState:SetMultColour(160/255,32/255,240/255,1)

    inst.entity:AddLight()
	inst.Light:Enable(true)
    inst.Light:SetRadius(0.5)
    inst.Light:SetFalloff(.9)
    inst.Light:SetIntensity(0.4)
    inst.Light:SetColour(1,1,1)

	AddTerraformBlockers(inst)
	inst:AddComponent("temperatureoverrider")
	

	inst._musicdirty =	net_tinybyte(inst.GUID, "bossrush._musicdirty", "musicdirty")
	--inst._level = net_tinybyte(inst.GUID, "bossrush._level", "leveldirty")
	--inst._level:set(1)
	inst._miastrigger = net_bool(inst.GUID,"bossrush._miasdirty","miasdirty")
    inst._talkerdirty = net_tinybyte(inst.GUID,'bossrush._talkerdirty',"talkdirty")

    inst._musictask = nil
	inst.OnMusicDirty = OnMusicDirty

	if not TheNet:IsDedicated() then
		CreateDropShadow(inst)
	end

	
	inst:AddTag("moistureimmunity")
	inst:AddTag("irreplaceable")
	inst:AddTag("portal")


	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
		inst:ListenForEvent("musicdirty", OnMusicDirty)
		inst:ListenForEvent("talkdirty", OnTalkDirty)
		inst:ListenForEvent("miasdirty",OnMiasDirty)
        return inst
    end
	inst.portalfx = SpawnPrefab("lavaarena_portal_activefx")
	inst.portalfx.AnimState:SetLightOverride(0.5)
	inst.portalfx.entity:SetParent(inst.entity)
	

	inst:AddComponent("entitytracker")

	inst:AddComponent("teleporter")
    inst.components.teleporter.offset = 0
	inst.components.teleporter.OnDoneTeleporting= OnActivate

	inst.components.temperatureoverrider:SetRadius(40)
	inst.components.temperatureoverrider:Enable()
    --inst.components.temperatureoverrider:SetTemperature(TUNING.DEERCLOPSEYEBALL_SENTRYWARD_TEMPERATURE_OVERRIDE)

	--inst:AddComponent("inspectable")

	inst:AddComponent("battlemanager")

	inst.ToggleBossRush = togglebossrush
	inst.ToggleVictory = togglevictory
	inst.CheckForPlayerAlive = CheckForPlayerAlive


	inst:ListenForEvent("bossrush_start",function(_,restart) inst:ToggleBossRush(restart) end, TheWorld)

	inst:DoTaskInTime(0,TrySpawnKeyhole)
	TheWorld:PushEvent("ms_registerBossRushManager", inst)

	return inst
end

local keyhole_assets =
{
    Asset("ANIM", "anim/lavaarena_keyhole.zip"),
}

local function OnUseKey(inst, key, doer)
	if not key:IsValid() or key.components.klaussackkey == nil or not inst:HasTag("klaussacklock") then
		return false, nil, false
    elseif inst.components.worldsettingstimer:ActiveTimerExists("cooldown") then
        return false, "COOLDOWN" , false
	elseif key.components.klaussackkey.keytype ~= inst.keyid then
		return false, "QUAGMIRE_WRONGKEY", false
	end
	if not inst.components.worldsettingstimer:ActiveTimerExists("cooldown") then
        inst.components.worldsettingstimer:StartTimer("cooldown", TUNING.EYEOFTERROR_SPAWNDELAY)
    end
	
    TheWorld:PushEvent("bossrush_start")
	if TheWorld.components.voidland_manager then
		TheWorld.components.voidland_manager.bossrush_on = true
	end
	return true, nil, false
end




local function keyhole_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("lavaarena_keyhole")
    inst.AnimState:SetBank("lavaarena_keyhole")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:Hide("key")
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(1)

    inst.Transform:SetEightFaced()
    inst.Transform:SetScale(1.1, 1.1, 1.1)

	
	inst:AddTag("klaussacklock")

	inst:AddTag("irreplaceable")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.keyid = "void_key"
    inst:AddComponent("klaussacklock")
	inst.components.klaussacklock:SetOnUseKey(OnUseKey)

	inst:AddComponent("inspectable")

    inst:AddComponent("worldsettingstimer")
    inst.components.worldsettingstimer:AddTimer("cooldown", TUNING.BOSSRUSH_CD, true)


	
    return inst
end



return Prefab("bossrush_manager",fn,assets),
	Prefab("voidkeyhole",keyhole_fn,keyhole_assets)