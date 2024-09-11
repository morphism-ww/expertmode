local assets = {
    Asset("ANIM", "anim/blackhole_projectile.zip"),
}

local prefabs = {
	"nightmarefuel",
	"horrorfuel",
	"shadow_soul",
	"dark_energy_small"
}

local brain = require("brains/darkenergybrain")

SetSharedLootTable("dark_energy",
{	
	{"nightmarefuel",  	1.0},
    {"horrorfuel", 		1.0},
    {"horrorfuel", 		1.0},
    {"horrorfuel", 		0.5},
})

local function RetargetFn(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local target = inst.components.combat.target
	if target then
		local range = TUNING.SHADOWTHRALL_MOUTH_STEALTH_ATTACK_RANGE
		if target.isplayer and target:GetDistanceSqToPoint(x, y, z) < range * range then
			--Keep target
			return
		end
	end

	--V2C: WARNING: FindClosestPlayerInRange returns 2 values, which
	--              we don't want to return as our 2nd return value.  
	local player--[[, rangesq]] = FindClosestPlayerInRange(x, y, z, TUNING.SHADOWTHRALL_AGGRO_RANGE, true)
	return player
end

local function KeepTargetFn(inst, target)
	return inst.components.combat:CanTarget(target)
		and inst:IsNear(target, TUNING.SHADOWTHRALL_DEAGGRO_RANGE)
end

local function OnSave(inst,data)
	data.newborn = inst.newborn
end

local function OnLoad(inst,data)
	if data~=nil then
		inst.newborn = data.newborn
	end
end

local function IgnoreTrueDamage(inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
	return afflicter==nil and cause==nil
end


local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeCharacterPhysics(inst, 200, 1)
	RemovePhysicsColliders(inst)
	inst.Physics:SetCollisionGroup(COLLISION.SANITY)
	
	

	inst.AnimState:SetBank("blackhole_projectile")
	inst.AnimState:SetBuild("blackhole_projectile")
    inst.AnimState:PlayAnimation("idle_loop",true)  --despawn,shoot,spawn,suck,suck_pre,swirl
    inst.AnimState:SetScale(3.5,3.5,3.5)
    --inst.AnimState:SetSymbolBloom("glow")
    inst.AnimState:SetSymbolLightOverride("glow",0.3)
	inst.AnimState:SetMultColour(0.28, 0.08, 0.46, 1)

    inst.entity:AddLight()
    inst.Light:SetColour(0.28, 0.08, 0.46)
    inst.Light:SetRadius(3.0)
    inst.Light:SetFalloff(.9)
    inst.Light:SetIntensity(0.65)

    inst:AddTag("shadow_aligned")
    inst:AddTag("shadow")
    inst:AddTag("hostile")
    inst:AddTag("notraptrigger")
    inst:AddTag("flying")


	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end


	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(1000)
	inst.components.health:SetMaxDamageTakenPerHit(200)
	inst.components.health.redirect = IgnoreTrueDamage
	--inst.components.health.nofadeout = true
	--inst:ListenForEvent("healthdelta", OnHealthDelta)

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(75)
    inst.components.combat:SetRange(0.5,2.5)
    inst.components.combat:SetAttackPeriod(1.5)
    inst.components.combat:SetRetargetFunction(2, RetargetFn)
	inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
	--inst.components.combat:SetKeepTargetFunction(KeepTargetFn)

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 5
	inst.components.locomotor.runspeed = 7
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorewalls = true, allowocean = true }

    inst:AddComponent("planarentity")
	inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(30)

	inst:AddComponent("damagetyperesist")
	inst.components.damagetyperesist:AddResist("explosive", inst, 0.5, "energy_absorb")

	--inst:AddComponent("inspectable")
    inst:AddComponent("knownlocations")

	inst:AddComponent("debuffable")
	inst.components.debuffable:Enable(false)

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("dark_energy")

	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aura = -TUNING.SANITYAURA_LARGE

    inst:SetStateGraph("SGdark_energy")
    inst:SetBrain(brain)

    inst.OnSave = OnSave
	inst.OnLoad = OnLoad

	return inst
end

local function on_size_update(inst, dt)
    inst.scale = inst.scale + dt * 0.2
    inst.AnimState:SetScale(inst.scale,inst.scale,inst.scale)
    if inst.scale>=3 then
        if inst.sizeupdatetask then
            inst.sizeupdatetask:Cancel()
            inst.sizeupdatetask = nil
        end
        inst.SoundEmitter:KillSound("loop")
        inst:DoTaskInTime(0.5,function ()
            local new_inst = ReplacePrefab(inst, "dark_energy")
            new_inst.newborn = true
        end)
    end
end    

local function OnTossLanded(inst)
	inst.tossing = nil
	inst.Physics:SetMotorVel(0, 0, 0)
	inst.Physics:Stop()
	
	
end

local function Toss(inst, dist, angle)
	inst.AnimState:PlayAnimation("spawn")
	inst.AnimState:PushAnimation("idle_loop")
	inst.Physics:SetMotorVel(dist * math.cos(angle), 0, -dist * math.sin(angle))
	inst.tossing = inst:DoTaskInTime(0.5+1*math.random(), OnTossLanded)

	inst.SoundEmitter:PlaySound("rifts4/goop/minion_blob_wobble_lp", "loop")
	inst.sizeupdatetask = inst:DoPeriodicTask(1, on_size_update, nil, 1)
end

local function OnDeath(inst)
    inst.AnimState:PlayAnimation("despawn")
    inst.Physics:Stop()
    inst.SoundEmitter:PlaySound("dontstarve/sanity/creature2/die","sound_0")
    inst:AddTag("NOCLICK")
    inst.persists = false
	if inst.sizeupdatetask then
		inst.sizeupdatetask:Cancel()
		inst.sizeupdatetask = nil
	end
	inst:ListenForEvent("animover",inst.Remove)
end

local function smallfn()
    local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeCharacterPhysics(inst, 20, 0.5)
	RemovePhysicsColliders(inst)
	inst.Physics:SetCollisionGroup(COLLISION.SANITY)
	
	

	inst.AnimState:SetBank("blackhole_projectile")
	inst.AnimState:SetBuild("blackhole_projectile")
    inst.AnimState:PlayAnimation("idle_loop",true)  --despawn,shoot,spawn,suck,suck_pre,swirl
    inst.AnimState:SetScale(1.5,1.5,1.5)
    --inst.AnimState:SetSymbolBloom("glow")
    inst.AnimState:SetSymbolLightOverride("glow",0.3)
	inst.AnimState:SetMultColour(0.28, 0.08, 0.46, 1)

	inst:SetPrefabNameOverride("dark_energy")

	inst:AddTag("hostile")
    inst:AddTag("shadow_aligned")
    inst:AddTag("shadow")
    inst:AddTag("notraptrigger")
    inst:AddTag("flying")


	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end


	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(500)

	inst:AddComponent("combat")
	

    inst:AddComponent("planarentity")
	
	inst:AddComponent("damagetyperesist")
	inst.components.damagetyperesist:AddResist("explosive", inst, 0.5, "energy_absorb")

	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    inst.Toss = Toss
    inst.scale = 1.5
    inst:ListenForEvent("death",OnDeath)
    
    return inst
end


return Prefab("dark_energy",fn,assets,prefabs),
    Prefab("dark_energy_small",smallfn,assets)