local function ObsidianToolHitWater(inst)
    inst.components.obsidiantool:SetCharge(0)
end

local function SpawnObsidianLight(inst)
    local owner = inst.components.inventoryitem.owner
    inst._obsidianlight = inst._obsidianlight or SpawnPrefab("obsidiantoollight")
    inst._obsidianlight.entity:SetParent((owner or inst).entity)
end

local function RemoveObsidianLight(inst)
    if inst._obsidianlight ~= nil then
        inst._obsidianlight:Remove()
        inst._obsidianlight = nil
    end
end

local function ChangeObsidianLight(inst, old, new)
    local percentage = new / inst.components.obsidiantool.maxcharge
    local rad = Lerp(1, 2.5, percentage)

    if percentage >= inst.components.obsidiantool.yellow_threshold then
        SpawnObsidianLight(inst)

        if percentage >= inst.components.obsidiantool.red_threshold then
            inst._obsidianlight.Light:SetColour(254/255,98/255,75/255)
            inst._obsidianlight.Light:SetRadius(rad)
            inst:AddTag("fire")
        elseif percentage >= inst.components.obsidiantool.orange_threshold then
            inst._obsidianlight.Light:SetColour(255/255,159/255,102/255)
            inst._obsidianlight.Light:SetRadius(rad)
            inst:RemoveTag("fire")
        else
            inst._obsidianlight.Light:SetColour(255/255,223/255,125/255)
            inst._obsidianlight.Light:SetRadius(rad)
            inst:RemoveTag("fire")
        end
    else
        RemoveObsidianLight(inst)
    end
end

local function ManageObsidianLight(inst)
    local cur, max = inst.components.obsidiantool:GetCharge()
    if cur / max >= inst.components.obsidiantool.yellow_threshold then
        SpawnObsidianLight(inst)
    else
        RemoveObsidianLight(inst)
    end
end

function MakeObsidianTool(inst, tooltype)
    inst:AddTag("obsidian")
    inst.no_wet_prefix = true

    if inst.components.floatable then
        inst.components.floatable:SetOnHitWaterFn(function()
            inst.components.obsidiantool:SetCharge(0)
        end)
    end
    inst:AddComponent("temperature")
    inst:AddComponent("obsidiantool")
    inst.components.obsidiantool.tool_type = tooltype

    inst.components.obsidiantool.onchargedelta = ChangeObsidianLight

    inst:ListenForEvent("equipped", ManageObsidianLight)
    inst:ListenForEvent("onputininventory", ManageObsidianLight)
    inst:ListenForEvent("ondropped", ManageObsidianLight)
    inst:ListenForEvent("floater_startfloating", ObsidianToolHitWater)
end


local function _base_onequip(inst, owner, symbol_override, swap_hat_override)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("equipskinneditem", inst:GetSkinName())
        owner.AnimState:OverrideItemSkinSymbol(swap_hat_override or "swap_hat", skin_build, symbol_override or "swap_hat", inst.GUID, fname)
    else
        owner.AnimState:OverrideSymbol(swap_hat_override or "swap_hat", inst.fname, symbol_override or "swap_hat")
    end

    if inst.components.fueled ~= nil then
        inst.components.fueled:StartConsuming()
    end

    if inst.skin_equip_sound and owner.SoundEmitter then
        owner.SoundEmitter:PlaySound(inst.skin_equip_sound)
    end
end

local function _onunequip(inst, owner)
    local skin_build = inst:GetSkinBuild()
    if skin_build ~= nil then
        owner:PushEvent("unequipskinneditem", inst:GetSkinName())
    end

    owner.AnimState:ClearOverrideSymbol("headbase_hat") --it might have been overriden by _onequip
    if owner.components.skinner ~= nil then
        owner.components.skinner.base_change_cb = owner.old_base_change_cb
    end

    owner.AnimState:ClearOverrideSymbol("swap_hat")
    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Show("HAIR_NOHAT")
    owner.AnimState:Show("HAIR")

    if owner:HasTag("player") then
        owner.AnimState:Show("HEAD")
        owner.AnimState:Hide("HEAD_HAT")
        owner.AnimState:Hide("HEAD_HAT_NOHELM")
        owner.AnimState:Hide("HEAD_HAT_HELM")
    end

    if inst.components.fueled ~= nil then
        inst.components.fueled:StopConsuming()
    end
end

Fullhelm_Onequip = function(inst, owner)
    if owner:HasTag("player") then
        _base_onequip(inst, owner, nil, "headbase_hat")

        owner.AnimState:Hide("HAT")
        owner.AnimState:Hide("HAIR_HAT")
        owner.AnimState:Hide("HAIR_NOHAT")
        owner.AnimState:Hide("HAIR")

        owner.AnimState:Hide("HEAD")
        owner.AnimState:Show("HEAD_HAT")
        owner.AnimState:Hide("HEAD_HAT_NOHELM")
        owner.AnimState:Show("HEAD_HAT_HELM")

        owner.AnimState:HideSymbol("face")
        owner.AnimState:HideSymbol("swap_face")
        owner.AnimState:HideSymbol("beard")
        owner.AnimState:HideSymbol("cheeks")

        owner.AnimState:UseHeadHatExchange(true)
    else
        _base_onequip(inst, owner)

        owner.AnimState:Show("HAT")
        owner.AnimState:Hide("HAIR_HAT")
        owner.AnimState:Hide("HAIR_NOHAT")
        owner.AnimState:Hide("HAIR")
    end
end

Fullhelm_Onunequip = function(inst, owner)
    _onunequip(inst, owner)

    if owner:HasTag("player") then
        owner.AnimState:ShowSymbol("face")
        owner.AnimState:ShowSymbol("swap_face")
        owner.AnimState:ShowSymbol("beard")
        owner.AnimState:ShowSymbol("cheeks")

        owner.AnimState:UseHeadHatExchange(false)
    end
end



function MakePlayerOnlyTarget(inst)
    inst.components.combat:AddNoAggroTag("epic")
    if inst.components.damagetyperesist==nil then
        inst:AddComponent("damagetyperesist")
    end
    inst.components.damagetyperesist:AddResist("epic", inst, 0) 
end

