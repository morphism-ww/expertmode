GLOBAL.setfenv(1, GLOBAL)
local params = require("containers").params
local packdata={
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
    table.insert(packdata.widget.slotpos, Vector3(-162, -75 * y + 170, 0))
    table.insert(packdata.widget.slotpos, Vector3(-162 + 75, -75 * y + 170, 0))
end
params['armorvortexcloak']=packdata

------------------------------------------------------

params.armor_voidcloth =
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
end


--[[params["wardrobe"] =
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
}

for y = 2.5, -0.5, -1 do
    for x = -1, 3 do
        table.insert(params.wardrobe.widget.slotpos, Vector3(75 * x - 75 * 2 + 75, 75 * y - 75 * 2 + 75, 0))
    end
end

function params.wardrobe.itemtestfn(container, item, slot)
    return item.replica.equippable~=nil and 
    (item.replica.equippable:EquipSlot()=="body" or item.replica.equippable:EquipSlot()=="head")
end]]