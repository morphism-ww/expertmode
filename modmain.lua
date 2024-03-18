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
Asset("ATLAS", "images/inventoryimages/volcanoinventory.xml"),
Asset("IMAGE", "images/inventoryimages/volcanoinventory.tex" ),
Asset("ATLAS", "images/tabs.xml"),
Asset("IMAGE", "images/tabs.tex" ),
Asset("IMAGE","images/inventoryimages/constant_soul.tex"),
Asset("ATLAS","images/inventoryimages/constant_soul.xml"),
Asset("IMAGE","images/inventoryimages/armorvortexcloak.tex"),
Asset("ATLAS","images/inventoryimages/armorvortexcloak.xml"),
Asset("IMAGE","images/inventoryimages/obsidian_hat.tex"),
Asset("ATLAS","images/inventoryimages/obsidian_hat.xml"),
Asset("IMAGE","images/inventoryimages/lunar_blast.tex"),
Asset("ATLAS","images/inventoryimages/lunar_blast.xml"),
Asset("IMAGE","images/inventoryimages/quaker.tex"),
Asset("ATLAS","images/inventoryimages/quaker.xml"),
Asset("ATLAS", "images/fx4te.xml"),
Asset("IMAGE", "images/fx4te.tex"),}


RegisterInventoryItemAtlas("images/inventoryimages/lunar_blast.xml", "lunar_blast.tex")

RegisterInventoryItemAtlas("images/inventoryimages/quaker.xml", "quaker.tex")

AddMinimapAtlas("images/inventoryimages/armorvortexcloak.xml")


modimport('other/containers')
modimport ("other/standardcomponents")
modimport('other/actions')
modimport('other/player')
modimport('other/stun_protect')
modimport('other/ui')





PrefabFiles={"twin_flame","twin_laser","armorvortexcloak","leechterror","shadowflame",
             "laser_ring","ancient_hulk","shadowdragon","ancient_scanner","laser_spark","laser","brightshade_projectile",
            "shadoweyeturret","scanner_spawn","true_sword_lunarplant","shadowwave","constant_souls",
            "obsidian","obsidianfirefire","obsidianfirepit","obsidiantoollight","spear_obsidian","axeobsidian","armor_obsidian","hat_obsidian",
            "meteor_impact","firerain","lavapool","dragoonheart","dragoonspit","dragoon","dragoonegg",
            "superbrilliance_projectile_fx","true_staff_lunarplant","klaus_soul",
            "super_boat","quaker","fire_tornado","alter_light","lunar_blast","lunar_shield",
            "fast_buff","make_buffs","cursefire_fx","poison_spore","brightshade_queen","anti_poison"}

if GetModConfigData("pig") then
    modimport("postinit/epic/daywalker")
    modimport("postinit/armor_dreadstone")
end

if GetModConfigData("twin") then
    modimport("postinit/epic/eyeofterror")
    modimport("postinit/epic/twinofterror")
    modimport("postinit/shieldofterror.lua")
end

if GetModConfigData("alter") then
    modimport("postinit/epic/alterguardian")
end

if GetModConfigData("rook") then
    modimport("postinit/epic/minotaur")
end

if GetModConfigData("alterhat") then
    TUNING.noalterguardianhat2hm=true
    modimport("postinit/alterguardianhat")
end

if GetModConfigData("dragon_fire") then
    modimport("postinit/epic/dragonfly")
    modimport("postinit/dragonflyfurnace")
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
    modimport("postinit/ruins")
end

if GetModConfigData("gestalt") then
    modimport("postinit/gestalt")
end


modimport("postinit/dont_skip")
--modimport("other/playercharge.lua")


modimport("postinit/area_weapon")

---------------------------------------


modimport("postinit/amulet")
--modimport("postinit/winter_hunter")
modimport("postinit/lunarplant_staff")
modimport("postinit/planar_armor")
modimport("postinit/repair_material")
------------------------------------------
modimport("postinit/invade")
---------------------------------------------
--modimport("postinit/ocean/cannon")



modimport("postinit/components/cn_boatphysics")
--modimport("postinit/components/growable")


modimport("postinit/food")


modimport("postinit/epic/lunarthrall_plant")

modimport("postinit/anti_poison")



modimport("other/new_loot")
modimport("other/newstring.lua")

----------------------------------------------------
TUNING.SHIELDOFTERROR_ARMOR = 840

TUNING.MINOTAUR_HEALTH=12000
TUNING.EYEOFTERROR_HEALTH = 8000
TUNING.TOADSTOOL_HEALTH = 35000
TUNING.TOADSTOOL_DARK_HEALTH = 50000

----------------------------------------------------
--黑曜石科技
----------------------------------------------------
local _G = GLOBAL
local require = _G.require
local TechTree = require("techtree")
table.insert(TechTree.AVAILABLE_TECH, "OBSIDIAN")
TechTree.Create = function(t)
	t = t or {}
	for i, v in ipairs(TechTree.AVAILABLE_TECH) do
	    t[v] = t[v] or 0
	end
	return t
end

_G.TECH.NONE.OBSIDIAN = 0
_G.TECH.OBSIDIAN_ONE = { OBSIDIAN = 1 }
_G.TECH.OBSIDIAN_TWO = { OBSIDIAN = 2 }

for k,v in pairs(TUNING.PROTOTYPER_TREES) do
    v.OBSIDIAN = 0
end

TUNING.PROTOTYPER_TREES.OBSIDIAN_ONE = TechTree.Create({
    OBSIDIAN = 1,
})
TUNING.PROTOTYPER_TREES.OBSIDIAN_TWO = TechTree.Create({
     OBSIDIAN = 2,
 })

for i, v in pairs(_G.AllRecipes) do
    if v.level.OBSIDIAN == nil then
        v.level.OBSIDIAN = 0
    end
end

_G.RECIPETABS['OBSIDIANTAB'] = {str = "OBSIDIANTAB", sort=90, icon = "tab_volcano.tex", icon_atlas = "images/tabs.xml", crafting_station = true}
AddPrototyperDef("dragonflyfurnace", {action_str = "OBSIDIANTAB", icon_image = "tab_volcano.tex", icon_atlas = "images/tabs.xml", is_crafting_station = true})
AddPrototyperDef("lava_pond", {action_str = "OBSIDIANTAB", icon_image = "tab_volcano.tex", icon_atlas = "images/tabs.xml", is_crafting_station = true})
modimport("other/recipes_change")