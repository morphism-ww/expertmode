local function noregen(target,food)
	if target.components.health~=nil then
		target.components.health:DoDelta(-33)
	end
end


local debuff_defs={
	curse_fire =
	{
		name="curse_fire",
		prefabs={ "cursefire_fx" },
		TICK_RATE = 2,
		TICK_FN=function(inst, target,data)
			if target.components.health ~= nil and
				not target.components.health:IsDead() then
				target.components.health:DoDelta(-inst.damage,false, inst.prefab)
				target.components.health:DoFireDamage(1,inst.prefab,false)
			else
				inst.components.debuff:Stop()
			end
		end,
		buff_fx = "cursefire_fx",
		postinit=function(inst)
			inst.duration=10
			inst.damage=6
		end,
		onextendedfn=function(inst,target,data)
			if data and data.upgrade then
				inst.damage=math.min(inst.damage+2,10)
			end
		end
	},
	poison=
	{
		name="poison",
		TICK_RATE = 15,
		TICK_FN=function(inst,target,data)
			target.components.health:DoDelta(-inst.damage, nil,"poison")
			if target:HasTag("player") then
				target.player_classified.poisonover:set_local(true)
				target.player_classified.poisonover:set(true)
			end
		end,
		postinit=function(inst)
			inst.damage=2
		end,
		onextendedfn=function(inst,target,data)
			if data and data.upgrade then
				inst.damage=math.min(inst.damage,3)
			end
		end
	},
	poison2=
	{
		name="poison_2",
		TICK_RATE = 2,
		TICK_FN=function(inst,target,data)
			target.components.health:DoDelta(-inst.damage, nil,"poison")
			if target.components.hunger ~= nil then
				if target.components.hunger.current > 0 then
					target.components.hunger:DoDelta(-1)
				end
			end
			if target.components.sanity~=nil then
				target.components.sanity:DoDelta(-1)
			end
			if target:HasTag("player") and not target:HasTag("playerghost") then
				target.player_classified.poisonover:set_local(true)
				target.player_classified.poisonover:set(true)
			end
		end,
		postinit=function(inst)
			inst.damage=3
		end,
		onextendedfn=function(inst,target,data)
			if data and data.upgrade then
				inst.damage=math.min(inst.damage+2,8)
			end
		end
	},
	weak=
	{
		name="weak",
		onattachedfn=function(inst,target,data)
			if target.components.locomotor and data then
				target.components.locomotor:SetExternalSpeedMultiplier(inst, "weak", data.speed)
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
		onextendedfn=function(inst,target,data)
			if target.components.locomotor and data then
				target.components.locomotor:SetExternalSpeedMultiplier(inst, "weak", data.speed)
			end
			if target:HasTag("player") then
				target.components.workmultiplier:AddMultiplier(ACTIONS.CHOP,    0.5, inst)
        		target.components.workmultiplier:AddMultiplier(ACTIONS.MINE,    0.5, inst)
        		target.components.workmultiplier:AddMultiplier(ACTIONS.HAMMER,  0.5, inst)
			end
			if target.components.combat then
				target.components.combat.externaldamagemultipliers:SetModifier(inst, 0.5)
			end
			if target.components.mightiness then
				target.components.mightiness.ratemodifiers:SetModifier(inst, 10)
			end
		end,
		postinit=function(inst)
		end,
	},
	corrupt=
	{
		name="vulnerable",
		onattachedfn=function(inst,target,data)
			if target.components.combat then
				target.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 2)
			end
		end,
		postinit=function(inst)
		end,
	},
	food_sickness=
	{
		name="food_sickness",
		onattachedfn=function(inst,target)
			inst:ListenForEvent("oneat",noregen,target)
		end,
		postinit=function(inst)

		end,
	},
	exhaustion=
	{
		name="exhaustion",
		TICK_RATE = 5,
		TICK_FN=function(inst,target)
			if target:HasTag("player") and target.components.health ~= nil then
				target.components.health:DeltaPenalty(0.05)
			end
		end,
		postinit=function (inst)
			inst.duration=30
		end
	},
}

return debuff_defs
