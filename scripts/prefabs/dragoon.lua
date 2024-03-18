local brain = require ("brains/dragoonbrain")
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
	"firesplash_fx",
	"firering_fx",
	"dragoonspit",
	"dragoonheart",
	--"dragoon_charge_fx",
}

local DRAGOON_TARGET_DIST = 10


local DRAGOON_KEEP_TARGET_DIST = 18



local SHARE_TARGET_DIST = 20

local NO_TAGS = {"FX", "NOCLICK","DECOR","INLIMBO"}

SetSharedLootTable( "dragoon",
{
    {"meat",            1.00},
    {"redgem", 		  1.00},
    {"dragoonheart",     0.50},
})

local function ShouldWakeUp(inst)
	return true
end

local function ShouldSleep(inst)
	return false
end 

local function OnNewTarget(inst, data)
	if inst.components.sleeper:IsAsleep() then
		inst.components.sleeper:WakeUp()
	end
end

local function retargetfn(inst)
	return FindEntity(inst, DRAGOON_TARGET_DIST, 
		function(guy) 
			return inst.components.combat:CanTarget(guy)
		end,
			nil, {"wall", "dragoon", "epic", "FX", "NOCLICK"},{"character","animal"})
end

local function KeepTarget(inst, target)
	return inst.components.combat:CanTarget(target) and inst:GetDistanceSqToInst(target) <= (DRAGOON_KEEP_TARGET_DIST*DRAGOON_KEEP_TARGET_DIST)
end

local function canshare(dude)
	return dude:HasTag("dragoon") and not dude.components.health:IsDead()
end

local function OnAttacked(inst, data)
	if data.attacker ~= nil and
        not (data.attacker.components.health ~= nil and data.attacker.components.health:IsDead()) and
        (data.weapon == nil or ((data.weapon.components.weapon == nil or data.weapon.components.weapon.projectile == nil) and data.weapon.components.projectile == nil)) and
        data.attacker.components.burnable ~= nil then
        data.attacker.components.burnable:Ignite(nil,nil,inst)
    end
	inst.components.combat:SetTarget(data.attacker)
	inst.components.combat:ShareTarget(data.attacker, SHARE_TARGET_DIST, canshare, 8)
end

local function OnAttackOther(inst, data)
	inst.components.combat:ShareTarget(data.target, SHARE_TARGET_DIST, canshare, 8)
end

local function OnCollide(inst, other)
    if other ~= nil and
		other:IsValid() and
		other.prefab~="dragoonegg" and
        other.components.workable ~= nil and
        other.components.workable:CanBeWorked() and
        other.components.workable.action ~= ACTIONS.NET then
        inst:DoTaskInTime(2 * FRAMES, other.components.workable:Destroy(inst))
    end
end



local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddPhysics()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	--inst.Transform:SetScale(1.3,1.3,1.3)

	local shadow = inst.entity:AddDynamicShadow()
	shadow:SetSize(3, 1.25)

	inst.Transform:SetFourFaced()
	
	inst:AddTag("scarytoprey")
	inst:AddTag("monster")
	inst:AddTag("hostile")
	inst:AddTag("lavaspitter")
	inst:AddTag("dragoon")

	MakeCharacterPhysics(inst, 10, .5)


	inst.last_spit_time = nil
	inst.last_target_spit_time = nil
	inst.spit_interval = math.random(20,30)
	inst.num_targets_vomited = 0
	 
	inst.AnimState:SetBank("dragoon")
	inst.AnimState:SetBuild("dragoon_build")
	inst.AnimState:PlayAnimation("idle_loop")

	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.Physics:SetCollisionCallback(OnCollide)
	inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	inst.components.locomotor.walkspeed = 6
	inst.components.locomotor.runspeed = 18
	inst:SetStateGraph("SGdragoon")

    -- boat hopping setup
    inst.components.locomotor:SetAllowPlatformHopping(true)
    inst:AddComponent("embarker")		
	

	inst:SetBrain(brain)
	
	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(800)
	inst.components.health.fire_damage_scale = 0


	inst:AddComponent("combat")
	inst.components.combat.hiteffectsymbol = "body"
	inst.components.combat:SetDefaultDamage(50)
	inst.components.combat:SetAttackPeriod(2)
	inst.components.combat:SetRetargetFunction(1, retargetfn)
	inst.components.combat:SetKeepTargetFunction(KeepTarget)
	inst.components.combat:SetHurtSound("dontstarve_DLC002/creatures/dragoon/hit")
	inst.components.combat:SetRange(3.5,3)
	
	inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("dragoon")

	inst:AddComponent("eater")

	--inst:AddComponent("inspectable")

	inst:AddComponent("sleeper")
	inst.components.sleeper:SetResistance(4)
	inst.components.sleeper:SetSleepTest(ShouldSleep)
	inst.components.sleeper:SetWakeTest(ShouldWakeUp)

	inst:ListenForEvent("newcombattarget", OnNewTarget)

	inst:ListenForEvent("attacked", OnAttacked)
	inst:ListenForEvent("onattackother", OnAttackOther)

	MakeMediumFreezableCharacter(inst, "hound_body")
	inst.components.freezable:SetResistance(6)

	inst:AddComponent("propagator")
    inst.components.propagator.damages = true
    inst.components.propagator.propagaterange = 6
    inst.components.propagator.damagerange = 6
	inst.components.propagator.decayrate = 0
	inst.components.propagator.heatoutput = 10

    inst.components.propagator:StartSpreading()

	return inst
end

return Prefab("dragoon", fn, assets, prefabs)