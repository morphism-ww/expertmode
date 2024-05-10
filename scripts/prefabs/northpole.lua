local assets =
{
    Asset("ANIM", "anim/swap_northpole.zip"),
    Asset("ANIM", "anim/northpole.zip"),
    Asset("INV_IMAGE", "trident"),
    
}

local prefabs =
{
    "crab_king_waterspout",
}

local function Projectile_CreateTailFx()
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    inst.AnimState:SetBank("deer_ice_flakes")
    inst.AnimState:SetBuild("deer_ice_flakes")
    inst.AnimState:PlayAnimation("idle")

    inst:ListenForEvent("animover", inst.Remove)

    return inst
end

local function Projectile_UpdateTail(inst)
    Projectile_CreateTailFx().Transform:SetPosition(inst.Transform:GetWorldPosition())
end

local function on_equipped(inst, equipper)
    equipper.AnimState:OverrideSymbol("swap_object", "swap_northpole", "swap_northpole")
    equipper.AnimState:Show("ARM_carry")
    equipper.AnimState:Hide("ARM_normal")
    inst.triggerfx:set(true)
end

local function on_unequipped(inst, equipper)
    equipper.AnimState:Hide("ARM_carry")
    equipper.AnimState:Show("ARM_normal")
    inst.triggerfx:set(false)
    
end

local function onfinished(inst)
    inst:Remove()
end

local function OnEquipped(inst)
    if not TheNet:IsDedicated() then
        if inst.triggerfx:value() then
            if inst.fxtask==nil then
                inst.fxtask=inst:DoPeriodicTask(0.8, Projectile_UpdateTail)
            end
        else
            if inst.fxtask~=nil then
                inst.fxtask:Cancel()
                inst.fxtask=nil
            end
        end          
    end    
end

local FLOATER_SWAP_DATA = {sym_build = "swap_trident"}
local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst:AddTag("pure")
    inst:AddTag("thrown")
    inst:AddTag("sharp")
    inst:AddTag("nosteal")
    inst:AddTag("rangedweapon")

    inst.AnimState:SetBank("northpole")
    inst.AnimState:SetBuild("northpole")
    inst.AnimState:PlayAnimation("idle")


    MakeInventoryFloatable(inst, "med", 0.05, {1.1, 0.5, 1.1}, true, -9, FLOATER_SWAP_DATA)
    inst.triggerfx = net_bool(inst.GUID, "northpole.triggerfx","northpole_equip")

    if not TheNet:IsDedicated() then
        inst:ListenForEvent("northpole_equip", OnEquipped)
    end

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        
        return inst
    end

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(68)
    inst.components.weapon:SetRange(14)
    inst.components.weapon:SetProjectile("northpole_proj")

    local planardamage = inst:AddComponent("planardamage")
	planardamage:SetBaseDamage(20)


    inst:AddComponent("inspectable")
    inst.components.inspectable:SetDescription("凛冬将至")

    -------
    inst:AddComponent("inventoryitem")
    -------

    inst:AddComponent("heater")
    inst.components.heater:SetThermics(false, true)
    inst.components.heater.equippedheat = 0


    inst:AddComponent("finiteuses")
    inst.components.finiteuses:SetOnFinished(onfinished)
    inst.components.finiteuses:SetMaxUses(400)
    inst.components.finiteuses:SetUses(400)

   
    inst:AddComponent("repairable")
    inst.components.repairable.repairmaterial = MATERIALS.ICE


    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(on_equipped)
    inst.components.equippable:SetOnUnequip(on_unequipped)


    return inst
end

local function frozen_debuff(inst,target)
    if target.components.health~=nil and not target.components.health:IsDead() and target.replica.health~=nil then
        target.components.health:DoDelta(-50,true,"frozen")
    end
end

local function onhit(inst, attacker, target)
	inst.AnimState:SetOrientation(0)
	inst.AnimState:PlayAnimation("idle")
	inst:RemoveComponent("projectile")
	
	if attacker~=nil and target.components.combat~=nil and
         target.components.health~=nil and not target.components.health:IsDead() then
        
        
        inst.entity:AddFollower()
        inst.Follower:FollowSymbol(target.GUID, target.components.combat.hiteffectsymbol, 0, 0, 0 )
        inst:FacePoint(attacker.Transform:GetWorldPosition())
        SpawnPrefab("sparks"):AlignToTarget(target, inst, true)
        if target:DebuffsEnabled() then
            target:AddDebuff("northpole_frozen","frozen")
        end 
        inst.frozentask=inst:DoPeriodicTask(1,frozen_debuff,0,target)
        --inst.debufftask=inst:DoPeriodicTask(1,frozen_debuff,0,target)
        if target.components.freezable ~= nil and target:IsValid() then
            target.components.freezable:AddColdness(1)
            target.components.freezable:SpawnShatterFX()
        end
        if target.components.burnable ~= nil then
            if target.components.burnable:IsBurning() then
                target.components.burnable:Extinguish()
            elseif target.components.burnable:IsSmoldering() then
                target.components.burnable:SmotherSmolder()
            end
        end
        --[[if target.components.locomotor then
            target.components.locomotor:SetExternalSpeedMultiplier(target, "frozen", 0.6)
        end]]
        inst:DoTaskInTime(15,inst.KillFX)

        inst:ListenForEvent("minhealth",function ()
            inst:KillFX()
        end,target)
    else
        inst:Remove()    
	end
end

local function KillFX(inst)
    if inst.frozentask~=nil then
        inst.frozentask:Cancel()
        inst.frozentask=nil
    end
    inst:DoTaskInTime(0.1,inst.Remove)
end

local function projfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    MakeProjectilePhysics(inst)

    inst:AddTag("FX")
    inst:AddTag("projectile")


    inst.AnimState:SetBank("northpole")
	inst.AnimState:SetBuild("northpole")
	inst.AnimState:PlayAnimation("thrown")
    inst.AnimState:SetOrientation(1)
    inst.AnimState:SetScale(1.4,1.4,1.4)

    inst.AnimState:SetMultColour(135/255,260/255,250/255,0.4)
    inst.AnimState:SetAddColour(173/255,216/255,230/255,0.6)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("projectile")
	inst.components.projectile:SetSpeed(25)
	inst.components.projectile:SetOnHitFn(onhit)
    inst.components.projectile:SetHoming(false)
    inst.components.projectile:SetLaunchOffset(Vector3(0.5, 0.5, 2.5))
    inst.components.projectile:SetHitDist(1.5)
    inst.components.projectile:SetOnMissFn(inst.Remove)
    inst.components.projectile:SetRange(32)

    inst.SoundEmitter:PlaySound("hookline_2/creatures/boss/crabking/ice_attack")
    inst.KillFX =KillFX

    return inst
end

local function OnAttached(inst, target, followsymbol, followoffset)
    inst.entity:SetParent(target.entity)
    inst:ListenForEvent("death", function()
        inst.components.debuff:Stop()
    end, target)
    --inst.Follower:FollowSymbol(target.GUID, "headbase", 0,0,0)
    --OnChangeFollowSymbol(inst, target, followsymbol, followoffset)
    if target.components.locomotor~=nil then
        target.components.locomotor:SetExternalSpeedMultiplier(inst, "frozen", 0.5)
    end
end

local function OnExtended(inst, target,followsymbol, followoffset, data)

    inst.components.timer:StopTimer("buffover")
    inst.components.timer:StartTimer("buffover", 15)
    if target.components.locomotor~=nil then
        target.components.locomotor:SetExternalSpeedMultiplier(inst, "frozen", 0.5)
    end
end

local function OnTimerDone(inst, data)
    if data.name == "buffover" then
        inst.components.debuff:Stop()
    end
end

local function OnDetached(inst, target)
	inst:Remove()
end

local function bufffn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddFollower()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.AnimState:SetBank("deer_ice_flakes")
    inst.AnimState:SetBuild("deer_ice_flakes")
    inst.AnimState:PlayAnimation("idle",true)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetFinalOffset(1)


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetExtendedFn(OnExtended)
    inst.components.debuff:SetDetachedFn(OnDetached)
    inst:AddComponent("timer")
    inst.components.timer:StartTimer("buffover",15)
    inst:ListenForEvent("timerdone", OnTimerDone)


    return inst
end


return Prefab("northpole", fn, assets, prefabs),
    Prefab("northpole_proj", projfn, assets, prefabs),
    Prefab("frozen",bufffn)
