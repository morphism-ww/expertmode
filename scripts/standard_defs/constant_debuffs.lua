local function noregen(target,food)
	if target.components.health~=nil then
		target.components.health:DoDelta(-33)
	end
end
local function ForbiddenRegen(target,data)
    if data.amount>0 then
        target.components.health:DoDelta(-data.amount)
    end
end

local debuff_defs={
	poison=
	{
		name = "poison",
		TICK_RATE = 15,
		TICK_FN = function(inst,target)
			target.components.health:DoDelta(-2, false,"poison")
			if target.player_classified then
				target.player_classified.poisonover:push()
			end
		end,
		duration = TUNING.TOTAL_DAY_TIME,
	},
	poison2=
	{
		name = "poison_2",
		onattachedfn = function(inst,target)
			inst.damage = 1
			if target.isplayer then
				target:PushEvent("startfumedebuff",inst)
			end
		end,		
		TICK_RATE = 1,
		TICK_FN = function(inst,target,data)
			target.components.health:DoDelta(-inst.damage, true,"poison_2")
		end,
		onextendedfn = function(inst,target)
			inst.damage = math.min(inst.damage + 1,3)
		end,
		duration = 20,
	},
	weak=
	{
		name = "weak",
		onattachedfn=function(inst,target,data)
			if target.components.locomotor then
				target.components.locomotor:SetExternalSpeedMultiplier(inst, "weak", 0.7)
			end
			if target:HasTag("player") then
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
		duration = 40,
	},
	vulnerable =
	{
		name = "vulnerable",
		onattachedfn = function(inst,target,data)
			if target.components.combat then
				target.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 1.3)
			end
		end,
		duration = 40

	},
	food_sickness=
	{
		name = "food_sickness",
		onattachedfn=function(inst,target)
			inst:ListenForEvent("oneat",noregen,target)
		end,
		duration = 30
	},
	exhaustion=
	{
		name = "exhaustion",
		TICK_RATE = 5,
		TICK_FN = function(inst,target)
			if target.isplayer and target.components.health ~= nil then
				target.components.health:DeltaPenalty(0.05)
			end
		end,
		duration=30
	},
	moon_curse = 
	{
		name = "moon_curse",
		duration = 12,
		onattachedfn = function(inst,target)
			inst:ListenForEvent("healthdelta",ForbiddenRegen,target)
		end,
	},
	solar_fire = 
	{
		name = "solar_fire",
		TICK_RATE = 2,
		TICK_FN = function(inst,target)
			if target.components.health~=nil and not target.components.health:IsDead() then
				target.components.health:DoDelta(-12,false,"solar_fire")
			end
			if target.components.temperature ~= nil then
                target.components.temperature:DoDelta(20)
            end 
		end,
		duration = 10,
		buff_fx = "cs_fireball_hit_fx"
	},
	vulnerability_hex = {
		name = "vulnerability_hex",
		TICK_RATE = 1,
		TICK_FN = function(inst,target)
			if target.components.health:IsDead() then
				inst.components.debuff:Stop()
			else
				target.components.health:DoFireDamage(4,inst,true)
			end 
		end,
		onattachedfn = function(inst,target,data)
			if target.components.combat~=nil then
				target.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 1.2)
				local fx = SpawnPrefab("character_fire")
				inst.fx = fx
				fx.entity:SetParent(target.entity)
				fx.entity:AddFollower():FollowSymbol(target.GUID, target.components.combat.hiteffectsymbol, 0,0,0)
				fx.persists = false
				fx.AnimState:SetMultColour(169/255, 36/255, 30/255,1)
				if fx.components.firefx ~= nil then
					fx.components.firefx:SetLevel(2, true)
				end
			end
			inst:ListenForEvent("healthdelta",ForbiddenRegen,target)
		end,
		duration = 5,
	}
}

return debuff_defs
