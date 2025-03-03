for i=1,10 do
    AddTaskPreInit("CaveExitTask"..i, function (task)
        task.background_room = "Blank"
    end)
end

AddTaskPreInit("BigBatCave",function (task)
    task.room_choices={
        ["BatCave"] = 2,
        ["BattyCave"] = 1,
        ["FernyBatCave"] = 1,
        ["PitRoom"] = 3,
    }
end)
AddTaskPreInit("MudWorld",function (task)
    task.locks={ LOCKS.TIER1 }
    task.keys_given={ KEYS.CAVE, KEYS.TIER2 }
    task.room_choices={
        ["LightPlantField"] = 1,
        ["WormPlantField"] = 1,
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
        ["FernyBatCave"] = 1,
        ["PitRoom"] = 1,
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
    task.background_room = "Blank"
    task.entrance_room = {"BlueMushMeadow"}
end)
AddTaskPreInit("MoonCaveForest",function (task)
    task.room_choices.MoonMushForest=1
end)
AddTaskPreInit("SpillagmiteCaverns",function (task)
    task.locks={ LOCKS.CAVE, LOCKS.TIER3 }
    task.keys_given={ KEYS.CAVE, KEYS.TIER4 }
    task.room_choices={
        ["SpillagmiteForest"] = 1,
        ["DropperCanyon"] = 1,
        ["StalagmitesAndLights"] = 1,
        ["ThuleciteDebris"] = 1,
    }
end)
AddTaskPreInit("RabbitCity",function (task)
    task.locks={ LOCKS.CAVE, LOCKS.TIER4 }
    task.keys_given={ KEYS.CAVE, KEYS.RABBIT, KEYS.TIER5, KEYS.ENTRANCE_OUTER }
    task.room_choices={
        ["RabbitCity"] = 1,
        ["RabbitTown"] = 1,
        ["RabbitArea"] = 1,
    }
end)

--[[AddTaskPreInit("ToadStoolTask1",function (task)
    task.room_choices["ToadstoolArenaBGMud"] = 1
end)
AddTaskPreInit("ToadStoolTask2",function (task)
    task.room_choices["ToadstoolArenaBGCave"] = 1
end)
AddTaskPreInit("ToadStoolTask3",function (task)
    task.room_choices["ToadstoolArenaBGMud"] = 1
end)]]
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
    task.room_choices =
    {
        ["MilitaryMaze"] = 5,
        ["Barracks"] = 1,
    }
end)

AddTaskPreInit("TheLabyrinth",function (task)
    task.locks={LOCKS.TIER3, LOCKS.RUINS}
    task.keys_given = {}
    task.room_choices["Labyrinth"] = function() return math.random(3,4) end
end)

AddTaskPreInit("Sacred",function (task)
    task.locks={LOCKS.TIER2, LOCKS.RUINS}
    task.keys_given= { KEYS.RUINS, KEYS.SACRED}
    task.room_choices={
        ["SacredBarracks"] = 1,
        ["BrokenAltar"] = 2,
        ["Bishops"] = 1,
        ["Spiral"] = 1,
        ["BrokenAltar2"] = 1,
        ["SacredDanger2"] = 1,
        --["Altar"] = 1,
    }
    task.room_bg = WORLD_TILES.BRICK
end)

AddTaskPreInit("AtriumMaze",function(task)
    task.locks={LOCKS.TIER2, LOCKS.RUINS}
    task.room_choices["AtriumMazeRooms"] = 4
end)
