newcs_env.AddPrefabPostInit("armorruins", function(inst)
    local function onequip(inst,owner)
        inst._oldonequipfn(inst,owner)
        if owner.components.sanity ~= nil then
            owner.components.sanity.neg_aura_modifiers:SetModifier(inst, 0.5)
        end
    end
    
    local function onunequip(inst,owner)
        inst._oldunequipfn(inst,owner)
        if owner.components.sanity ~= nil then
            owner.components.sanity.neg_aura_modifiers:RemoveModifier(inst)
        end
    end

	inst:AddTag("poison_immune")
    inst:AddTag("soul_protect")

	if not TheWorld.ismastersim then
		return inst
	end

    inst._oldonequipfn=inst.components.equippable.onequipfn
	inst._oldunequipfn=inst.components.equippable.onunequipfn

    inst.components.equippable:SetOnEquip(onequip)
	inst.components.equippable:SetOnUnequip(onunequip)
	inst.components.equippable.insulated = true
	inst.components.equippable.dapperness = TUNING.DAPPERNESS_LARGE
end)

--ThePlayer.AnimState:OverrideSymbol("cheeks", "farm_plant_potato", "seed")
newcs_env.AddPrefabPostInit("thurible",function (inst)
    local function UpdateSnuff(inst, owner)
        local x, y, z = owner.Transform:GetWorldPosition()
        for i, v in ipairs(TheSim:FindEntities(x, 0, z, 5, nil, { "INLIMBO"}, {"cs_soul"})) do
            if v:IsValid() and not v:IsInLimbo() then
                owner.SoundEmitter:PlaySound("meta3/willow_lighter/ember_absorb")
                local fxprefab = SpawnPrefab("channel_absorb_embers")
                fxprefab.Follower:FollowSymbol(owner.GUID, "swap_object", 56, -40, 0)
                v.AnimState:PlayAnimation("idle_pst")
                v:DoTaskInTime(10*FRAMES,function()
                    if not owner.components.health:IsDead() then
                        owner.components.inventory:GiveItem(v, nil, owner:GetPosition())
                    end
                    v.AnimState:PlayAnimation("idle_pre")
                    v.AnimState:PushAnimation("idle_loop",true)
                end)
            end
        end
    end            
    local function onequip_2(inst,data)
        if inst.snuff_task then
            inst.snuff_task:Cancel()
        end
        if data.owner and data.owner:HasTag("player") then
            inst.snuff_task = inst:DoPeriodicTask(0.5, UpdateSnuff, nil, data.owner)
        end
    end
    local function onunequip_2(inst,data)
        if inst.snuff_task then
            inst.snuff_task:Cancel()
            inst.snuff_task = nil
        end
    end
    if not TheWorld.ismastersim then
		return inst
	end

    inst:ListenForEvent("equipped",onequip_2)
    inst:ListenForEvent("unequipped",onunequip_2)
end)