GLOBAL.setmetatable(env, {__index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end})

require("map/tasks")
require("map/lockandkey")

local Layouts = require("map/layouts").Layouts
local StaticLayout = require("map/static_layout")




Layouts["WalledGarden2"]= StaticLayout.Get("map/static_layouts/walledgarden2",
		{
			areas =
			{
				plants = function(area) return PickSomeWithDups(0.3 * area, {"cave_fern", "lichen", "flower_cave", "flower_cave_double", "flower_cave_triple"}) end,
			},
			start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
			fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
			layout_position = LAYOUT_POSITION.CENTER
		})
Layouts["Barracks3"] = StaticLayout.Get("map/static_layouts/barracks_three",{
			start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
			fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
			layout_position = LAYOUT_POSITION.CENTER})

if GetModConfigData("ancient") then

    AddRoom("Metal_Labyrinth", {-- Not a real Labyrinth.. more of a maze really.
        colour={r=.25,g=.28,b=.25,a=.50},
        value = WORLD_TILES.BRICK,
        tags = {"Labyrinth", "Nightmare"},
        --internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeCentroid,
        contents =  {
            distributepercent = 0.2,
            distributeprefabs = {

                ruins_rubble_vase = 0.05,
                ruins_rubble_chair = 0.05,
                ruins_rubble_table = 0.05,

                chessjunk_spawner = 0.1,

                shadoweyeturret_spawner=0.04,
                scanner_spawn=0.06,
                bishop_nightmare_spawner = 0.1,
                knight_nightmare_spawner = 0.1,

                thulecite_pieces = 0.1,
            },
        }
    })

    AddRoom("HulkGuarden", {
        colour={r=0.3,g=0.2,b=0.1,a=0.3},
        value = WORLD_TILES.BRICK,
        tags = {"Nightmare"},
        required_prefabs = {},
        type = NODE_TYPE.Room,
        internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeSite,
        contents =  {
            countstaticlayouts = {
                ["WalledGarden2"] = 1,
            },
            countprefabs= {

                flower_cave = function () return 5 + math.random(3) end,
                chessjunk_spawner = function () return 4 + math.random(4) end
            }
        }
    })


    AddTask("MeTal_Labyrinth_Task", {
        locks={LOCKS.TIER3, LOCKS.RUINS},
        keys_given= {KEYS.TIER3, KEYS.RUINS},
        room_tags = {"Nightmare"},
        entrance_room="LabyrinthEntrance",
        room_choices={
            ["Metal_Labyrinth"] = function() return 1+math.random(2) end,
            ["HulkGuarden"] = 1,
        },
        room_bg=WORLD_TILES.IMPASSABLE,
        background_room="Metal_Labyrinth",
        colour={r=0.4,g=0.4,b=0.0,a=1},
    })
    --[[AddTaskPreInit("BigBatCave",function(task)
        task.room_choices={
        ["BatCave"] = 1,
        ["BattyCave"] = 1,
        ["FernyBatCave"] = 1,
        ["PitRoom"] = 1,
        }
    end)]]
    AddTaskSetPreInit("cave_default", function(task)
        table.insert(task.tasks, "MeTal_Labyrinth_Task")
    end)
    AddRoomPreInit("Barracks",function (room)
        room.contents.distributeprefabs.scanner_spawn=0.1
    end)
    AddRoomPreInit("BGSacred",function (room)
        room.contents.distributepercent = 0.05
        room.contents.distributeprefabs=
        {
            chessjunk_spawner = .3,

            nightmarelight = 1,

            pillar_ruins = 0.5,

            ruins_statue_head_spawner = .1,
            ruins_statue_head_nogem_spawner = .2,

            scanner_spawn=0.01,
            shadoweyeturret_spawner=0.02,
            shadowdragon_spawner=0.04,

            ruins_statue_mage_spawner =.1,
            ruins_statue_mage_nogem_spawner = .2,

            rook_nightmare_spawner = .07,
            bishop_nightmare_spawner = .07,
            knight_nightmare_spawner = .07,
        }
    end)
    AddRoomPreInit("Bishops",function(room)
        room.contents.countstaticlayouts={
            ["Barracks3"] = 1,
        }
    end)
    Layouts["MilitaryEntrance"].layout["shadowdragon_spawner"]={{x=-4,y=4}}
    Layouts["BrokenAltar"].layout["shadowdragon_spawner"]={{x=1,y=-4}}
    Layouts["SacredBarracks"].layout["scanner_spawn"]={{x=-3,y=0},{x=0,y=0}}
    Layouts["Barracks"].layout["scanner_spawn"]={{x=0,y=0}}
    Layouts["AltarRoom"].layout["shadoweyeturret_spawner"]={{x=0,y=4}}
    Layouts["AltarRoom"].layout["scanner_spawn"]={{x=2,y=2}}
end