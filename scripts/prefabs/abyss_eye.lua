local assets =
{
    Asset("ANIM", "anim/abyss_eye.zip"),
}

local function Blink(inst)
    inst.AnimState:PlayAnimation("look")
    inst.AnimState:PushAnimation("idle_loop", true)
    inst.blinktask = inst:DoTaskInTime(1.5 + math.random(), Blink)
end

local function Disappear(inst)
    if inst.blinktask ~= nil then
        inst.blinktask:Cancel()
        inst.blinktask = nil
    end
    if inst.deathtask ~= nil then
        inst.deathtask:Cancel()
        inst.deathtask = nil
        inst.AnimState:PlayAnimation("escape_pre")
        inst.AnimState:PushAnimation("escape_loop",false)
        inst.AnimState:PushAnimation("escape_pst",false)
        inst:ListenForEvent("animqueueover", inst.Remove)
    end
end

local function OnInit(inst)
    if inst:IsInLight() then
        inst:Remove()
    else
        inst.entity:Show()
    end
end

local function SetTarget(inst,target)
    inst:RemoveComponent("playerprox")
    inst:DoTaskInTime(3,function ()
        if target~=nil and target:IsValid() then
            local x, y, z = inst.Transform:GetWorldPosition()
            local laser = SpawnPrefab("darkball_projectile")
            
            target.Physics:Stop()
            
            laser.components.projectile:SetSpeed(40)
            laser.components.projectile:SetHoming(true)
            laser.Transform:SetPosition(x,y,z)
            laser.components.projectile:Throw(inst, target, inst)
        end
    end)
    inst:DoTaskInTime(6,function ()
        Disappear(inst)
    end)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst:AddTag("NOCLICK")
    
    inst.entity:SetCanSleep(false)
    
    --inst.entity:AddLightWatcher()

    --inst.LightWatcher:SetLightThresh(.2)
    --inst.LightWatcher:SetDarkThresh(.19)
    --inst:ListenForEvent("enterlight", inst.Remove)

    --inst.animname = tostring(math.random(3))
    inst.AnimState:SetBank("abyss_eye")
    inst.AnimState:SetBuild("abyss_eye")
    inst.AnimState:SetLightOverride(0.5)
    inst.AnimState:SetMultColour(1,0,1,1)
    inst.AnimState:PlayAnimation("spawn")
    inst.AnimState:PushAnimation("idle_loop", true)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("combat")

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(3, 5)
    inst.components.playerprox:SetOnPlayerNear(Disappear)

    inst.blinktask = inst:DoTaskInTime(1 + 2*math.random(), Blink)
    inst.deathtask = inst:DoTaskInTime(10 + 5 * math.random(), Disappear)

    inst:AddComponent("truedamage")
    inst.components.truedamage:SetBaseDamage(1000)

    inst.SetTarget = SetTarget
    

    return inst
end

return Prefab("abyss_eye", fn, assets)
