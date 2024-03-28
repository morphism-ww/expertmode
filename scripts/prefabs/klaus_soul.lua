local assets =
{
    Asset("ANIM", "anim/wortox_soul_ball.zip"),
    Asset("SCRIPT", "scripts/prefabs/wortox_soul_common.lua"),
}

local prefabs =
{
    "wortox_soul_heal_fx",
}

local SCALE = .8

local function DoHeal(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z,16)
    for i, v in ipairs(ents) do
        if  v.prefab=="klaus" and
            not (v.components.health~=nil and v.components.health:IsDead()) then
            -- NOTES(JBK): If the target is hurt put them on the list to do heals.
            if v.components.health:IsHurt() then -- Wanda tag.
                v.components.health:DoDelta(80, nil, inst.prefab)
                local fx = SpawnPrefab("wortox_soul_heal_fx")
                fx.entity:AddFollower():FollowSymbol(v.GUID, v.components.combat.hiteffectsymbol, 0, -50, 0)
                fx:Setup(v)
                v.soulcount=v.soulcount+1
            end
        end
    end
end
local function Maxhealer(inst,target)
    target.components.health:DeltaPenalty(-0.75)
end

local function demonfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.AnimState:SetBank("wortox_soul_ball")
    inst.AnimState:SetBuild("wortox_soul_ball")
    inst.AnimState:PlayAnimation("idle_loop", true)
    inst.AnimState:SetScale(SCALE, SCALE)

    inst:AddTag("nosteal")



    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

	inst:AddComponent("waterproofer")
	inst.components.waterproofer:SetEffectiveness(0)


    inst:AddComponent("inventoryitem")
    
    inst:AddComponent("healer")
    inst.components.healer:SetHealthAmount(150)
    inst.components.healer.onhealfn=Maxhealer

    return inst
end


local SPEED = 10

local function CreateTail()
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()

    MakeInventoryPhysics(inst)
    inst.Physics:ClearCollisionMask()

    inst.AnimState:SetBank("wortox_soul_ball")
    inst.AnimState:SetBuild("wortox_soul_ball")
    inst.AnimState:PlayAnimation("disappear")
    inst.AnimState:SetScale(SCALE, SCALE)
    inst.AnimState:SetFinalOffset(3)

    inst:ListenForEvent("animover", inst.Remove)

    return inst
end

local function OnUpdateProjectileTail(inst)--, dt)
    local x, y, z = inst.Transform:GetWorldPosition()
    for tail, _ in pairs(inst._tails) do
        tail:ForceFacePoint(x, y, z)
    end
    if inst.entity:IsVisible() then
        local tail = CreateTail()
        local rot = inst.Transform:GetRotation()
        tail.Transform:SetRotation(rot)
        rot = rot * DEGREES
        local offsangle = math.random() * 2 * PI
        local offsradius = (math.random() * .2 + .2) * SCALE
        local hoffset = math.cos(offsangle) * offsradius
        local voffset = math.sin(offsangle) * offsradius
        tail.Transform:SetPosition(x + math.sin(rot) * hoffset, y + voffset, z + math.cos(rot) * hoffset)
        tail.Physics:SetMotorVel(SPEED * (.2 + math.random() * .3), 0, 0)
        inst._tails[tail] = true
        inst:ListenForEvent("onremove", function(tail) inst._tails[tail] = nil end, tail)
        tail:ListenForEvent("onremove", function(inst)
            tail.Transform:SetRotation(tail.Transform:GetRotation() + math.random() * 30 - 15)
        end, inst)
    end
end

local function OnHit(inst, attacker, target)
    if target ~= nil then
        local x, y, z = inst.Transform:GetWorldPosition()
        local fx = SpawnPrefab("wortox_soul_in_fx")
        fx.Transform:SetPosition(x, y, z)
        fx:Setup(target)
        DoHeal(inst)
    end
    inst:DoTaskInTime(0.2,inst.Remove)
end

local function OnHasTailDirty(inst)
    if inst._hastail:value() and inst._tails == nil then
        inst._tails = {}
        if inst.components.updatelooper == nil then
            inst:AddComponent("updatelooper")
        end
        inst.components.updatelooper:AddOnUpdateFn(OnUpdateProjectileTail)
    end
end

local function OnThrownTimeout(inst)
    inst._timeouttask = nil
    inst.components.projectile:Miss(inst.components.projectile.target)
end

local function OnThrown(inst)
    if inst._timeouttask ~= nil then
        inst._timeouttask:Cancel()
    end
    inst._timeouttask = inst:DoTaskInTime(6, OnThrownTimeout)
    if inst._seektask ~= nil then
        inst._seektask:Cancel()
        inst._seektask = nil
    end
    inst.AnimState:Hide("blob")
    inst._hastail:set(true)
    if not TheNet:IsDedicated() then
        OnHasTailDirty(inst)
    end
end

local function SeekSoulStealer(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local soulthieves
    local ents = TheSim:FindEntities(x,y,z,18)
    for i, v in ipairs(ents) do
        if  v.prefab=="klaus" and
            not (v.components.health~=nil and v.components.health:IsDead()) then
            soulthieves=v
        end
    end
    if soulthieves~=nil then
        inst.components.projectile:Throw(inst,soulthieves ,inst)
    end
end

local function OnTimeout(inst)
    inst._timeouttask = nil
    if inst._seektask ~= nil then
        inst._seektask:Cancel()
        inst._seektask = nil
    end
    inst:ListenForEvent("animover", inst.Remove)
    inst.AnimState:PlayAnimation("idle_pst")
    inst.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/spawn", nil, .5)

    DoHeal(inst)
end

local TINT = { r = 154 / 255, g = 23 / 255, b = 19 / 255 }

local function PushColour(inst, addval, multval)
    if inst.components.highlight == nil then
        inst.AnimState:SetHighlightColour(TINT.r * addval, TINT.g * addval, TINT.b * addval, 0)
        inst.AnimState:OverrideMultColour(multval, multval, multval, 1)
    else
        inst.AnimState:OverrideMultColour()
    end
end

local function PopColour(inst)
    if inst.components.highlight == nil then
        inst.AnimState:SetHighlightColour()
    end
    inst.AnimState:OverrideMultColour()
end

local function OnUpdateTargetTint(inst)--, dt)
    if inst._tinttarget:IsValid() then
		local curframe = inst.AnimState:GetCurrentAnimationFrame()
        if curframe < 15 then
            local k = curframe / 15
            k = k * k
            PushColour(inst._tinttarget, 1 - k, k)
        else
            inst.components.updatelooper:RemoveOnUpdateFn(OnUpdateTargetTint)
            inst.OnRemoveEntity = nil
            PopColour(inst._tinttarget)
        end
    else
        inst.components.updatelooper:RemoveOnUpdateFn(OnUpdateTargetTint)
        inst.OnRemoveEntity = nil
    end
end

local function OnRemoveEntity(inst)
    if inst._tinttarget:IsValid() then
        PopColour(inst._tinttarget)
    end
end

local function OnTargetDirty(inst)
    if inst._target:value() ~= nil and inst._tinttarget == nil then
        if inst.components.updatelooper == nil then
            inst:AddComponent("updatelooper")
        end
        inst.components.updatelooper:AddOnUpdateFn(OnUpdateTargetTint)
        inst._tinttarget = inst._target:value()
        inst.OnRemoveEntity = OnRemoveEntity
    end
end

local function Setup(inst, target)
    inst.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/spawn", nil, .5)
    inst._target:set(target)
    if not TheNet:IsDedicated() then
        OnTargetDirty(inst)
    end
end

local function spawnfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.AnimState:SetBank("wortox_soul_ball")
    inst.AnimState:SetBuild("wortox_soul_ball")
    inst.AnimState:PlayAnimation("idle_pre")
    inst.AnimState:SetScale(SCALE, SCALE)
    inst.AnimState:SetFinalOffset(3)

    --weapon (from weapon component) added to pristine state for optimization
    inst:AddTag("weapon")

    --projectile (from projectile component) added to pristine state for optimization
    inst:AddTag("projectile")

    inst._target = net_entity(inst.GUID, "wortox_soul._target", "targetdirty")
    inst._hastail = net_bool(inst.GUID, "wortox_soul._hastail", "hastaildirty")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        inst:ListenForEvent("targetdirty", OnTargetDirty)
        inst:ListenForEvent("hastaildirty", OnHasTailDirty)

        return inst
    end

    inst.AnimState:PushAnimation("idle_loop", true)

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(0)

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(SPEED)
    inst.components.projectile:SetHitDist(.5)
    inst.components.projectile:SetOnThrownFn(OnThrown)
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:SetOnMissFn(inst.Remove)

    inst._seektask = inst:DoPeriodicTask(.5, SeekSoulStealer, 1)
    inst._timeouttask = inst:DoTaskInTime(10, OnTimeout)

    inst.persists = false
    inst.Setup = Setup

    return inst
end




return Prefab("demon_soul", demonfn, assets, prefabs),
    Prefab("klaus_soul_spawn",spawnfn,assets,prefabs)
