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
            ["Barracks_ab"] = 1,
        },
        distributepercent = 0.1,
        distributeprefabs=
        {
            chessjunk_spawner = .3,
            ruins_statue_head_spawner = .1,
            ruins_statue_mage_spawner =.1,
            
            shadowdragon_spawner = 0.02,
        }
    }
})

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
            ["BrokenAltar_ab"] = 1,
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
-----------------------------Abyss----------------------

AddRoom("AbyssEntrance",{
    colour={r=0.2,g=0.0,b=0.2,a=0.3},
    value = WORLD_TILES.IMPASSABLE,
    tags = {"RoadPoison","Nightmare"},
    contents = {
        countstaticlayouts= {
            ["Abyss_Blocker"] = 1 ,
        }, 
        
    },
})


AddRoom("shadow_wild",{
    colour={r=0.7,g=0.5,b=0.3,a=0.9},
    value = WORLD_TILES.CAVE,
    tags = {"Nightmare","Abyss","DarkLand"},
    contents =  {
        countstaticlayouts =
        {
            ["CornerWall"] = 1,
            ["StraightWall"] =1,
            ["CornerWall2"] = function() return math.random(1,2) end,
            ["StraightWall2"] = function() return math.random(1,2) end,
        },
        distributepercent = .1,
        distributeprefabs=
        {  
            nightmaregrowth_abyss = 0.15,

            abysslight = 0.05,

            fissure_abyss = 0.01,
            
            ruins_statue_head_spawner = .1,
            ruins_statue_mage_spawner =.1,

            shadowthrall_horns_spawner = 0.04,
            shadowthrall_wings_spawner = 0.04,
            shadowthrall_hands_spawner = 0.04,

            shadowdragon_spawner = 0.02,

            pillar_ruins = 0.02

        },
    }
})

AddRoom("Abyss_Frontline", {
    colour={r=.25,g=.28,b=.25,a=.50},
    value = WORLD_TILES.BRICK,
    tags = {"Nightmare","Abyss","DarkLand"},
    internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeCentroid,
    contents =  {
        countstaticlayouts = {
            ["ChessBlockerAB"] = 1
        },
    },
    distributepercent = 0.05,
        distributeprefabs=
        {   
            nightmaregrowth_abyss = 0.03,

            chessjunk_spawner = 0.1,

            ruins_statue_mage_spawner =.05,

            abysslight = 0.2,

            shadowdragon_spawner = 0.04,

            pillar_ruins = 0.05,
        }
})

AddRoom("RuinedCity_Abyss", {
    colour={r=.25,g=.28,b=.25,a=.50},
    value = WORLD_TILES.BRICK,
    tags = {"Nightmare","Abyss","DarkLand"},
    --internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeCentroid,
    contents =  {
        countprefabs=
        {
            spider_robot= 2,
        },
        countstaticlayouts = {
            ["Blocker_Sab"] = 1,
        },
        distributepercent = 0.05,
        distributeprefabs=
        {
            chessjunk_spawner = 0.1,

            ruins_statue_mage_spawner =.05,

            abysslight = 0.3,

            rook_nightmare_spawner = .1,
            bishop_nightmare_spawner = .1,
            knight_nightmare_spawner = .1,
            shadowdragon_spawner = 0.1,

            pillar_ruins = 0.05,
        }
    }
})



AddRoom("BGAbyss1", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.BRICK,
    tags = {"Nightmare","Abyss","DarkLand"},
    contents =  {
        countprefabs=
        {
            spider_robot = 1,
        },
        distributepercent = 0.05,
        distributeprefabs=
        {
            chessjunk_spawner = .3,

            abysslight = 1,

            pillar_ruins = 0.5,

            ruins_statue_head_spawner = .1,  

            ruins_statue_mage_spawner =.1,

            shadowdragon_spawner= 0.1,
        }
    }
})

AddRoom("Metal_Labyrinth", {-- Not a real Labyrinth.. more of a maze really.
        colour={r=.25,g=.28,b=.25,a=.50},
        value = WORLD_TILES.BRICK,
        tags = {"Labyrinth", "Nightmare","Abyss"},
        internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeCentroid,
        contents =  {
            distributepercent = 0.1,
            distributeprefabs = {

                chessjunk_spawner = 0.08,

                shadoweyeturret_spawner = 0.02,
                shadoweyeturret2_spawner = 0.02,

                scanner_spawn = 0.03,

                bishop_nightmare_spawner = 0.05,
                knight_nightmare_spawner = 0.05,
                rook_nightmare_spawner = 0.05,

                maze_key = 0.03,

                abysslight = 0.03,
            },
        }
})

AddRoom("HulkGuarden", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.BRICK,
    tags = {"Nightmare","Abyss","DarkLand"},
    type = NODE_TYPE.Room,
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

AddRoom("Marsh_Abyss", {
    colour={r=.45,g=.75,b=.45,a=.50},
    value = WORLD_TILES.MARSH,
    tags = {"Nightmare","Abyss","DarkLand"},
    
    contents = {
        countprefabs = {
            abyss_knight_spawner = 1,
            mist_spawner = math.random(0,1),
        },
        
        distributepercent = .1,
        distributeprefabs=
        {
            livingtree = 0.5,

            ancienttree_nightvision = 0.5,

            fissure_abyss = 0.7,

            abyss_flower_spawner = 0.3,
            
            shadowthrall_horns_spawner = 0.3,
            shadowthrall_wings_spawner = 0.3,
            shadowthrall_hands_spawner = 0.3,
        },
    }
})

AddRoom("EndsWell",{
    colour={r=.45,g=.75,b=.45,a=.50},
    value = WORLD_TILES.MARSH,
    internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeCentroid,
    tags = {"Nightmare","Abyss","DarkLand"},
    contents = {
        countprefabs = {
            abyss_knight_spawner = 1,
            mist_spawner = 1,
        },
        countstaticlayouts =
        {
            ["EndsWell"] = 1,
        },
        distributepercent = .05,
        distributeprefabs=
        {
            livingtree = 1,

            ancienttree_nightvision = 1,

            fissure_abyss = 2,

            abyss_flower_spawner = 0.5
        },
    }
})


AddRoom("Mine_Iron", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.ROCKY,
    tags = {"Nightmare","Abyss","DarkLand"},
    type = NODE_TYPE.Room,
    contents =  {
        countprefabs = {
            abyss_knight_spawner = 1,
            mist_spawner = 1,
        },
        distributepercent = .1,
        distributeprefabs=
        {
            nightmaregrowth_abyss = 0.1,

            fissure_abyss = 0.03,

            iron_mine = 0.04,

            pillar_cave_rock = 0.1,
            
            ancienttree_gem = 0.02,
        }
    }
})
AddRoom("GemLand", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.ROCKY,
    tags = {"Nightmare","Abyss","DarkLand"},
    type = NODE_TYPE.Room,
    contents =  {
        countprefabs = {
            abyss_thrall_spawner = 1,
            
            mist_spawner = 1,
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
    tags = {"Nightmare","Abyss","DarkLand"},
    contents = {
        countprefabs = {
            abyss_knight_spawner = 1,
            mist_spawner = 1,
        },
        distributepercent = .06,
        distributeprefabs =
        {
            livingtree = 0.05,

            fissure_abyss = 0.2,

            nightmaregrowth_abyss = 0.05,

            shadowdragon_spawner = 0.05,
        },
    }
})

AddRoom("QueenGarden", {
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    value = WORLD_TILES.IMPASSABLE,
    tags = {"Nightmare","Abyss","DarkLand"},
    --required_prefabs = {"cs_shadowthrone"},
    internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeSite,
    contents =  {
        countstaticlayouts =
        {
            ["DarkGarden"] = 1,
        },
    }
})