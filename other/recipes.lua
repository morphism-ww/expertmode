local Ingredient=Ingredient
local AddRecipe2=AddRecipe2


AddRecipe2("axeobsidian", 	{Ingredient("goldenaxe", 1), Ingredient("obsidian", 1), Ingredient("dragoonheart", 1)},
        TECH.OBSIDIAN_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("spear_obsidian", 		{Ingredient("livinglog", 1), Ingredient("obsidian", 2),Ingredient("dragoonheart", 1)},
        TECH.OBSIDIAN_TWO, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("armorobsidian", 		 {Ingredient("obsidian", 5),Ingredient("dragoonheart",2)},
        TECH.OBSIDIAN_TWO, {nounlock=true}, {"CRAFTING_STATION"})

AddRecipe2("obsidian_hat", 		 {Ingredient("dragoonheart",3),Ingredient("dragon_scales",1),Ingredient("footballhat",1)},
        TECH.OBSIDIAN_TWO, {nounlock=true}, {"CRAFTING_STATION"})

AddRecipe2("obsidianfirepit", 		 {Ingredient("obsidian",5),Ingredient("log",8)},
        TECH.SCIENCE_TWO,  {placer="obsidianfirepit_placer"},{"LIGHT","COOKING","WINTER","RAIN"})

AddRecipe2("obsidian", 		 {Ingredient("dreadstone",1),Ingredient("redgem",2)},
        TECH.OBSIDIAN_ONE,{nounlock=true, numtogive=2,no_deconstruction=true})

AddRecipe2("volcanostaff",      {Ingredient("firestaff",1),Ingredient("dragoonheart",3),Ingredient("obsidian",4),Ingredient("demon_soul",1)},
        TECH.OBSIDIAN_ONE,{nounlock=true, numtogive=1,no_deconstruction=true})

AddRecipe2("quaker",{Ingredient("gears",2),Ingredient("orangegem",1),Ingredient("wagpunk_bits", 2),Ingredient("hammer",2),Ingredient("bearger_fur",1)},
        TECH.SCIENCE_TWO,{placer="quaker_placer"},{"TOOLS"})

AddRecipe2("superboat_kit",{Ingredient("wagpunk_bits", 4),Ingredient("boards",6),Ingredient("driftwood_log",3),Ingredient("palmcone_scale",6)},
        TECH.SEAFARING,	{ image="boat_yotd_item.tex"},{"SEAFARING"})

--[[AddRecipe2("lunar_blast",{Ingredient("opalstaff", 1),Ingredient("alterguardianhatshard",1),Ingredient("purebrilliance",3)},
        TECH.LUNARFORGING_TWO,	{ nounlock=true},{"CRAFTING_STATION"})]]

AddRecipe2("antidote",{Ingredient("spore_small", 1),Ingredient("spore_tall",1),Ingredient("kelp",1)},
        TECH.SCIENCE_TWO,	{ numtogive=5},{"RESTORATION"})

AddRecipe2("lunarlight",{Ingredient("opalpreciousgem", 1),Ingredient("moonrocknugget",8),Ingredient("purebrilliance",4)},
        TECH.LOST,	{ placer="lunarlight_placer"},{"LIGHT","STRUCTURES"})

AddRecipe2("armorvortexcloak",  { Ingredient("armorskeleton",1),Ingredient("horrorfuel", 20),Ingredient("voidcloth",20)},
         TECH.SHADOWFORGING_ONE,{nounlock=true,no_deconstruction=true},{"CRAFTING_STATION"})

AddRecipe2("true_sword_lunarplant",   {Ingredient("sword_lunarplant",1),Ingredient("alterguardianhatshard",1),Ingredient("purebrilliance",8)},
          TECH.OBSIDIAN_THREE,  {nounlock=true,image="sword_lunarplant.tex"})

AddRecipe2("true_staff_lunarplant",   {Ingredient("staff_lunarplant",1),Ingredient("insight_soul",1),Ingredient("purebrilliance",8),Ingredient(	"moonglass_charged",4)},
          TECH.OBSIDIAN_THREE,  {nounlock=true,image="staff_lunarplant.tex"})

AddRecipe2("northpole",   {Ingredient("trident",1),Ingredient("insight_soul",1),Ingredient("bluegem",20)},
          TECH.OBSIDIAN_THREE,  {nounlock=true})

AddRecipe2("true_voidcloth_scythe",   {Ingredient("voidcloth_scythe",1),Ingredient("dreadstone",8),Ingredient("horrorfuel",10)},
          TECH.OBSIDIAN_THREE,  {nounlock=true,no_deconstruction=true,image="voidcloth_scythe.tex"})

--[[AddRecipe2("sword_ancient",     {Ingredient("voidcloth_scythe",1),Ingredient("true_sword_lunarplant",1,nil,true,"sword_lunarplant.tex"),
        Ingredient("thulecite",20),Ingredient("opalpreciousgem",4),Ingredient("alterguardianhatshard",1)},
         TECH.OBSIDIAN_THREE,  {nounlock=true, no_deconstruction=true})         
AddRecipe2("armor_ancient",     {Ingredient("thulecite",20),Ingredient(	"armor_voidcloth",1),
         Ingredient("armordreadstone",1),Ingredient("armorskeleton",1),Ingredient("alterguardianhatshard",1)},
          TECH.OBSIDIAN_THREE,  {nounlock=true, no_deconstruction=true,image="lavaarena_armor_hpextraheavy.tex"})
AddRecipe2("hat_ancient",     {Ingredient("thulecite",20),Ingredient("voidclothhat",1),
          Ingredient("dreadstonehat",1),Ingredient("skeletonhat",1),Ingredient("security_pulse_cage_full",1)},
           TECH.OBSIDIAN_THREE,  {nounlock=true, no_deconstruction=true,image="lavaarena_crowndamagerhat.tex"})]]                             