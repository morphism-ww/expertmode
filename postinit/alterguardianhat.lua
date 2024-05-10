TUNING.SANITY_BECOME_ENLIGHTENED_THRESH = 150/200
TUNING.SANITY_LOSE_ENLIGHTENMENT_THRESH = 145/200


local enlightenedtechtree={
    SCIENCE = 2,
    MAGIC = 3,
    ANCIENT = 4,
    SEAFARING = 2,
}


local function onequip_2(inst,data)
    local builder = data.owner.components.builder
    if builder~=nil then
        for k, v in pairs(enlightenedtechtree) do
            builder[string.lower(k).."_tempbonus"] = v
        end
    end
end

local function onunequip_2(inst,data)
    local builder = data.owner.components.builder
    if builder~=nil then
        for k, v in pairs(enlightenedtechtree) do
            builder[string.lower(k).."_tempbonus"] = nil
        end
    end
end
AddPrefabPostInit("alterguardianhat",function(inst)
    if not TheWorld.ismastersim then return end

    inst:ListenForEvent("equipped",onequip_2)
    inst:ListenForEvent("unequipped",onunequip_2)

    inst.components.equippable.dapperness = -TUNING.CRAZINESS_MED
end)