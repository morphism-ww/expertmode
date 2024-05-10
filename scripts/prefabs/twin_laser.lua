local assets =
{
    Asset("ANIM", "anim/metal_hulk_projectile.zip"),
    Asset("SOUND", "sound/chess.fsb"),
}

local function OnHit(inst, owner, target)
    if owner and target and target.components.combat~=nil then
        target.components.combat:GetAttacked(owner,50)
    end
    inst:Remove()
end


local function OnAnimOver(inst)
    inst:DoTaskInTime(3, inst.Remove)
end

local function OnThrown(inst)
    inst:ListenForEvent("animover", OnAnimOver)
end




local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("metal_hulk_projectile")
    inst.AnimState:SetBuild("metal_hulk_projectile")
    inst.AnimState:PlayAnimation("spin_loop", true)

    --projectile (from projectile component) added to pristine state for optimization
    inst:AddTag("projectile")
    inst.Transform:SetScale(0.7,0.7,0.7)
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(36)
    inst.components.projectile:SetHoming(false)
    inst.components.projectile:SetHitDist(2)
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:SetOnMissFn(inst.Remove)
    inst.components.projectile:SetOnThrownFn(OnThrown)

    inst:AddComponent("weapon")


    return inst
end
local assets2 =
{
    Asset("ANIM", "anim/eyeball_turret_attack.zip"),
    --Asset("SOUND", "sound/eyeballturret.fsb"),
}
local AOE_RANGE = 1
local AOE_RANGE_PADDING = 2
local AOE_TARGET_MUSTHAVE_TAGS = { "_combat" }
local AOE_TARGET_CANT_TAGS = { "INLIMBO", "flight", "invisible", "notarget", "noattack", "shadow_aligned" }

local function OnHit(inst)--, attacker, target)
	inst:RemoveComponent("linearprojectile")
	
	inst.SoundEmitter:PlaySound("rifts2/thrall_wings/projectile")

	local x, y, z = inst.Transform:GetWorldPosition()
	for i, v in ipairs(TheSim:FindEntities(x, y, z, AOE_RANGE + AOE_RANGE_PADDING, AOE_TARGET_MUSTHAVE_TAGS, AOE_TARGET_CANT_TAGS)) do
		if not (inst.targets ~= nil and inst.targets[v]) and
			v:IsValid() and not v:IsInLimbo() and
			not (v.components.health ~= nil and v.components.health:IsDead())
			then
			local range = AOE_RANGE + v:GetPhysicsRadius(0)
			if v:GetDistanceSqToPoint(x, y, z) < range * range then
				local attacker = inst.owner ~= nil and inst.owner:IsValid() and inst.owner or inst
				v.components.combat:GetAttacked(attacker, 20)
				if inst.targets ~= nil then
					inst.targets[v] = true
				end
			end
		end
	end
    inst:DoTaskInTime(0.1,inst.Remove)
end
local function fn2()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    --inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("eyeball_turret_attack")
    inst.AnimState:SetBuild("eyeball_turret_attack")
    inst.AnimState:PlayAnimation("idle",true)

    --projectile (from projectile component) added to pristine state for optimization
    inst:AddTag("projectile")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("linearprojectile")
    inst.components.linearprojectile:SetHorizontalSpeed(20)
    inst.components.linearprojectile:SetOnHit(OnHit)
    inst.components.linearprojectile:SetLaunchOffset(Vector3(0,3,0))

    inst:DoTaskInTime(8,inst.Remove)
    return inst
end
return Prefab("twin_laser", fn,assets),
    Prefab("shadow_ball",fn2,assets2)