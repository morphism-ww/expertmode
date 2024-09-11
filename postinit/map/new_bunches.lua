local bunches = require "map/bunches"
bunches.Bunches["nightmaregrowth_abyss_spawner"] = 
{
	prefab = "nightmaregrowth_abyss",
	range = 8,
	min = 40,
	max = 40,
	min_spacing = 1,
	valid_tile_types = {
		WORLD_TILES.ROCKY,
		WORLD_TILES.TILES,
	},
}