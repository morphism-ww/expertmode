local function fxfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    

    inst.AnimState:SetBank("fireball_fx")
    inst.AnimState:SetBuild("deer_fire_charge")
    inst.AnimState:PlayAnimation("blast")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetMultColour(139/255, 0, 0, 1)
    inst.AnimState:SetScale(2,2,2)
    inst.AnimState:SetFinalOffset(-1)

    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    --inst:AddComponent("scaler")
    

    inst:ListenForEvent("animover", inst.Remove)


    return inst
end


local skullassets = 
{
	Asset("ANIM", "anim/skulls.zip"),
}
local notags = {"FX", "INLIMBO","playerghost","invisible", "notarget", "noattack","calamita" }
local musttag = {"_combat","_health"}
local function CheckForHit(inst,dt)
    inst.life = inst.life + dt
    if inst.life<6 then
        inst.speed = inst.speed + dt*inst.speedrate 
        inst.Physics:SetMotorVel(inst.speed,0,0)
        local x,y,z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, 0, z, 1, musttag, notags)
        for _,v in ipairs(ents) do
            -- The owner/attacker is not a valid target.
            if v.entity:IsValid() and v.components.health~=nil and not v.components.health:IsDead() then
                v:AddDebuff("buff_vulnerability_hex","buff_vulnerability_hex")
                v.components.combat:GetAttacked(inst,200,nil,nil,{["planar"] = 40})
                inst:RemoveComponent("updatelooper")
                inst:Remove()
                return
            end
        end
    else
        inst:RemoveComponent("updatelooper")
        inst:Remove()
    end    
end

local function Trigger(inst,rot)
    inst.components.spawnfader:FadeIn()
    inst.Transform:SetRotation(rot)
    inst.speedrate = 2+2*math.random()
    inst.speed = 7 + inst.speedrate
    inst.Physics:SetMotorVel(inst.speed,0,0)
    inst.Physics:ClearCollidesWith(COLLISION.LIMITS)
    inst:AddTag("activeprojectile")
    inst.life = 0
    inst:DoTaskInTime(0.5,function (inst)
        inst:AddComponent("updatelooper")
        inst.components.updatelooper:AddOnUpdateFn(CheckForHit)
    end)
end

local function OnHit(inst,attacker,target)
    if target:IsValid() and target.components.health~=nil and not target.components.health:IsDead() then
        target:AddDebuff("buff_vulnerability_hex","buff_vulnerability_hex")
    end
    inst:Remove()
end


local function skullfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
	MakeProjectilePhysics(inst)

	inst.AnimState:SetBank("skulls")
	inst.AnimState:SetBuild("skulls")
	inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetAddColour(139/255, 0, 0, 1)
    inst.AnimState:SetMultColour(138/255,32/255,48/255,1)
    inst.AnimState:SetLightOverride(0.2)
    inst.AnimState:SetScale(2,2,2)

    inst.entity:AddLight()
    inst.Light:SetIntensity(.6)
    inst.Light:SetRadius(2)
    inst.Light:SetFalloff(0.9)
    inst.Light:SetColour(139/255,0,0)

    inst:AddTag("projectile")

	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.persists = false

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(200)

    --inst.components.weapon:SetOnAttack(OnHit)
    
    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(30)
    inst.components.projectile:SetRange(35)
    inst.components.projectile:SetHitDist(1)
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:SetOnMissFn(inst.Remove)
    inst.components.projectile:SetHoming(false)
	
    inst:AddComponent("spawnfader")

    inst.Trigger = Trigger
    

	return inst
end


return Prefab("brimstone_blast_fx",fxfn),
    Prefab("hellblasts",skullfn,skullassets)