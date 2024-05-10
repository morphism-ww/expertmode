local bossrush_program = require("bossrush/bossrush_program")
local commonfn = bossrush_program.commonfn
local bossrush_tuning = require("bossrush/bossrush_tuning")

local assets =
{
    Asset("ANIM", "anim/pocketwatch_portal_fx.zip"),
}

local function NextStage(inst)
	inst.progress = inst.progress + 1

	commonfn.clearland(inst)

	local delay = (inst.level>=5) and 8 or 2

	if inst.progress<=inst.maxprogress then
		inst:DoTaskInTime(delay,inst.OnProgressStart)
	else
		inst:ToggleVictory()
	end		
end



local function OnProgressStart(inst)
	local program = inst.program[inst.progress]


	if program.type_special then
		program.initfn(inst)
	else
		if program.scenery_postinit~=nil then
			program.scenery_postinit(inst)
		end

		local boss = SpawnPrefab(program.boss)	

		local x,y,z = inst.Transform:GetWorldPosition()
		boss.Transform:SetPosition(x,0,z)



		if boss.components.lootdropper~=nil then
			boss.components.lootdropper.DropLoot = function ()end
		end

		if program.postinitfn~=nil then
			program.postinitfn(boss)
		end

		if boss.components.grouptargeter==nil then
			boss:AddComponent("grouptargeter")
		end

		local maxhealth = boss.components.health.maxhealth
		boss.components.health:SetMaxHealth(inst.mode*maxhealth)

		boss.components.combat:SetRetargetFunction(1, commonfn.retarget)
		boss.components.combat:SetKeepTargetFunction(commonfn.keeptarget)

		inst:ListenForEvent("death",function ()
			inst:NextStage()
		end,boss)
	end		
end

local function ModeCalcFn(num)
	local mult = 1
	for i = 1, math.min(num,10) do
		if i>1 and i<4 then
			mult = mult + 0.5
		elseif i>=4 then
			mult = mult + 0.3
		end
	end
	return mult
end

local function togglebossrush(inst)

	inst.mode = ModeCalcFn(TheWorld.components.voidland_manager:CountPlayer())

	inst.components.talker:Chatter("BOSSRUSH", 1, nil, nil, CHATPRIORITIES.HIGH)
	for k, v in pairs(bossrush_tuning) do
		ORIGINAL_TUNING[k] = TUNING[k]
		TUNING[k] = v
	end

	inst.level = 1
	inst.progress = 1
	inst.is_on = true

	
	inst:OnProgressStart()
end

local function SendPlayerBack(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	for i, v in ipairs(AllPlayers) do
        if v.entity:IsVisible() and
            v:GetDistanceSqToPoint(x, y, z) < 2500 then
			inst.components.teleporter:Activate(v)
        end
    end
	inst.AnimState:PlayAnimation("idle")
end

local function togglevictory(inst)
	local x,y,z = inst.Transform:GetWorldPosition()

    SpawnPrefab("void_key").Transform:SetPosition(x+3,0,z)
	SpawnPrefab("atrium_key").Transform:SetPosition(x+3,0,z+3)

	inst.progress = 1
	inst.level = 1
	inst.is_on = false

	for k, v in pairs(bossrush_tuning) do
		TUNING[k] = ORIGINAL_TUNING[k]
	end
	inst._musicdirty:set(0)
	inst.components.talker:Chatter("BOSSRUSH", 10, nil, nil, CHATPRIORITIES.HIGH)
	
	inst:RemoveTag("NOCLICK")
	inst.AnimState:PlayAnimation("portal_entrance_pre")
    inst.AnimState:PushAnimation("portal_entrance_loop", true)
	TheWorld:PushEvent("bossrush_end")

	inst:DoTaskInTime(600, inst.SendPlayerBack)
end



local function PlayerActionFilter(inst, action)
    return not action.ghost_exclusive
end
local function OnActivate(inst, doer)

    if doer.components.playercontroller == nil then
        inst.components.playeractionpicker:PushActionFilter(PlayerActionFilter, -99)
    end
    doer.player_classified.MapExplorer:EnableUpdate(true)
    if doer.components.playercontroller ~= nil then
        doer.components.playercontroller:EnableMapControls(true)
    end
    if doer.components.maprevealable~=nil then
        doer.components.maprevealable:Start()
    end
    TheWorld.components.voidland_manager:UnregisterPlayer(doer)
end

--------------music-----------------------
local function PushMusic(inst,value)
    if ThePlayer ~= nil and ThePlayer:IsNear(inst, 50) then
        TheFocalPoint.SoundEmitter:PlaySound("bossrush/bossrush1/Stained, Brutal Calamity","bossrush_lv1")
    end
end

local function OnMusicDirty(inst)
	
	if inst._musictask ~= nil then
		inst._musictask:Cancel()
	end
	if inst._musicdirty:value()>=1 then
		inst._musictask = inst:DoPeriodicTask(1, PushMusic,0.5,inst._musicdirty:value())
	else
		TheFocalPoint.SoundEmitter:KillSound("bossrush_lv1")
	end		
	
end

-------------------------------------
local function OnSave(inst,data)
	data.level = inst.level
	data.is_on = inst.is_on
	data.mode = inst.mode
end

local function OnLoad(inst, data)
    if data ~= nil then
        inst.level = data.level
		inst.is_on = data.is_on
		inst.mode = data.mode
    end
end

local ProgressReset = {1,6,12,17,22}
local Remove_Any = {"epic","hound","ancient_hulk_mine","groundspike","renewable"}
local function ResetProgress(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, 0, z, 50, nil, {"player"},Remove_Any)
	for i,v in ipairs(ents) do
		v:Remove()
	end


	if inst.is_on then
		for k, v in pairs(bossrush_tuning) do
			ORIGINAL_TUNING[k] = TUNING[k]
			TUNING[k] = v
		end
		inst.progress = ProgressReset[inst.level]
		inst:OnProgressStart()
	end
	
end

------------------------------------
local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddNetwork()
	inst.entity:AddAnimState()

	inst.entity:SetCanSleep(false)

	inst.AnimState:SetBank("pocketwatch_portal_fx")
    inst.AnimState:SetBuild("pocketwatch_portal_fx")
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetSortOrder(-1)
	inst.AnimState:Hide("front")
	inst.AnimState:Hide("water_shadow")
    --inst.AnimState:PlayAnimation("overload_pst",true)

	inst:AddComponent("temperatureoverrider")
	
	inst.nameoverride =	"BOSSRUSH"
	inst:AddComponent("talker")
    inst.components.talker.colour = Vector3(238 / 255, 69 / 255, 105 / 255)
    inst.components.talker.disablefollowtext = true
    inst.components.talker:MakeChatter()

	inst._musicdirty =	net_tinybyte(inst.GUID, "bossrush._musicdirty", "musicdirty")
	--inst._level = net_tinybyte(inst.GUID, "bossrush._level", "leveldirty")
	--inst._level:set(1)
    
    inst._musictask = nil
	inst.OnMusicDirty = OnMusicDirty

	if not TheNet:IsDedicated() then
		inst:ListenForEvent("musicdirty", OnMusicDirty)
	end


	--inst:AddTag("FX")
	inst:AddTag("NOCLICK")


	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("entitytracker")

	inst:AddComponent("teleporter")
    inst.components.teleporter.offset = 0
	inst.components.teleporter.onActivate = OnActivate

	inst.components.temperatureoverrider:SetRadius(36)
    --inst.components.temperatureoverrider:SetTemperature(TUNING.DEERCLOPSEYEBALL_SENTRYWARD_TEMPERATURE_OVERRIDE)

	inst.progress = 1
	inst.level = 1
	inst.mode = 1
	inst.is_on = false
	inst.program = bossrush_program.program
	inst.maxprogress = #inst.program

	inst.ToggleBossRush = togglebossrush
	inst.ToggleVictory = togglevictory
	inst.NextStage = NextStage
	inst.OnProgressStart = OnProgressStart
	inst.SendPlayerBack = SendPlayerBack

	inst:ListenForEvent("bossrush",function (world)
		inst:ToggleBossRush()
	end,TheWorld)

	inst:DoTaskInTime(1, ResetProgress)

	inst.OnSave = OnSave
    inst.OnLoad = OnLoad


	return inst
end

return Prefab("bossrush_manager", fn,assets)