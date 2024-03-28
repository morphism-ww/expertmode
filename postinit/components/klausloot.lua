local giant_loot1 =
{
    "deerclops_eyeball",
    "dragon_scales",
    "hivehat",
    "shroom_skin",
}

local giant_loot2 =
{
    "dragonflyfurnace_blueprint",
    "red_mushroomhat_blueprint",
    "green_mushroomhat_blueprint",
    "blue_mushroomhat_blueprint",
    "mushroom_light2_blueprint",
    "mushroom_light_blueprint",
    "townportal_blueprint",
    "bundlewrap_blueprint",
	"trident_blueprint",
}

local giant_loot3 =
{
    "bearger_fur",
    "lavae_egg",
    "greengem",
	"malbatross_beak",
}
local giant_loot4 =
{
    "lightninggoathorn",
    "staff_tornado",
	"mandrake",
	"tallbirdegg",
}
local boss_ornaments =
{
    "winter_ornament_boss_klaus",
    "winter_ornament_boss_noeyeblue",
    "winter_ornament_boss_noeyered",
    "winter_ornament_boss_krampus",
}

local function FillItems(items, prefab)
    for i = 1 + #items, math.random(3, 4) do
        table.insert(items, prefab)
    end
end

AddComponentPostInit("klaussackloot", function(KlausSackLoot)
    function KlausSackLoot:RollKlausLoot()
        --WINTERS FEAST--
        self.wintersfeast_loot = {}

        local rnd = math.random(3)
        local items = {
            boss_ornaments[math.random(#boss_ornaments)],
            GetRandomFancyWinterOrnament(),
            GetRandomLightWinterOrnament(),
            ((rnd == 1 and GetRandomLightWinterOrnament()) or (rnd == 2 and GetRandomFancyWinterOrnament()) or GetRandomBasicWinterOrnament()),
        }
        table.insert(self.wintersfeast_loot, items)

        items = {
            "goatmilk",
            "goatmilk",
            {"winter_food"..tostring(math.random(2)), 4},
        }
        table.insert(self.wintersfeast_loot, items)

        --WINTERS FEAST--
        self.loot = {}

        items = {}
        table.insert(items, "amulet")
        table.insert(items, "goldnugget")
        FillItems(items, "charcoal")
        table.insert(self.loot, items)

        items = {}
        if math.random() < .5 then
            table.insert(items, "yellowamulet")
        end
        if math.random()< .75 then
            FillItems(items, "bluegem")
        else
            FillItems(items, "yellowgem")
        end

        table.insert(self.loot, items)

        items = {}
        if math.random() < .5 then
            table.insert(items, "krampus_sack")
        end
        table.insert(items, "goldnugget")
        FillItems(items, "charcoal")
        table.insert(self.loot, items)

        items = {}

        table.insert(items, giant_loot1[math.random(#giant_loot1)])
        table.insert(items, giant_loot2[math.random(#giant_loot2)])
        table.insert(items, giant_loot3[math.random(#giant_loot3)])
        table.insert(items, giant_loot4[math.random(#giant_loot4)])
        table.insert(self.loot, items)
    end
    KlausSackLoot:RollKlausLoot()
end)
