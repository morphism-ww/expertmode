AddRoomPreInit("Barracks",function (room)
    --[[room.contents.countprefabs=
    {
        spider_robot= 1
    }]]
    --room.random_node_entrance_weight = 0
    --room.internal_type = nil
end)

AddRoomPreInit("MilitaryMaze",function (room)
    --room.internal_type = nil
end)

AddRoomPreInit("SacredBarracks",function (room)
    room.value = WORLD_TILES.TILES
    room.contents.distributepercent = 0.05
    room.contents.distributeprefabs=
    {
        chessjunk_spawner = .1,

        ruins_statue_head_spawner = .2,

        ruins_statue_mage_spawner =.2,

        shadowdragon_spawner = .05,

        knight_nightmare_spawner = .05,

        scanner_spawn = 0.1,
    }
end)

AddRoomPreInit("Altar",function (room)
    room.value = WORLD_TILES.TILES
    room.contents.distributepercent = 0.05
    room.contents.distributeprefabs=
    {
        chessjunk_spawner = .1,

        ruins_statue_head_spawner = .2,

        ruins_statue_mage_spawner =.2,

        knight_nightmare_spawner = .05,

        scanner_spawn = 0.1,
    }
end)

AddRoomPreInit("BrokenAltar",function (room)
    room.value = WORLD_TILES.TILES
    --room.internal_type = nil
    room.contents =  {
        countstaticlayouts =
        {   
            ["Barracks3"] = 1,
            ["BrokenAltar_ab"] = 1,
        },
    }
    room.contents.distributepercent = 0.05
    room.contents.distributeprefabs=
    {
        chessjunk_spawner = .1,

        ruins_statue_head_spawner = .2,

        ruins_statue_mage_spawner =.2,

        shadoweyeturret2_spawner = 0.02,

        knight_nightmare_spawner = .05,
        scanner_spawn = 0.04,
    }
end)


AddRoom("BrokenAltar2", {
    colour={r=.25,g=.28,b=.25,a=.50},
    value = WORLD_TILES.BRICK,
    tags = {"Nightmare"},
    --internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeCentroid,
    contents =  {
        countprefabs=
        {
            spider_robot= function() return math.random() < 0.25 and 2 or 1 end,
        },
        countstaticlayouts = {
            ["AltarRoom_ab"] = 1,
        },
        distributepercent = 0.2,
        distributeprefabs=
        {
            chessjunk_spawner = .3,

            nightmarelight = 0.5,

            shadoweyeturret2_spawner = 0.05,

            rook_nightmare_spawner = .03,
            bishop_nightmare_spawner = .03,
            knight_nightmare_spawner = .03,
            
        }
    }
})

AddRoom("SacredDanger2", {
    colour={r=.25,g=.28,b=.25,a=.50},
    value = WORLD_TILES.BRICK,
    tags = {"Nightmare"},
    internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeCentroid,
    contents =  {
        countprefabs=
        {
            spider_robot= 1
        },
        countstaticlayouts = {
            ["SacredBarracks_ab"] = 1,
        },
        distributepercent = 0.1,
        distributeprefabs=
        {
            chessjunk_spawner = .3,

            scanner_spawn = 0.05,

            ruins_statue_head_spawner = .15,
            ruins_statue_mage_spawner =.15,
            
            shadowdragon_spawner = 0.05,
        }
    }
})