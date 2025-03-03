local cooking = require "cooking"
local recipes = cooking.recipes.cookpot
local warly_recipes = cooking.recipes.portablecookpot


recipes.fruitmedley.priority = 20
recipes.fruitmedley.test = function(cooker, names, tags)
	return tags.dairy and tags.fruit and tags.fruit >= 2 and not tags.meat and not tags.veggie
end
recipes.fruitmedley.stacksize = 3


warly_recipes.fruitmedley.priority =20
warly_recipes.fruitmedley.test = function(cooker, names, tags)
	return tags.dairy and tags.fruit and tags.fruit >= 2 and not tags.meat and not tags.veggie
end
warly_recipes.fruitmedley.stacksize = 3



local function oneaten_fast(oneatenfn_old)
	return function (inst,eater)
		if oneatenfn_old then 
			oneatenfn_old(inst,eater)
		end	
		eater:AddDebuff("buff_fast","buff_fast")
	end
end

local fruitmedley_list = {"fruitmedley","fruitmedley_spice_chili","fruitmedley_spice_garlic","fruitmedley_spice_salt","fruitmedley_spice_sugar"}
for k,v in ipairs(fruitmedley_list) do
	newcs_env.AddPrefabPostInit(v, function(inst)
		if not TheWorld.ismastersim then
			return inst
		end
		inst.components.edible.hungervalue = TUNING.CALORIES_SMALL  --12.5
		inst.components.edible.sanityvalue = TUNING.SANITY_HUGE  --50
		inst.components.edible.healthvalue = TUNING.HEALING_MEDLARGE  --30

		inst.components.edible.foodtype = FOODTYPE.GOODIES

		local oneatenfn_old = inst.components.edible.oneaten
		inst.components.edible:SetOnEatenFn(oneaten_fast(oneatenfn_old))
	end)
end


local function oneaten_warm(inst,eater)
	eater:AddDebuff("buff_warm", "buff_warm")
end

newcs_env.AddPrefabPostInit("dragonchilisalad", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst.components.edible:SetOnEatenFn(oneaten_warm)
end)

--禁止回血！
newcs_env.AddComponentPostInit("edible",function (self)
	local old_gethealth = self.GetHealth
	function self:GetHealth(eater)
		local old_hp = old_gethealth(self,eater)
		if eater~=nil and eater:HasDebuff("food_sickness") then
			return -0.5*math.abs(old_hp)
		else
			return old_hp
		end
	end
end)