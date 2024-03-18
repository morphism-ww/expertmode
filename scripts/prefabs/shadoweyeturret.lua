local RuinsRespawner = require "prefabs/ruinsrespawner"
local assets =
{
    Asset("ANIM", "anim/eyeball_turret.zip"),
    Asset("ANIM", "anim/eyeball_turret_object.zip"),
}
local socketassets=
{
    Asset("ANIM", "anim/staff_purple_base.zip"),
}
local prefabs =
{
    "eye_charge",
    "shadoweyeturret_base",
    "purple_gembase",
    "green_gembase",
    "blue_gembase"
}

SetSharedLootTable("shadoweyeturret",
{
    {'thulecite',         1.00},
    {'thulecite',         1.00},
    {'thulecite',         1.00},
    {'greengem',         1.00},
    {'bluegem',         1.00},
    {'purplegem',         1.00},
})

local brain = require "brains/eyeturretbrain"

local MAX_LIGHT_FRAME = 24

local function OnUpdateLight(inst, dframes)
    local frame = inst._lightframe:value() + dframes
    if frame >= MAX_LIGHT_FRAME then
        inst._lightframe:set_local(MAX_LIGHT_FRAME)
        inst._lighttask:Cancel()
        inst._lighttask = nil
    else
        inst._lightframe:set_local(frame)
    end

    if frame <= 20 then
    local k = frame / 20
    --radius:    0   -> 3.5
    --intensity: .65 -> .9
    --falloff:   .7  -> .9
    inst.Light:SetRadius(3.5 * k)
    inst.Light:SetIntensity(.9 * k + .65 * (1 - k))
    inst.Light:SetFalloff(.9 * k + .7 * (1 - k))
    else
    local k = (frame - 20) / (MAX_LIGHT_FRAME - 20)
    --radius:    3.5 -> 0
    --intensity: .9  -> .65
    --falloff:   .9  -> .7
    inst.Light:SetRadius(3.5 * (1 - k))
    inst.Light:SetIntensity(.65 * k + .9 * (1 - k))
    inst.Light:SetFalloff(.7 * k + .9 * (1 - k))
    end

    if TheWorld.ismastersim then
    inst.Light:Enable(frame < MAX_LIGHT_FRAME)
    end
    end

local function OnLightDirty(inst)
    if inst._lighttask == nil then
        inst._lighttask = inst:DoPeriodicTask(FRAMES, OnUpdateLight, nil, 1)
    end
    OnUpdateLight(inst, 0)
end

local function triggerlight(inst)
    inst._lightframe:set(0)
    OnLightDirty(inst)
end

local RETARGET_MUST_TAGS = { "_combat" }
local RETARGET_CANT_TAGS = { "INLIMBO", "player", "eyeturret", "engineering" }
local function retargetfn(inst)
    local target = inst.components.combat.target
    if target ~= nil and
        target:IsValid() and
        inst:IsNear(target, TUNING.EYETURRET_RANGE + 3) then
        --keep current target
        return
    end
    for i, v in ipairs(AllPlayers) do
        if not v:HasTag("playerghost") then
            local distsq = v:GetDistanceSqToInst(inst)
                if distsq < 16 and inst.components.combat:CanTarget(v) then
                    return v
            end
        end
    end
end

local function shouldKeepTarget(inst, target)
    return target ~= nil
        and target:IsValid()
        and target.components.health ~= nil
        and not target.components.health:IsDead()
        and inst:IsNear(target, 20)
end

local function ShareTargetFn(dude)
    return dude:HasTag("shadoweyeturret") or dude:HasTag("chess")
end


local function OnAttacked(inst, data)
    local attacker = data ~= nil and data.attacker or nil
    if attacker ~= nil then
        inst.components.combat:SetTarget(attacker)
        inst.components.combat:ShareTarget(attacker, 20, ShareTargetFn, 10)
        if inst.gem=="blue" and attacker.components.freezable~=nil then
            attacker.components.freezable:AddColdness(2)
        end
    end
end

local function gemmagic(inst,owner,target)
    if target~=nil then
        if owner.gem=="purple" and target.components.sanity~=nil then
            target.components.sanity:DoDelta(-25)
        elseif owner.gem=="blue" then
            if target.components.freezable~=nil then
                target.components.freezable:AddColdness(3,3,true)
            end
            if target.components.temperature ~= nil then
                target.components.temperature:DoDelta(-20)
            end
            if target.components.grogginess ~= nil then
                target.components.grogginess:AddGrogginess(TUNING.DEER_ICE_FATIGUE)
            end
        elseif owner.gem=="green" then
            if target.components.inventory~=nil then
                target.components.inventory:ApplyDamage(300,owner)
            end
            if target.prefab=="bernie_big" or target:HasTag("rocky") then
                target.components.health:Kill()
            end
        end
    end
end


local function EquipWeapon(inst)
    if inst.components.inventory and not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
        local weapon = CreateEntity()
        --[[Non-networked entity]]
        weapon.entity:AddTransform()
        weapon:AddComponent("weapon")
        weapon.components.weapon:SetDamage(inst.components.combat.defaultdamage)
        weapon.components.weapon:SetRange(inst.components.combat.attackrange, inst.components.combat.attackrange+4)
        weapon.components.weapon:SetProjectile("eye_charge")
        weapon.components.weapon.onattack=gemmagic
        weapon:AddComponent("inventoryitem")
        weapon.persists = false
        weapon.components.inventoryitem:SetOnDroppedFn(weapon.Remove)
        weapon:AddComponent("equippable")

        inst.components.inventory:Equip(weapon)
    end
end


local function syncanim(inst, animname, loop)
    inst.AnimState:PlayAnimation(animname, loop)
    inst.base.AnimState:PlayAnimation(animname, loop)
end

local function syncanimpush(inst, animname, loop)
    inst.AnimState:PushAnimation(animname, loop)
    inst.base.AnimState:PushAnimation(animname, loop)
end

local telebase_parts =
{
    {  x = -1.6, z = -1.6 ,type="purple_gembase"},
    {  x =  2.7, z = -0.8 ,type="blue_gembase"},
    {  x = -0.8, z =  2.7 ,type="green_gembase"},
}

local function spawngembase(inst)
    if #inst.components.objectspawner.objects>0 then
        return
    end
    local x, y, z = inst.Transform:GetWorldPosition()
    local rot = (45 - inst.Transform:GetRotation()) * DEGREES
    local sin_rot = math.sin(rot)
    local cos_rot = math.cos(rot)
    for i, v in ipairs(telebase_parts) do
        local part =inst.components.objectspawner:SpawnObject(v.type)
        part.Transform:SetPosition(x + v.x * cos_rot - v.z * sin_rot, 0, z + v.z * cos_rot + v.x * sin_rot)
    end
end


local function choosegem(inst)
    if inst.gem=="purple" then
        inst.gem="green"
        inst.AnimState:SetMultColour(0,139/255,0,0.8)
    elseif inst.gem=="green" then
        inst.gem="blue"
        inst.AnimState:SetMultColour(0,0,1,0.8)
    else
        inst.gem="purple"
        inst.AnimState:SetMultColour(72/255,61/255,139/255,0.8)
    end
end

local function onsave(inst, data)
    data.gem=inst.gem
end

local function onload(inst,data)
    inst.gem=data.gem
end

local function OnDeath(inst)
    for k, v in pairs(inst.components.objectspawner.objects) do
        v:Remove()
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    MakeObstaclePhysics(inst, 1)

    inst.Transform:SetFourFaced()

    inst:AddTag("hostile")
    inst:AddTag("shadoweyeturret")
    inst:AddTag("chess")
    inst:AddTag("cavedweller")

    inst.AnimState:SetBank("eyeball_turret")
    inst.AnimState:SetBuild("eyeball_turret")
    inst.AnimState:PlayAnimation("idle_loop")

    inst.Light:SetRadius(0)
    inst.Light:SetIntensity(.65)
    inst.Light:SetFalloff(.7)
    inst.Light:SetColour(251/255, 234/255, 234/255)
    inst.Light:Enable(false)
    inst.Light:EnableClientModulation(true)

    inst._lightframe = net_smallbyte(inst.GUID, "eyeturret._lightframe", "lightdirty")
    inst._lighttask = nil

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("lightdirty", OnLightDirty)

        return inst
    end

    inst.gem="purple"
    inst.base = SpawnPrefab("shadoweyeturret_base")
    inst.base.entity:SetParent(inst.entity)
    inst.highlightchildren = { inst.base }

    inst:AddComponent("objectspawner")

    inst.syncanim = syncanim
    inst.syncanimpush = syncanimpush

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(2000)
    inst.components.health:StartRegen(TUNING.EYETURRET_REGEN, 1)
    inst.components.health.fire_damage_scale = 0

    inst:AddComponent("damagetyperesist")
    inst.components.damagetyperesist:AddResist("explosive", inst, 0)
    inst.components.damagetyperesist:AddResist("projectile", inst, 0.2)

    inst:AddComponent("combat")
    inst.components.combat:SetRange(16)
    inst.components.combat:SetDefaultDamage(75)
    inst.components.combat:SetAttackPeriod(2)
    inst.components.combat:SetRetargetFunction(1, retargetfn)
    inst.components.combat:SetKeepTargetFunction(shouldKeepTarget)
    inst.components.combat.onhitotherfn=gemmagic


    inst:AddComponent("entitytracker")

    inst.triggerlight = triggerlight

    MakeLargeFreezableCharacter(inst)
    inst:AddComponent("inventory")
    inst:DoTaskInTime(1, EquipWeapon)

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_LARGE


    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("shadoweyeturret")
    inst.components.lootdropper.droprecipeloot = false

    inst:ListenForEvent("attacked", OnAttacked)

    inst:SetStateGraph("SGeyeturret")
    inst:SetBrain(brain)
    inst:DoTaskInTime(0.1,spawngembase)
    inst:DoPeriodicTask(10,function() choosegem(inst) end)

    inst:ListenForEvent("death", OnDeath)

    inst.OnSave=onsave
    inst.OnLoad=onload

    return inst
end

local baseassets =
{
    Asset("ANIM", "anim/eyeball_turret_base.zip"),
}

local function OnEntityReplicated(inst)
    local parent = inst.entity:GetParent()
    if parent ~= nil and parent.prefab == "shadoweyeturret" then
        parent.highlightchildren = { inst }
    end
end

local function basefn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("eyeball_turret_base")
    inst.AnimState:SetBuild("eyeball_turret_base")
    inst.AnimState:PlayAnimation("idle_loop")
    inst.AnimState:SetAddColour(85/255,26/255,139/255,0.8)

    inst.entity:SetPristine()

	inst:AddTag("DECOR")

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = OnEntityReplicated
        return inst
    end

    return inst
end

local function commonfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("staff_purple_base")
    inst.AnimState:SetBuild("staff_purple_base")
    inst.AnimState:PlayAnimation("idle_full_loop",true)

    inst:AddTag("NOCLICK")
    inst:AddTag("DECOR")


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    return inst
end
local function greenfn()
    local inst=commonfn()
    inst.AnimState:OverrideSymbol("gem","gems","swap_greengem")
    return inst
end
local function bluefn()
    local inst=commonfn()
    inst.AnimState:OverrideSymbol("gem","gems","swap_bluegem")
    return inst
end


return Prefab("shadoweyeturret", fn, assets, prefabs),
    Prefab("shadoweyeturret_base", basefn, baseassets),
    Prefab("purple_gembase",commonfn, socketassets),
    Prefab("green_gembase",greenfn, socketassets),
    Prefab("blue_gembase",bluefn, socketassets),
RuinsRespawner.Inst("shadoweyeturret"), RuinsRespawner.WorldGen("shadoweyeturret")
