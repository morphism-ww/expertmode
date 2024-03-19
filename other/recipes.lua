local Ingredient=Ingredient
local AddRecipe2=AddRecipe2


AddRecipe2("axeobsidian", 	{Ingredient("goldenaxe", 1), Ingredient("obsidian", 2), Ingredient("dragoonheart", 1)},
        TECH.OBSIDIAN_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("spear_obsidian", 		{Ingredient("livinglog", 1), Ingredient("obsidian", 2),Ingredient("dragoonheart", 1)},
        TECH.OBSIDIAN_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("armorobsidian", 		 {Ingredient("obsidian", 5),Ingredient("dragoonheart",2)},
        TECH.OBSIDIAN_TWO, {nounlock=true}, {"CRAFTING_STATION"})

AddRecipe2("obsidian_hat", 		 {Ingredient("dragoonheart",2),Ingredient("dragon_scales",1),Ingredient("footballhat",1)},
        TECH.OBSIDIAN_TWO, {atlas="images/inventoryimages/obsidian_hat.xml", nounlock=true}, {"CRAFTING_STATION"})

AddRecipe2("obsidianfirepit", 		 {Ingredient("obsidian",6),Ingredient("log",8)},
        TECH.SCIENCE_TWO,{placer="obsidianfirepit_placer"},{"LIGHT","COOKING","WINTER","RAIN"})

AddRecipe2("obsidian", 		 {Ingredient("dreadstone",1),Ingredient("redgem",2)},
        TECH.OBSIDIAN_ONE,{nounlock=true, numtogive=2,no_deconstruction=true})

AddRecipe2("volcanostaff",      {Ingredient("yellowstaff",1),Ingredient("firestaff",1),Ingredient("dragoonheart",3),Ingredient("obsidian",4),
        Ingredient("demon_soul",1)},
        TECH.OBSIDIAN_ONE,{nounlock=true, numtogive=2,no_deconstruction=true})

AddRecipe2("quaker",{Ingredient("gears",4),Ingredient("orangegem",1),Ingredient("hammer",2),Ingredient("bearger_fur",1)},
        TECH.SCIENCE_TWO,{placer="quaker_placer"},{"TOOLS"})

AddRecipe2("superboat_kit",{Ingredient("gears", 4),Ingredient("boards",6),Ingredient("driftwood_log",3),Ingredient("palmcone_scale",8)},
        TECH.SEAFARING,	{ image="boat_yotd_item.tex"},{"SEAFARING"})

--[[AddRecipe2("lunar_blast",{Ingredient("opalstaff", 1),Ingredient("alterguardianhatshard",1),Ingredient("purebrilliance",3)},
        TECH.LUNARFORGING_TWO,	{ nounlock=true},{"CRAFTING_STATION"})]]

AddRecipe2("antidote",{Ingredient("spore_small", 1),Ingredient("spore_tall",1),Ingredient("kelp",1)},
        TECH.SCIENCE_TWO,	{ numtogive=5},{"RESTORATION"})


local config = {
    atlas = "images/inventoryimages/armorvortexcloak.xml",nounlock=true,no_deconstruction=true
}


AddRecipe2("armorvortexcloak",  { Ingredient("armorskeleton",1),Ingredient("horrorfuel", 20),Ingredient("voidcloth",20)},
         TECH.SHADOWFORGING_ONE,{nounlock=true,no_deconstruction=true},{"CRAFTING_STATION"})