name = "永恒新界111"
author = "莫非则"
version = "2.1.0"
forumthread = ""

description = [[一个困难模式的mod。主要内容有生物增强，物品增强，原版内容优化，单机版内容引入
定位类似于泰拉瑞亚的专家模式，献给追求挑战的玩家

目前本mod的体系尚未健全，因此建议将本mod作为其他大型mod的补充

目前更新内容：
天体英雄，噩梦猪人，双子魔眼，犀牛增强
相应地，启迪之冠、绝望石盔甲、克盾增强
引入了单机版猪镇的漩涡斗篷，在暗影术基座处制造
引入了单机版的毁灭机甲，并极大提升其强度

注意远古改动是默认关闭的

]]

icon_atlas = "modicon.xml"
icon = "modicon.tex"
priority=-2048
api_version = 10

dst_compatible = true --是否兼容联机
--dont_starve_compatible = false --是否兼容原版
--reign_of_giants_compatible = false --是否兼容巨人DLC
---client_only_mod = false
--server_only_mod = false
all_clients_require_mod =true --所有人都需要mod，true就是

server_filter_tags = { "the new Constant", "hard", "difficult", "madness", "challenge",
    "hardcore","永恒新界" }


configuration_options = {
    {
        name = "health_alter",
        label = "天体英雄血量倍率(health multiple)",
        hover = "boss health multiple",
        options = {
            { description = "1x", data = 1 },
            { description = "1.5x", data = 1.5 },
            { description = "2x", data = 2 },
            { description = "3x", data = 3 },
            { description = "5x", data = 5 },
        },
        default = 1,

    },
    {
        name = "twin",
        label = "克眼、双子魔眼改动",
        hover = "eye and twin change",
        options = {
            { description = "开启", data = true },
            { description = "关闭", data = false },
        },
        default = true,

    },
    {
        name = "alter",
        label = "天体英雄改动",
        hover = "alterguardian change",
        options = {
            { description = "开启", data = true },
            { description = "关闭", data = false },
        },
        default = true,

    },
    {
        name = "pig",
        label = "噩梦猪人改动",
        hover = "nightmarepig change",
        options = {
            { description = "开启", data = true },
            { description = "关闭", data = false },
        },
        default = true,

    },
    {
        name = "rook",
        label = "犀牛改动",
        hover = "rook change",
        options = {
            { description = "开启", data = true },
            { description = "关闭", data = false },
        },
        default = true,

    },
    {
        name = "ancient",
        label = "远古改动",
        hover = "ancient change",
        options = {
            { description = "开启", data = true },
            { description = "关闭", data = false },
        },
        default = true,

    },
    {
        name = "alterhat",
        label = "启迪之冠改动",
        hover = "alterhat change",
        options = {
            { description = "开启", data = true },
            { description = "关闭", data = false },
        },
        default = true,

    },
    {
        name = "dragon_fire",
        label = "开启龙与火",
        hover = "dragon and fire",
        options = {
            { description = "开启", data = true },
            { description = "关闭", data = false },
        },
        default = true,

    },
    {
        name = "klaus",
        label = "克劳斯改动",
        hover = "klaus",
        options = {
            { description = "开启", data = true },
            { description = "关闭", data = false },
        },
        default = true,

    },
    {
        name = "poison",
        label = "来点剧毒",
        hover = "poison",
        options = {
            { description = "开启", data = true },
            { description = "关闭", data = false },
        },
        default = true,

    },
    {
        name = "gestalt",
        label = "月灵改动",
        hover = "gestalt",
        options = {
            { description = "开启", data = true },
            { description = "关闭", data = false },
        },
        default = true,

    },
}
