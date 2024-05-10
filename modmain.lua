GLOBAL.setmetatable(env, {__index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end})
local TUNING = GLOBAL.TUNING


Assets={
Asset("SOUNDPACKAGE", "sound/dontstarve_DLC002.fev"),
Asset("SOUNDPACKAGE", "sound/sw_character.fev"),
Asset("SOUND", "sound/dontstarve_shipwreckedSFX.fsb"),
Asset("SOUND", "sound/sw_character.fsb"),
Asset("SOUNDPACKAGE", "sound/dontstarve_DLC003.fev"),
Asset("SOUND", "sound/DLC003_sfx.fsb"),
Asset("SOUND","sound/wagstaff.fsb"),
Asset("SOUNDPACKAGE","sound/wagstaff.fev"),
Asset("SOUND","sound/bossrush.fsb"),
Asset("SOUNDPACKAGE","sound/bossrush.fev"),
Asset("ATLAS", "images/inventoryimages/volcanoinventory.xml"),
Asset("IMAGE", "images/inventoryimages/volcanoinventory.tex" ),
Asset("ATLAS", "images/tabs.xml"),
Asset("IMAGE", "images/tabs.tex" ),
Asset("IMAGE","images/inventoryimages/armorvortexcloak.tex"),
Asset("ATLAS","images/inventoryimages/armorvortexcloak.xml"),
Asset("IMAGE","images/inventoryimages/obsidian_hat.tex"),
Asset("ATLAS","images/inventoryimages/obsidian_hat.xml"),
Asset("IMAGE","images/inventoryimages/lunar_blast.tex"),
Asset("ATLAS","images/inventoryimages/lunar_blast.xml"),
Asset("IMAGE","images/inventoryimages/quaker.tex"),
Asset("ATLAS","images/inventoryimages/quaker.xml"),
Asset("IMAGE","images/inventoryimages/demon_soul.tex"),
Asset("ATLAS","images/inventoryimages/demon_soul.xml"),
Asset("IMAGE","images/inventoryimages/iron_soul.tex"),
Asset("ATLAS","images/inventoryimages/iron_soul.xml"),
Asset("IMAGE","images/inventoryimages/insight_soul.tex"),
Asset("ATLAS","images/inventoryimages/insight_soul.xml"),
Asset("IMAGE","images/inventoryimages/lunarlight.tex"),
Asset("ATLAS","images/inventoryimages/lunarlight.xml"),
Asset("IMAGE","images/inventoryimages/northpole.tex"),
Asset("ATLAS","images/inventoryimages/northpole.xml"),
Asset("IMAGE","images/inventoryimages/sword_ancient.tex"),
Asset("ATLAS","images/inventoryimages/sword_ancient.xml"),
Asset("ATLAS", "images/fx4te.xml"),
Asset("IMAGE", "images/fx4te.tex"),}

local atlas = "images/inventoryimages/volcanoinventory.xml"
local function ProcessAtlas(atlas, ...)
  local path = softresolvefilepath(atlas)
  if not path then
    print("[API]: The atlas \"" .. atlas .. "\" cannot be found.")
    return
  end
  local success, file = pcall(io.open, path)
  if not success or not file then
    print("[API]: The atlas \"" .. atlas .. "\" cannot be opened.")
    return
  end
  local xml = file:read("*all")
  file:close()
  local images = xml:gmatch("<Element name=\"(.-)\"")
  for tex in images do
    RegisterInventoryItemAtlas(path, tex)
    RegisterInventoryItemAtlas(path, hash(tex))
  end
end
ProcessAtlas(atlas)

RegisterInventoryItemAtlas("images/inventoryimages/lunar_blast.xml", "lunar_blast.tex")

RegisterInventoryItemAtlas("images/inventoryimages/quaker.xml", "quaker.tex")

RegisterInventoryItemAtlas("images/inventoryimages/armorvortexcloak.xml", "armorvortexcloak.tex")

RegisterInventoryItemAtlas("images/inventoryimages/demon_soul.xml", "demon_soul.tex")

RegisterInventoryItemAtlas("images/inventoryimages/insight_soul.xml", "insight_soul.tex")

RegisterInventoryItemAtlas("images/inventoryimages/iron_soul.xml", "iron_soul.tex")

RegisterInventoryItemAtlas("images/inventoryimages/lunarlight.xml", "lunarlight.tex")

RegisterInventoryItemAtlas("images/inventoryimages/obsidian_hat.xml", "obsidian_hat.tex")

RegisterInventoryItemAtlas("images/inventoryimages/northpole.xml", "northpole.tex")

RegisterInventoryItemAtlas("images/inventoryimages/sword_ancient.xml", "sword_ancient.tex")

AddMinimapAtlas("images/inventoryimages/armorvortexcloak.xml")


modimport('other/containers')
modimport ("other/standardcomponents")
modimport('other/actions')
modimport('other/player')
modimport('other/player_sg')
modimport('other/ui')
modimport("other/init_constants")
--modimport("other/move_attack")




PrefabFiles={"twin_flame","twin_laser","armorvortexcloak","leechterror","shadowflame",
             "laser_ring","ancient_hulk","shadowdragon","ancient_scanner","laser_spark","laser","brightshade_projectile",
            "shadoweyeturret","scanner_spawn","true_sword_lunarplant","shadowwave","constant_souls",
            "obsidian","obsidianfirefire","obsidianfirepit","obsidiantoollight","spear_obsidian","axeobsidian","armor_obsidian","hat_obsidian",
            "meteor_impact","firerain","lavapool","dragoonheart","dragoonspit","dragoon","dragoonegg",
            "superbrilliance_projectile_fx","true_staff_lunarplant","klaus_soul",
            "super_boat","quaker","fire_tornado","alter_light","lunar_blast","lunar_shield",
            "fast_buff","make_buffs","cursefire_fx","brightshade_queen","anti_poison","obsidianstaff",
            "lunar_light","lunarlight_flame","magic_fx","shadow_mfz","god_judge",
            "ancient_robots","corrupt_heart","northpole","armor_ancient","hat_ancient","sword_ancient","constant_star",
            "void_light","bossrush_manager","void_key","true_voidcloth_scythe"}

if GetModConfigData("pig") then
    modimport("postinit/epic/daywalker")
end

if GetModConfigData("twin") then
    modimport("postinit/epic/eyeofterror")
    modimport("postinit/epic/twinofterror")
    modimport("postinit/shieldofterror.lua")
end

if GetModConfigData("alter") then
    modimport("postinit/epic/alterguardian")
    modimport("postinit/components/meteorshower")
end

if GetModConfigData("rook") then
    modimport("postinit/epic/minotaur")
end

if GetModConfigData("alterhat") then
    TUNING.noalterguardianhat2hm=true
    modimport("postinit/alterguardianhat")
end

if GetModConfigData("dragon_fire") then
    TUNING.FIRERAIN_ENABLE = true
    modimport("postinit/epic/dragonfly")
    

end

if GetModConfigData("klaus") then
    modimport("postinit/epic/klaus")
    modimport("postinit/components/klausloot")
end

if GetModConfigData("poison") then
    modimport("postinit/epic/beequeen")
    modimport("postinit/epic/toadstool")
    modimport("postinit/mushroom_hat")
    modimport("postinit/poison_creature")
end

if GetModConfigData("ancient") then
    modimport("postinit/shadowmachine")
end

if GetModConfigData("gestalt") then
    TUNING.ALLOW_LUNAR_QUEEN=true
    modimport("postinit/gestalt")
end

if GetModConfigData("ruins") then
    modimport("postinit/ruins")
end

if GetModConfigData("chess") then
    modimport("postinit/epic/shadowchesspieces")
end

if GetModConfigData("wardrobe") then
    modimport("postinit/wardrobe")
end

modimport("postinit/dragonflyfurnace")
modimport("postinit/shadow_armor")
modimport("postinit/components/explosive")
modimport("postinit/dont_skip")
modimport("other/playercharge.lua")
modimport("postinit/components/true_defence")

modimport("postinit/upgrade_weapon")
modimport("postinit/epic/stalker")
---------------------------------------

modimport("postinit/fuel")
modimport("postinit/amulet")
modimport("postinit/town_portal")
modimport("postinit/lunarplant_staff")
modimport("postinit/planar_armor")
modimport("postinit/repairable")
------------------------------------------
modimport("postinit/invade")
---------------------------------------------
modimport("postinit/ocean/cannon")


TUNING.NEW_CONSTANT_SHADOWDRAGON=GetModConfigData("shadowdragon")

modimport("postinit/components/cn_boatphysics")
--modimport("postinit/components/growable")
--modimport("postinit/components/ambientlighting")


modimport("postinit/food")


modimport("postinit/epic/lunarthrall_plant")
modimport("postinit/epic/shadowthrall")
modimport("postinit/anti_poison")


modimport("postinit/epic/warg")
modimport("postinit/punchingbag")
modimport("postinit/farming")
--modimport("postinit/ranged_weapon")


------------bossrush
modimport("postinit/bossrush/entrance")
modimport("postinit/bossrush/bossrush_protect")





modimport("other/new_loot")
modimport("other/newstring.lua")

----------------------------------------------------
TUNING.SHIELDOFTERROR_ARMOR = 840

TUNING.EYEOFTERROR_HEALTH = 8000
TUNING.TOADSTOOL_HEALTH = 35000
TUNING.TOADSTOOL_DARK_HEALTH = 50000

----------------------------------------------------
--黑曜石科技
----------------------------------------------------
local GLOBAL = GLOBAL
local require = GLOBAL.require
local TechTree = require("techtree")
table.insert(TechTree.AVAILABLE_TECH, "OBSIDIAN")
TechTree.Create = function(t)
	t = t or {}
	for i, v in ipairs(TechTree.AVAILABLE_TECH) do
	    t[v] = t[v] or 0
	end
	return t
end

GLOBAL.TECH.NONE.OBSIDIAN = 0
GLOBAL.TECH.OBSIDIAN_ONE = { OBSIDIAN = 1 }
GLOBAL.TECH.OBSIDIAN_TWO = { OBSIDIAN = 2 }
GLOBAL.TECH.OBSIDIAN_THREE = { OBSIDIAN = 3 }

for k,v in pairs(TUNING.PROTOTYPER_TREES) do
    v.OBSIDIAN = 0
end

TUNING.PROTOTYPER_TREES.OBSIDIAN_ONE = TechTree.Create({
    OBSIDIAN = 1,
})
TUNING.PROTOTYPER_TREES.OBSIDIAN_TWO = TechTree.Create({
     OBSIDIAN = 2,
 })

 TUNING.PROTOTYPER_TREES.OBSIDIAN_THREE = TechTree.Create({
    OBSIDIAN = 3,
})
for i, v in pairs(GLOBAL.AllRecipes) do
    if v.level.OBSIDIAN == nil then
        v.level.OBSIDIAN = 0
    end
end

GLOBAL.RECIPETABS['OBSIDIANTAB'] = {str = "OBSIDIANTAB", sort=90, icon = "tab_volcano.tex", icon_atlas = "images/tabs.xml", crafting_station = true}
AddPrototyperDef("dragonflyfurnace", {action_str = "OBSIDIANTAB", icon_image = "tab_volcano.tex", icon_atlas = "images/tabs.xml", is_crafting_station = true})
AddPrototyperDef("lava_pond", {action_str = "OBSIDIANTAB", icon_image = "tab_volcano.tex", icon_atlas = "images/tabs.xml", is_crafting_station = true})
modimport("other/recipes")