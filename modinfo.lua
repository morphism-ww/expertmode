local is_chinese = locale == "zh" or locale == "zht" or locale=="zhr"

name = is_chinese and "永恒新界" or "New Constant"
author = "莫非则"
version = "3.9.802"
forumthread = ""

icon_atlas = "modicon.xml"
icon = "modicon.tex"
priority = -2048
api_version = 10

dst_compatible = true 
all_clients_require_mod = true

server_filter_tags = { "New Constant", "difficult","mfz","challenge","hardcore","永恒新界" }


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

local function Header(title)
    return {
        name = "",
        label = title,
        options = { { description = "", data = false } },
        default = false
    }
end

local key_info = {
    {description = "Z", data = "KEY_Z"},
    {description = "ALT",data = "KEY_LALT"},
    {description = "CTRL",data = "KEY_LCTRL"},
    {description = "SHIFT",data = "KEY_LSHIFT"},
    {description = "A", data = "KEY_A"},
    {description = "B", data = "KEY_B"},
    {description = "C", data = "KEY_C"},
    {description = "D", data = "KEY_D"},
    {description = "E", data = "KEY_E"},
    {description = "F", data = "KEY_F"},
    {description = "G", data = "KEY_G"},
    {description = "H", data = "KEY_H"},
    {description = "I", data = "KEY_I"},
    {description = "J", data = "KEY_J"},
    {description = "K", data = "KEY_K"},
    {description = "L", data = "KEY_L"},
    {description = "M", data = "KEY_M"},
    {description = "N", data = "KEY_N"},
    {description = "O", data = "KEY_O"},
    {description = "P", data = "KEY_P"},
    {description = "Q", data = "KEY_Q"},
    {description = "R", data = "KEY_R"},
    {description = "S", data = "KEY_S"},
    {description = "T", data = "KEY_T"},
    {description = "U", data = "KEY_U"},
    {description = "V", data = "KEY_V"},
    {description = "W", data = "KEY_W"},
    {description = "X", data = "KEY_X"},
    {description = "Y", data = "KEY_Y"},
    {description = "BACKSPACE",data = "KEY_BACKSPACE"},
}

if is_chinese then
    description = [[永恒新界是致力于打造冒险与战斗的mod
    我们对原版的boss进行了加强，也引入了许多更强大的装备和道具来助力玩家的冒险
    对远古区域进行了改动与优化，增加了许多新的机制和事件
    此外，我们增加了一个裂隙时期的新地形，击败天体英雄和织影者将只是冒险的起点！

    键位提示：
    按下强制检查键可以暂时关闭默认右键动作，如恶魔的灵魂跳跃，使恶魔玩家也能使用格挡等其他右键动作
    若玩家装备某些物品时，套装位移的默认按键为Z，可以在模组设置中调整
    mod交流群255268032
    mod wiki页 (mod wiki)
    http://wap.modwikis.com/mod/mainPage?_id=65d20da1aa49810aaddeedc8
    ]]
    configuration_options = {
        Header("控制与UI"),
        {
            name = "charge_control",
            label = "冲刺键位",
            client = true,
            options = key_info,
            default = "KEY_Z",
        },
        {
            name = "charge_mode",
            label = "冲刺模式",
            client = true,
            options = {
                { description = "根据鼠标方向", data = true },
                { description = "根据人物朝向", data = false },
            },
            default = true,
        },
        GetConfigTab("buff_info","状态栏"),

        Header("世界规则"),
        {
            name = "bosshp",
            label = "boss血量倍率",
            options = {
                { description = "x0.5", data = 0.5 },
                { description = "x1", data = 1 },
                { description = "x1.5", data = 1.5 },
                { description = "x2", data = 2 },
                { description = "x3", data = 3 },
            },
            default = 1,
        },
        GetConfigTab("ruins","远古改动"),
        GetConfigTab("abyss","开启深渊"),
        GetConfigTab("dragon_fire","龙与火"),
        GetConfigTab("poison","开启剧毒"),
        GetConfigTab("gestalt","月灵改动"),

        Header("Boss改动"),
        GetConfigTab("twin","克眼双子改动"),
        GetConfigTab("alter","天体英雄改动"),
        GetConfigTab("pig","噩梦猪人改动"),
        GetConfigTab("rook","远古守护者改动"),
        GetConfigTab("klaus","克劳斯改动"),
        GetConfigTab("chess","暗影棋子改动"),
        GetConfigTab("stalker","织影者改动"),
        
        Header("兼容性相关"),
        GetConfigTab("wardrobe","衣柜储物"),
        GetConfigTab("ruinsbat","铥棒格挡"),
    }
else
    description = [[This MOD focuses on adventure and combat. If you're a fan of Terraria, you will love it!
    We have enhanced the original bosses and introduced many more powerful equipment and items to assist players in their adventures. We have made changes and optimizations to RUINS, adding many new creatures and events. w
    We add a new region--Abyss,which is in the depth of Ruins, 
    defeating Celestial Champion and Ancient Fuelweaver is just the beginning of the adventure!


    Controlls Tip: The charging key is [Force Inspect] + Left Mouse Button. 
    [Force Inspect] is default Alt key and can be adjusted in the Control Options.

    Mod wiki page: (mod wiki)
    http://wap.modwikis.com/mod/mainPage?_id=65d20da1aa49810aaddeedc8]]
    configuration_options = 
    {   
        Header("Controls&UI"),
        {
            name = "charge_control",
            label = "charge key map",
            client = true,
            options = key_info,
            default = "KEY_Z",
        },
        {
            name = "charge_mode",
            label = "冲刺模式",
            client = true,
            options = {
                { description = "mouse mode", data = true, hover = "Based on mouse direction" },
                { description = "orient mode",   data = false ,hover = "Based on character orientation"},
            },
            default = true,
        },
        GetConfigTab("buff_info","buff panel"),

        Header("world setting"),
        {
            name = "bosshp",
            label = "boss hp multiplier",
            options = {
                { description = "x0.5", data = 0.5 },
                { description = "x1", data = 1 },
                { description = "x1.5", data = 1.5 },
                { description = "x2", data = 2 },
                { description = "x3", data = 3 },
            },
            default = 1,
        },
        GetConfigTab("ruins","Ruins change"),
        GetConfigTab("abyss","enable Abyss"),
        GetConfigTab("dragon_fire","dragonfly and enable Fire falling"),
        GetConfigTab("poison","Poison"),
        GetConfigTab("gestalt","Gestalt"),

        Header("boss change"),

        GetConfigTab("twin","Eyeofterror and twins"),
        GetConfigTab("alter","Celestial Champion"),
        GetConfigTab("pig","Nightmare Werepig"),
        GetConfigTab("rook","Ancient Guardian"),
        GetConfigTab("klaus","Klaus"),
        GetConfigTab("chess","Shadowchess"),
        GetConfigTab("stalker","Ancient FuelWeaver"),
        
        Header("Compatibility"),
        GetConfigTab("wardrobe","Wardrobe container"),
        GetConfigTab("ruinsbat","Ruins bat parry"),
    }
end

