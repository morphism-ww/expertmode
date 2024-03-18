TUNING.SANITY_BECOME_ENLIGHTENED_THRESH = 150/200
TUNING.SANITY_LOSE_ENLIGHTENMENT_THRESH = 145/200
local TechTree = require("techtree")

local enlightenedtechtree={
                SCIENCE = 2,
                MAGIC = 3,
                ANCIENT = 4,
                CELESTIAL = 3,
                SEAFARING = 2,
                FISHING = 1,
            }


local function onequip(inst,owner)
    inst.oldequipfn(inst,owner)
    local builder=owner.components.builder
    for k, v in pairs(enlightenedtechtree) do
        builder[string.lower(k).."_tempbonus"] = v
    end
end

local function onunequip(inst,owner)
    inst.oldunequipfn(inst,owner)
    local builder=owner.components.builder
    for k, v in pairs(enlightenedtechtree) do
        builder[string.lower(k).."_tempbonus"] = nil
    end
end
AddPrefabPostInit("alterguardianhat",function(inst)
    if not TheWorld.ismastersim then return end
    inst.oldequipfn=inst.components.equippable.onequipfn
    inst.oldunequipfn=inst.components.equippable.onunequipfn

    inst.components.equippable.dapperness = -TUNING.CRAZINESS_MED
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
end)