local v_atlas = "images/inventoryimages/volcanoinventory.xml"


--Ingredient("dragoonheart", 1, v_atlas)

AddRecipe2("axeobsidian", 			{Ingredient("goldenaxe", 1), Ingredient("obsidian", 2,v_atlas), Ingredient("dragoonheart", 1,v_atlas)},
        TECH.OBSIDIAN_TWO, {atlas=v_atlas, nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("spear_obsidian", 		{Ingredient("livinglog", 1), Ingredient("obsidian", 2,v_atlas),Ingredient("dragoonheart", 1,v_atlas)},
        TECH.OBSIDIAN_TWO, {atlas=v_atlas, nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("armorobsidian", 		 {Ingredient("obsidian", 5,v_atlas),Ingredient("dragoonheart",2,v_atlas)},
        TECH.OBSIDIAN_TWO, {atlas=v_atlas, nounlock=true}, {"CRAFTING_STATION"})

AddRecipe2("obsidian_hat", 		 {Ingredient("dragoonheart",2,v_atlas),Ingredient("dragon_scales",1),Ingredient("footballhat",1)},
        TECH.OBSIDIAN_TWO, {atlas="images/inventoryimages/obsidian_hat.xml", nounlock=true}, {"CRAFTING_STATION"})

AddRecipe2("obsidianfirepit", 		 {Ingredient("obsidian",6,v_atlas),Ingredient("log",8)},
        TECH.SCIENCE_TWO,{placer="obsidianfirepit_placer",atlas=v_atlas},{"LIGHT","COOKING","WINTER","RAIN"})

AddRecipe2("obsidian", 		 {Ingredient("dreadstone",1),Ingredient("redgem",2)},
        TECH.OBSIDIAN_ONE,{atlas=v_atlas, nounlock=true, numtogive=2,no_deconstruction=true})

AddRecipe2("quaker",{Ingredient("gears",4),Ingredient("orangegem",1),Ingredient("hammer",2),Ingredient("bearger_fur",1)},
        TECH.SCIENCE_TWO,{placer="quaker_placer"},{"TOOLS"})

AddRecipe2("superboat_kit",{Ingredient("gears", 4),Ingredient("boards",6),Ingredient("driftwood_log",3),Ingredient("palmcone_scale",8)},
        TECH.SEAFARING,	{ image="boat_yotd_item.tex"},{"SEAFARING"})

--[[AddRecipe2("lunar_blast",{Ingredient("opalstaff", 1),Ingredient("alterguardianhatshard",1),Ingredient("purebrilliance",3)},
        TECH.LUNARFORGING_TWO,	{ nounlock=true},{"CRAFTING_STATION"})]]

AddRecipe2("antidote",{Ingredient("spore_small", 1),Ingredient("spore_tall",1),Ingredient("spore_medium",1),Ingredient("slurtle_shellpieces",1)},
TECH.SCIENCE_TWO,	{ numtogive=5,atlas=v_atlas},{"RESTORATION"})


local config = {
    atlas = "images/inventoryimages/armorvortexcloak.xml",nounlock=true,no_deconstruction=true
}
local ingredients = { Ingredient("armorskeleton",1),Ingredient("horrorfuel", 20),Ingredient("voidcloth",20)}--Ingredient("staff_lunarplant",1)}}
AddRecipe2("armorvortexcloak", ingredients, TECH.SHADOWFORGING_ONE,config,{"CRAFTING_STATION"})