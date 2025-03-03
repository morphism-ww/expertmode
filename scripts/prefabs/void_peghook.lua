local assets =
{
    Asset("ANIM", "anim/lavaarena_peghook_basic.zip"),
	Asset("ANIM", "anim/fossilized.zip"),
}

local brain = require"brains.voidpeghookbrain"
local creacureutil = require"util.newcs_prefab_util"

SetSharedLootTable("void_peghook",
{
	{ "horrorfuel",		1.00 },
	{ "horrorfuel",	    1.00 },
})


--[[local CHAIN_LEN = 15
local PILLAR_RADIUS = 1.2
local COLLAR_RADIUS = 1.2

local function OnWallUpdate(inst, dt)
	dt = dt * TheSim:GetTimeScale()
	local prisoner = inst.prisoner:value()
	if prisoner ~= nil then

		--no z, just declaring the locals here
		local x1, y1, z1 = TheSim:GetScreenPos(inst.Transform:GetWorldPosition())
		local x2, y2, z2 = TheSim:GetScreenPos(prisoner.Transform:GetWorldPosition())
		local w, h = TheSim:GetWindowSize()
		local dfront = (y2 - y1) * RESOLUTION_Y / h
		local front = dfront > -10

		x1, y1, z1 = inst.AnimState:GetSymbolPosition("tail1")
		x2, y2, z2 = prisoner.AnimState:GetSymbolPosition("torso")
		if front then
			local theta = TheCamera:GetHeading() * DEGREES
			x2 = x2 + math.cos(theta)
			z2 = z2 + math.sin(theta)
			y2 = y2 + 0.7
		end
		local dx = x2 - x1
		local dy = y2 - y1
		local dz = z2 - z1
		local len = math.sqrt(dx * dx + dz * dz)
		x1 = x1 + dx * PILLAR_RADIUS / len
		z1 = z1 + dz * PILLAR_RADIUS / len
		x2 = x2 - dx * COLLAR_RADIUS / len
		z2 = z2 - dz * COLLAR_RADIUS / len
		dx = x2 - x1
		dy = y2 - y1
		dz = z2 - z1

		len = math.sqrt(dx * dx + dy * dy + dz * dz)
		if front then
			local k = math.clamp(dfront, 0, 100) / 100
			len = len + 1.5 * k * k
		end
		local droopmult = 1 - math.clamp(6 - len, 0, 3) / 3
		droopmult = 1 - droopmult * droopmult

		for i, v in ipairs(inst.chains) do
			local index = i - 1 --0 based
			local droop = CHAIN_LEN / 2
			droop = math.abs(droop - index) / droop
			droop = (1 - droop * droop) * droopmult

			local k = index / CHAIN_LEN
			x2 = x1 + dx * k
			y2 = y1 + dy * k - droop * 1.5
			z2 = z1 + dz * k


			if v.lastx ~= nil then
				--reduced chain lag when rotating camera
				droop = droop * (TheCamera:GetHeadingTarget() == TheCamera:GetHeading() and 0.9 or 0.5)
				k = 1 - droop
				x2 = k * x2 + droop * v.lastx
				y2 = k * y2 + droop * v.lasty
				z2 = k * z2 + droop * v.lastz
			end

			v.lastx, v.lasty, v.lastz = x2, y2, z2
			v.Transform:SetPosition(x2, y2, z2)
			v:Show()

			if index > CHAIN_LEN - 2 then
				k = front and (index - CHAIN_LEN + 2) / 3 or 0
				v.AnimState:SetMultColour(1, 1, 1, 1 - k)
			end
		end
	else
		for i, v in ipairs(inst.chains) do
			v:Hide()
		end
	end
end


local LINK_VARS = { "1", "2", "3", "4" }
local function GetNextLinkVar()
	local var = table.remove(LINK_VARS, math.random(2))
	table.insert(LINK_VARS, var)
	return var
end

local function CreateChainLink()
	local inst = CreateEntity()

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")

	inst.entity:SetCanSleep(false)
	inst.persists = false

	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	inst.AnimState:SetBank("daywalker_pillar")
	inst.AnimState:SetBuild("daywalker_pillar")
	inst.AnimState:AddOverrideBuild("fossilized")
	inst.variation = GetNextLinkVar()
	inst.AnimState:PlayAnimation("link_"..inst.variation, true)
	inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)

	local scale = .785
	inst.AnimState:SetScale(scale, scale)

	inst:Hide()

	return inst
end

local function CreateChainBracket()
	local inst = CreateEntity()

	--inst:AddTag("FX")
	inst:AddTag("decor")
	inst:AddTag("NOCLICK")

	inst.entity:SetCanSleep(false)
	inst.persists = false

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddFollower()

	inst.AnimState:SetBank("daywalker_pillar")
	inst.AnimState:SetBuild("daywalker_pillar")
	inst.AnimState:PlayAnimation("chain_idle", true)
	inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)

	return inst
end

local function SpawnChains(inst)
	if inst.chains == nil then
		inst.chains = {}
		for i = 0, CHAIN_LEN do
			table.insert(inst.chains, CreateChainLink())
		end
        inst.chainbracket = CreateChainBracket()

        local prisoner = inst.prisoner:value()
        if prisoner~=nil then
            inst.chainbracket.entity:SetParent(prisoner.entity)
            inst.chainbracket.Follower:FollowSymbol(prisoner.GUID, "torso", nil, nil, nil, true)
        end

		inst:AddComponent("updatelooper")
		inst.components.updatelooper:AddOnWallUpdateFn(OnWallUpdate)
	end
end

local function RemoveChains(inst, broken)
    if broken then
        local x, y, z = inst.chainbracket.Transform:GetWorldPosition()
        inst.chainbracket.Follower:StopFollowing()
        inst.chainbracket.entity:SetParent(nil)
        inst.chainbracket.Transform:SetPosition(x, y, z)
        inst.chainbracket.AnimState:PlayAnimation("chain_break")
        inst.chainbracket:ListenForEvent("animover", inst.chainbracket.Remove)
    else
        inst.chainbracket:Remove()
    end
    inst.chainbracket = nil
	if inst.chains ~= nil then
        
		if broken then
            
			for i, v in ipairs(inst.chains) do
				local x, y, z = v.Transform:GetWorldPosition()
				v.entity:SetParent(nil)
				v.Transform:SetPosition(x, y, z)
				v.AnimState:PlayAnimation("link_break_"..v.variation)
				v:ListenForEvent("animover", v.Remove)
			end
		else
			for i, v in ipairs(inst.chains) do
				v:Remove()
			end
		end
		inst.chains = nil
		inst:RemoveComponent("updatelooper")
	end
end

local function OnChainsDirty(inst)
	if inst.enablechains:value() then
		SpawnChains(inst)
	else
		RemoveChains(inst, true)
		
	end
end


local function EnableChains(inst, enable)
	enable = enable ~= false
	if enable ~= inst.enablechains:value() then
		inst.enablechains:set(enable)

		--Dedicated server does not need to spawn the local fx
		if not TheNet:IsDedicated() then
			OnChainsDirty(inst)
		end
	end
end

local function SetPrisoner(inst, prisoner)
	local old = inst.prisoner:value()
	if prisoner ~= old then
		if old ~= nil then
			inst.components.entitytracker:ForgetEntity("prisoner")
			--inst:RemoveEventCallback("daywalkerchainbreak", inst._onchainbreak, old)
			--inst:RemoveEventCallback("onremove", inst._onremoveprisoner, old)
		end
		inst.prisoner:set(prisoner)
		EnableChains(inst, prisoner ~= nil)
		if prisoner ~= nil then
			inst.components.entitytracker:TrackEntity("prisoner", prisoner)
			--inst:ListenForEvent("daywalkerchainbreak", inst._onchainbreak, prisoner)
			--inst:ListenForEvent("onremove", inst._onremoveprisoner, prisoner)
		end
	end
end]]

--------------------------------------------------------------------------
local function voidpeghook_CreateFxFollowFrame(owner,i,j,k)
    local inst = CreateEntity()

    --[[Non-networked entity]]
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()

    inst:AddTag("FX")

    inst.AnimState:SetBank("hat_shadow_thrall_parasite")
    inst.AnimState:SetBuild("hat_shadow_thrall_parasite")
    inst.AnimState:PlayAnimation("idle"..tostring(i), true)

    inst.persists = false
    
    inst.entity:SetParent(owner.entity)
    inst.Follower:FollowSymbol(owner.GUID, "head", nil, nil, nil, true, nil, j,k)
end

local function CreateChainBracket(owner)
	local inst = CreateEntity()

	--inst:AddTag("FX")
	inst:AddTag("decor")
	inst:AddTag("NOCLICK")
	--[[Non-networked entity]]
	inst.entity:SetCanSleep(false)
	inst.persists = false

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddFollower()

	inst.AnimState:SetBank("daywalker_pillar")
	inst.AnimState:SetBuild("daywalker_pillar")
	inst.AnimState:PlayAnimation("chain_idle", true)
	inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)

    inst.entity:SetParent(owner.entity)
    inst.Follower:FollowSymbol(owner.GUID, "shoulder", nil, nil, nil, true)
	
end


local function shadowthrall_parasite_ondonetalking(inst)
    inst.SoundEmitter:KillSound("talk")
end

local function shadowthrall_parasite_ontalk(inst)
    inst.SoundEmitter:KillSound("talk")
    inst.SoundEmitter:PlaySound("hallowednights2024/thrall_parasite/vocalization", "talk")
end

local function shadowthrall_parasite_talk(inst, strid)
	inst.components.talker:Chatter("SHADOWTHRALL_PARASITE_CHANT", strid)	
end

local function shadowthrall_parasite_onspawn(inst)
	local shadowparasitemanager = TheWorld.components.shadowparasitemanager

	if shadowparasitemanager ~= nil then
		shadowparasitemanager:StartTrackingParasite(inst)
	end

	if inst.fossilized and inst:IsInLight() then
		inst:OnEnterLight()
	end
end

local function shadowthrall_parasite_onkilledsomething(owner, data)
	if TheWorld.components.shadowparasitemanager == nil then
		return
	end

	if data.victim == nil or not data.victim:IsValid() then
		return
	end

	if data.victim.sg == nil or not (data.victim.sg:HasState("parasite_revive") or data.victim.sg:HasState("death_hosted")) then
		return
	end

	data.victim.shadowthrall_parasite_hosted_death = true

	if data.victim.erode_task ~= nil then
		data.victim.erode_task:Cancel()
		data.victim.erode_task = nil
		data.victim:RemoveTag("NOCLICK")
		data.victim.persists = true
	end
end
-------------------------------------------------------------------------------------------
--[[anim
"attack",hit,idle_loop,run_loop,run_pre,run_pst,sleep_plp,"taunt","split"
]]




local SHADOWTHRALL_PARASITE_RETARGET_CANT_TAGS = { "shadowthrall_parasite_hosted", "shadowthrall_parasite_mask","shadowthrall","shadow" }
local function RetargetFn(inst)
	return FindEntity(
            inst,
            TUNING.ABYSS_CREATURE_TARGET_DIST,
            function(guy)
                return inst.components.combat:CanTarget(guy) and 
                       (guy:HasTag("smallcreature") or 
                        guy:HasTag("animal") or
                        guy:HasTag("largecreature") or
                        guy:HasTag("monster") or 
                        guy:HasTag("character"))
            end,
            nil,
            SHADOWTHRALL_PARASITE_RETARGET_CANT_TAGS
        )
end

local function KeepTargetFn(inst, target)
	return inst.components.combat:CanTarget(target)
		 and not target:HasTag("shadowthrall_parasite_hosted")
		 and not target:HasTag("shadowthrall")
end

local SHARE_TARGET_DIST = 35
local MAX_TARGET_SHARES = 5

local function ShareTargetFn(guy)
    return
        guy:HasTag("shadowthrall_parasite_hosted") and
		not guy:HasTag("notarget")
end

local function OnAttacked(inst, data)
	if data.attacker ~= nil then
		local target = inst.components.combat.target
		if not (target ~= nil and
				target:HasTag("player") and
				inst:IsNear(target, 12 + target:GetPhysicsRadius(0))) then
			--
			inst.components.combat:SetTarget(data.attacker)
		end
		inst.components.combat:ShareTarget(data.attacker, SHARE_TARGET_DIST, ShareTargetFn, MAX_TARGET_SHARES)
	end
end

local function reserattackrange(inst,data)
	if data.name == "spit" then
		inst.components.combat.attackrange = 18
	end
end


local function GetAttackRange(self)
	if self.inst:AbleAbility("spit") 
	or (self.inst:AbleAbility("cursed_spit")) then
		return 18
	end
	return 5
end

local function PoisonOther(inst,target, damage, stimuli, weapon, damageresolved, spdamage, damageredirecttarget)
	if target:IsPoisonable() and damageredirecttarget==nil then
		target:AddDebuff("acid_poison","buff_deadpoison")
	end
end


-------------------------------------------------

local function Releash(inst)

	inst:RemoveTag("noattack")
	inst:RemoveTag("notarget")

	inst:RemoveEventCallback("enterlight",inst.OnEnterLight)
	inst:RemoveEventCallback("enterdark",inst.OnEnterDark)
		
	inst.components.health:SetInvincible(false)

	inst.components.combat:SetRetargetFunction(2, RetargetFn)
	inst.fossilized = false

	inst.components.combat:TryRetarget()

	inst:SetBrain(brain)
	inst:RestartBrain()

	inst.sg:GoToState("taunt")
end

local function CancelTask(inst)
	if inst.shaketask~=nil then
		inst.shaketask:Cancel()
		inst.shaketask = nil
	end
end

local function unfossilized(inst)

	inst.sg:GoToState("unfossilized")
	--inst.AnimState:PlayAnimation("fossilized_pst",false)

	CancelTask(inst)

    --inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/fossilized_break")
	--inst:ListenForEvent("animover",Releash)
end

local function OnEnterLight(inst)

	inst.AnimState:PlayAnimation("fossilized_shake",true)
	if not inst.SoundEmitter:PlayingSound("shakeloop") then
		inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/fossilized_shake_LP", "shakeloop")
	end
	if inst.shaketask==nil then
		inst.shaketask = inst:DoTaskInTime(2,unfossilized)
	end
end



local function OnEnterDark(inst)
	inst.AnimState:PlayAnimation("fossilized")
	inst.AnimState:SetFrame(inst.AnimState:GetCurrentAnimationNumFrames()-1)
	if inst.SoundEmitter:PlayingSound("shakeloop") then
		inst.SoundEmitter:KillSound("shakeloop")
	end
	if inst.canceltask~=nil then
		inst.canceltask:Cancel()
	end
	inst.canceltask = inst:DoTaskInTime(0.5,CancelTask)
end

local function MakeFossilized(inst,onload)
	inst:AddTag("noattack")
	inst:AddTag("notarget")

	inst.fossilized = true

	inst.components.health:SetInvincible(true)
	inst:SetBrain(nil)


	inst:ListenForEvent("enterdark", inst.OnEnterDark)
    inst:ListenForEvent("enterlight", inst.OnEnterLight)

	if not onload then
		inst:PushEvent("fossilized")
	end
end

local function OnSave(inst,data)
	data.fossilized = inst.fossilized
end


local function OnLoadPostPass(inst,data)
	if data~=nil then
		inst.fossilized = data.fossilized
		if not inst.fossilized then
			Releash(inst)
		end
	end
end

-------------------------------------------------

local sound_path = "dontstarve/creatures/lava_arena/peghook/"

local function fn()

    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
	inst.entity:AddNetwork()	

    inst.DynamicShadow:SetSize(3, 1.5)
    inst.Transform:SetSixFaced()

	inst.entity:AddLightWatcher()
    inst.LightWatcher:SetLightThresh(.2)
    inst.LightWatcher:SetDarkThresh(.1)
    
    MakeCharacterPhysics(inst, 200, .8)

	if not TheNet:IsDedicated() then
		voidpeghook_CreateFxFollowFrame(inst,1,0)
		voidpeghook_CreateFxFollowFrame(inst,1,3)
		voidpeghook_CreateFxFollowFrame(inst,1,5)
		voidpeghook_CreateFxFollowFrame(inst,2,1)
		voidpeghook_CreateFxFollowFrame(inst,2,4)
		
		CreateChainBracket(inst)
	end

    inst.AnimState:SetBank("peghook")
    inst.AnimState:SetBuild("lavaarena_peghook_basic")
    inst.AnimState:PlayAnimation("idle_loop", true)

	inst.AnimState:AddOverrideBuild("fossilized")

	inst.sounds = {
		taunt     = sound_path .. "taunt",
		grunt     = sound_path .. "grunt",
		step      = sound_path .. "step",
		attack    = sound_path .. "attack",
		spit      = sound_path .. "spit",
		hit       = sound_path .. "hit",
		stun      = sound_path .. "stun",
		bodyfall  = sound_path .. "bodyfall",
		sleep_in  = sound_path .. "sleep_in",
		sleep_out = sound_path .. "sleep_out",
		death     = sound_path .. "death",
	}

	inst:AddTag("hostile")
	inst:AddTag("shadow_aligned")
    inst:AddTag("abysscreature")
    inst:AddTag("laser_immune")
    inst:AddTag("shadowthrall_parasite_hosted")
    

    inst:AddComponent("talker")
    inst.components.talker.fontsize = 28
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.colour = Vector3(168/255, 61/255, 213/255)
    inst.components.talker.offset = Vector3(0, -500, 0)
    inst.components.talker:MakeChatter()

    inst:ListenForEvent("ontalk", shadowthrall_parasite_ontalk)
    inst:ListenForEvent("donetalking", shadowthrall_parasite_ondonetalking)

    --inst.prisoner = net_entity(inst.GUID, "void_peghook.prisoner")
    --inst.enablechains = net_bool(inst.GUID, "void_peghook.enablechains", "chainsdirty")
	

	inst.SoundEmitter:PlaySound("hallowednights2024/thrall_parasite/thrall_idle_LP","parasite_LP")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        --inst:ListenForEvent("chainsdirty", OnChainsDirty)
        return inst
    end

    inst:AddComponent("inspectable")

    ----------------------------------------------------------------
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.VOID_PEGHOOKHEALTH)

    inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(70)
    inst.components.combat:SetRange(18,5)
	
	inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
	inst.components.combat.GetAttackRange = GetAttackRange
	inst.components.combat.onhitotherfn = PoisonOther
	inst.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 0.2, "dark_armor")

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.runspeed = 4

    ----------------------------------------------------------------
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("void_peghook")


    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_LARGE

    inst:AddComponent("planarentity")

    inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(30)

    inst:AddComponent("entitytracker")

	creacureutil.CreateAbilityCooldown(inst,{
		["spit"] = 12,
		["cursed_spit"] = 10,
	})
    -----------------------------------------------------------------

    --inst.SetPrisoner = SetPrisoner
	inst.SaySpeechLine = shadowthrall_parasite_talk

	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("killed",shadowthrall_parasite_onkilledsomething)
	--inst:ListenForEvent("timerdone",reserattackrange)
	inst:DoTaskInTime(0,shadowthrall_parasite_onspawn)

	inst.MakeFossilized = MakeFossilized
	inst.Releash = Releash
	inst.OnEnterLight = OnEnterLight
	inst.OnEnterDark = OnEnterDark

	inst.OnSave = OnSave
    inst.OnLoadPostPass = OnLoadPostPass

	inst:SetStateGraph("SGvoid_peghook")

	inst:MakeFossilized(true)

	MakeHitstunAndIgnoreTrueDamageEnt(inst)
    
    return inst
end


return Prefab("void_peghook",fn,assets)