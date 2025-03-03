local SpDamageUtil = require("components/spdamageutil")

local function ForbiddenRegen(target,data)
    if data.amount>0 and not data.overtime then
        target.components.health:DoDelta(-data.amount)
    end
end

local INSIGHTSOUL_NIGHTVISION_COLOURCUBES = {
    regular = "images/colour_cubes/lunacy_regular_cc.tex",
    full_moon = "images/colour_cubes/purple_moon_cc.tex",
    moon_storm = "images/colour_cubes/moonstorm_cc.tex",
}

local function GetBestSymbolAndSize(target)
    local burnable = target.components.burnable

    local fxdata1 = burnable ~= nil and burnable.fxdata ~= nil and burnable.fxdata[1] or nil

    if fxdata1 ~= nil and fxdata1.follow ~= nil then
        return fxdata1.follow, burnable.fxlevel
    end

    local freezable = target.components.freezable

    fxdata1 = freezable ~= nil and freezable.fxdata ~= nil and freezable.fxdata[1] or nil

    if fxdata1 ~= nil and fxdata1.follow ~= nil then
        return fxdata1.follow, freezable.fxlevel - 1
    end

    local combat = target.components.combat

    if combat ~= nil and combat.hiteffectsymbol ~= nil then
        return combat.hiteffectsymbol, (target:HasTag("smallcreature") and 1) or (target:HasAnyTag("largecreature", "epic") and 3) or 2
    end
end

local function SpawnHitFx(inst, target)
    if inst._owner == nil or not inst._owner:IsValid() or inst._hitfx~=nil then
        return
    end

	local fx = SpawnPrefab("slingshotammo_purebrilliance_debuff_fx")
	fx:AttachTo(target)
	inst._hitfx = fx
	fx:DoTaskInTime(3,function (inst2)
		inst2:Remove()
		inst._hitfx = nil
	end)
    return fx
end

local function eclipse_onattackedfn(inst,owner,data)
    if data == nil or data.redirected or data.weapon==nil then
        return
    end

	--Only work for anti-shadow_aligned 
	--and weapon.components.damagetypebonus.tags["shadow_aligned"]
	local weapon = data.weapon
	if not (weapon.components.damagetypebonus) then
		return
	end

    local attacker_spdmg = data.attacker ~= nil and SpDamageUtil.GetSpDamageForType(data.attacker,"planar") or 0
    local weapon_spdmg = weapon and SpDamageUtil.GetSpDamageForType(data.weapon,"planar") or 0


    if attacker_spdmg == 0 and weapon_spdmg == 0 then
        return -- Only triggered by planar attacks.
    end

    if owner ~= nil and owner:IsValid() and
        not (owner.components.health and owner.components.health:IsDead()) and
        (owner.components.combat and owner.components.combat:CanBeAttacked())
    then
		local spdmg = attacker_spdmg+weapon_spdmg

		owner.components.health:DoDelta(-spdmg,false,inst.prefab,false, inst,true)
		if inst.fx~=nil then
			SpawnPrefab("bomb_lunarplant_explode_fx").Transform:SetPosition(inst.fx.Transform:GetWorldPosition())
		end
		
        --[[if data.attacker ~= nil then
            SpawnHitFx(inst,owner)
        end]]
    end
end

local debuff_defs = {

	poison =
	{
		TICK_RATE = 15,
		TICK_FN = function(inst,target)
			target.components.health:DoDelta(-2,true,"buff_poison")
		end,
		net_ent = true,
		OnEnabledDirty = function (inst,target,enable)
			if enable and target.HUD~=nil then
				inst:DoPeriodicTask(15, function ()
					target:PushEvent("poisondamage")
				end)
			end
		end,
		DURATION = TUNING.TOTAL_DAY_TIME,
		DEBUFF = true
	},

	deadpoison=
	{
		ONAPPLY = function(inst,target)
			inst.damage = 1
		end,		
		TICK_RATE = 1,
		TICK_FN = function(inst,target)
			target.components.health:DoDelta(-inst.damage,true,"buff_deadpoison")
		end,
		ONEXTEND = function(inst,target)
			inst.damage = math.min(inst.damage + 1,3)
		end,
		net_ent = true,
		OnEnabledDirty = function (inst,target,enable)
			if enable then
				target:PushEvent("startfumedebuff", inst)
			end
		end,
		DEBUFF = true,
		DURATION = 20,
	},

	weak=
	{
		ONAPPLY = function(inst,target,data)
			if target.components.locomotor then
				target.components.locomotor:SetExternalSpeedMultiplier(inst, "weak", 0.7)
			end
			if target.components.workmultiplier then
				target.components.workmultiplier:AddMultiplier(ACTIONS.CHOP,    0.5, inst)
        		target.components.workmultiplier:AddMultiplier(ACTIONS.MINE,    0.5, inst)
        		target.components.workmultiplier:AddMultiplier(ACTIONS.HAMMER,  0.5, inst)
			end
			if target.components.combat then
				target.components.combat.externaldamagemultipliers:SetModifier(inst, 0.7)
			end
			if target.components.mightiness then
				target.components.mightiness.ratemodifiers:SetModifier(inst, 5)
			end
		end,
		DEBUFF = true,
		DURATION = 40,
	},
	slow = {
		ONAPPLY = function(inst,target,data)
			if target.components.locomotor then
				target.components.locomotor:SetExternalSpeedMultiplier(inst, "slow", 0.7)
			end
		end,
		DEBUFF = true,
		DURATION = 12,
	},
	vulnerable =
	{
		ONAPPLY = function(inst,target,data)
			if target.components.combat then
				target.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 1.5)
			end
		end,
		DEBUFF = true,
		DURATION = 40
	},
	foodsick=
	{	
		DEBUFF = true,
		DURATION = 30
	},
	exhaustion=
	{
		TICK_RATE = 5,
		TICK_FN = function(inst,target)
			if target.isplayer then
				target.components.health:DeltaPenalty(0.05)
			end
		end,
		DEBUFF = true,
		DURATION=30
	},

	mooncurse = 
	{
		
		ONAPPLY = function(inst,target)
			inst:ListenForEvent("healthdelta",ForbiddenRegen,target)
			
		end,
		ONDETACH = function (inst,target)
			inst:RemoveEventCallback("healthdelta",ForbiddenRegen,target)
		end,
		DEBUFF = true,
		DURATION = 12,
	},

	solarfire = 
	{
		TICK_RATE = 2,
		TICK_FN = function(inst,target)
			target.components.health:DoDelta(-12,false,"solar_fire")
			if target.components.temperature ~= nil then
                target.components.temperature:DoDelta(20)
            end 
		end,
		DEBUFF = true,
		CreateFx = function (target)
			return SpawnPrefab("cs_fireball_hit_fx")
		end,
		DURATION = 10,
	},
	cursefire = 
	{
		TICK_RATE = 0.5,
		TICK_FN = function (inst,target)
			target.components.health:DoDelta(-1.5,true,"buff_cursefire")
			target.components.health:DoFireDamage(0,inst)
			--target.components.health.takingfiredamage = true
		end,
		CreateFx = function (target)
			local burnable = target.components.burnable
			if burnable~=nil then
				local fx_type = burnable.fxdata[1].prefab
				local sym = burnable.fxdata[1].follow
				local fx = SpawnPrefab(fx_type)
				fx.AnimState:SetMultColour(173/255,1,47/255,1)
				fx.components.firefx:SetLevel(burnable.fxlevel,false,true)
				--fx.components.firefx:SetLevel(3,false,true)
			
				fx.entity:AddFollower():FollowSymbol(target.GUID,sym,0,0,0)
				
				return fx
			end
		end,
		DEBUFF = true,
		DURATION = 15,
	},
	vulnerability_hex = {
		TICK_RATE = 1,
		TICK_FN = function(inst,target)
			target.components.health:DoDelta(-3,true,"buff_vulnerability_hex")
			target.components.health:DoFireDamage(1,inst,true)
		end,
		ONAPPLY = function(inst,target,data)
			if target.components.combat~=nil then
				target.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 1.2)
			end	
		end,
		CreateFx = function (target)
			local burnable = target.components.burnable
			if burnable~=nil then
				local fx_type = burnable.fxdata[1].prefab
				local sym = burnable.fxdata[1].follow
				local fx = SpawnPrefab(fx_type)
				fx.AnimState:SetMultColour(139/255,0,0,1)
				fx.components.firefx:SetLevel(burnable.fxlevel)
				if sym==nil then
					target:AddChild(fx)
				else
					fx.entity:AddFollower():FollowSymbol(target.GUID,sym,0,0,0)
				end
				return fx
			end
		end,
		DEBUFF = true,
		DURATION = 5,
	},

	crazy = {
		ONAPPLY = function (inst,target)
			if target.components.sanity~=nil then
				target.components.sanity:AddSanityPenalty("crazy",0.4)
				target:AddTag("crazy")
				target.components.combat.externaldamagemultipliers:SetModifier(inst, 1.25)
				target.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 1.25)
			end
		end,
		ONDETACH = function (inst,target)
			target:RemoveTag("crazy")
			if target.components.sanity~=nil then
				target.components.sanity:RemoveSanityPenalty("crazy",0.4)
			end		
		end,
		DEBUFF = true,
		DURATION = 360,
	},
	
	fast = {
		ONAPPLY = function (inst,target)
			if target.components.locomotor ~= nil then
				target.components.locomotor:SetExternalSpeedMultiplier(inst,"fast_buff",1.3)
			end
		end,
		priority = 1,
		DURATION = TUNING.TOTAL_DAY_TIME
	},

	warm = {
		ONAPPLY = function (inst,target)
			if target.components.freezable ~= nil then
				target.components.freezable:AddResistance(inst,8)
			end
		end,
		priority = 1,
		DURATION = TUNING.TOTAL_DAY_TIME
	},

	insight = {
		ONAPPLY = function (inst,target)
			if target.isplayer then
				target:AddCameraExtraDistance(inst, TUNING.SCRAP_MONOCLE_EXTRA_VIEW_DIST)
				target.components.playervision:PushForcedNightVision(inst, 2, INSIGHTSOUL_NIGHTVISION_COLOURCUBES,true)
			end
		end,
		ONDETACH = function (inst,target)
			if target.isplayer then
				target:RemoveCameraExtraDistance(inst)
				target.components.playervision:PopForcedNightVision(inst)
			end
		end,
		OnEnabledDirty = function (inst,target,enable)	
			if target.components.playervision ~= nil then
				if enable then
					ThePlayer.components.playervision:PushForcedNightVision(inst, 2, INSIGHTSOUL_NIGHTVISION_COLOURCUBES, true)
				else
					ThePlayer.components.playervision:PopForcedNightVision(inst)
				end
			end
		end,
		net_ent = true,
		priority = 1,
		DURATION = TUNING.TOTAL_DAY_TIME*1.5
	},

	iron = {
		ONAPPLY = function (inst,target)
			if target.isplayer then
				target.components.planardefense:AddBonus(inst, 5, "iron_soul")
				if target.prefab~="wx78" then
					target:AddTag("chessfriend")
				end
			end
		end,
		priority = 1,
		ONDETACH = function (inst,target)
			if target.isplayer then
				target.components.planardefense:RemoveBonus(inst, "iron_soul")
				if target.prefab~="wx78" then
					target:RemoveTag("chessfriend")
				end
			end
		end,
		DURATION = TUNING.TOTAL_DAY_TIME
	},
	eclipse_radiance = {
		ONAPPLY = function (inst,target)
			inst._onattackedfn = function (owner,data)
				eclipse_onattackedfn(inst,owner,data)
			end
			inst._owner = target
			inst:ListenForEvent("attacked", inst._onattackedfn, target)

			if target:IsValid() then
				inst.fx = SpawnPrefab("slingshotammo_purebrilliance_debuff_fx")
				inst.fx:AttachTo(target)
			end
			
		end,

		ONDETACH = function (inst,target)
			if inst._owner ~= nil and inst._owner:IsValid() then
				inst:RemoveEventCallback("attacked", inst._onattackedfn, inst._owner)
			end
		end,

		DURATION = 20,
		DEBUFF = true,
	},
	slimed = {
		ONAPPLY = function (inst,target)
			--target.components.locomotor:SetExternalSpeedMultiplier(inst, "slimed", TUNING.CAREFUL_SPEED_MOD)
			--[[if target.components.sanity ~= nil then
				target.components.sanity.externalmodifiers:SetModifier(inst, -TUNING.DAPPERNESS_MED_LARGE,"slimed")
			end]]
			inst._fx = SpawnPrefab("gelblob_small_fx")
			inst._fx.Transform:SetPosition(target.Transform:GetWorldPosition())
			inst._fx:SetLifespan(30)
			inst._fx:ReleaseFromAmmoAfflicted()
			inst.life = 2
		end,
		
		ONDETACH = function (inst,target)
			if inst._fx~=nil then
				inst._fx:KillFX(true)
				inst._fx = nil
			end
		end,
		TICK_RATE = 0.2,
		TICK_FN = function (inst,target)			
			if inst._fx._targets[target] == nil then
				inst._fx.Transform:SetPosition(target.Transform:GetWorldPosition())
			end
		end,
		DURATION = 30,
	},
	halluc = {
		ONAPPLY = function (inst,target)
			if target.components.damagetypebonus~=nil then
				target.components.damagetypebonus:AddBonus("_combat", inst, 2)
			end
			if target.components.combat~=nil then
				target.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 2)
			end
		end,
		OnEnabledDirty = function (inst,target,enable)	
			if ThePlayer ~= nil and target == ThePlayer then
				if enable then
					PostProcessor:EnablePostProcessEffect(PostProcessorEffects.HALLUC, true)
				else
					PostProcessor:EnablePostProcessEffect(PostProcessorEffects.HALLUC, false)
				end
			end
		end,
		DEBUFF = true,
		net_ent = true,
		DURATION = TUNING.TOTAL_DAY_TIME
	},
	conprotect = {
		ONAPPLY = function (inst,target)
			if target.components.freezable~=nil then
				if inst.components.freezable:IsFrozen() then
					inst.components.freezable:Unfreeze()
				end
			end
			if target.components.burnable~=nil then
				if target.components.burnable:IsBurning() then
					target.components.burnable:Extinguish()
				end
			end
			if target.components.grogginess~=nil then
				target.components.grogginess:ResetGrogginess()
			end
			target.components.health.externalabsorbmodifiers:SetModifier(inst, 1, "constant_protect")
		end,
		ONDETACH = function (inst,target)
			target.components.health:RemoveRegenSource(inst,"constant_protect")
		end,
		DURATION = 10,
	}
}

return debuff_defs
