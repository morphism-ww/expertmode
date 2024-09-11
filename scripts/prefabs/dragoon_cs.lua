local assets=
{
	Asset("ANIM", "anim/dragonfly_fx.zip"),
	Asset("ANIM", "anim/dragoon_build.zip"),
	Asset("ANIM", "anim/dragoon_basic.zip"),
	Asset("ANIM", "anim/dragoon_actions.zip"),
}


local prefabs =
{
	"meat",
	"dragoonspit_cs",
	"dragoonheart",
	--"dragoon_charge_fx",
}

local brain = require ("brains/dragoonbrain")


local DRAGOON_TARGET_DIST = 14
local MAX_HEAT = 80
local SHARE_TARGET_DIST = 20


SetSharedLootTable( "dragoon",
{
    {"meat",            1.00},
    {"redgem", 		  	0.75},
    {"dragoonheart",     0.75},
})

local function ShouldWakeUp(inst)
	return true
end

local function ShouldSleep(inst)
	return false
end 

local function retargetfn(inst)
	return FindEntity(inst, DRAGOON_TARGET_DIST, 
		function(guy) 
			return inst.components.combat:CanTarget(guy)
		end,
		nil, 
		{"dragoon", "epic"},
		{"character","animal"})
end

local function KeepTarget(inst, target)
	return inst.components.combat:CanTarget(target) and inst:IsNear(target,	20)
end

local function canshare(dude)
	return dude:HasTag("dragoon")
end

local function OnAttacked(inst, data)
	local attacker = data.attacker
	if attacker ~= nil and
        not (attacker.components.health ~= nil and attacker.components.health:IsDead()) and
        (data.weapon == nil or ((data.weapon.components.weapon == nil or data.weapon.components.weapon.projectile == nil) and data.weapon.components.projectile == nil)) and
        attacker.components.burnable ~= nil and
        not data.redirected and
        not attacker:HasTag("thorny") then
        attacker.components.burnable:Ignite(nil,nil,inst)
    end
	inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, canshare, 8)
end

local function OnNewTarget(inst, data)
	if inst.components.sleeper:IsAsleep() then
		inst.components.sleeper:WakeUp()
	end
end


local function LockTarget(inst, target)
    inst.components.combat:SetTarget(target)
end


local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
	inst.entity:AddNetwork()

	MakeCharacterPhysics(inst, 50, .3)

	inst.DynamicShadow:SetSize(1.5, .75)
	--inst.Transform:SetScale(1.3,1.3,1.3)

	inst.Transform:SetFourFaced()
	
	inst:AddTag("scarytoprey")
	inst:AddTag("monster")
	inst:AddTag("hostile")
	inst:AddTag("lavae")
	inst:AddTag("dragoon")

	 
	inst.AnimState:SetBank("dragoon")
	inst.AnimState:SetBuild("dragoon_build")
	inst.AnimState:PlayAnimation("idle_loop")

	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	
	
	inst.last_spit_time = nil
	inst.last_target_spit_time = nil
	inst.spit_interval = math.random(20,30)
	inst.num_targets_vomited = 0
	
	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.DRAGOON_HEALTH)
	inst.components.health.fire_damage_scale = 0


	inst:AddComponent("combat")
	inst.components.combat.hiteffectsymbol = "body"
	inst.components.combat:SetDefaultDamage(TUNING.DRAGOON_DAMAGE)
	inst.components.combat:SetAttackPeriod(2)
	inst.components.combat:SetRetargetFunction(1, retargetfn)
	inst.components.combat:SetKeepTargetFunction(KeepTarget)
	inst.components.combat:SetHurtSound("dontstarve_DLC002/creatures/dragoon/hit")
	inst.components.combat:SetRange(3.5,3)
	
	inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("dragoon")

	inst:AddComponent("inspectable")

	inst:AddComponent("sleeper")
	inst.components.sleeper:SetResistance(4)
	inst.components.sleeper:SetSleepTest(ShouldSleep)
	inst.components.sleeper:SetWakeTest(ShouldWakeUp)

	inst:AddComponent("eater")
	inst.components.eater:SetDiet({ FOODTYPE.MEAT }, { FOODTYPE.MEAT })
	inst.components.eater:SetCanEatHorrible()
	inst.components.eater:SetStrongStomach(true) 

	inst:AddComponent("heater")
	inst.components.heater.heat = MAX_HEAT
	inst:AddComponent("entitytracker")

	inst.LockTargetFn = LockTarget

	

	inst:AddComponent("propagator")
    inst.components.propagator.damages = true
    inst.components.propagator.propagaterange = 6
    inst.components.propagator.damagerange = 6
	inst.components.propagator.heatoutput = 10
    inst.components.propagator:StartSpreading()

	inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	inst.components.locomotor.walkspeed = 6
	inst.components.locomotor.runspeed = 16
	-- boat hopping setup
    inst.components.locomotor:SetAllowPlatformHopping(true)

	inst:AddComponent("embarker")	

	inst:SetStateGraph("SGdragoon")
	inst:SetBrain(brain)

	MakeMediumFreezableCharacter(inst, "hound_body")
	

	inst:ListenForEvent("newcombattarget", OnNewTarget)
	inst:ListenForEvent("attacked", OnAttacked)
	
	return inst
end

return Prefab("dragoon_cs", fn, assets, prefabs)