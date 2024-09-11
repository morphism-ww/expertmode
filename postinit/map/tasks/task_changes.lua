for i=1,10 do
    AddTaskPreInit("CaveExitTask"..i, function (task)
        task.background_room = "Blank"
    end)
end

AddTaskPreInit("BigBatCave",function (task)
    task.room_choices={
        ["BatCave"] = 1 ,
        ["BattyCave"] = 1,
        ["FernyBatCave"] = 1,
    }
end)
AddTaskPreInit("MudWorld",function (task)
    task.locks={ LOCKS.TIER1 }
    task.keys_given={ KEYS.CAVE, KEYS.TIER2 }
    task.room_choices={
        ["LightPlantField"] = 1,
        ["WormPlantField"] = 2,
        ["FernGully"] = 1,
        ["SlurtlePlains"] = 2,
        ["MudWithRabbit"] = 1,
    }
end)
AddTaskPreInit("MudCave",function (task)
    task.locks={LOCKS.TIER1 }
    task.keys_given={ KEYS.CAVE, KEYS.TIER2 }
    task.room_choices={
        ["WormPlantField"] = 1,
        ["MudWithRabbit"] = 1,
    }
end)
AddTaskPreInit("MudLights",function (task)
    task.locks={ LOCKS.CAVE, LOCKS.TIER2 }
    task.keys_given={ KEYS.CAVE, KEYS.TIER3 }
    task.room_choices={
        ["LightPlantField"] = 1,
        ["WormPlantField"] = 1,
        ["PitRoom"] = 1,
    }
end)
AddTaskPreInit("MudPit",function (task)
    task.locks={ LOCKS.CAVE, LOCKS.TIER2 }
    task.keys_given={ KEYS.CAVE, KEYS.TIER3 }
    task.room_choices={
        ["SlurtlePlains"] = 1,
        ["PitRoom"] = 1,
    }
end)


AddTaskPreInit("BigBatCave",function (task)
    task.locks={ LOCKS.CAVE, LOCKS.TIER3 }
    task.keys_given={ KEYS.CAVE, KEYS.TIER4, KEYS.BATS }
    task.room_choices={
        ["BatCave"] = 2,
        ["BattyCave"] = 1,
        ["FernyBatCave"] = 2,
        ["PitRoom"] = 2,
    }
end)

AddTaskPreInit("RockyLand",function (task)
    task.locks={ LOCKS.CAVE, LOCKS.TIER3 }
    task.keys_given={ KEYS.CAVE, KEYS.TIER4, KEYS.ROCKY }
    task.room_choices={
        ["SlurtleCanyon"] = 1,
        ["BatsAndSlurtles"] = 1,
        ["RockyPlains"] = 1,
        ["RockyHatchingGrounds"] = 1,
        ["BatsAndRocky"] = 1,
    }
end)

AddTaskPreInit("RedForest",function (task)
    task.locks={ LOCKS.CAVE, LOCKS.TIER3 }
    task.keys_given={ KEYS.CAVE, KEYS.TIER4, KEYS.RED, KEYS.ENTRANCE_INNER }
    task.room_choices={
        ["RedMushForest"] = 1,
        ["RedSpiderForest"] = 1,
        ["RedMushPillars"] = 1,
        ["StalagmiteForest"] = 1,
        ["SpillagmiteMeadow"] = 1,
    }
end)

AddTaskPreInit("GreenForest",function (task)
    task.locks={ LOCKS.CAVE, LOCKS.TIER3 }
    task.keys_given={ KEYS.CAVE, KEYS.TIER4, KEYS.GREEN, KEYS.ENTRANCE_INNER }
    --[[task.room_choices={
        ["GreenMushForest"] = 2,
        ["GreenMushPonds"] = 1,
        ["GreenMushSinkhole"] = 1,
        ["RabbitCity"] = 1,
        ["GreenMushNoise"] = 1,
    }]]
    task.room_choices.PitRoom = nil
    task.room_choices.GreenMushForest = 1
    task.background_room = "Blank"
end)

AddTaskPreInit("BlueForest",function (task)
    task.locks={ LOCKS.CAVE, LOCKS.TIER3 }
    task.keys_given={ KEYS.TIER4, KEYS.MOONMUSH, KEYS.ENTRANCE_INNER }
    task.room_choices={
        ["BlueMushForest"] = 1,
        ["BlueSpiderForest"] = 1,
        ["DropperDesolation"] = 1,
        ["BlueMushMeadow"] = 1,
    }
    --task.entrance_room = {"BlueMushMeadow"}
end)
AddTaskPreInit("SpillagmiteCaverns",function (task)
    task.locks={ LOCKS.CAVE, LOCKS.TIER3 }
    task.keys_given={ KEYS.CAVE, KEYS.TIER4 }
    task.room_choices={
        ["SpillagmiteForest"] = 1,
        ["DropperCanyon"] = 2,
        ["StalagmitesAndLights"] = 1,
        ["ThuleciteDebris"] = 1,
    }
end)


-------------------------------------------
AddTaskPreInit("LichenLand", function (task)
    task.locks={LOCKS.NONE}
    task.keys_given= {KEYS.TIER1, KEYS.RUINS}
    task.room_tags = {"Nightmare"}
    task.room_choices={
        ["WetWilds"] = function() return math.random(1,2) end,
        ["LichenMeadow"] = function() return math.random(1,2) end,
        ["LichenLand"] = 2,
    }
    task.hub_room = "LichenLand"
    task.room_bg=WORLD_TILES.MUD
    task.background_room="BGWilds"
    task.colour={r=0,g=0,b=0.0,a=1}
end)
AddTaskPreInit("Residential",function(task)
    task.locks={LOCKS.TIER1, LOCKS.RUINS}
    task.keys_given= {KEYS.TIER2, KEYS.RUINS}
    task.room_choices =
    {
        ["CaveJungle"] = 1,
        ["MonkeyMeadow"] = 1,
        ["Vacant"] = 2,
    }
end)
AddTaskPreInit("CaveJungle",function(task)
    task.locks={LOCKS.TIER1, LOCKS.RUINS}
    task.keys_given= {KEYS.TIER2, KEYS.RUINS}
    task.room_choices={
        ["WetWilds"] = 1,
        ["LichenMeadow"] = 1,
        ["CaveJungle"] = 1,
        ["MonkeyMeadow"] = 1,
    }
end)

AddTaskPreInit("Military",function (task)
    task.locks={LOCKS.TIER2, LOCKS.RUINS}
    task.keys_given= {KEYS.TIER3, KEYS.RUINS}
end)
AddTaskPreInit("Sacred",function (task)
    task.locks={LOCKS.TIER2, LOCKS.RUINS}
    task.keys_given= { KEYS.RUINS, KEYS.SACRED}
    task.room_choices={
        ["SacredBarracks"] = 1,
        ["BrokenAltar"] = 1,
        ["Spiral"] = 1,
        ["BrokenAltar2"] = 1,
        ["SacredDanger2"] = 1,
        --["Altar"] = 1,
    }
    task.room_bg = WORLD_TILES.BRICK
end)

AddTaskPreInit("TheLabyrinth",function (task)
    task.locks={LOCKS.TIER3, LOCKS.RUINS}
    task.keys_given = {}
    task.room_choices={
        ["RuinedGuarden"] = 1,
        ["Labyrinth"] = function() return 3+math.random(1) end,
    }
end)

AddTaskPreInit("AtriumMaze",function(task)
    task.locks={LOCKS.TIER2, LOCKS.RUINS}
    task.room_choices =
    {
        ["AtriumMazeRooms"] = 4,
    }
end)
---------------------------------------

AddTask("RUINS_TO_SHADOW", {
    locks={LOCKS.SACRED,LOCKS.RUINS},
    keys_given = {KEYS.SACRED, KEYS.TIER4},
    entrance_room = "AbyssEntrance",
    room_tags = {"Nightmare","nocavein"},
    room_choices={
        ["Abyss_Frontline"] = 1,
        ["shadow_wild"] = 3,
	    ["RuinedCity_Abyss"] = 1
    },
    background_room = "Blank",
    room_bg = WORLD_TILES.BRICK,
    colour={r=0.3,g=0.2,b=0.1,a=0.3},
    level_set_piece_blocker = true
})


AddTask("MeTal_Labyrinth_Task", {
    locks={ LOCKS.SACRED, LOCKS.TIER4},
    keys_given= {},
    room_tags = {"Nightmare","Abyss","nocavein"},
    entrance_room="LabyrinthEntrance",
    room_choices={
        ["Metal_Labyrinth"] = function() return 3+math.random(3) end,
        ["HulkGuarden"] = 1,
    },
    room_bg = WORLD_TILES.IMPASSABLE,
    background_room = "Metal_Labyrinth",
    colour={r=0.4,g=0.4,b=0.0,a=1},
    level_set_piece_blocker = true
})

AddTask("Hades",{
    locks={ LOCKS.SACRED, LOCKS.TIER4},
    keys_given= {KEYS.SACRED, KEYS.TIER5},
    room_tags = {"Nightmare","Abyss","nocavein"},
    room_choices={
        ["EndsWell"] = 1,
        ["Marsh_Abyss"] = 3,
    },
    hub_room = "EndsWell",
    background_room="BGHades",
    room_bg = WORLD_TILES.CAVE,
    colour={r=0.8,g=0.8,b=0.8,a=0.9},
    level_set_piece_blocker = true
})

AddTask("Iron_Miner",{
    locks={ LOCKS.SACRED, LOCKS.TIER4},
    keys_given= {},
    required_prefabs = {"ancient_hulk_spawner"},
    room_tags = {"Nightmare","Abyss","nocavein"},
    room_choices={
        ["Mine_Iron"] = 3,
        ["GemLand"] = 1,
    },
    background_room="Blank",
    room_bg = WORLD_TILES.ROCKY,
    hub_room = "GemLand",
    cove_room_name = "Mine_Iron",
    cove_room_chance = 1,
	cove_room_max_edges = 2,
    crosslink_factor = 2,
    colour={r=0.8,g=0.8,b=0.8,a=0.9},
    level_set_piece_blocker = true
})

AddTask("DarkGarden",{
    locks={ LOCKS.SACRED, LOCKS.TIER5},
    keys_given= {},
    room_tags = {"Nightmare","Abyss","nocavein"},
    entrance_room = "BridgeEntrance",
    room_choices={
        ["QueenGarden"] = 1
    },
    background_room="Blank",
    room_bg = WORLD_TILES.CAVE,
    colour={r=0.8,g=0.8,b=0.8,a=0.9},
    level_set_piece_blocker = true
})
