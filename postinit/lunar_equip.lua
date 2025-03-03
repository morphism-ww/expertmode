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
    if not data.owner:HasTag("fastbuilder") then
        data.owner:AddTag("fastbuilder")
    end
end

local function onunequip_2(inst,data)
    local builder = data.owner.components.builder
    if builder~=nil then
        for k, v in pairs(enlightenedtechtree) do
            builder[string.lower(k).."_tempbonus"] = nil
        end
    end
    if not data.owner:HasTag("handyperson") then
        data.owner:RemoveTag("fastbuilder")
    end
    
end
newcs_env.AddPrefabPostInit("alterguardianhat",function(inst)
    if not TheWorld.ismastersim then return end

    inst:ListenForEvent("equipped",onequip_2)
    inst:ListenForEvent("unequipped",onunequip_2)

    inst.components.equippable.dapperness = -TUNING.CRAZINESS_MED
end)

local FREEZE_CANT_TAGS = {"shadow", "companion", "player","INLIMBO", "flight", "invisible"}
local FREEZETARGET_ONEOF_TAGS = { "freezable","fire","smolder"}
local function NewSpell(inst, target, position,doer)
    inst.water_spell(inst, target, position)
    local px, py, pz = position:Get()
    local fx = SpawnPrefab("crabking_ring_fx")
    fx.Transform:SetPosition(px,0,pz)
    fx.Transform:SetScale(0.7,0.7,0.7)
    local ents = TheSim:FindEntities(px,0,pz,6, nil, FREEZE_CANT_TAGS,FREEZETARGET_ONEOF_TAGS)
    for i,v in ipairs(ents)do
        if not v:IsValid() then
            --target killed or removed in combat damage phase
            return
        end
    
        if v.components.burnable ~= nil then
            if v.components.burnable:IsBurning() then
                v.components.burnable:Extinguish()
            elseif v.components.burnable:IsSmoldering() then
                v.components.burnable:SmotherSmolder()
            end
        end
    
        if v.components.combat ~= nil then
            v.components.combat:SuggestTarget(doer)
        end

        --[[if v.sg ~= nil and not v.sg:HasStateTag("frozen") then
            v:PushEvent("attacked", { attacker = doer, damage = 0, weapon = inst })
        end]]
    
        if v.components.freezable ~= nil then
            v.components.freezable:AddColdness(8)
            v.components.freezable:SpawnShatterFX()
        end
    end
end

newcs_env.AddPrefabPostInit("trident",function (inst)
    if not TheWorld.ismastersim then return end
    inst.components.spellcaster.canuseonpoint = true

    inst.water_spell = inst.components.spellcaster.spell
    inst.components.spellcaster:SetSpellFn(NewSpell)
end)