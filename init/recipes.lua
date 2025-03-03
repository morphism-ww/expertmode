local AddRecipePostInit = AddRecipePostInit
local AddPrototyperDef = AddPrototyperDef
local AddRecipe2 = AddRecipe2
local RUINSBAT_PARRY = GetModConfigData("ruinsbat")

GLOBAL.setfenv(1,GLOBAL)
----------------------------------------------------
--新科技
----------------------------------------------------

local TechTree = require("techtree")


table.insert(TechTree.AVAILABLE_TECH, "OBSIDIAN")


for k,v in pairs(TECH) do
    v.OBSIDIAN = 0
end

TECH.OBSIDIAN_ONE = { OBSIDIAN = 1 }
TECH.OBSIDIAN_TWO = { OBSIDIAN = 1,LUNARFORGING=2,SHADOWFORGING=2}


--for k,v in pairs(TUNING.PROTOTYPER_TREES) do
  --  v.OBSIDIAN = 0
--end

TUNING.PROTOTYPER_TREES.OBSIDIAN_ONE = TechTree.Create({OBSIDIAN = 1})
TUNING.PROTOTYPER_TREES.OBSIDIAN_TWO = TechTree.Create({OBSIDIAN = 1,LUNARFORGING=2,SHADOWFORGING=2})


for i, v in pairs(AllRecipes) do
    if v.level.OBSIDIAN == nil then
        v.level.OBSIDIAN = 0
    end
end

RECIPETABS['OBSIDIANTAB'] = {str = "OBSIDIANTAB", sort=90, icon = "tab_volcano.tex", icon_atlas = "images/tabs.xml", crafting_station = true}
AddPrototyperDef("dragonflyfurnace", {action_str = "OBSIDIANTAB", icon_image = "tab_volcano.tex", icon_atlas = "images/tabs.xml", is_crafting_station = true})

----------------------------------------------------------------------------
if RUINSBAT_PARRY then
    AddRecipePostInit("ruins_bat", function (self)
      self.image = "lavaarena_heavyblade.tex"
      self.ingredients[2].amount = 5
    end)  
end
AddRecipePostInit("voidcloth_boomerang", function (self)
table.insert(self.ingredients,Ingredient("shadowheart_infused", 1))
end)
CONSTRUCTION_PLANS["ironlord_death"] = { Ingredient("alterguardianhatshard", 1), Ingredient("aurumite", 6), Ingredient("wagpunk_bits", 5) }
----------------------------------------------------------------------------




AddRecipe2("newcs_axeobsidian", 	{Ingredient("goldenaxe", 1), Ingredient("newcs_obsidian", 1), Ingredient("newcs_dragoonheart", 1)},
        TECH.OBSIDIAN_ONE, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("newcs_spear_obsidian", 		{Ingredient("spear", 1), Ingredient("newcs_obsidian", 2),Ingredient("newcs_dragoonheart", 1)},
        TECH.OBSIDIAN_ONE, {nounlock=true}, {"CRAFTING_STATION"})
AddRecipe2("newcs_armorobsidian", 		 {Ingredient("newcs_obsidian", 5),Ingredient("newcs_dragoonheart",2)},
        TECH.OBSIDIAN_ONE, {nounlock=true}, {"CRAFTING_STATION"})

AddRecipe2("obsidianhat", 		 {Ingredient("newcs_dragoonheart",3),Ingredient("dragon_scales",1),Ingredient("footballhat",1)},
        TECH.OBSIDIAN_ONE, {nounlock=true,image="dragonheadhat.tex"}, {"CRAFTING_STATION"})

AddRecipe2("newcs_obsidianfirepit", 		 {Ingredient("newcs_obsidian",5),Ingredient("log",8)},
        TECH.SCIENCE_TWO,  {placer="newcs_obsidianfirepit_placer"},{"LIGHT","COOKING","WINTER","RAIN"})

AddRecipe2("newcs_volcanostaff",      {Ingredient("firestaff",1),Ingredient("newcs_dragoonheart",3),Ingredient("newcs_obsidian",4),Ingredient("demon_soul",2)},
        TECH.OBSIDIAN_ONE,{nounlock=true, numtogive=1,no_deconstruction=true})

AddRecipe2("quaker",{Ingredient("gears",2),Ingredient("orangegem",1),Ingredient("wagpunk_bits", 2),Ingredient("hammer",2),Ingredient("bearger_fur",1)},
        TECH.SCIENCE_TWO,{placer="quaker_placer"},{"TOOLS"})

AddRecipe2("antidote",{Ingredient("spore_small", 1),Ingredient("spore_tall",1),Ingredient("kelp",1)},
        TECH.SCIENCE_TWO,	{ numtogive=5},{"RESTORATION"})

AddRecipe2("lunarlight",{Ingredient("opalpreciousgem", 1),Ingredient("moonrocknugget",8),Ingredient("purebrilliance",4)},
        TECH.LOST,	{ placer="lunarlight_placer"},{"LIGHT","STRUCTURES"})

AddRecipe2("armorabyss",  { Ingredient("armorskeleton",1),Ingredient("horrorfuel",8),Ingredient("voidcloth",8),Ingredient("shadow_soul",2)},
         TECH.SHADOWFORGING_TWO,{nounlock=true,no_deconstruction=true},{"CRAFTING_STATION"})

AddRecipe2("cs_dreadsword",  {Ingredient("horrorfuel",3),Ingredient("voidcloth",3),Ingredient("dreadstone",4),Ingredient("shadowheart",1)},
         TECH.SHADOWFORGING_TWO,{nounlock=true,station_tag = "shadow_forge"},{"CRAFTING_STATION"})

AddRecipe2("laser_generator",  { Ingredient("aurumite",6),Ingredient("alterguardianhatshard",1),Ingredient("wagpunk_bits",8),Ingredient("iron_soul",2)},
        TECH.OBSIDIAN_TWO,{nounlock=true, no_deconstruction=true},{"CRAFTING_STATION"})

AddRecipe2("sword_lunarblast",   {Ingredient("sword_lunarplant",1),Ingredient("purebrilliance",3),Ingredient("aurumite",4),Ingredient("alterguardianhatshard",1)},
          TECH.OBSIDIAN_TWO,  {nounlock=true,no_deconstruction=true})

AddRecipe2("staff_lunarblast",   {Ingredient("staff_lunarplant",1),Ingredient("insight_soul",1),Ingredient("purebrilliance",8),Ingredient("aurumite",6)},
          TECH.OBSIDIAN_TWO,  {nounlock=true,no_deconstruction=true})

AddRecipe2("true_voidcloth_scythe",   {Ingredient("voidcloth_scythe",1),Ingredient("dreadstone",12),Ingredient("shadowheart_infused",1),Ingredient("shadow_soul",1)},
          TECH.OBSIDIAN_TWO,  {nounlock=true,no_deconstruction=true})

AddRecipe2("cs_infused_iron",   {Ingredient("aurumite",5),Ingredient("insight_soul",1),Ingredient("thulecite",10),Ingredient("cs_waterdrop",2)},
          TECH.OBSIDIAN_TWO,  {nounlock=true,no_deconstruction=true,numtogive = 5})  

AddRecipe2("cs_void_bag",   {Ingredient("horrorfuel",10),Ingredient("voidcloth",10),Ingredient("shadow_soul",1),Ingredient("cs_waterdrop",1)},
          TECH.SHADOWFORGING_TWO,  {nounlock=true,no_deconstruction=true,numtogive = 1})  

AddRecipe2("iokheira",   {Ingredient("trident",1),Ingredient("cs_infused_iron",3),Ingredient("bluegem",10),Ingredient("purebrilliance",5)},
          TECH.OBSIDIAN_TWO,  {nounlock=true,no_deconstruction=true})          

AddRecipe2("armororichal",  {Ingredient("armorruins",1),Ingredient("aurumite",8),Ingredient("shadow_soul",2),Ingredient("cs_waterdrop",1),Ingredient("dreadstone",10),},
          TECH.OBSIDIAN_TWO,  {nounlock=true, no_deconstruction=true})

AddRecipe2("orichalhat",    {Ingredient("ruinshat",1),Ingredient("aurumite",6),Ingredient("insight_soul",1),Ingredient("voidcloth",10),Ingredient("cs_waterdrop",1)},
           TECH.OBSIDIAN_TWO,  {nounlock=true, no_deconstruction=true})

AddRecipe2("laser_cannon",   {Ingredient("laser_generator",1),Ingredient("cs_infused_iron",2)},
           TECH.LOST,  {no_deconstruction=true,image="laser_generator.tex"},{"WAR", "TOOLS"}) 
           
AddRecipe2("constant_medal", {Ingredient("amulet",1),Ingredient("cs_waterdrop",1),Ingredient("aurumite",8)},
           TECH.OBSIDIAN_TWO,  {nounlock=true,no_deconstruction=true,image ="quagmire_coin3.tex"})     

AddRecipe2("aurumite_kit",    {Ingredient("aurumite",10),Ingredient("greengem",1),Ingredient("cs_waterdrop",1)},
           TECH.OBSIDIAN_TWO,  {nounlock=true, no_deconstruction=true})