local brain = require( "brains/shadowdragonbrain")
local RuinsRespawner = require "prefabs/ruinsrespawner"

local prefabs =
{
    "nightmarefuel",
}

local loots={}
for i=1,10 do
    loots[i]='nightmarefuel'
end



local function retargetfn(inst)
    local maxrangesq = 576
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

local function steallife(inst,data)
    local victim = (data~=nil and data.target) or nil
    if victim~=nil and victim.components.sanity~=nil then
        inst.components.health:DoDelta(100)
        victim.components.sanity:DoDelta(-15)
    end
end
local function onkilledbyother(inst, attacker)
    if attacker ~= nil and attacker.components.sanity ~= nil then
        attacker.components.sanity:DoDelta(inst.sanityreward)
    end
end


local function MakeShadowCreature(data)

    local bank = data.bank 
    local build = data.build 
    
    local assets=
    {
	    Asset("ANIM", "anim/"..data.build..".zip"),
    }
    
    local sounds = 
    {
        attack = "dontstarve/sanity/creature"..data.num.."/attack",
        attack_grunt = "dontstarve/sanity/creature"..data.num.."/attack_grunt",
        death = "dontstarve/sanity/creature"..data.num.."/die",
        idle = "dontstarve/sanity/creature"..data.num.."/idle",
        taunt = "dontstarve/sanity/creature"..data.num.."/taunt",
        appear = "dontstarve/sanity/creature"..data.num.."/appear",
        disappear = "dontstarve/sanity/creature"..data.num.."/dissappear",
    }

    local function fn()
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

        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation("idle_loop")
        inst.AnimState:SetMultColour(1, 1, 1, 0.5)
        --inst.AnimState:OverrideSymbol("seashadow_head",           "shadow_knight_upg_build", "face2")
        --inst.AnimState:OverrideSymbol("seashadow_spine",           "shadow_bishop_upg_build", "wing2")

        inst.Transform:SetScale(1.4,1.4,1.4)

        inst:AddTag("nightmarecreature")
	    inst:AddTag("hostile")
        inst:AddTag("shadow")
        inst:AddTag("notraptrigger")
        inst:AddTag("shadow_aligned")
        inst:AddTag("shadowsubmissive")

        inst.HostileToPlayerTest = CLIENT_ShadowSubmissive_HostileToPlayerTest

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("shadowsubmissive")
        inst:AddComponent("timer")
        inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
	    inst.components.locomotor:SetTriggersCreep(false)
        inst.components.locomotor.pathcaps = { ignorecreep = true }
        inst.components.locomotor.walkspeed = data.speed
        inst.sounds = sounds

        inst:SetStateGraph("SGshadowdragon")
        inst:SetBrain(brain)
        
	    inst:AddComponent("sanityaura")
	    inst.components.sanityaura.aura = -TUNING.SANITYAURA_LARGE
        

        inst:AddComponent("health")
        inst.components.health:SetMaxHealth(data.health)
        
		inst.sanityreward = data.sanityreward
		
        inst:AddComponent("combat")
        inst.components.combat:SetRange(5)
        inst.components.combat:SetDefaultDamage(data.damage)
        inst.components.combat:SetAttackPeriod(data.attackperiod)
        inst.components.combat:SetRetargetFunction(2, retargetfn)
        inst.components.combat.canbeattackedfn = canbeattackedfn
        inst.components.combat.onkilledbyother = onkilledbyother

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:SetLoot(loots)
        
        inst:ListenForEvent("attacked", OnAttacked)
        inst:ListenForEvent("onhitother", steallife)
        inst:AddComponent("knownlocations")


        return inst
    end
        
    return Prefab(data.name, fn, assets, prefabs)
end

local data = {
    {
        name="shadowdragon",
        build = "shadow_insanity_water1",
        bank = "shadowseacreature",
        num = 2,
        speed = 7,
        health=1000,
        damage= 50 ,
        attackperiod = 4,
        sanityreward = TUNING.SANITY_LARGE
    }
}

local ret = {}
for k,v in pairs(data) do
	table.insert(ret, MakeShadowCreature(v))
end

return unpack(ret) ,
RuinsRespawner.Inst("shadowdragon"), RuinsRespawner.WorldGen("shadowdragon")