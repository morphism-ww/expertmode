GLOBAL.setmetatable(env, {__index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end})


Assets = 
{
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
    Asset("SOUND","sound/abyss_sound_bank.fsb"),
    Asset("SOUNDPACKAGE","sound/abyss_sound.fev"),
    
    Asset("ATLAS", "images/inventoryimages/volcanoinventory.xml"),
    Asset("IMAGE", "images/inventoryimages/volcanoinventory.tex" ),
    Asset("ATLAS", "images/inventoryimages/newconstant_inventoryitems.xml"),
    Asset("IMAGE", "images/inventoryimages/newconstant_inventoryitems.tex" ),
    Asset("ATLAS", "images/tabs.xml"),
    Asset("IMAGE", "images/tabs.tex" ),
    Asset("IMAGE","images/inventoryimages/obsidian_hat.tex"),
    Asset("ATLAS","images/inventoryimages/obsidian_hat.xml"),
    Asset("IMAGE","images/inventoryimages/quaker.tex"),
    Asset("ATLAS","images/inventoryimages/quaker.xml"),
    Asset("IMAGE","images/inventoryimages/lunarlight.tex"),
    Asset("ATLAS","images/inventoryimages/lunarlight.xml"),
    Asset("IMAGE","images/inventoryimages/sword_ancient.tex"),
    Asset("ATLAS","images/inventoryimages/sword_ancient.xml"),
    Asset("IMAGE","images/inventoryimages/sword_constant.tex"),
    Asset("ATLAS","images/inventoryimages/sword_constant.xml"),
    Asset("IMAGE","images/inventoryimages/cs_potions.tex"),
    Asset("ATLAS","images/inventoryimages/cs_potions.xml"),
    Asset("IMAGE","images/inventoryimages/apocalypse-of-the-constant.tex"),
    Asset("ATLAS","images/inventoryimages/apocalypse-of-the-constant.xml"),
    Asset("ATLAS", "images/fx4te.xml"),
    Asset("IMAGE", "images/fx4te.tex"),

    Asset("ANIM", "anim/sword_buster.zip"),
    Asset("ANIM", "anim/swap_sword_buster.zip"),


    Asset("ANIM", "anim/player_actions_roll.zip"),
    Asset("SHADER", "shaders/red_shader.ksh"),
    Asset("SOUNDPACKAGE", "sound/calamita.fev"), 
    Asset("SOUND", "sound/calamita_bank.fsb")
}



local function ProcessAtlas(atlas)
    local path = GLOBAL.softresolvefilepath(atlas)
    if path == nil then
        print("[API]: The atlas \"" .. atlas .. "\" cannot be found.")
        return
    end
    local success, file = pcall(io.open, path)
    if not success or file == nil then
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

ProcessAtlas("images/inventoryimages/volcanoinventory.xml")
ProcessAtlas("images/inventoryimages/cs_potions.xml")
ProcessAtlas("images/inventoryimages/apocalypse-of-the-constant.xml")
ProcessAtlas("images/inventoryimages/newconstant_inventoryitems.xml")


RegisterInventoryItemAtlas("images/inventoryimages/quaker.xml", "quaker.tex")

RegisterInventoryItemAtlas("images/inventoryimages/lunarlight.xml", "lunarlight.tex")

RegisterInventoryItemAtlas("images/inventoryimages/obsidian_hat.xml", "obsidian_hat.tex")

RegisterInventoryItemAtlas("images/inventoryimages/sword_ancient.xml", "sword_ancient.tex")

RegisterInventoryItemAtlas("images/inventoryimages/sword_constant.xml", "sword_constant.tex")


AddMinimapAtlas("images/inventoryimages/armorvortexcloak.xml")
AddMinimapAtlas("images/brightshade_queen.xml")
AddMinimapAtlas("images/inventoryimages/cs_void_bag.xml")

AddReplicableComponent("debuffable")


modimport("init/init_constants")
modimport("init/newconstant_tuning")
modimport("init/containers")

require("cs_standardcomponents")

require("cs_entitychange")


modimport("init/actions")

modimport("init/player")
modimport("init/player_sg")
modimport("init/ui")

if LOC.GetLocaleCode() == "zh" then
    modimport("init/newstring.lua")
else
    modimport("init/newstring_en.lua")
end    



modimport("init/newloot")

modimport("init/prefablist")


--"dreadsword","nightmare_hat","dread_cloak","knightmare","sword_constant","cs_shadow_queen","lavaarena_heavyblade","them_shadow",
if GetModConfigData("pig") then
    modimport("postinit/epic/daywalker")
end

if GetModConfigData("twin") then
    modimport("postinit/epic/eyeofterror")
    modimport("postinit/epic/twinofterror")
end

if GetModConfigData("alter") then
    modimport("postinit/epic/alterguardian")
end

if GetModConfigData("rook") then
    modimport("postinit/epic/minotaur")
end

if GetModConfigData("dragon_fire") then
    TUNING.FIRERAIN_ENABLE = true
    modimport("postinit/epic/dragonfly")
end

if GetModConfigData("klaus") then
    modimport("postinit/epic/klaus")
end

if GetModConfigData("stalker") then
    modimport("postinit/epic/stalker")
end

if GetModConfigData("poison") then
    modimport("postinit/epic/beequeen")
    modimport("postinit/epic/toadstool")
    modimport("postinit/mushroom_hat")
    modimport("postinit/poison_creature")
end

if GetModConfigData("ruins") then
    modimport("postinit/shadowmachine")
end

if GetModConfigData("gestalt") then
    TUNING.ALLOW_LUNAR_QUEEN = true
    TUNING.ALLOW_GESTALT_GUARD = true
    modimport("postinit/gestalt")
end


if GetModConfigData("chess") then
    modimport("postinit/epic/shadowchess")
end

if GetModConfigData("wardrobe") then
    modimport("postinit/wardrobe")
end


modimport("postinit/town_portal")


--装备
modimport("postinit/ruins_equip")
modimport("postinit/normal_weapons")
modimport("postinit/amulet")
modimport("postinit/lunar_equip")
modimport("postinit/planar_armor")

--霸体护甲
modimport("postinit/nostun_armor")

--材料
modimport("postinit/fuel")
modimport("postinit/repairable")
-----------------------------------
---
--深渊补充机制
modimport("postinit/abyss_makedark")

modimport("postinit/ironlord_spawner")

--暗影位面生物
modimport("postinit/epic/shadowthrall")

--迷宫箱子
modimport("postinit/scenario_change")

--龙鳞火炉
modimport("postinit/dragonflyfurnace")


--抗击飞
modimport("postinit/anti_knockback")


--愚蠢,非常愚蠢！
modimport("postinit/stupid_stuff")

--月亮相关的位面前装备


modimport("postinit/components/klausloot") --klaussackloot,stewer
modimport("postinit/components/meteorshower")
modimport("postinit/components/explosive")  --explosive,health

if GetModConfigData("damagemultiplier") then
    DAMAGEMULTIPLIER_CHANGE = true
end    
modimport("postinit/components/truedamage_system") --inventory
modimport("postinit/components/cn_boatphysics")
modimport("postinit/components/components_change1") --freezable,burnable,debuffable,rooted


modimport("postinit/epic/deerclops")

modimport('postinit/epic/mutated_bosses')
---------------------------------------

-------

--世界组件
modimport("postinit/worldchange")
---------------------------------------------

--modimport("postinit/components/growable")
--modimport("postinit/components/ambientlighting")

--食物
modimport("postinit/food")


modimport("postinit/epic/lunarthrall_plant")


modimport("postinit/anti_debuffs")


modimport("postinit/farming")


modimport("postinit/legion_medal")

--modimport("postinit/ranged_weapon")
--modimport("postinit/punchingbag")

------------bossrush-----------------
modimport("postinit/bossrush/entrance")
modimport("postinit/bossrush/bossrush_protect")

-------------------------------------
modimport("init/recipes")


modimport("init/debugmode")

----------------------------------------------------
Popups = require("GUI/popups")

-- GLOBALS
local server_name = TheNet:GetServerName()
local welcome_message = [[
在正式开始前请仔细查看mod设置
注意洞穴开巨大，地表不开巨大
]]	


local has_selected_character = false
local first_time_on_server = true


local function ShowWelcomeMessage(player)

	if not first_time_on_server then
		
		return
	end
	
	first_time_on_server = false
	
	if not has_selected_character then
		
		return
	end
    local main = function()
    local body = welcome_message
        
        Popups.CreateChoicePopup(server_name,body,nil,nil,"original","big","light")
    end
    player:DoTaskInTime(0.5, function() main() end)
end


-- There is definitely a simpler way to detect if this is the first time the player spawns
-- but for now we will just assume that first_time_on_server = first_spawn and has_selected_character
local function ListenForNewcomers(inst)
    inst:ListenForEvent("entercharacterselect", 
	function()
		has_selected_character = true
		inst:RemoveEventCallback("entercharacterselect", ListenForNewcomers)
	end)
end
--if not TheNet:GetIsMasterSimulation() then
AddPrefabPostInit("world", ListenForNewcomers)


AddPlayerPostInit(ShowWelcomeMessage)