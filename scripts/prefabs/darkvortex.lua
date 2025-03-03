local assets = {
    Asset("ANIM", "anim/lavaarena_portal_fx.zip"),
    Asset("ANIM","anim/blackhole_projectile.zip")
}


local function CreateSwirl(s)
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false


    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()
    inst.AnimState:SetScale(3.5*s,3.5*s,3.5*s)

    inst.AnimState:SetBank("blackhole_projectile")
    inst.AnimState:SetBuild("blackhole_projectile")
    inst.AnimState:PlayAnimation("swirl",true)
    inst.AnimState:SetDeltaTimeMultiplier(0.5)
    inst.AnimState:SetLightOverride(0.3)
    inst.AnimState:SetMultColour(1, 17/255, 130/255, 1)
	
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(2)

    return inst
end

local brain = require "brains/vortexbrain"
local MUST_TAGS = {"_combat"}
local NO_TAGS = { "playerghost", "shadow", "fossil","shadowcreature", "FX", "INLIMBO", "notarget", "noattack", "flight", "invisible" }
local function OnUpdate(inst)

	local x, y, z = inst.Transform:GetWorldPosition()
	for i, v in ipairs(TheSim:FindEntities(x, y, z, 4*inst.scale, MUST_TAGS, NO_TAGS)) do
		if v.entity:IsVisible() and v.components.health~=nil and not v.components.health:IsDead() then
            v.components.health:DoDelta(-6,nil,"NIL")
            if v.components.locomotor~=nil then
                v.components.locomotor:PushTempGroundSpeedMultiplier(0.1)
            end
			if v.components.grogginess ~= nil and not v.components.grogginess:IsKnockedOut() then
                local curgrog = v.components.grogginess.grog_amount
                if curgrog < TUNING.DEER_ICE_FATIGUE then
                    v.components.grogginess:AddGrogginess(TUNING.DEER_ICE_FATIGUE)
                end
            end
            if v.components.sanity~=nil then
                v.components.sanity:DoDelta(-6)
            end
		end
	end
end    

local function SetScale(inst,s)
    inst:AddTag("large")
    inst.scale = s
    inst.AnimState:SetScale(1.5*s,1.5*s,1.5*s)
    inst.components.locomotor.walkspeed = 3
end


local function disappear(inst)
    inst:StopBrain()
    inst.sg:GoToState("disappear")
end

local delay_time = 0.5

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst,10,2)
    RemovePhysicsColliders(inst)
    inst.Physics:SetCollisionGroup(COLLISION.SANITY)
    inst.Physics:CollidesWith(COLLISION.SANITY)
	
	inst.AnimState:SetBank("lavaportal_fx")
    inst.AnimState:SetBuild("lavaarena_portal_fx")
    inst.AnimState:PlayAnimation("portal_loop",true)
    inst.AnimState:SetScale(1.5,1.5,1.5)
    inst.AnimState:SetSymbolMultColour("black",0,0,0,0.5)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetSymbolLightOverride("vortex2_loop", 0.1)
    
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
    inst.AnimState:SetLayer(LAYER_BACKGROUND)
    inst.AnimState:SetSortOrder(3)


    inst.entity:AddLight()
    inst.Light:SetIntensity(0.6)
    inst.Light:SetRadius(0)
    inst.Light:SetFalloff(0.6)
    inst.Light:Enable(false)

    
    if not TheNet:IsDedicated() then
        --[[local aura = CreateRing()
        aura.entity:SetParent(inst.entity)
	    aura.Follower:FollowSymbol(inst.GUID, "blackhole", 0, 0, 0)]]
        inst:DoTaskInTime(delay_time,function ()
            local swirl = CreateSwirl(inst:HasTag("large") and 2 or 1)
            swirl.entity:SetParent(inst.entity)
            swirl.Follower:FollowSymbol(inst.GUID, "glow", 0, 0, 0)
        end)
    end

    inst:AddTag("FX")
    inst:AddTag("notraptrigger")

    ------------------------------------------
	inst.entity:SetPristine()
	
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("knownlocations")

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.walkspeed = 1

    inst:SetStateGraph("SGdarkvortex")
    inst:SetBrain(brain)

    inst.scale = 1
    inst.SetScale = SetScale
    inst.Disappear = disappear

    inst.task = inst:DoPeriodicTaskWithTimeLimit(0.5,OnUpdate,delay_time,60,disappear)
		
    return inst
end

local function onhit(inst,attacker)
    inst.AnimState:PlayAnimation("portal_pst")
    if attacker and attacker:IsValid() 
        and attacker.components.health~=nil and not attacker.components.health:IsDead() then
        local x,y,z = inst.Transform:GetWorldPosition()
        for i, v in ipairs(TheSim:FindEntities(x, y, z, 3, MUST_TAGS, NO_TAGS)) do
            if v.entity:IsVisible() and v.components.health~=nil and not v.components.health:IsDead() then
                v.components.combat:GetAttacked(attacker,75)
                if v.components.sanity~=nil then
                    v.components.sanity:DoDelta(-10)
                end
            end
        end
    end
    inst:ListenForEvent("animover",inst.Remove)
end

local function onmiss(inst,attacker)
    if not inst.pounced and attacker and attacker:IsValid() then
        inst.pounced = true
        local pos
        if inst.target and inst.target:IsValid() then
            pos = inst.target:GetPosition()
        else
            pos = attacker:GetPosition()
        end
        inst.components.linearprojectile:SetRange(28)    
        inst.components.linearprojectile:LineShoot(pos,attacker)
    else
        inst:Remove()
    end    
    
end

local function shadowball()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeProjectilePhysics(inst)

    inst.AnimState:SetBank("lavaportal_fx")
    inst.AnimState:SetBuild("lavaarena_portal_fx")
    inst.AnimState:PlayAnimation("portal_loop",true)
    inst.AnimState:SetLightOverride(0.1)
    inst.AnimState:SetScale(0.3,0.3,0.3)

    inst:AddTag("projectile")
    inst:AddTag("FX")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("linearprojectile")
    inst.components.linearprojectile:SetHorizontalSpeed(14)
    inst.components.linearprojectile:SetRange(20)
    inst.components.linearprojectile:SetOnHit(onhit)
    inst.components.linearprojectile:SetOnMiss(onmiss)
    inst.components.linearprojectile.oneoftags = {"character","monster","animal"}
    inst.components.linearprojectile:AddNoHitTag("fossil")
    inst.components.linearprojectile:AddNoHitTag("shadowcreature")

    inst:DoTaskInTime(15,inst.Remove)

    return inst

end


return Prefab("darkvortex",fn,assets),
    Prefab("shadowball_linear",shadowball,assets)