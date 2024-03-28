local brain=require("brains/mfzbrain")
local assets =
{
	Asset("ANIM", "anim/living_suit_build.zip"),
	Asset("ANIM", "anim/player_living_suit_morph.zip"),
	Asset("ANIM", "anim/player_living_suit_punch.zip"),
	Asset("ANIM", "anim/player_living_suit_shoot.zip"),
	Asset("ANIM", "anim/player_living_suit_destruct.zip"),
    Asset("ANIM", "anim/player_idles_wonkey.zip"),
    Asset("ANIM", "anim/player_attack_leap.zip"),
}



local function retargetfn(inst)
    local x,y,z=inst.Transform:GetWorldPosition()
    local players=FindPlayersInRange(x,y,z,40)
    for i,v in ipairs(players) do
        if not v:HasTag("playerghost") then
            return v
        end
    end
end

local function keeptargetfn(inst,target)
    return  inst.components.combat:CanTarget(target)
end

local function levelup(inst)
    inst.AnimState:AddOverrideBuild("living_suit_build")
    inst.AnimState:OverrideSymbol("arm_lower", "living_suit_build", "arm_lower")
    inst.AnimState:OverrideSymbol("arm_upper", "living_suit_build", "arm_upper")
    inst.AnimState:OverrideSymbol("arm_upper_skin", "living_suit_build", "arm_upper_skin")
    inst.AnimState:OverrideSymbol("foot", "living_suit_build", "foot")
    inst.AnimState:OverrideSymbol("hand", "living_suit_build", "hand")
    inst.AnimState:OverrideSymbol("headbase", "living_suit_build", "headbase")
    inst.AnimState:OverrideSymbol("leg", "living_suit_build", "leg")
    inst.AnimState:OverrideSymbol("torso", "living_suit_build", "torso")
    inst.AnimState:OverrideSymbol("torso_pelvis", "living_suit_build", "torso_pelvis")	
    inst.AnimState:OverrideSymbol("hair", "living_suit_build", " ")
    inst.AnimState:OverrideSymbol("hair_hat", "living_suit_build", " ")
    inst.AnimState:OverrideSymbol("face", "living_suit_build", " ")
    inst.AnimState:OverrideSymbol("cheeks", "living_suit_build", " ")	
    inst.AnimState:OverrideSymbol("hairpigtails", "living_suit_build", " ")	
    inst.AnimState:Hide("beard")
end

---------------------------------------
local function become_boss(inst)
    if inst.is_boss then return end
    
    inst.components.health:SetInvincible(true)
    inst.sg:GoToState("morph") 
end

local function warning(shadowchild)
    shadowchild:PushEvent("upgrade")
end

local function changename(inst)
    inst.components.named:PickNewName()
end


--------------------------------------------------------------------------
---跳劈
-----------------------------------------------------
local function EquipGod_Judge(inst)
    if inst.components.inventory and not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
        local weapon=SpawnPrefab("god_judge")
        inst.components.inventory:Equip(weapon)
    end
end
---------------------------------------------------------------------------
---dont_skip
--------------------------------------------------------------------------
local function onlyplayer(inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    return (amount>200) or (afflicter~=nil and not afflicter:HasTag("player"))
end
local function OnCollide(inst, other)
    if other ~= nil and
        other:IsValid() and
        other.components.workable ~= nil and
        other.components.workable:CanBeWorked() and
        other.components.workable.action ~= ACTIONS.NET then
        inst:DoTaskInTime(2 * FRAMES, other.components.workable:Destroy(inst))
    end
end
local function EnterShield(inst)
    if inst._shieldfx ~= nil then
        inst._shieldfx:kill_fx()
    end
    inst._shieldfx = SpawnPrefab("forcefieldfx")
    inst._shieldfx.Transform:SetScale(1.1,1.1,1.1)
    inst._shieldfx.entity:SetParent(inst.entity)
    inst._shieldfx.Transform:SetPosition(0, 0.5, 0)
    inst.components.health.externalabsorbmodifiers:SetModifier(inst._shieldfx, 1)
end

local function ExitShield(inst)

    if inst._shieldfx ~= nil then
        inst._shieldfx:kill_fx()
        inst._shieldfx = nil
    end
end
------------------------------------------------------------------------------
--save and load
local function onsave(inst, data)
    data.is_boss = inst.is_boss
end

local function onpreload(inst, data)
    inst.is_boss=data.is_boss
    if data ~= nil then
        if data.is_boss then
            inst:LevelUp()
        end
        
    end
end

--[[local function OnEntitySleep(inst)
    if inst.components.health:IsDead() then
        return
    end

    for k,v in pairs(AllPlayers) do
        if v:IsValid() and not v:HasTag("playerghost") then
            local pt=v:GetPosition()
            local offset = FindWalkableOffset(pt, PI2*math.random(), 6, 10, true) 
            or FindWalkableOffset(pt, PI2*math.random(), 12, 8, true, false)
            TheNet:Announce("哼，想逃？")
            inst.Transform:SetPosition(pt.x+offset.x, 0, pt.z+offset.z)
            return
        end    
    end
end]]
-------------------------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()


    inst.Transform:SetFourFaced()
    inst.Transform:SetScale(2,2,2)

    MakeCharacterPhysics(inst, 75, .5)
    inst.Physics:ClearCollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.GROUND)

    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("wonkey")
    inst.AnimState:AddOverrideBuild("player_living_suit_morph")	
    inst.AnimState:AddOverrideBuild("player_attack_leap")

    inst.AnimState:PlayAnimation("idle")

    inst.AnimState:Hide("ARM_carry")
    inst.AnimState:Hide("HAT")
    inst.AnimState:Hide("HAIR_HAT")
    inst.AnimState:Show("HAIR_NOHAT")
    inst.AnimState:Show("HAIR")
    inst.AnimState:Show("HEAD")
    inst.AnimState:Hide("HEAD_HAT")
    inst.AnimState:Hide("HEAD_HAT_NOHELM")
    inst.AnimState:Hide("HEAD_HAT_HELM")


    inst.AnimState:OverrideSymbol("fx_wipe", "wilson_fx", "fx_wipe")
    inst.AnimState:OverrideSymbol("fx_liquid", "wilson_fx", "fx_liquid")
    inst.AnimState:OverrideSymbol("shadow_hands", "shadow_hands", "shadow_hands")
    inst.AnimState:OverrideSymbol("snap_fx", "player_actions_fishing_ocean_new", "snap_fx")
    
    inst.DynamicShadow:SetSize(1.3, .6)

    inst:AddComponent("talker")
    inst.components.talker.fontsize = 40
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.colour = Vector3(238 / 255, 69 / 255, 105 / 255)
    inst.components.talker.offset = Vector3(0, -700, 0)
    inst.components.talker.symbol = "fossil_chest"
    inst.components.talker:MakeChatter()

    inst:AddTag("epic")
    inst:AddTag("hostile")
    inst:AddTag("monkey")
    inst:AddTag("notraptrigger")
    inst:AddTag("toughworker")
    inst:AddTag("noteleport")
    inst:AddTag("god")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end	

    inst.Physics:SetCollisionCallback(OnCollide)
	
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(6666)
    inst.components.health.redirect=onlyplayer
    inst.components.health:SetMaxDamageTakenPerHit(88)
    inst.components.health.destroytime = 2
    inst.components.health:StartRegen(50, 5)
    inst.components.health:SetAbsorptionAmount(0.5)
    --inst.components.health.nofadeout = true

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(150)
    inst.components.combat:SetAttackPeriod(2)
    inst.components.combat:SetRange(18)
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)
    inst.components.combat:SetRetargetFunction(1, retargetfn)

    inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(20)

    local stunnable = inst:AddComponent("stunnable")
    stunnable.stun_threshold = 500
    stunnable.stun_period = 5
    stunnable.stun_duration = 20
    stunnable.stun_resist = 0
    stunnable.stun_cooldown = 0

    inst:AddComponent("inventory")

    inst:AddComponent("timer")
    inst:AddComponent("knownlocations")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"powder_monkey","cave_banana"})

    inst:AddComponent("colouradder")
    inst:AddComponent("bloomer")

    inst:AddComponent("named")
    inst.components.named.possiblenames = {"邪恶海棠","莫则非","???"}
    inst.components.named:PickNewName()

    local groundpounder = inst:AddComponent("groundpounder")
    groundpounder:UseRingMode()
    groundpounder.numRings = 4
    groundpounder.radiusStepDistance = 2
    groundpounder.ringWidth = 2
    groundpounder.damageRings = 3
    groundpounder.destructionRings = 3
    groundpounder.platformPushingRings = 3
    groundpounder.fxRings = 2
    groundpounder.fxRadiusOffset = 1.5
    groundpounder.destroyer = true
    groundpounder.burner = true
    groundpounder.groundpoundfx = "firesplash_fx"
    groundpounder.groundpounddamagemult = 0.5
    groundpounder.groundpoundringfx = "firering_fx"

    inst.components.timer:StartTimer("killer_cd", 40)


    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = 6
    inst.components.locomotor.runspeed = 7
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { allowocean = true,ignorewalls = true }

    inst:SetStateGraph("SGironlord")
    inst:SetBrain(brain)

    inst.LevelUp=levelup
    inst.EquipLeap=EquipGod_Judge
    inst.swc2hmfn =warning
    inst.EnterShield = EnterShield
    inst.ExitShield = ExitShield

    inst.OnSave = onsave
    inst.OnPreLoad = onpreload
    
    --inst:DoTaskInTime(0, EquipGod_Judge)
    inst:DoPeriodicTask(10,changename)
    inst:ListenForEvent("upgrade",become_boss)


    return inst
end


return Prefab( "shadow_mfz", fn, assets)
