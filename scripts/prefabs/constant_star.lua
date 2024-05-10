local function onmiss(inst)
    inst:Remove()
end

local function onthrown(inst)
    inst:DoTaskInTime(3,inst.Remove)
end

local function Projectile_CreateTailFx(cold)
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

    inst.AnimState:SetBank("fireball_fx")
    inst.AnimState:SetBuild("fireball_2_fx")
    inst.AnimState:PlayAnimation("disappear")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetFinalOffset(3)
    if cold then
        inst.AnimState:SetMultColour(64 / 255, 64 / 255, 208 / 255, 1)
    else
        inst.AnimState:SetMultColour(223 / 255, 208 / 255, 69 / 255, 1)
    end        

    inst:ListenForEvent("animover", inst.Remove)

    return inst
end

local function Projectile_UpdateTail(inst,cold)
    local x, y, z = inst.Transform:GetWorldPosition()
    for tail,_ in pairs(inst.tails) do
        tail:ForceFacePoint(x, y, z)
    end
    if inst.entity:IsVisible() then
        local tail = Projectile_CreateTailFx(cold)
        local rot = inst.Transform:GetRotation()
        tail.Transform:SetRotation(rot)
        rot = rot * DEGREES
        local offset = math.random() * .2 + .4
        tail.Transform:SetPosition(x - math.sin(rot) * offset, y, z - math.cos(rot) * offset)
        tail.Physics:SetMotorVel(15* (.2 + math.random() * .3), 0, 0)
        inst.tails[tail] = true
        inst:ListenForEvent("onremove", function(tail)
            inst.tails[tail] = nil
        end, tail)
        tail:ListenForEvent("onremove", function(inst)
            tail.Transform:SetRotation(tail.Transform:GetRotation() + math.random() * 30 - 15)
        end, inst)
    end
end


local function makestafflight(name, anim, colour, onhit,cold)
    local assets =
    {
        Asset("ANIM", "anim/"..anim..".zip"),
        Asset("ANIM", "anim/fireball_2_fx.zip"),
    }


    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddLight()
        inst.entity:AddNetwork()

        MakeInventoryPhysics(inst)
        RemovePhysicsColliders(inst)

        inst.Light:SetColour(unpack(colour))
        inst.Light:Enable(true)
        inst.Light:SetFalloff(0.8)
        inst.Light:SetIntensity(0.7)
        inst.Light:SetRadius(6)
        
        inst.AnimState:SetBank(anim)
        inst.AnimState:SetBuild(anim)
        inst.AnimState:PlayAnimation("idle_loop",true)
        inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

        inst:AddTag("NOCLICK")
        inst:AddTag("NOBLOCK")

        
        if not TheNet:IsDedicated() then
            inst.tails = {}

            inst:DoPeriodicTask(0, Projectile_UpdateTail,nil,cold)
        end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end
        
        inst.persists = false

        inst:AddComponent("circleprojectile")
        inst.components.circleprojectile:SetSpeed(24)
        inst.components.circleprojectile:SetHitDist(2)
        inst.components.circleprojectile:SetOnHitFn(onhit)
        inst.components.circleprojectile:SetOnMissFn(onmiss)
        inst.components.circleprojectile:SetOnThrownFn(onthrown)


        inst:AddComponent("weapon")
        inst.components.weapon:SetDamage(100)


        return inst
    end

    return Prefab(name, fn, assets)
end


local function fire_onhit(inst,owner,target)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 3, {"_combat"}, { "INLIMBO" ,"FX" ,"player"})
    for i, ent in ipairs(ents) do
        if ent ~= owner then
			ent.components.combat:GetAttacked(owner, 100, nil, nil,{["planar"] = 100})
            ent:AddDebuff("constant_fire","constantfire_buff")
        end
    end
    SpawnPrefab("bomb_lunarplant_explode_fx").Transform:SetPosition(x, y, z)
    inst:DoTaskInTime(0.1,inst.Remove)
end

local function cold_onhit(inst,owner,target)
    local health = target.components.health
    if health~=nil and not health:IsDead() then
        health:DoDelta(-0.02*health.maxhealth, nil, nil, nil, nil, true)
        target.components.combat:GetAttacked(owner,0,nil,nil,{["planar"] = 500})
        target:AddDebuff("constant_freeze","weak",{speed = 0.5,duration = 15})
        if owner~=nil and owner.components.health~=nil and not owner.components.health:IsDead() then
            owner.components.health:DoDelta(10)
        end
    end
    inst:DoTaskInTime(0.1,inst.Remove)
end



return makestafflight("constant_fire", "star_hot", { 223 / 255, 208 / 255, 69 / 255 }, fire_onhit,false),
    makestafflight("constant_light", "star_cold", { 64 / 255, 64 / 255, 208 / 255 }, cold_onhit,true)