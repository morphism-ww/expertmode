-------------------------------------------------------------
---加载资源
-------------------------------------------------------------
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

    Asset("SOUND","sound/calamita_sound_bank.fsb"),
    Asset("SOUNDPACKAGE","sound/calamita_sound.fev"),

    Asset("ATLAS", "images/inventoryimages/newcs_inventoryitems.xml"),
    Asset("IMAGE", "images/inventoryimages/newcs_inventoryitems.tex" ),
    Asset("ATLAS", "images/tabs.xml"),
    Asset("IMAGE", "images/tabs.tex" ),
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
    Asset("ATLAS", "images/fx4te.xml"),
    Asset("IMAGE", "images/fx4te.tex"),

    Asset("ANIM", "anim/sword_buster.zip"),
    Asset("ANIM", "anim/swap_sword_buster.zip"),

    Asset("ATLAS", "images/newcs_minimap.xml"),
    Asset("IMAGE", "images/newcs_minimap.tex"),

    Asset("ANIM", "anim/player_actions_roll.zip"),
    --Asset("ANIM", "anim/player_combo_wo.zip"),


    Asset("SHADER", "shaders/red_shader.ksh"),
    Asset("SHADER", "shaders/misc.ksh"),

    --Asset("SHADER", "shaders/blues.ksh"),
    Asset("SHADER", "shaders/auric.ksh"),
    --Asset("SHADER", "shaders/adamantitepulse.ksh"),
    --Asset("SHADER", "shaders/mirror.ksh"),
}



local function RegisterAtlas(atlas)
    local path = MODROOT..atlas
    local file = GLOBAL.io.open(path,"r")
    if file == nil then
        print("[API]: The atlas \"" .. atlas .. "\" cannot be opened.")
        return
    end
    local xml = file:read("*all")
    file:close()
    local images = xml:gmatch("<Element name=\"(.-)\"")
    for tex in images do
        RegisterInventoryItemAtlas(path, tex)
    end
end

----override image must has hash value!!!
local function RegisterOverrideImage(image,atlas)
    local path = atlas or "images/inventoryimages/newcs_inventoryitems.xml"
    RegisterInventoryItemAtlas(path, GLOBAL.hash(image))
end

RegisterAtlas("images/inventoryimages/cs_potions.xml")
RegisterAtlas("images/inventoryimages/newcs_inventoryitems.xml")

RegisterInventoryItemAtlas("images/inventoryimages/quaker.xml", "quaker.tex")

RegisterInventoryItemAtlas("images/inventoryimages/lunarlight.xml", "lunarlight.tex")

RegisterInventoryItemAtlas("images/inventoryimages/sword_ancient.xml", "sword_ancient.tex")

RegisterInventoryItemAtlas("images/inventoryimages/sword_constant.xml", "sword_constant.tex")

RegisterOverrideImage("laser_generator.tex")

AddMinimapAtlas("images/newcs_minimap.xml")
-----------------------------------------------------------------

AddReplicableComponent("statemeter")

-----------------------------------------------------------------
local locale = GLOBAL.LOC.GetLocaleCode()
if locale == "zh" or locale == "zht" or locale=="zhr" then
    require"languages.newstring.names"
    require"languages.newstring.recipes"
    require"languages.newstring.describes"
    require"languages.newstring.others"
else
    require"languages.newstring_en.names"
    require"languages.newstring_en.recipes"
    require"languages.newstring_en.describes"
    require"languages.newstring_en.others"
end    

-------------------------------------------

local my_name = GLOBAL.ModInfoname(modname)

function modimport_global(modulename)
    print("modimport [global]: "..MODROOT..modulename)
    modulename = modulename..".lua"
    local result = GLOBAL.kleiloadlua(MODROOT..modulename)
    if result == nil then
        GLOBAL.error("Error in modimport [global]: "..modulename.." not found!")
    elseif type(result) == "string" then
        GLOBAL.error("Error in modimport [global]: "..my_name.." importing "..modulename.."!\n"..result)
    else
        GLOBAL.setfenv(result, GLOBAL)
        result()
    end
end


require("newcs_constants")
require("newcs_tuning")
require("newcs_standardcomponents")
require("newcs_entitychange")

GLOBAL.newcs_env = env

modimport("init/containers")

--modimport("init/CES_API")
if not GLOBAL.TheNet:IsDedicated() then
    modimport("init/shader_init")
end

--------------------------------------------


-------------------------------------------
----注册实体
modimport("init/prefablist")

-----------------------------------------

modimport("init/actions")

modimport("init/player")

modimport("init/player_sg")

modimport("init/ui")

modimport_global("init/newloot")

modimport("init/recipes")

modimport_global("init/mod_rpc")
----------------------------------------

modimport("init/postinit")


modimport("init/debugmode")

GLOBAL.newcs_env = nil