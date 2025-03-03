AddTask("RUINS_TO_SHADOW", {
    locks={LOCKS.NONE},
    keys_given = {KEYS.ISLAND_TIER1},
    required_prefabs = {"abyss_rift"},
    entrance_room = "Rift_Abyss",
    region_id = "abyss",
    room_tags = {"Nightmare","RoadPoison","Abyss","notele"},
    room_choices={
        ["Guard_Abyss"] = 1,
        ["shadow_wild"] = 2,
        ["Infusedcity_Abyss"] = 1,
	    ["RuinedCity_Abyss"] = 1,
        --["RuinedAltar_Abyss"] = 1,
    },
    background_room = "BGAbyss1",
    --room_bg=WORLD_TILES.IMPASSABLE,
    room_bg = WORLD_TILES.BRICK,
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    level_set_piece_blocker = true
})

AddTask("Night_Land", {
    locks={ LOCKS.ISLAND_TIER1},
    keys_given = {KEYS.ISLAND_TIER2,KEYS.WILDS},
    region_id = "abyss",
    room_tags = {"Nightmare","Abyss","notele"},
    room_choices={
        ["Night_Land"] = 2,
    },
    background_room = "Blank",
    --room_bg=WORLD_TILES.IMPASSABLE,
    room_bg = WORLD_TILES.MUD,
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    level_set_piece_blocker = true
})


AddTask("MeTal_Labyrinth_Task", {
    locks={ LOCKS.ISLAND_TIER1},
    keys_given= {},
    room_tags = {"Nightmare","Abyss","RoadPoison","notele"},
    entrance_room = "Metal_LabyrinthEntrance",
    region_id = "abyss",
    room_choices={
        ["Metal_Labyrinth"] = function() return 3+math.random(3) end,
        ["HulkGuarden"] = 1,
    },
    room_bg = WORLD_TILES.IMPASSABLE,
    background_room = "Metal_Labyrinth",
    colour={r=0.4,g=0.4,b=0.0,a=1},
    level_set_piece_blocker = true
})



AddTask("Iron_Miner",{
    locks={ LOCKS.ISLAND_TIER2,LOCKS.WILDS},
    keys_given= {},
    required_prefabs = {"ancient_hulk_spawner"},
    room_tags = {"Nightmare","Abyss","RoadPoison","notele"},
    region_id = "abyss",
    room_choices={
        ["Mine_Iron"] = 3,
        ["GemLand"] = 1,
    },
    entrance_room = "DarkLand",
    background_room="Blank",
    room_bg = WORLD_TILES.ROCKY,
    --room_bg=WORLD_TILES.IMPASSABLE,
    hub_room = "GemLand",
    cove_room_name = "Mine_Iron",
    cove_room_chance = 0.5,
	cove_room_max_edges = 2,
    crosslink_factor = 2,
    colour={r=0.8,g=0.8,b=0.8,a=0.9},
    level_set_piece_blocker = true
})

AddTask("Hades",{
    locks={ LOCKS.ISLAND_TIER1},
    keys_given= {KEYS.ISLAND_TIER2,KEYS.SACRED},
    room_tags = {"Nightmare","Abyss","RoadPoison","notele"},
    region_id = "abyss",
    entrance_room = "MarshAbyss_Entrance",
    room_choices={
        ["EndsWell"] = 1,
        ["DarkLand"] = 1,
        ["Marsh_Abyss"] = 2,
    },
    hub_room = "EndsWell",
    background_room="BGHades",
    room_bg = WORLD_TILES.CAVE,
    colour={r=0.8,g=0.8,b=0.8,a=0.9},
    level_set_piece_blocker = true
})

AddTask("DarkGarden",{
    locks={ LOCKS.ISLAND_TIER2,LOCKS.SACRED},
    keys_given= {},
    room_tags = {"Nightmare","Abyss","RoadPoison","notele"},
    required_prefabs = {"cs_shadowthrone"},
    region_id = "abyss",
    entrance_room = "Abyss_Blocker",
    room_choices={
        ["QueenGarden"] = 1
    },
    background_room="Blank",
    --room_bg=WORLD_TILES.IMPASSABLE,
    colour={r=0.8,g=0.8,b=0.8,a=0.9},
    level_set_piece_blocker = true
})