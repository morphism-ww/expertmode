local RuinsRespawner = require "prefabs/ruinsrespawner"
local assets =
{
    Asset("ANIM", "anim/eyeball_turret.zip"),
    Asset("ANIM", "anim/eyeball_turret_object.zip"),
    Asset("ANIM", "anim/staff_purple_base.zip"),
}

local prefabs =
{
    "eye_charge",
    "shadoweyeturret_base",
}


local brain = require "brains/eyeturretbrain"

--[[local GEMCOLOUR = {
    green = #2F992F,
    red = #972A2A,
    yellow = #E9D044,
    purple = #682279,
    orange = "#CC8237",
    blue = "#2C509C"
}]]
local GEMCOLOUR = {
    red = {1,0,0,1},
    blue = {0,0,1,1},
    purple = {128/255,0,128/255,1},
    yellow = {1,1,0,1},
    orange = {1,165/255,0,1},
    green = {0,128/255,0,1}
}    

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

local no_aggro_tags = {"chess","shadowthrall"}

local function retargetfn(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local target = inst.components.combat.target
    if target ~= nil then
		local range = 8 + target:GetPhysicsRadius(0)
		if target:HasTag("player") and target:GetDistanceSqToPoint(x, y, z) < range * range then
			--Keep target
			return
		end
	end
    local player--[[, rangesq]] = FindClosestPlayerInRangeSq(x, y, z, inst.targetdsq, true)
	return player
end

local function shouldKeepTarget(inst, target)
    return not target:HasTag("shadow_aligned")
        and inst:IsNear(target, 26)
end

local function ShareTargetFn(dude)
    return dude:HasTag("chess")
end

local function OnAttacked(inst, data)
    local attacker = data ~= nil and data.attacker or nil
    if attacker ~= nil then
        inst.components.combat:SuggestTarget(attacker)
        inst.components.combat:ShareTarget(attacker, 30, ShareTargetFn, 8)
    end
end

local states = {
    red = function (inst,target,damageredirecttarget)
        if target.components.temperature ~= nil then
            target.components.temperature:DoDelta(50)
        end
        if damageredirecttarget~=nil then
            return
        end
        if target.components.burnable ~= nil and not target.components.burnable:IsBurning() then
            if target.components.burnable.canlight or target.components.combat ~= nil then
                target.components.burnable:Ignite(true, inst)
            end
        end   
    end,
    blue = function (inst,target,damageredirecttarget)
        if target.components.temperature ~= nil then
            target.components.temperature:DoDelta(-50)
        end
        if damageredirecttarget~=nil then
            return
        end 
        if target.components.freezable~=nil then
            target.components.freezable:AddColdness(3,3)
        end
        if target.components.grogginess ~= nil then
            target.components.grogginess:AddGrogginess(TUNING.DEER_ICE_FATIGUE)
        end
    end,
    purple = function (inst,target,damageredirecttarget)
        if damageredirecttarget==nil and target.components.sanity~=nil then
            target.components.sanity:DoDelta(-30)
        end        
    end,
    yellow = function (inst,target)
        if target.isplayer then
            target:ScreenFade(false,0.5)
            target:DoTaskInTime(2,function (inst2)
                inst2:ScreenFade(true, 1)
            end)
        elseif target.components.hauntable ~= nil and target.components.hauntable.panicable then
            target.components.hauntable:Panic(15)
        end
    end,
    orange = function (inst,target,damageredirecttarget)
        target:PushEvent("knockback", { knocker = inst, radius = 6,strengthmult = 2})
    end,
    green = function (inst,target,damageredirecttarget)
        local break_target = damageredirecttarget or target
        if break_target.components.finiteuses~=nil then
            break_target.components.finiteuses:Use(30)
        elseif break_target.components.inventory~=nil then
            break_target.components.inventory:ApplyDamage(300,inst)
        elseif break_target.components.workable~=nil or break_target.prefab == "bernie_big" then
            break_target.components.health:Kill()
        end
    end
}

local function gemmagic(inst,target,damage, stimuli, weapon, damageresolved,spdamage, damageredirecttarget)
   local gem = inst.colours[inst.gemindex]
   if target:IsValid() and target.components.health~=nil and not target.components.health:IsDead() then
        states[gem](inst,target,damageredirecttarget)
   end
end


local function EquipWeapon(inst)
    if inst.components.inventory and not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
        local weapon = CreateEntity()
        --[[Non-networked entity]]
        weapon.persists = false

        weapon.entity:AddTransform()
        weapon:AddComponent("weapon")
        weapon.components.weapon:SetDamage(inst.components.combat.defaultdamage)
        weapon.components.weapon:SetRange(inst.components.combat.attackrange, inst.components.combat.attackrange+4)
        weapon.components.weapon:SetProjectile("eye_charge")

        weapon:AddComponent("inventoryitem")
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


local function changegem(inst)
    inst.gemindex = (inst.gemindex + 1) % 3 + 1
    local gem = inst.colours[inst.gemindex]
    inst.AnimState:SetMultColour(unpack(GEMCOLOUR[gem]))    
end

local GEM_TYPES = {
    {"orange","red","yellow"},
    {"blue","purple","yellow"},
    {"orange","purple","yellow"},
    {"green","orange","red"},
    {"green","blue","purple"},
    {"green","yellow","orange"},
}

local function onsave(inst, data)
    data.gemindex = inst.gemindex
    data.typeid = inst._typeid
end

local function onload(inst,data)
    if data~=nil then
        inst.gemindex = data.gemindex
    end
end

local function onloadpostpass(inst,data)
    local typeid = data.typeid or 1
    inst._typeid = typeid
    inst.colours = GEM_TYPES[typeid]
    for k,v in ipairs(inst.colours) do
        table.insert(inst.components.lootdropper.loot,v.."gem")
    end
end

local function OnDeath(inst)
    for k, v in pairs(inst.components.objectspawner.objects) do
        v:Remove()
    end
end

---------------------------------------------------------------------
--[[
local Firestorm = {"orange","red","yellow"}
local Frostfall = {"blue","purple","yellow"}

local Chaos = {"orange","purple","yellow"}
local Shatter = {"green","orange","red"}
local Frostbite = {"green","blue","purple"}

]]





local function CommonFn(upgrade)
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
    inst:AddTag("shadow_aligned")
    inst:AddTag("laser_immune")

    inst.AnimState:SetBank("eyeball_turret")
    inst.AnimState:SetBuild("eyeball_turret")
    inst.AnimState:PlayAnimation("idle_loop")

    inst.Light:SetRadius(0)
    inst.Light:SetIntensity(.65)
    inst.Light:SetFalloff(.7)
    inst.Light:SetColour(251/255, 234/255, 234/255)
    inst.Light:Enable(false)
    inst.Light:EnableClientModulation(true)

    inst._lightframe = net_smallbyte(inst.GUID, "shadoweyeturret._lightframe", "lightdirty")
    inst._lighttask = nil


    inst:SetPrefabNameOverride("shadoweyeturret")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("lightdirty", OnLightDirty)
        return inst
    end
    

    inst.base = SpawnPrefab("shadoweyeturret_base")
    inst.base.entity:SetParent(inst.entity)
    inst.highlightchildren = { inst.base }


    inst.syncanim = syncanim
    inst.syncanimpush = syncanimpush

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.EYETURRET_HEALTH2)
    inst.components.health:StartRegen(TUNING.EYETURRET_REGEN, 1)

    inst.targetdsq = upgrade and 400 or 36

    inst:AddComponent("combat")
    inst.components.combat:SetRange(upgrade and 24 or 14)
    inst.components.combat:SetDefaultDamage(TUNING.EYETURRET_DAMAGE2)
    inst.components.combat:SetAttackPeriod(3)
    inst.components.combat:SetRetargetFunction(1, retargetfn)
    inst.components.combat:SetKeepTargetFunction(shouldKeepTarget)
    inst.components.combat.onhitotherfn = gemmagic
    inst.components.combat:SetNoAggroTags(no_aggro_tags)

    
    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_LARGE

    local lootdropper = inst:AddComponent("lootdropper")
    lootdropper:SetLoot({"thulecite","thulecite","thulecite"})
    lootdropper:AddChanceLoot("minotaurhorn",0.1)
    

    inst.OnSave = onsave
    inst.OnLoad = onload
    inst.OnLoadPostPass = onloadpostpass
    inst.triggerlight = triggerlight

    inst:AddComponent("objectspawner")

    MakeLargeFreezableCharacter(inst)

    MakeHauntableFreeze(inst)


    --init will be override by spanwer
    inst._typeid = 1
    inst.colours = GEM_TYPES[1]
    inst.gemindex = 1

    inst:AddComponent("inventory")

    inst:SetStateGraph("SGeyeturret")
    inst:SetBrain(brain)

    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("attacked", OnAttacked)
    inst:DoPeriodicTask(15,changegem,5*math.random())

    inst:DoTaskInTime(0,EquipWeapon)

    return inst
end



local function Randomfn()
    return CommonFn()
end

local function Randomfn2()
	return CommonFn(true)
end


local baseassets =
{
    Asset("ANIM", "anim/eyeball_turret_base.zip"),
}

local function OnEntityReplicated(inst)
    local parent = inst.entity:GetParent()
    if parent ~= nil and parent.nameoverride == "shadoweyeturret" then
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
    inst.AnimState:SetMultColour(85/255,26/255,139/255,1)

    inst.entity:SetPristine()

	inst:AddTag("DECOR")

    if not TheWorld.ismastersim then
        inst.OnEntityReplicated = OnEntityReplicated
        return inst
    end

    return inst
end

local telebase_parts =
{
    {  x = -1.6, z = -1.6},
    {  x =  2.7, z = -0.8},
    {  x = -0.8, z =  2.7},
}

local function SpawnGemBase(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local rot = (45 - inst.Transform:GetRotation()) * DEGREES
    local sin_rot = math.sin(rot)
    local cos_rot = math.cos(rot)
    for i, v in ipairs(telebase_parts) do
        local part = inst.components.objectspawner:SpawnObject(inst.colours[i].."gembase")
        part.Transform:SetPosition(x + v.x * cos_rot - v.z * sin_rot, 0, z + v.z * cos_rot + v.x * sin_rot)
    end
end


local function onrespawnfn(inst)
    inst._typeid = math.random(1,3)
    inst.colours = GEM_TYPES[inst._typeid]
    SpawnGemBase(inst)
end

local function onrespawnfn2(inst)
    inst._typeid = math.random(2,6)
    inst.colours = GEM_TYPES[inst._typeid]
    SpawnGemBase(inst)
end


local socketassets=
{
    Asset("ANIM", "anim/staff_purple_base.zip"),
}

local function MakeGemBase(type)
    local function fn()
        local inst = CreateEntity()
    
        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddNetwork()
        inst.AnimState:SetBank("staff_purple_base")
        inst.AnimState:SetBuild("staff_purple_base")
        inst.AnimState:PlayAnimation("idle_full_loop",true)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
        inst.AnimState:OverrideSymbol("gem","gems","swap_"..type.."gem")
    
        inst:AddTag("DECOR")
    
        return inst
    end
    return Prefab(type.."gembase",fn,socketassets)
end

return Prefab("shadoweyeturret", Randomfn, assets, prefabs),
    Prefab("shadoweyeturret2", Randomfn2, assets, prefabs),
    Prefab("shadoweyeturret_base", basefn, baseassets),
    MakeGemBase("green"),
    MakeGemBase("blue"),
    MakeGemBase("purple"),
    MakeGemBase("yellow"),
    MakeGemBase("red"),
    MakeGemBase("orange"),
    RuinsRespawner.Inst("shadoweyeturret",onrespawnfn), RuinsRespawner.WorldGen("shadoweyeturret",onrespawnfn),
    RuinsRespawner.Inst("shadoweyeturret2",onrespawnfn2), RuinsRespawner.WorldGen("shadoweyeturret2",onrespawnfn2)
