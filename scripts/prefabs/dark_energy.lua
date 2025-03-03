local RuinsRespawner = require "prefabs/ruinsrespawner"
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
    {"nightmarefuel", 	1.0},
    {"horrorfuel", 		1.0},
    {"horrorfuel", 		0.5},
})

local function RetargetFn(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local target = inst.components.combat.target
	if target then
		
		if target.isplayer and target:GetDistanceSqToPoint(x, y, z) < 10 * 10 then
			--Keep target
			return
		end
	end

	--V2C: WARNING: FindClosestPlayerInRange returns 2 values, which
	--              we don't want to return as our 2nd return value.  
	local player = FindClosestPlayerInRange(x, y, z, 20, true)
	return player
end



local function KeepTargetFn(inst, target)
	return inst.components.combat:CanTarget(target)
		and inst:IsNear(target, 25)
end

local function OnSave(inst,data)
	if inst.newborn then
		data.newborn = inst.newborn
	end
end

local function OnLoad(inst,data)
	if data~=nil then
		inst.newborn = data.newborn
	end
end

local function BreakSanity(inst,target)
	if target:IsValid() and target.components.sanity~=nil then
		target.components.sanity:GetSoulAttacked(inst, 15)
	end
end


local function OnAttacked(inst, data)
	if data.attacker ~= nil then
		local target = inst.components.combat.target
		if not (target ~= nil and
				target:HasTag("player") and
				inst:IsNear(target, 8 + target:GetPhysicsRadius(0))) then
			--
			inst.components.combat:SetTarget(data.attacker)
		end
	end
end

local function areacheckhit(target,inst)
	return not target:HasTag("shadow_aligned")
end

local function OnEnterDark(inst)
	--inst.entity:AddTag("INLIMBO")
    --inst.entity:SetInLimbo(true)
    --inst.inlimbo = true
	
	inst:AddTag("notarget")
	inst.components.health:SetInvincible(true)


	inst._fade:set(true)			
    --inst.entity:Hide()
end

local function OnEnterLight(inst)
	--inst.entity:RemoveTag("INLIMBO")
    --inst.entity:SetInLimbo(false)
    --inst.inlimbo = false
	inst:RemoveTag("notarget")
	inst.components.health:SetInvincible(false)

	inst._fade:set(false)
	
    --inst.entity:Show()
end


local function OnFadeDirty(inst)
	if inst._fade:value() then
		if inst.fadeintask~=nil then
			inst.fadeintask:Cancel()
			inst.fadeintask = nil
		end
		if inst.fadeouttask~=nil then
			inst.fadeouttask:Cancel()
			inst.fadeouttask = nil
		end
		if inst.override_a>0.2 then
			inst.fadeouttask = inst:DoPeriodicTaskWithLimit(0.1,function (inst2)
				inst2.override_a = math.max(inst2.override_a - 0.1,0)
				inst2.AnimState:OverrideMultColour(0.28, 0.08, 0.46,inst2.override_a)

			end,nil,10)
		else
			inst.AnimState:OverrideMultColour(0.28, 0.08, 0.46,0)
		end
	else
		if inst.fadeintask~=nil then
			inst.fadeintask:Cancel()
			inst.fadeintask = nil
		end
		if inst.fadeouttask~=nil then
			inst.fadeouttask:Cancel()
			inst.fadeouttask = nil
		end
		if inst.override_a<0.8 then
			inst.fadeintask = inst:DoPeriodicTaskWithLimit(0.1,function (inst2)
				inst2.override_a = math.min(inst2.override_a + 0.1,1)
				inst2.AnimState:OverrideMultColour(0.28, 0.08, 0.46,inst2.override_a)
			end,nil,10)
		else
			inst.AnimState:OverrideMultColour()
		end
	end
end

local function InitLightWatcher(inst)
	if not inst.LightWatcher:IsInLight() then
		inst._fade:set_local(true)	
		OnEnterDark(inst)
	end
	inst:ListenForEvent("enterlight",OnEnterLight)
	inst:ListenForEvent("enterdark",OnEnterDark)
end



local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.entity:AddLightWatcher()
	inst.LightWatcher:SetLightThresh(.4)
    inst.LightWatcher:SetDarkThresh(.2)

	MakeGhostPhysics(inst, 200, 1)
	RemovePhysicsColliders(inst)
	
	
	inst.AnimState:SetBank("blackhole_projectile")
	inst.AnimState:SetBuild("blackhole_projectile")
    inst.AnimState:PlayAnimation("idle_loop",true)  --despawn,shoot,spawn,suck,suck_pre,swirl
    inst.AnimState:SetScale(3.5,3.5,3.5)
    --inst.AnimState:SetSymbolBloom("glow")
    --inst.AnimState:SetSymbolLightOverride("glow",0.3)
	inst.AnimState:SetMultColour(0.28, 0.08, 0.46, 1)


    inst:AddTag("shadow_aligned")
    inst:AddTag("shadow")
    inst:AddTag("hostile")
    inst:AddTag("notraptrigger")
    inst:AddTag("flying")
	inst:AddTag("nosinglefight_l")
	inst:AddTag("notaunt")
	inst:AddTag("laser_immune")

	
	inst._fade  = net_bool(inst.GUID,"dark_energy._fade","fadedirty")
	if not TheNet:IsDedicated() then
		inst.override_a = 1
		inst:ListenForEvent("fadedirty", OnFadeDirty)
	end

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end


	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.DARK_ENERGY_HEALTH)
	inst.components.health:SetMaxDamageTakenPerHit(250)
	inst.components.health:StartRegen(50, 5)
	

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(75)
	inst.components.combat:SetAreaDamage(2.5, 1, areacheckhit)
    inst.components.combat:SetRange(0.5,2.5)
    inst.components.combat:SetAttackPeriod(1.5)
    inst.components.combat:SetRetargetFunction(2, RetargetFn)
	inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
	inst.components.combat.onhitotherfn = BreakSanity
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

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("dark_energy")

	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aura = -TUNING.SANITYAURA_LARGE

    inst:SetStateGraph("SGdark_energy")
    inst:SetBrain(brain)
	inst:ListenForEvent("attacked", OnAttacked)

    inst.OnSave = OnSave
	inst.OnLoad = OnLoad
	
	inst:DoTaskInTime(0,InitLightWatcher)


	MakeHitstunAndIgnoreTrueDamageEnt(inst)

	
	return inst
end

local function SizeUpdate(inst, dt)
    inst.scale = inst.scale + 0.2 * dt
    inst.AnimState:SetScale(inst.scale,inst.scale,inst.scale)
    if inst.scale>3 then
        inst:RemoveComponent("updatelooper")
        inst:DoTaskInTime(0,function ()
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
	inst.tossing = inst:DoTaskInTime(1 + math.random(), OnTossLanded)

	inst:AddComponent("updatelooper")
	inst.components.updatelooper:AddOnUpdateFn(SizeUpdate)
end

local function OnDeath(inst)
	inst.Physics:Stop()

    inst.AnimState:PlayAnimation("despawn")
    inst.SoundEmitter:PlaySound("dontstarve/sanity/creature2/die","sound_0")
    
	if inst.components.updatelooper~=nil then
		inst:RemoveComponent("updatelooper")
	end

	inst:ListenForEvent("animover",inst.Remove)
end

local function smallfn()
    local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	MakeGhostPhysics(inst, 25, 0.5)
	RemovePhysicsColliders(inst)
	
	

	inst.AnimState:SetBank("blackhole_projectile")
	inst.AnimState:SetBuild("blackhole_projectile")
    inst.AnimState:PlayAnimation("idle_loop",true)  --despawn,shoot,spawn,suck,suck_pre,swirl
    inst.AnimState:SetScale(1.5,1.5,1.5)
    --inst.AnimState:SetSymbolBloom("glow")
    inst.AnimState:SetSymbolLightOverride("glow",0.3)
	inst.AnimState:SetMultColour(0.28, 0.08, 0.46, 1)

	inst:SetPrefabNameOverride("dark_energy")

	inst:AddTag("shadow")
    inst:AddTag("shadow_aligned")
    inst:AddTag("flying")
	inst:AddTag("laser_immune")

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
	inst.components.sanityaura.aura = -TUNING.SANITYAURA_LARGE

    inst.Toss = Toss
    inst.scale = 1.5
    inst:ListenForEvent("death",OnDeath)

	
    
    return inst
end


return Prefab("dark_energy",fn,assets,prefabs),
    Prefab("dark_energy_small",smallfn,assets),
	RuinsRespawner.Inst("dark_energy"), RuinsRespawner.WorldGen("dark_energy")