local Layouts = require("map/layouts").Layouts
local StaticLayout = require("map/static_layout")

Layouts["Void_Land"] = StaticLayout.Get("map/static_layouts/void_land",{
    start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    layout_position = LAYOUT_POSITION.CENTER}) 

Layouts["MilitaryEntrance"].layout["shadowdragon_spawner"]={{x=-4,y=4}}
Layouts["BrokenAltar"].layout["shadowdragon_spawner"]={{x=1,y=-4}}
Layouts["SacredBarracks"].layout["scanner_spawn"]={{x=-3,y=0},{x=0,y=0}}
Layouts["Barracks"].layout["scanner_spawn"]={{x=0,y=0}}
Layouts["AltarRoom"].layout["shadoweyeturret_spawner"]={{x=0,y=3}}




Layouts["WalledGarden2"]= StaticLayout.Get("map/static_layouts/walledgarden2",
		{
			areas =
			{
				plants = {"chessjunk_spawner"},
			},
			start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
			fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
			layout_position = LAYOUT_POSITION.CENTER
		})
Layouts["Barracks3"] = StaticLayout.Get("map/static_layouts/barracks_three")
            
     
                
                
Layouts["ChessBlockerAB"] = StaticLayout.Get("map/static_layouts/chess_blocker_ab", {
    start_mask = PLACE_MASK.NORMAL,
    fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    layout_position = LAYOUT_POSITION.CENTER,            
})

Layouts["Abyss_Blocker"] = {
    type = LAYOUT.CIRCLE_EDGE,
    start_mask = PLACE_MASK.NORMAL,
    fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    layout_position = LAYOUT_POSITION.CENTER,
    ground_types = {WORLD_TILES.ROCKY},
    defs =
        {
            rocks = { "nightmaregrowth_abyss_spawner"},
        },
    count =
        {
            rocks = 8,
        },
    scale = 2,
}

Layouts["AltarRoom_ab"] = StaticLayout.Get("map/static_layouts/altar")
Layouts["BrokenAltar_ab"] = StaticLayout.Get("map/static_layouts/brokenaltar")
Layouts["SacredBarracks_ab"] = StaticLayout.Get("map/static_layouts/sacred_barracks")
Layouts["Barracks_ab"] = StaticLayout.Get("map/static_layouts/barracks")
Layouts["Blocker_Sab"] = StaticLayout.Get("map/static_layouts/blocker_sab")
Layouts["EndsWell"] = StaticLayout.Get("map/static_layouts/endswell")
Layouts["DarkGarden"] = {
    type = LAYOUT.CIRCLE_EDGE,
    start_mask = PLACE_MASK.NORMAL,
    fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    layout_position = LAYOUT_POSITION.CENTER,
    ground_types = {WORLD_TILES.CARPET2},
    ground =
        {
            {1, 1, 1, 1, 1},
            {1, 1, 1, 1, 1},
            {1, 1, 1, 1, 1},
            {1, 1, 1, 1, 1},
            {1, 1, 1, 1, 1},
        },
    layout =
        {
            cs_shadowthrone = 	{ {x=  0, y=  0} },
            dark_energy_spawner = {{x=  2, y=  2},{x=  -2, y=  -2}},
            sanityrock = {{x=1,y=1},{x=1,y=-1},{x=-1,y=1},{x=-1,y=-1}}
                        
        }, 
    count = {
            flower_rose = 15,
        },
    scale = 1, -- scale must be 1 if we set grount tiles
    --layout_position = LAYOUT_POSITION.CENTER
}