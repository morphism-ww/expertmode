local assets =
{
	Asset("ANIM", "anim/living_artifact.zip"),
	Asset("ANIM", "anim/living_suit_build.zip"),
}

local function onequip1(inst,owner)
    owner:AddTag("laserworker")
    owner:DoTaskInTime(0.2,function ()
        owner.AnimState:OverrideSymbol("arm_lower", "living_suit_build", "arm_lower")
        owner.AnimState:OverrideSymbol("arm_upper", "living_suit_build", "arm_upper")
        owner.AnimState:OverrideSymbol("arm_upper_skin", "living_suit_build", "arm_upper_skin")
        owner.AnimState:OverrideSymbol("hand", "living_suit_build", "hand")
    end)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/iron_lord/morph")
end

local function onunequip1(inst,owner)
    owner:RemoveTag("laserworker")
    
    --owner.AnimState:ClearOverrideBuild("living_suit_build")
    owner.AnimState:ClearOverrideSymbol("arm_lower")
    owner.AnimState:ClearOverrideSymbol("arm_upper")
    owner.AnimState:ClearOverrideSymbol("arm_upper_skin")
    owner.AnimState:ClearOverrideSymbol("hand")


    if owner.components.skinner~=nil then
        owner.components.skinner:SetSkinMode()
    end
    
end

local function OnRepaired(inst)
    inst.SoundEmitter:PlaySound("dontstarve/characters/wx78/levelup")
end

-------------------------------------------------------------------------
local function Lightning_ReticuleTargetFn()
    --Cast range is 8, leave room for error (6.5 lunge)
    return Vector3(ThePlayer.entity:LocalToWorldSpace(6.5, 0, 0))
end

local function Lightning_ReticuleMouseTargetFn(inst, mousepos)
    if mousepos ~= nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        local dx = mousepos.x - x
        local dz = mousepos.z - z
        local l = dx * dx + dz * dz
        if l <= 0 then
            return inst.components.reticule.targetpos
        end
        l = 6.5 / math.sqrt(l)
        return Vector3(x + dx * l, 0, z + dz * l)
    end
end

local function Lightning_ReticuleUpdatePositionFn(inst, pos, reticule, ease, smoothing, dt)
    local x, y, z = inst.Transform:GetWorldPosition()
    reticule.Transform:SetPosition(x, 0, z)
    local rot = -math.atan2(pos.z - z, pos.x - x) / DEGREES
    if ease and dt ~= nil then
        local rot0 = reticule.Transform:GetRotation()
        local drot = rot - rot0
        rot = Lerp((drot > 180 and rot0 + 360) or (drot < -180 and rot0 - 360) or rot0, rot, dt * smoothing)
    end
    reticule.Transform:SetRotation(rot)
end

---------------------------------------------------------------------------------------
local function SetBuffEnabled(inst, enabled)
	if enabled then
		if not inst._bonusenabled then
			inst._bonusenabled = true
			
		end
	elseif inst._bonusenabled then
		inst._bonusenabled = nil
		
	end
end

local function SetBuffOwner(inst, owner)
	if inst._owner ~= owner then
		if inst._owner ~= nil then
			inst:RemoveEventCallback("equip", inst._onownerequip, inst._owner)
			inst:RemoveEventCallback("unequip", inst._onownerunequip, inst._owner)
			inst._onownerequip = nil
			inst._onownerunequip = nil
			SetBuffEnabled(inst, false)
		end
		inst._owner = owner
		if owner ~= nil then
			inst._onownerequip = function(owner, data)
				if data ~= nil then
					if data.item ~= nil and data.item.prefab == "wagpunkhat" then
						SetBuffEnabled(inst, true)
					elseif data.eslot == EQUIPSLOTS.HEAD then
						SetBuffEnabled(inst, false)
					end
				end
			end
			inst._onownerunequip  = function(owner, data)
				if data ~= nil and data.eslot == EQUIPSLOTS.HEAD then
					SetBuffEnabled(inst, false)
				end
			end
			inst:ListenForEvent("equip", inst._onownerequip, owner)
			inst:ListenForEvent("unequip", inst._onownerunequip, owner)

			local hat = owner.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
			if hat ~= nil and hat.prefab == "wagpunkhat" then
				SetBuffEnabled(inst, true)
			end
		end
	end
end

local function onequip2(inst,owner)
    
    owner:AddTag("canrepeatcast")
    --[[if not owner.components.channelcaster:IsChanneling() then
        owner.components.channelcaster:StartChanneling()
    end]]
    if owner.player_classified then
        owner.components.locomotor:StartStrafing()
		owner.player_classified.ischannelcasting:set(true)
	end

    
    owner:DoTaskInTime(0.2,function ()
        owner.AnimState:OverrideSymbol("arm_lower", "living_suit_build", "arm_lower")
        owner.AnimState:OverrideSymbol("arm_upper", "living_suit_build", "arm_upper")
        owner.AnimState:OverrideSymbol("arm_upper_skin", "living_suit_build", "arm_upper_skin")
        owner.AnimState:OverrideSymbol("hand", "living_suit_build", "hand")
        inst.components.fueled:StartConsuming()
    end)
    SetBuffOwner(inst, owner)
    inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/iron_lord/morph")
end


local function onunequip2(inst,owner)
    
    owner:RemoveTag("canrepeatcast")
    --owner.AnimState:ClearOverrideBuild("living_suit_build")
    owner.AnimState:ClearOverrideSymbol("arm_lower")
    owner.AnimState:ClearOverrideSymbol("arm_upper")
    owner.AnimState:ClearOverrideSymbol("arm_upper_skin")
    owner.AnimState:ClearOverrideSymbol("hand")
    
    --[[if owner.components.channelcaster then
		owner.components.channelcaster:StopChanneling()
	end]]
    if owner.player_classified then
        owner.components.locomotor:StopStrafing()
		owner.player_classified.ischannelcasting:set(false)
	end
    if owner.components.skinner~=nil then
        owner.components.skinner:SetSkinMode()
    end
    
    SetBuffOwner(inst, nil)
    inst.components.fueled:StopConsuming()
end

local function DoLaserShoot(inst,owner,pos)
    --[[if not owner.components.channelcaster:IsChanneling() then
        owner.components.channelcaster:StartChanneling()
        
    end]]    
    if owner.components.combat:InCooldown() then
        return
    end
    owner.components.combat:OverrideCooldown(inst._bonusenabled and 0.25 or 0.5)
    inst.components.fueled:DoDelta(inst._bonusenabled and -10 or -40)
    local proj = SpawnPrefab("laser_orb")
    local x, y, z = owner.Transform:GetWorldPosition()
    local dir = (pos - Vector3(x, y, z)):Normalize()
    dir = dir * 0.5
    proj.Transform:SetPosition(x + dir.x, y, z + dir.z)
    proj.components.linearprojectile:LineShoot(pos,owner)
end



local function commonfn1(inst)
    inst:AddTag("tool")
    
     --weapon (from weapon component) added to pristine state for optimization
     inst:AddTag("weapon")

     inst:AddTag("toolpunch")

     inst:AddTag("supertoughworker")
end

local function postinitfn1(inst)
    inst.components.equippable:SetOnEquip(onequip1)
    inst.components.equippable:SetOnUnequip(onunequip1)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(68)

    inst:AddComponent("tool")
    inst.components.tool:SetAction(ACTIONS.CHOP, 5)
    inst.components.tool:SetAction(ACTIONS.MINE, 5)
    inst.components.tool:SetAction(ACTIONS.HAMMER, 5)
	inst.components.tool:EnableToughWork(true)

    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetMaxUses(TUNING.LASERWORKER_USES)
    inst.components.finiteuses:SetUses(TUNING.LASERWORKER_USES)
    inst.components.finiteuses:SetOnFinished(inst.Remove)
    inst.components.finiteuses:SetConsumption(ACTIONS.CHOP, 1)
    inst.components.finiteuses:SetConsumption(ACTIONS.MINE, 2)
    inst.components.finiteuses:SetConsumption(ACTIONS.HAMMER, 2)
    
    inst:AddComponent("repairable")
    inst.components.repairable.onrepaired = OnRepaired
    inst.components.repairable.repairmaterial = MATERIALS.GEARS
    inst.components.repairable:SetFiniteUsesRepairable(true)
end



local function commonfn2(inst)
    inst:AddTag("locomote_atk")
    inst:AddTag("blocker_immune")

    inst:AddComponent("aoetargeting")
    inst.components.aoetargeting:SetAlwaysValid(true)
    inst.components.aoetargeting.reticule.reticuleprefab = "reticuleline"
    inst.components.aoetargeting.reticule.pingprefab = "reticulelineping"
    inst.components.aoetargeting.reticule.targetfn = Lightning_ReticuleTargetFn
    inst.components.aoetargeting.reticule.mousetargetfn = Lightning_ReticuleMouseTargetFn
    inst.components.aoetargeting.reticule.updatepositionfn = Lightning_ReticuleUpdatePositionFn
    inst.components.aoetargeting.reticule.validcolour = { 1, .75, 0, 1 }
    inst.components.aoetargeting.reticule.invalidcolour = { .5, 0, 0, 1 }
    inst.components.aoetargeting.reticule.ease = true
    inst.components.aoetargeting.reticule.mouseenabled = true
    inst.components.aoetargeting:SetShouldRepeatCastFn(function () return true end)

    
end

local function onfuelchange(newsection, oldsection, inst)
    inst.components.aoetargeting:SetEnabled(newsection>0)
end

local function postinitfn2(inst)
    inst.components.equippable:SetOnEquip(onequip2)
    inst.components.equippable:SetOnUnequip(onunequip2)
    --inst.components.equippable.walkspeedmult = 0.8

    inst:AddComponent("aoespell")
    inst.components.aoespell:SetSpellFn(DoLaserShoot)

    inst:AddComponent("fueled")
    inst.components.fueled:InitializeFuelLevel(TUNING.LASERCANNON_FUEL)
    inst.components.fueled:SetSectionCallback(onfuelchange)

    inst.components.inventoryitem:ChangeImageName("laser_generator")
end

local function MakeGun(name,common,postinit)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()
        
        MakeInventoryPhysics(inst)
        
        inst.AnimState:SetBank("living_artifact")
        inst.AnimState:SetBuild("living_artifact")
        inst.AnimState:PlayAnimation("idle")

        --inst:AddTag("supertoughworker")

        MakeInventoryFloatable(inst)

        common(inst)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end	
        
        inst:AddComponent("inspectable")

        inst:AddComponent("inventoryitem")

        inst:AddComponent("equippable")
        inst.components.equippable.equipslot = EQUIPSLOTS.HANDS

        postinit(inst)

        MakeHauntableLaunch(inst)
        
        return inst
    end
    return Prefab(name,fn,assets)
end


return MakeGun("laser_generator",commonfn1,postinitfn1),
    MakeGun("laser_cannon",commonfn2,postinitfn2)