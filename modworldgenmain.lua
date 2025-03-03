--FRONTEND
if ReloadFrontEndAssets ~=nil then
    return
end

local SWELL_OCEAN_COLOR =
{
    primary_color =        {0 ,0,255,255},
    secondary_color =      {0,   255,  255,  255},
    secondary_color_dusk = {0,   0,  0,  150},
    minimap_color =        {14,  34,  61,  204},
}

--WORLD_TILES.ABYSS_DARKNESS

--is worldgen

AddTile(
    "ABYSS_DARKNESS",
    "LAND",
    nil,
    {
        name = "cave",
        noise_texture = "ground_abyss_dark",
        runsound="dontstarve/movement/run_marsh",
        walksound="dontstarve/movement/walk_marsh",
        snowsound="dontstarve/movement/run_ice",
        mudsound = "dontstarve/movement/run_mud",
        colors = SWELL_OCEAN_COLOR,
        hard = true,
    }
)



---在当前环境中插入常量
PLACE_MASK = GLOBAL.PLACE_MASK
LAYOUT_ROTATION = GLOBAL.LAYOUT_ROTATION
LAYOUT_POSITION = GLOBAL.LAYOUT_POSITION
LAYOUT = GLOBAL.LAYOUT
NODE_INTERNAL_CONNECTION_TYPE = GLOBAL.NODE_INTERNAL_CONNECTION_TYPE
NODE_TYPE = GLOBAL.NODE_TYPE
KEYS = GLOBAL.KEYS

require("map.newcs_layouts")

if not GetModConfigData("ruins") then
    return
end


modimport("postinit/map/new_bunches")

---------------------------------------------------------------------------

modimport("postinit/map/rooms/room_changes")
modimport("postinit/map/tasks/task_changes")

if not GetModConfigData("abyss") then
    return
end

modimport("postinit/map/rooms/abyss_room")

modimport("postinit/map/tasks/abyss")
modimport("postinit/map/tasksets/cs_cave")
modimport("postinit/map/new_map")

modimport("postinit/map/newstorygen")

