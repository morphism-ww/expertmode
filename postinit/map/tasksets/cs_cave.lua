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

        "MoonCaveForest",
        "ArchiveMaze",

        "CaveExitTask1",
        "CaveExitTask2",
        "CaveExitTask3",

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
        "Iron_Miner",
        "DarkGarden"
        
    }    
    task.numoptionaltasks = 0
    task.valid_start_tasks = {"CaveExitTask1", "CaveExitTask2", "CaveExitTask3"}
    --[[task.set_pieces = {
        ["TentaclePillar"] = { count = 7, tasks= { -- Note: An odd number because AtriumMaze contains one
            "MudWorld", "MudLights", "MudPit", "BigBatCave", "RockyLand", "RedForest", "GreenForest", "BlueForest", "SpillagmiteCaverns", "SwampySinkhole", "CaveSwamp", 
        } },
        ["ResurrectionStone"] = { count = 2, tasks={
            "MudWorld",  "MudLights", "MudPit", "BigBatCave", "RockyLand", "RedForest", "GreenForest", "BlueForest", "SpillagmiteCaverns", "SwampySinkhole", "CaveSwamp",
        } },
        ["skeleton_notplayer"] = { count = 1, tasks={
            "MudWorld",  "MudLights", "MudPit", "BigBatCave", "RockyLand", "RedForest", "GreenForest", "BlueForest", "SpillagmiteCaverns", "SwampySinkhole", "CaveSwamp",
        }}
    }]]
    task.set_pieces["TentaclePillar"] = { count = 5, tasks= { -- Note: An odd number because AtriumMaze contains one
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
    tasks.set_pieces["CaveEntrance"] = { count = 3, tasks={"Make a pick", "Dig that rock", "Great Plains",}}
end)
