local require = GLOBAL.require
local cooking = require "cooking"
local recipes = cooking.recipes.cookpot
local warly_recipes = cooking.recipes.portablecookpot


recipes.fruitmedley.priority =20
recipes.fruitmedley.test=function(cooker, names, tags)
	return names.royal_jelly and tags.dairy and tags.fruit and tags.fruit >= 2 and not tags.meat and not tags.veggie
end
recipes.fruitmedley.stacksize = 3
recipes.fruitmedley.foodtype=FOODTYPE.GOODIES


warly_recipes.fruitmedley.priority =20
warly_recipes.fruitmedley.test=function(cooker, names, tags)
	return names.royal_jelly and tags.dairy and tags.fruit and tags.fruit >= 2 and not tags.meat and not tags.veggie
end
warly_recipes.fruitmedley.stacksize = 3
warly_recipes.fruitmedley.foodtype=FOODTYPE.GOODIES

local function oneatenfn(inst,eater)
	eater:AddDebuff("fastbuff", "buff_fast")
end

AddPrefabPostInit("fruitmedley", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst.components.edible.hungervalue = 33
	inst.components.edible.sanityvalue = 50
	inst.components.edible.healthvalue = 40
	inst.components.edible:SetOnEatenFn(oneatenfn)
end)