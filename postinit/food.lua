local cooking = require "cooking"
local recipes = cooking.recipes.cookpot
local warly_recipes = cooking.recipes.portablecookpot


recipes.fruitmedley.priority =20
recipes.fruitmedley.test = function(cooker, names, tags)
	return tags.dairy and tags.fruit and tags.fruit >= 2 and not tags.meat and not tags.veggie
end
recipes.fruitmedley.stacksize = 3


warly_recipes.fruitmedley.priority =20
warly_recipes.fruitmedley.test = function(cooker, names, tags)
	return tags.dairy and tags.fruit and tags.fruit >= 2 and not tags.meat and not tags.veggie
end
warly_recipes.fruitmedley.stacksize = 3
warly_recipes.fruitmedley.foodtype = FOODTYPE.GOODIES


local function oneaten_fast(oneatenfn_old)
	return function (inst,eater)
		if oneatenfn_old then 
			oneatenfn_old(inst,eater)
		end	
		eater:AddDebuff("fastbuff", "buff_fast")
	end
end

local fruitmedley_list = {"fruitmedley","fruitmedley_spice_chili","fruitmedley_spice_garlic","fruitmedley_spice_salt","fruitmedley_spice_sugar"}
for k,v in ipairs(fruitmedley_list) do
	AddPrefabPostInit(v, function(inst)
		if not TheWorld.ismastersim then
			return inst
		end
		inst.components.edible.hungervalue = 33
		inst.components.edible.sanityvalue = 50
		inst.components.edible.healthvalue = 40

		inst.foodtype = FOODTYPE.GOODIES

		local oneatenfn_old = inst.components.edible.oneaten
		inst.components.edible:SetOnEatenFn(oneaten_fast(oneatenfn_old))
	end)
end


local function oneaten_warm(inst,eater)
	eater:AddDebuff("warmbuff", "buff_warm")
end

AddPrefabPostInit("dragonchilisalad", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst.components.edible:SetOnEatenFn(oneaten_warm)
end)