name = "永恒新界"
author = "莫非则"
version = "3.9.4.30"
forumthread = ""

local is_chinese = locale == "zh"

description = is_chinese and [[永恒新界是致力于打造冒险与战斗的mod
我们对原版的boss进行了加强，也引入了许多更强大的装备和道具来助力玩家的冒险
对远古区域进行了改动与优化，增加了许多新的机制和事件
此外，我们增加了一个裂隙时期的新地形，击败天体英雄和织影者将只是冒险的起点！

！！！注意！！！
洞穴请开[巨大]，地表请不要开[巨大]，谨慎改变洞穴地形

键位提示：冲刺键为【辅助键】+鼠标左键
其中【辅助键】为游戏内的"强制查看键"，默认为左Alt键，可自行在游戏设置界面调整

mod交流群255268032
mod wiki页 (mod wiki)
http://wap.modwikis.com/mod/mainPage?_id=65d20da1aa49810aaddeedc8
]] or 
[[This MOD focuses on adventure and combat. If you're a fan of Terraria, you will love it!
We have enhanced the original bosses and introduced many more powerful equipment and items to assist players in their adventures. We have made changes and optimizations to RUINS, adding many new creatures and events. w
We add a new region--Abyss,which is in the depth of Ruins, 
defeating Celestial Champion and Ancient Fuelweaver is just the beginning of the adventure!

!!! Attention !!!
Please set caves to [Huge], and avoid setting the forest to [Huge]. 
Carefully change terrain-related settings. 

Controlls Tip: The charging key is [Force Inspect] + Left Mouse Button. 
[Force Inspect] is default Alt key and can be adjusted in the Control Options.

Mod wiki page: (mod wiki)
http://wap.modwikis.com/mod/mainPage?_id=65d20da1aa49810aaddeedc8]]

icon_atlas = "modicon.xml"
icon = "modicon.tex"
priority = -2048
api_version = 10

dst_compatible = true --是否兼容联机
all_clients_require_mod = true --所有人都需要mod，true就是

server_filter_tags = { "the new Constant", "hard", "difficult","mfz","challenge",
    "hardcore","永恒新界" }



local enable_choice = is_chinese and "启用" or "Enable"
local close_choice = is_chinese and "关闭" or "Close"

local function GetConfigTab(name,label)
    return  {
        name = name,
        label = label,
        options = {
            { description = enable_choice, data = true },
            { description = close_choice, data = false },
        },
        default = true
    }
end    


configuration_options = 
is_chinese and {
    GetConfigTab("twin","克眼双子改动"),
    GetConfigTab("alter","天体英雄改动"),
    GetConfigTab("pig","噩梦猪人改动"),
    GetConfigTab("rook","远古守护者改动"),
    GetConfigTab("ruins","远古改动"),
    GetConfigTab("antlion","蚁狮批量换蛋"),
    GetConfigTab("dragon_fire","龙与火"),
    GetConfigTab("klaus","克劳斯改动"),
    GetConfigTab("chess","暗影棋子改动"),
    GetConfigTab("stalker","织影者改动"),
    GetConfigTab("poison","开启剧毒"),
    GetConfigTab("wardrobe","衣柜储物"),
    GetConfigTab("buff_info","状态栏"),
    GetConfigTab("ruinsbat","铥棒格挡"),
    GetConfigTab("damagemultiplier","攻击倍率调整"),
    GetConfigTab("gestalt","月灵改动"),
    GetConfigTab("legion_medal","棱镜勋章平衡"),
} or 
{
    GetConfigTab("twin","Eyeofterror and twins"),
    GetConfigTab("alter","Celestial Champion"),
    GetConfigTab("pig","Nightmare Werepig"),
    GetConfigTab("rook","Ancient Guardian"),
    GetConfigTab("ruins","Ruins change and enable Abyss"),
    GetConfigTab("dragon_fire","dragonfly and enable Fire falling"),
    GetConfigTab("klaus","Klaus"),
    GetConfigTab("chess","Shadowchess"),
    GetConfigTab("stalker","Ancient FuelWeaver"),
    GetConfigTab("poison","Poison"),
    GetConfigTab("ruinsbat","Wardrobe container"),
    GetConfigTab("buff_info","buff panel"),
    GetConfigTab("ruinsbat","Ruins bat parry"),
    GetConfigTab("damagemultiplier","Damagemultiplier Rework"),
    GetConfigTab("gestalt","Gestalt"),
}