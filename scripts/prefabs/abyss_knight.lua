local RuinsRespawner = require "prefabs/ruinsrespawner"
local assets =
{
    Asset("ANIM", "anim/crabking_mob.zip"),
    Asset("ANIM", "anim/crabking_mob_knight_build.zip"),
}

local prefabs =
{
   "horrorfuel",
   "dreadstone",
   "shadow_soul",
   "shadow_despawn",
   "shadow_trap"
}

local brain = require "brains/abyssknightbrain"

local SHARE_TARGET_DIST = 30
local MAX_TARGET_SHARES = 10

------------------------------------------------------------------------------------------------------------------------------------

SetSharedLootTable("abyss_knight",
{
    {"horrorfuel", 1.00},
    {"horrorfuel", 1.00},
    {"horrorfuel", 0.50},
    {"dreadstone", 1.00},
    {"dreadstone", 0.50},
    {"shadow_soul",1.00}
})


------------------------------------------------------------------------------------------------------------------------------------



local function RetargetFn(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local target = inst.components.combat.target
	if target then
		local range = TUNING.ABYSS_KNIGHT_MELEE_RANGE
		if target.isplayer and target:GetDistanceSqToPoint(x, y, z) < range * range then
			--Keep target
			return
		end
	end

	--V2C: WARNING: FindClosestPlayerInRange returns 2 values, which
	--              we don't want to return as our 2nd return value.  
	local player= FindClosestPlayerInRange(x, y, z, TUNING.ABYSS_CREATURE_TARGET_DIST, true)
	return player
end


local function OnAttacked(inst, data)
    inst.components.combat:SetTarget(data.attacker)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/hit")
end

local function KeepTargetFn(inst, target)
    return
        target ~= nil and
        target:IsValid() and
        target.components.combat ~= nil and
        target.components.health ~= nil and
        not target.components.health:IsDead()
 end

local function PlaySound(inst, event)
    inst.SoundEmitter:PlaySound("meta4/crabcritter/" .. event)
end

local function ShowAgain(inst,data)
    if data.name=="hide_cd" and inst.sg.mem.ishiding then
        inst.sg.mem.wantstoshow = true
        if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy")) then
            inst.sg:GoToState("appear")
        end
    end
end



------------------------------------------------------------------------------------------------------------------------------------
local KNIGHT_SCALE = 2.5

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

	MakeCharacterPhysics(inst, 1000, 0.5)

    inst.Transform:SetSixFaced()
    inst.Transform:SetScale(KNIGHT_SCALE, KNIGHT_SCALE, KNIGHT_SCALE)

    
    inst.AnimState:SetBank("crabking_mob")
    inst.AnimState:SetBuild("crabking_mob_knight_build")
    inst.AnimState:PlayAnimation("idle")
    inst.AnimState:SetSymbolMultColour("cc_fin", 169/255, 36/255, 30/255, 1)
    inst.AnimState:SetSymbolLightOverride("cc_fin", 0.5)
    inst.AnimState:SetSymbolMultColour("cc_claw", 0, 0, 0, 1)
    inst.AnimState:SetSymbolMultColour("cc_shell_parts", 0, 0, 0, 1)
    inst.AnimState:SetSymbolMultColour("cc_bod",169/255, 36/255, 30/255, 1)
    inst.AnimState:SetSymbolHue("cc_eye",0)
    --inst.AnimState:SetSymbolMultColour("cc_pupil", 169/255, 36/255, 30/255, 1)
    --inst.AnimState:OverrideSymbol("cc_pupil", "blackhole_projectile", "blackhole")	
    inst.AnimState:SetSymbolMultColour("cc_leg",  169/255, 36/255, 30/255, 1)
    inst.AnimState:HideSymbol("cc_mouth_parts")
    

    inst:AddTag("hostile")
    inst:AddTag("notaunt")
    inst:AddTag("shadow_aligned")
    inst:AddTag("abysscreature")
    inst:AddTag("largecreature")
    inst:AddTag("shadowthrall")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.PlaySound = PlaySound -- Used in the stategraph.

    inst:AddComponent("inspectable")
    inst:AddComponent("knownlocations")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("abyss_knight")

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_LARGE

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 3
    inst.components.locomotor.runspeed = 4
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { ignorecreep = true }


    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.ABYSS_KNIGHT_HEALTH)
    inst.components.health:StartRegen(50, 5)

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.ABYSS_KNIGHT_DAMAGE)
    inst.components.combat:SetRange(TUNING.ABYSS_KNIGHT_MELEE_RANGE)
    inst.components.combat.hiteffectsymbol = "cc_bod"
    inst.components.combat:SetAttackPeriod(3)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat:SetRetargetFunction(1, RetargetFn)
    inst.components.combat.battlecryenabled = false

    inst:AddComponent("planarentity")

    inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(30)

    inst:AddComponent("damagetyperesist")
	inst.components.damagetyperesist:AddResist("shadow_item", inst, 0.8)

    inst:AddComponent("timer")

    inst:SetStateGraph("SGabyss_knight")
    inst:SetBrain(brain)

    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("timerdone", ShowAgain)

    MakeHitstunAndIgnoreTrueDamageEnt(inst)

    return inst
end



return Prefab("abyss_knight",fn, assets, prefabs),
RuinsRespawner.Inst("abyss_knight"), RuinsRespawner.WorldGen("abyss_knight")
