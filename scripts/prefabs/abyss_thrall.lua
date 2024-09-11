local brain = require "brains/abyssthrallbrain"
local RuinsRespawner = require "prefabs/ruinsrespawner"
local assets =
{
    Asset("ANIM", "anim/ancient_spirit.zip"),
}

local prefabs =
{
    "nightmarefuel",
    "horrorfuel",
    "shadowfireball",
    "voidcloth",
    "shadow_soul"
}


local SHARE_TARGET_DIST = 20
local MAX_TARGET_SHARES = 10

SetSharedLootTable("abyss_thrall",
{
    { "voidcloth",		1.00 },
	{ "voidcloth",		1.00 },
	{ "voidcloth",		1.00 },
	{ "voidcloth",		0.50 },
	{ "horrorfuel",		1.00 },
	{ "horrorfuel",		1.00 },
	{ "horrorfuel",	    0.50 },
	{ "shadow_soul",	1.00 },
})


local function RetargetFn(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
	local target = inst.components.combat.target
	if target ~= nil then
		local range = TUNING.ABYSS_CREATURE_TARGET_DIST + target:GetPhysicsRadius(0)
		if target:HasTag("player") and target:GetDistanceSqToPoint(x, y, z) < range * range then
			--Keep target
			return
		end
	end

    local player--[[, rangesq]] = FindClosestPlayerInRange(x, y, z, TUNING.ABYSS_CREATURE_TARGET_DIST, true)
	return player
end


local function KeepTargetFn(inst, target)
    return inst.components.combat:CanTarget(target)
end


local function ShareTargetFn(guy)
    return
        guy:HasTag("shadow_aligned") and
        guy.components.health ~= nil and
        not guy.components.health:IsDead()
end

local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.components.combat:ShareTarget(data.attacker, SHARE_TARGET_DIST, ShareTargetFn, MAX_TARGET_SHARES)
end



local function nodmgshielded(inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    return inst.hasshield and amount <= 0 and not ignore_absorb
end

local function fn()    
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()	
    
    
    
    inst.Transform:SetSixFaced()

    MakeCharacterPhysics(inst, 1000, .5)
    RemovePhysicsColliders(inst)
    inst.Physics:SetCollisionGroup(COLLISION.SANITY)
    inst.Physics:CollidesWith(COLLISION.SANITY)

    inst.AnimState:SetBank("ancient_spirit")
    inst.AnimState:SetBuild("ancient_spirit")
    inst.AnimState:PlayAnimation("idle")

    local scale  = 1.25
    inst.Transform:SetScale(scale,scale,scale)


	inst:AddTag("hostile")
	inst:AddTag("scarytoprey")
	inst:AddTag("shadow_aligned")
    inst:AddTag("fossil")
    inst:AddTag("abysscreature")
    inst:AddTag("epic")
    inst:AddTag("shadowthrall")
    inst:AddTag("laser_immune")
    --inst:AddTag("noepicmusic")

	
    inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end	
    

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.ABYSS_THRALL_HEALTH)
    inst.components.health:StartRegen(50, 5)
    inst.components.health.redirect = nodmgshielded

    ------------------
    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.ABYSS_THRALL_DAMAGE)
    inst.components.combat:SetRange(5)
    inst.components.combat:SetAttackPeriod(3)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat:SetRetargetFunction(1, RetargetFn)    
    ------------------------------------------

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 4 
    ------------------------------------------

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("abyss_thrall")
	
    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_HUGE

    inst:AddComponent("planarentity")

    inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(40)

    inst:AddComponent("damagetyperesist")
	inst.components.damagetyperesist:AddResist("shadow_item", inst, 0.7)

    inst:AddComponent("knownlocations")

    inst:AddComponent("timer")

    ------------------------------------------
    inst:SetStateGraph("SGabyssthrall")
    inst:SetBrain(brain)	
    ------------------------------------------
    inst.hasshield = false

    inst:ListenForEvent("attacked", OnAttacked)

    return inst
end

return Prefab( "abyss_thrall", fn, assets, prefabs),
RuinsRespawner.Inst("abyss_thrall"), RuinsRespawner.WorldGen("abyss_thrall")