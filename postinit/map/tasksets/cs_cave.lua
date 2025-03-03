AddTaskSetPreInit("cave_default", function (task)
    task.tasks = {
        "LichenLand",
        "MudWorld",
        --"MudCave",
        "CaveJungle",
        "Residential",
        "MudLights",
        "MudPit",

        "BigBatCave",
        "RockyLand",
        "RedForest",
        "GreenForest",
        "BlueForest",
        "SpillagmiteCaverns",
        "RabbitCity",
        
        
        "MoonCaveForest",
        "ArchiveMaze",

        "CaveExitTask1",
        "CaveExitTask2",
        "CaveExitTask3",
        "CaveExitTask5",

		"ToadStoolTask1",
		"ToadStoolTask2",
		"ToadStoolTask3",

        "Sacred",
        "Military",
        "AtriumMaze",
        "TheLabyrinth",
        "RUINS_TO_SHADOW",
        "MeTal_Labyrinth_Task",
        "Hades",
        "Night_Land",
        "Iron_Miner",
        "DarkGarden",
        
        
    }    
    task.numoptionaltasks = 0
    --[[task.optionaltasks = {
        "UndergroundForest",
        "PleasantSinkhole",  
        "FungalNoiseMeadow",
        "RabbitTown",
        "RabbitCity",
    }]]
    task.valid_start_tasks = {"CaveExitTask1", "CaveExitTask2", "CaveExitTask3","CaveExitTask5"}
   
    task.set_pieces["TentaclePillar"] = { count = 4, tasks= {
    "MudWorld", "MudLights", "MudPit", "BigBatCave", "RockyLand", "RedForest", "GreenForest", "BlueForest", "SpillagmiteCaverns", "CaveSwamp", 
    } }
    task.set_pieces["ResurrectionStone"]= { count = 2, tasks={
        "MudWorld",  "MudLights", "MudPit", "BigBatCave", "RockyLand", "RedForest", "GreenForest", "BlueForest", "SpillagmiteCaverns", "SwampySinkhole", "CaveSwamp",
    } }
    task.set_pieces["skeleton_notplayer"] = { count = 1, tasks={
        "MudWorld",  "MudLights", "MudPit", "BigBatCave", "RockyLand", "RedForest", "GreenForest", "BlueForest", "SpillagmiteCaverns", "SwampySinkhole", "CaveSwamp",
    }}
end )


AddTaskSetPreInit("default",function (tasks)
    tasks.set_pieces["CaveEntrance"] = { count = 4, tasks={"Make a pick", "Dig that rock", "Great Plains","Squeltch","Beeeees!", "Speak to the king",}}
end)


--[[AddLevelPreInit("DST_CAVE",function (level)
    level.overrides.keep_disconnected_tiles = true	
    level.overrides.no_joining_islands = true
end)]]