local params = require("containers").params

local Vector3 = GLOBAL.Vector3

params["armorabyss"] = {
    widget =
    {
        slotpos = {},
        animbank = "ui_piggyback_2x6",
        animbuild = "ui_piggyback_2x6",
        pos = Vector3(-5, -90, 0),
    },
    issidewidget = true,
    type = "pack",
    openlimit = 1,
}
for y = 0, 5 do
    table.insert(params.armorabyss.widget.slotpos, Vector3(-162, -75 * y + 170, 0))
    table.insert(params.armorabyss.widget.slotpos, Vector3(-162 + 75, -75 * y + 170, 0))
end
------------------------------------------------------

--[[params.armor_voidcloth =
{
    widget =
    {
        slotpos = {
            Vector3(0, 2, 0),
        },
        animbank = "ui_antlionhat_1x1",
        animbuild = "ui_antlionhat_1x1",
        pos = Vector3(53,40, 0),
    },
    type = "hand_inv",
    excludefromcrafting = true,
}

function params.armor_voidcloth.itemtestfn(container, item, slot)
    return item.prefab=="nightmarefuel"
end]]
-----------------------------------------------------------------------------------

if GetModConfigData("wardrobe") then
    local function CheckWardrobeItem(container, item, slot)
        return item:HasTag("_equippable")
    end
    
    
    params["wardrobe"] =
    {
        widget =
        {
            slotpos = {},
            animbank = "ui_fish_box_5x4",
            animbuild = "ui_fish_box_5x4",
            pos = Vector3(0, 220, 0),
            side_align_tip = 160,
        },
        type = "chest",
        itemtestfn = CheckWardrobeItem,
    }
    
    for y = 2.5, -0.5, -1 do
        for x = -1, 3 do
            table.insert(params.wardrobe.widget.slotpos, Vector3(75 * x - 75 * 2 + 75, 75 * y - 75 * 2 + 75, 0))
        end
    end
end


-----------------------------------------------------------------------------------
local function NoContainer(container, item, slot)
    return not (item:HasTag("irreplaceable") or item:HasTag("_container") or item:HasTag("bundle") or item:HasTag("nobundling"))
end

params["cs_void_bag"] = {
    widget =
    {
        slotpos = {},
        animbank = "ui_fish_box_5x4",
        animbuild = "ui_fish_box_5x4",
        pos = Vector3(0, 200, 0),
        side_align_tip = 160,
    },
    type = "chest",
    itemtestfn = NoContainer
}

for y = 2.5, -0.5, -1 do
    for x = -1, 3 do
        table.insert(params.cs_void_bag.widget.slotpos, Vector3(80 * x - 80 * 2 + 80, 80 * y - 80 * 2 + 80, 0))
    end
end


params["aurumite_kit"] = {
    widget =
    {   
        animbank = "ui_auric_2x2",
        animbuild = "ui_auric_2x2",
        slotpos =
        {
            Vector3(-37.5, 32 + 4, 0),
            Vector3(37.5, 32 + 4, 0),
            Vector3(-37.5, -(32 + 4), 0),
            Vector3(37.5, -(32 + 4), 0),
        },
        slotbg =
        {   
            
            { image = "inv_slot_dragonflyfurnace.tex", atlas = "images/hud2.xml" },
            { image = "inv_slot_dragonflyfurnace.tex", atlas = "images/hud2.xml" },
            { image = "inv_slot_dragonflyfurnace.tex", atlas = "images/hud2.xml" },
            { image = "inv_slot_dragonflyfurnace.tex", atlas = "images/hud2.xml" },
        },
        --animbank = "ui_bundle_2x2",
        --animbuild = "ui_bundle_2x2",
        pos = Vector3(0, 160, 0),
    },
    itemtestfn = function (container, item, slot)  return GLOBAL.MYTHICAL_REPAIR_MAP[item.prefab]~=nil end,
    type = "chest",
}

