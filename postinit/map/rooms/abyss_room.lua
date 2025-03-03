AddRoom("Abyss_Blocker",{
    colour={r=0.2,g=0.0,b=0.2,a=0.3},
    value = WORLD_TILES.IMPASSABLE,
    tags = {"RoadPoison","Nightmare","ForceConnected"},
    contents = {
        countstaticlayouts= {
            ["Abyss_Blocker"] = 1 ,
        }, 
        
    },
})

AddRoom("Rift_Abyss",{
    colour={r=.45,g=.75,b=.45,a=.50},
    value = WORLD_TILES.CAVE,
    tags = {"Nightmare"},
    internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeSite,
    contents = {
        countprefabs = {
            abyss_rift = 1,
            fissure_lower = 3,
        },
        distributepercent = .05,
        distributeprefabs=
        {

            nightmaregrowth_abyss = 0.3,

            thulecite_pieces = 0.05,

            flower_evil = 0.1,

        },
    }
})


AddRoom("DarkLand",{
    colour={r=.25,g=.28,b=.25,a=.50},
    value = WORLD_TILES.ABYSS_DARKNESS,
    contents =  {
        countprefabs = {
            gelblobspawning_worldgen = 1,
            dark_energy_spawner = 1,
            void_peghook_spawner = function ()
                return math.random(1,2)
            end
        },
        distributepercent = .1,
        distributeprefabs=
        {  
            
            nightmaregrowth_abyss = 0.02,
            
            pillar_stalactite = .04,

            stalagmite_med = 0.03,

            stalagmite_low = 0.03,

            hosted_spiderhole = 0.01,

            pillar_cave = 0.02,

        },
    }
})

AddRoom("Guard_Abyss", {
    colour={r=.25,g=.28,b=.25,a=.50},
    value = WORLD_TILES.BRICK,
    --internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeCentroid,
    --type = NODE_TYPE.Room,
    contents =  {
        countstaticlayouts = {
            ["ChessBlockerAB"] = 1
        },
    
        distributepercent = 0.1,
        distributeprefabs=
        {   
            nightmaregrowth_abyss = 0.03,

            chessjunk_spawner = 0.1,

            ruins_statue_mage_spawner =.05,

            abysslight = 0.2,

            pillar_ruins = 0.05,
        }
    },
})


AddRoom("shadow_wild",{
    colour={r=0.7,g=0.5,b=0.3,a=0.9},
    value = WORLD_TILES.CAVE,
    random_node_entrance_weight = 0,
    contents =  {
        countstaticlayouts =
        {
            ["CornerWall"] = 1,
            ["StraightWall"] = 1,
            ["CornerWall2"] = 1,
        },
        countprefabs = {
            shadowthrall_spawner = function() return math.random(2,3) end,
        },
        distributepercent = .1,
        distributeprefabs=
        {  
            
            abysslight = 0.04,

            spotty_shrub = 0.05,

            shadowdragon_spawner = 0.02,

            fissure_lower = 0.02,

            flower_evil = 0.01,

            pillar_stalactite = .05,

            pillar_cave = 0.02,
        },
    }
})



AddRoom("RuinedCity_Abyss", {
    colour={r=.25,g=.28,b=.25,a=.50},
    value = WORLD_TILES.BRICK,
    random_node_exit_weight = 1,
    --internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeCentroid,
    contents =  {
        countstaticlayouts = {
            ["Blocker_Sab"] = 1,
        },
        countprefabs = {
            --dark_energy_spawner = math.random(1,2),
            abyss_leak = 1,
        },
        distributepercent = 0.1,
        distributeprefabs=
        {
            chessjunk_spawner = 0.1,

            abysslight = 0.3,

            ruins_statue_mage_spawner =.1,

            shadowdragon_spawner = 0.01,

            spider_robot = 0.05,

            fissure = 0.02,

            nightmaregrowth_abyss = 0.15,
        }
    }
})

AddRoom("Infusedcity_Abyss", {
    colour={r=.25,g=.28,b=.25,a=.50},
    value = WORLD_TILES.BRICK,
    --internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeCentroid,
    --internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeCentroid,
    contents =  {
        distributepercent = 0.07,
        distributeprefabs=
        {
            chessjunk_spawner = 0.1,

            abysslight = 0.25,

            ruins_statue_mage_spawner = .1,

            abyss_hoplite_spawner = 0.05,

            scanner_spawn = 0.05,

            spider_robot = 0.05,

            shadowdragon_spawner = 0.1,

            nightmaregrowth_abyss = 0.1,
        }
    }
})


AddRoom("Night_Land",{
    value = WORLD_TILES.MARSH,
    tags = {"Mist"},
    --random_node_exit_weight = 0,
    contents = {
        distributepercent = .1,
        distributeprefabs=
        {
            shadowmouth_spawner = 0.2,

            ancienttree_nightvision = 0.4,

            flower_evil = 0.3,

            livingtree = 0.4,

            fissure_abyss = 0.2,

            fissure_lower = 0.02,
            fissure = 0.02,

            spotty_shrub = 0.3,

            wormlight_plant = 0.5,

        },
    }
})
--[[AddRoom("Worm_Land",{
    value = WORLD_TILES.MARSH,
    tags = {"Mist","Abyss","DarkLand"},
    random_node_entrance_weight = 0,
    contents = {
        countstaticlayouts = {
            ["Worm_Land"] = 1,
        },
        distributepercent = .1,
        distributeprefabs=
        {
            
            ancienttree_nightvision = 0.4,

            flower_evil = 0.3,

            fissure_abyss = 0.2,

            spotty_shrub = 0.3,

            wormlight_plant = 0.5,
        },
    }
})]]

AddRoom("BGAbyss1", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.BRICK,
    contents =  {
        countprefabs=
        {
            spider_robot = 1,
            shadowthrall_spawner = 1,
        },
        distributepercent = 0.05,
        distributeprefabs=
        {
            chessjunk_spawner = .3,

            abysslight = 04,

            pillar_ruins = 0.4,

            pillar_stalactite = 0.1,

            ruins_statue_head_spawner = .1,  

            ruins_statue_mage_spawner =.1,

            shadowdragon_spawner= 0.1,
        }
    }
})

AddRoom("Metal_LabyrinthEntrance", {
    colour={r=0.2,g=0.0,b=0.2,a=0.3},
    value = WORLD_TILES.MUD,
    tags = {"ForceConnected", "LabyrinthEntrance", "Abyss"},--"Labyrinth",
    contents =  {
        distributepercent = .1,
        distributeprefabs=
        {
            
            flower_evil = 0.5,
            
            cave_fern = 1,

            pillar_cave = .05,

            chessjunk_spawner = .2,

            fissure = 0.05,
            
            wall_ruins = .05,
        },
    }
})

AddRoom("Metal_Labyrinth", {-- Not a real Labyrinth.. more of a maze really.
        colour={r=.25,g=.28,b=.25,a=.50},
        value = WORLD_TILES.BRICK,
        tags = {"Labyrinth", "Nightmare","Abyss"},
        internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeCentroid,
        contents =  {
            countprefabs = {
                gelblobspawning_worldgen = 1,
            },
            distributepercent = 0.15,
            distributeprefabs = {
                thulecite_pieces = 0.01,

                gears = 0.02,

                chessjunk_spawner = 0.05,

                shadoweyeturret2_spawner = 0.02,

                scanner_spawn = 0.03,

                bishop_nightmare_spawner = 0.05,
                knight_nightmare_spawner = 0.05,
               
                maze_key = 0.02,

                abysslight = 0.04,
            },
        }
})

AddRoom("HulkGuarden", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.BRICK,
    --type = NODE_TYPE.Room,
    internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeSite ,
    contents =  {
        countstaticlayouts = {
            ["WalledGarden2"] = 1,
        },
        countprefabs= {
            chessjunk_spawner = function () return 4 + math.random(2) end,
            thulecite = function () return 4+math.random(2) end
        }
    }
})


AddRoom("MarshAbyss_Entrance", {
    colour={r=.45,g=.75,b=.45,a=.50},
    value = WORLD_TILES.MARSH,
    
    contents = {
        countprefabs = {
            abyss_knight_spawner = 1,
        },
        
        distributepercent = .08,
        distributeprefabs=
        {
            flower_evil = 0.4,

            spotty_shrub = 0.3,

            nightmaregrowth_abyss = 0.2,

            ancienttree_nightvision = 0.4,

            fissure_abyss = 0.4,

            fissure_lower = 0.1,

            shadowthrall_spawner = 0.2,
        },
    }
})


AddRoom("Marsh_Abyss", {
    colour={r=.45,g=.75,b=.45,a=.50},
    value = WORLD_TILES.MARSH,

    
    contents = {
        countprefabs = {
            abyss_knight_spawner = function () return math.random(1,2) end,
            
           -- mist_spawner = 1,
        },
        
        distributepercent = .1,
        distributeprefabs=
        {
            flower_evil = 0.4,

            spotty_shrub = 0.3,

            ancienttree_nightvision = 0.5,

            fissure_abyss = 0.6,

            fissure_lower = 0.1,

            abyss_flower_spawner_worldgen = 0.2,

            shadowthrall_spawner = 0.2,
        },
    }
})



AddRoom("EndsWell",{
    colour={r=.45,g=.75,b=.45,a=.50},
    value = WORLD_TILES.MARSH,
    internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeSite,
    --random_node_entrance_weight = 0,

    contents = {
        countprefabs = {
            shadowmouth_spawner = 1,
        },
        countstaticlayouts =
        {
            ["EndsWell"] = 1,
        },
        distributepercent = .1,
        distributeprefabs=
        {
            flower_evil = 0.5,

            abyss_hoplite_spawner = 0.5,

            ancienttree_nightvision = 1,

            fissure_abyss = 1.5,

            abyss_flower_spawner = 0.2
        },
    }
})


AddRoom("Mine_Iron", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.ROCKY,

    type = NODE_TYPE.Room,
    contents =  {
        countprefabs = {
            abyss_knight_spawner = function() return math.random(0,1) end,
            gelblobspawning_worldgen = 1,
        },
        distributepercent = .1,
        distributeprefabs=
        {
            nightmaregrowth_abyss = 0.1,

            fissure_abyss = 0.02,

            aurumite_mine = 0.04,

            pillar_cave_rock = 0.07,

            abyss_hoplite_spawner = 0.01,
            
            ancienttree_gem = 0.02,

            shadowmouth_spawner = 0.02,

            pillar_stalactite = 0.05,

            spider_robot = 0.02
        }
    }
})
AddRoom("GemLand", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.ROCKY,

    type = NODE_TYPE.Room,
    contents =  {
        countprefabs = {
            abyss_thrall_spawner = 1,
            abyss_leak = 1,
           -- mist_spawner = 1,
        },
        distributepercent = .07,
        distributeprefabs=
        {
            nightmaregrowth_abyss = 0.1,

            ancienttree_gem = 0.1,

            fissure_abyss = 0.03,

            pillar_cave_rock = 0.1,
        }
    }
})
AddRoom("BGHades", {
    colour={r=.45,g=.75,b=.45,a=.50},
    value = WORLD_TILES.MARSH,

    contents = {
        countprefabs = {
            abyss_knight_spawner = 1,
        },
        distributepercent = .05,
        distributeprefabs =
        {
           
            fissure_abyss = 0.2,

            spotty_shrub = 0.2,

            nightmaregrowth_abyss = 0.05,

            shadowdragon_spawner = 0.05,

            shadowthrall_spawner = 0.02,
        },
    }
})

AddRoom("QueenGarden", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.IMPASSABLE,
    contents =  {
        countstaticlayouts =
        {
            ["DarkGarden"] = 1,
        },
    }
})