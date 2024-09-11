AddRoomPreInit("Barracks",function (room)
    room.contents.countprefabs=
    {
        spider_robot= 1
    }
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

--[[AddRoom("LabyrinthEntrance", {
    colour={r=0.2,g=0.0,b=0.2,a=0.3},
    value = WORLD_TILES.MUD,
    tags = {"ForceConnected",  "LabyrinthEntrance", "Nightmare"},--"Labyrinth",
    contents =  {
        countprefabs=
        {
            spider_robot= 1
        },
        distributepercent = .2,
        distributeprefabs=
        {
            lichen = .8,
            cave_fern = 1,
            pillar_algae = .05,

            flower_cave = .2,
            flower_cave_double = .1,
            flower_cave_triple = .05,
        },
    }
})]]


