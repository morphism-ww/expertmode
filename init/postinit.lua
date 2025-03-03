--"dreadsword","nightmare_hat","dread_cloak","knightmare","sword_constant","cs_shadow_queen","lavaarena_heavyblade","them_shadow",
if GetModConfigData("bosshp")~=1 then
    modimport("postinit/bosshealth_modifiler")
end

if GetModConfigData("pig") then
    modimport_global("postinit/epic/daywalker")
end

if GetModConfigData("twin") then
    modimport_global("postinit/epic/eyeofterror")
    modimport_global("postinit/epic/twinofterror")
end

if GetModConfigData("alter") then
    modimport_global("postinit/epic/alterguardian")
end

if GetModConfigData("rook") then
    modimport_global("postinit/epic/minotaur")
end

if GetModConfigData("dragon_fire") then
    TUNING.FIRERAIN_ENABLE = true
    modimport_global("postinit/epic/dragonfly")
end

if GetModConfigData("klaus") then
    modimport_global("postinit/epic/klaus")
end

if GetModConfigData("stalker") then
    modimport_global("postinit/epic/stalker")
end

if GetModConfigData("poison") then
    modimport_global("postinit/epic/beequeen")
    modimport_global("postinit/epic/toadstool")
    modimport_global("postinit/mushroom_hat")
    modimport_global("postinit/poison_creature")
end

if GetModConfigData("ruins") then
    modimport_global("postinit/shadowmachine")
end

if GetModConfigData("gestalt") then
    TUNING.ALLOW_LUNAR_QUEEN = true
    modimport_global("postinit/gestalt")
end


if GetModConfigData("chess") then
    modimport_global("postinit/epic/shadowchess")
end

if GetModConfigData("wardrobe") then
    modimport_global("postinit/wardrobe")
end

if GetModConfigData("ruinsbat") then
    modimport_global("postinit/ruins_bat")
end

modimport_global("postinit/town_portal")


--装备
modimport_global("postinit/ruins_equip")
modimport_global("postinit/normal_weapons")
modimport_global("postinit/amulet")
modimport_global("postinit/lunar_equip")
modimport_global("postinit/planar_armor")

--霸体护甲
modimport_global("postinit/nostun_armor")


-----------------------------------

--深渊环境机制
modimport_global("postinit/new_story/abyss_makedark")

--反传送
modimport_global("postinit/new_story/notele")

modimport_global("postinit/ironlord_spawner")

--暗影位面生物
modimport_global("postinit/epic/shadowthrall")

--迷宫箱子
modimport_global("postinit/scenario_change")


--添加bgm
modimport_global("postinit/components/dynamicmusic")

--食物
modimport_global("postinit/food")

modimport_global("postinit/epic/lunarthrall_plant")

modimport_global("postinit/anti_debuffs")

modimport_global("postinit/legion_medal")


------------bossrush-----------------
modimport_global("postinit/new_story/bossrush_entrance")
modimport_global("postinit/new_story/bossrush_protect")

-----之后的文件只在服务器导入
if not GLOBAL.TheNet:GetIsMasterSimulation() then
    return
end

--材料
modimport_global("postinit/fuel")
modimport_global("postinit/repairable")

--龙鳞火炉
modimport_global("postinit/dragonflyfurnace")

--抗击飞
modimport_global("postinit/anti_knockback")

--愚蠢
modimport_global("postinit/stupid_stuff")

--直线射弹
modimport_global("postinit/components/projectile_init")

--modimport_global("postinit/components/klausloot") --klaussackloot,stewer
modimport_global("postinit/components/meteorshower")

modimport_global("postinit/components/truedamage_system") --inventory
--modimport_global("postinit/components/cn_boatphysics")
modimport_global("postinit/components/components_change1") --freezable,burnable,debuffable,rooted


--modimport_global("postinit/epic/deerclops")

modimport_global('postinit/epic/mutated_bosses')
---------------------------------------


--世界组件
modimport("postinit/worldchange")
---------------------------------------------

modimport_global("postinit/farming")





 



