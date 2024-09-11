local brain = require( "brains/shadowdragonbrain")
local brain2 = require( "brains/dreaddragonbrain")
local RuinsRespawner = require "prefabs/ruinsrespawner"

local assets=
    {
	    Asset("ANIM", "anim/shadow_insanity_water1.zip"),
    }

local prefabs =
{
    "nightmarefuel",
}

SetSharedLootTable("shadow_dragon",
{
    { "nightmarefuel",  1.0 },
    { "nightmarefuel",  1.0 },
    { "nightmarefuel",  1.0 },
    { "nightmarefuel",  0.5 },
})

local function retargetfn(inst)
    local maxrangesq = 20*20
    local rangesq, rangesq1, rangesq2 = maxrangesq, math.huge, math.huge
    local target1, target2 = nil, nil
    for i, v in ipairs(AllPlayers) do
        if  not v:HasTag("playerghost") then
            local distsq = v:GetDistanceSqToInst(inst)
            if distsq < rangesq then
                if inst.components.shadowsubmissive:TargetHasDominance(v) then
                    if distsq < rangesq1 and inst.components.combat:CanTarget(v) then
                        target1 = v
                        rangesq1 = distsq
                        rangesq = math.max(rangesq1, rangesq2)
                    end
                elseif distsq < rangesq2 and inst.components.combat:CanTarget(v) then
                    target2 = v
                    rangesq2 = distsq
                    rangesq = math.max(rangesq1, rangesq2)
                end
            end
        end
    end

    if target1 ~= nil and rangesq1 <= math.max(rangesq2, maxrangesq * .25) then
        --Targets with shadow dominance have higher priority within half targeting range
        --Force target switch if current target does not have shadow dominance
        return target1, not inst.components.shadowsubmissive:TargetHasDominance(inst.components.combat.target)
    end
    return target2
end


local function retargetfn2(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local target = inst.components.combat.target
	if target ~= nil then
		local range = 24 + target:GetPhysicsRadius(0)
		if target:HasTag("player") and target:GetDistanceSqToPoint(x, y, z) < range * range then
			--Keep target
			return
		end
	end


	--V2C: WARNING: FindClosestPlayerInRange returns 2 values, which
	--              we don't want to return as our 2nd return value.  
	local player--[[, rangesq]] = FindClosestPlayerInRange(x, y, z, 30, true)
	return player
end

local function canbeattackedfn(inst, attacker)
	return inst.components.combat.target ~= nil or
		(attacker and attacker.components.sanity and attacker.components.sanity:IsCrazy())
end


local function OnAttacked(inst, data)
    if data.attacker ~= nil then
        inst.components.combat:SetTarget(data.attacker)
    end
end



local function CLIENT_ShadowSubmissive_HostileToPlayerTest(inst, player)
	if player:HasTag("shadowdominance") then
		return false
	end
	local combat = inst.replica.combat
	if combat ~= nil and combat:GetTarget() == player then
		return true
	end
	local sanity = player.replica.sanity
	if sanity ~= nil and sanity:IsCrazy() then
		return true
	end
	return false
end


local function StealLife2(inst,victim,damage, stimuli, weapon, damageresolved, spdamage, damageredirecttarget)
    --local victim = (data~=nil and data.target) or nil
    if damageredirecttarget==nil and victim and victim.components.sanity~=nil then
        inst.components.health:DoDelta(200)
        victim.components.sanity:DoDelta(-15)
        victim:AddDebuff("exhaustion","exhaustion",{duration=10})
    end
end
local function onkilledbyother(inst, attacker,damage, stimuli, weapon, damageresolved, spdamage, damageredirecttarget)
    if damageredirecttarget==nil and attacker ~= nil and attacker.components.sanity ~= nil then
        attacker.components.sanity:DoDelta(inst.sanityreward)
    end
end

local num = 2
local sounds = 
{
    attack = "dontstarve/sanity/creature"..num.."/attack",
    attack_grunt = "dontstarve/sanity/creature"..num.."/attack_grunt",
    death = "dontstarve/sanity/creature"..num.."/die",
    idle = "dontstarve/sanity/creature"..num.."/idle",
    taunt = "dontstarve/sanity/creature"..num.."/taunt",
    appear = "dontstarve/sanity/creature"..num.."/appear",
    disappear = "dontstarve/sanity/creature"..num.."/dissappear",
}


local function CreateCommon(common_init)
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetSixFaced()

    MakeCharacterPhysics(inst, 10, 1.5)
    RemovePhysicsColliders(inst)

    inst.Physics:SetCollisionGroup(COLLISION.SANITY)
    inst.Physics:CollidesWith(COLLISION.SANITY)
    inst.AnimState:SetBank("shadowseacreature")
    inst.AnimState:SetBuild("shadow_insanity_water1")
    inst.AnimState:PlayAnimation("idle_loop")
    

    inst:AddTag("hostile")
    inst:AddTag("shadow")
    inst:AddTag("notraptrigger")
    inst:AddTag("shadow_aligned")
    

    common_init(inst)

    inst.HostileToPlayerTest = CLIENT_ShadowSubmissive_HostileToPlayerTest

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("timer")
    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = true }
    inst.sounds = sounds
    inst.sanityreward = TUNING.SANITY_LARGE

    inst:AddComponent("sanityaura")
	inst.components.sanityaura.aura = -TUNING.SANITYAURA_LARGE

    inst:AddComponent("lootdropper")

    inst:AddComponent("health")

    inst:AddComponent("combat")
    inst.components.combat:SetRange(6,5)
    inst.components.combat:SetAttackPeriod(4)
    inst.components.combat.canbeattackedfn = canbeattackedfn
    inst.components.combat.onkilledbyother = onkilledbyother

    inst:ListenForEvent("attacked", OnAttacked)
    --inst:ListenForEvent("onhitother", steallife)

    inst:SetStateGraph("SGshadowdragon")
    
    return inst
end

local function RegularCommongPostInit(inst)
    inst:AddTag("nightmarecreature")
    inst:AddTag("shadowsubmissive")
    inst.AnimState:SetMultColour(1, 1, 1, 0.5)
    --inst.Transform:SetScale(1.4,1.4,1.4)
    inst.HostileToPlayerTest = CLIENT_ShadowSubmissive_HostileToPlayerTest
end

local function RegularFn()
    local inst = CreateCommon(RegularCommongPostInit)

    if not TheWorld.ismastersim then
        return inst
    end

    inst.canwave = true
    

    inst:AddComponent("shadowsubmissive")

    inst.components.health:SetMaxHealth(TUNING.SHAODWDRAGON_HEALTH)
    inst.components.combat:SetDefaultDamage(TUNING.SHAODWDRAGON_DAMAGE)
    inst.components.combat:SetRetargetFunction(1.5,retargetfn)
    --inst.components.combat.onhitotherfn = steallife
    inst.components.locomotor.walkspeed = 7

    
    inst.components.lootdropper:SetChanceLootTable('shadow_dragon')
    --inst:ListenForEvent("onhitother", steallife)
    inst:SetBrain(brain)

    return inst
end

local function CreateFlameFx()
    local inst = CreateEntity()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    if not TheWorld.ismastersim then
        inst.entity:SetCanSleep(false)
    end
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()

    inst.AnimState:SetMultColour(1,1,1,0.5)
    inst.AnimState:SetScale(1.3,1.3,1.3)

    inst.AnimState:SetBank("pigman")
    inst.AnimState:SetBuild("merm_actions_skills")

    local anim = "alternateeyes"

    inst.AnimState:PlayAnimation(anim, true)

    --inst.AnimState:SetSymbolLightOverride("fx_flame_red", 1)
    --inst.AnimState:SetSymbolLightOverride("fx_red", 1)

    inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()))

    return inst
end

local function AbyssCommongPostInit(inst)

    local flames = CreateFlameFx()
    flames.entity:SetParent(inst.entity)
    flames.Follower:FollowSymbol(inst.GUID, "seashadow_head", 20, 30, 0, true)  --head

    inst.AnimState:SetSymbolMultColour("seashadow_spine", 1, 1, 1, 1)
    inst.AnimState:SetSymbolAddColour("seashadow_spine", 169/255, 36/255, 30/255, 1)
    --inst.AnimState:SetSymbolAddColour("seashadow_spine", 169/255, 36/255, 30/255, 1)
    inst.AnimState:SetSymbolLightOverride("seashadow_bit", 0.1)
    inst.Transform:SetScale(1.7,1.7,1.7)
end    

local function AbyssFn()
    local inst = CreateCommon(AbyssCommongPostInit)

    inst:AddTag("notaunt")
    inst:AddTag("shadowthrall")
    inst:AddTag("abysscreature")

    if not TheWorld.ismastersim then
        return inst
    end

    inst.dread = true

    inst.canwave = true

    inst:AddComponent("planarentity")

    inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(30)

    inst.components.health:SetMaxHealth(2000)
    --inst.components.combat:SetRange(12,5)
    inst.components.combat:SetAreaDamage(5, 1)
    inst.components.combat:SetDefaultDamage(100)
    inst.components.combat.onhitotherfn = StealLife2

    inst.components.combat:SetRetargetFunction(1.5,retargetfn2)
    
    inst.components.locomotor.walkspeed = 8

    local loots={}
    for i=1,8 do
        loots[i]="horrorfuel"
    end
    inst.components.lootdropper:SetLoot(loots)

    inst:SetBrain(brain2)
    --inst:ListenForEvent("onhitother", StealLife2)
    return inst
end

return Prefab("shadowdragon",RegularFn,assets,prefabs),
    Prefab("dreaddragon",AbyssFn,assets,prefabs),
RuinsRespawner.Inst("shadowdragon"), RuinsRespawner.WorldGen("shadowdragon")