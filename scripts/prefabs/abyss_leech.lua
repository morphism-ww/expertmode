local assets =
{
	Asset("ANIM", "anim/shadow_leech.zip"),
}

local prefabs =
{
	"nightmarefuel",
}

local brain = require("brains/abyss_leechbrain")

local LOOT = { "nightmarefuel" }

local function CalcSanityAura(inst, observer)
	return observer.components.sanity:IsCrazy()
		and -TUNING.SANITYAURA_MED
		or 0
end

local function ToggleBrain(inst, enable)
	if enable then
		inst:SetBrain(brain)
		if inst.brain == nil and not inst:IsAsleep() then
			inst:RestartBrain()
		end
	else
		inst:SetBrain(nil)
	end
end

local function OnSpawnedBy(inst, portal)
    if portal ~= nil then
        inst:ListenForEvent("onremove", inst._on_portal_removed, portal)
    end

    inst.sg:GoToState("spawn_delay", FRAMES)
end


local function sucklife(inst, owner)
    if owner.components.health ~= nil and not owner.components.health:IsDead() then
        owner.components.health:DoDelta(-2, nil, "shadow_leech")
    else
        inst:StopTrackingTarget()
    end

    if owner.components.hunger ~= nil and not owner.components.hunger:IsStarving() then
        owner.components.hunger:DoDelta(-2)
    end    
    if owner.components.mightiness~=nil and owner.components.mightiness:GetCurrent()>0 then
        owner.components.mightiness:DoDelta(-3)
    end
end

local function AttachTarget(inst,target)
    if target.components.health:IsDead() then
        inst:StopTrackingTarget()
        return 
    end

    local oldarmor = target.components.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    if oldarmor ~= nil then
        target.components.inventory:DropItem(oldarmor)
    end

    inst.task = inst:DoPeriodicTask(1, sucklife, nil, target)
    inst:ListenForEvent("death",inst.ontargetloss,target)

    if inst.keeptargettask~=nil then
        inst.keeptargettask:Cancel()
        inst.keeptargettask = nil
    end
    
	inst.Follower:FollowSymbol(target.GUID, "swap_body", nil, nil, nil, true)
	inst.sg:GoToState("attached")
end

local function KeepTargetFn(inst,target)
    if target==nil or not target:IsValid() then
        inst:StopTrackingTarget(target)
        return
    end

    if inst.components.homeseeker~=nil then
        local pos = inst.components.homeseeker:GetHomePos()
        if pos~=nil and inst:GetDistanceSqToPoint(pos:Get()) < 1600 then
            inst:StopTrackingTarget()
        end
    end
end

local function SearchForPlayer(inst)
    if inst.__host~=nil then
        return
    end
    local x,y,z = inst.Transform:GetWorldPosition()
    local target = FindClosestPlayerInRangeSq(x,y,z,144,true)
    if target then
        inst:StartTrackingTarget(target)
        if inst.keeptargettask == nil then
            inst.keeptargettask = inst:DoPeriodicTask(2,KeepTargetFn,nil,target)
        end
        if inst.searchtask~=nil then
            inst.searchtask:Cancel()
            inst.searchtask = nil
        end
    end
end

local function GetHost(inst)
    return  inst.__host
end

local function StartTrackingTarget(inst,target)
    if target then
        inst.__host = target
        inst:ListenForEvent("enterlimbo", inst.ontargetloss, target)
        inst:ListenForEvent("onremove", inst.ontargetloss, target)
        inst:ListenForEvent("death", inst.ontargetloss, target)
    end
end

local function StopTrackingTarget(inst)
    local target = inst.__host

    if inst.entity:IsAwake() and inst.searchtask==nil then
        inst.searchtask = inst:DoPeriodicTask(2,SearchForPlayer)
    end

    inst.__host = nil
    inst:RemoveEventCallback("enterlimbo", inst.ontargetloss, target)
    inst:RemoveEventCallback("onremove", inst.ontargetloss, target)
    inst:RemoveEventCallback("death", inst.ontargetloss, target)

    if inst.task~=nil then
        inst.task:Cancel()
        inst.task = nil
    end

    if inst.keeptargettask~=nil then
        inst.keeptargettask:Cancel()
        inst.keeptargettask = nil
    end

    inst:PushEvent("target_loss",{host = target})
end

local function OnEntityWake(inst)
    if inst.searchtask==nil and inst.__host==nil then
        inst.searchtask = inst:DoPeriodicTask(2,SearchForPlayer)
    end
end

local function OnEntitySleep(inst)
    if inst.searchtask~=nil then
        inst.searchtask:Cancel()
        inst.searchtask = nil
    end
    if inst.keeptargettask ~= nil then
        inst.keeptargettask:Cancel()
        inst.keeptargettask = nil
    end
    inst:StopTrackingTarget()
end


local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddFollower()
	inst.entity:AddNetwork()

	MakeCharacterPhysics(inst, 10, 0.9)
	inst.Physics:ClearCollisionMask()
	inst.Physics:SetCollisionGroup(COLLISION.SANITY)
	inst.Physics:CollidesWith(COLLISION.SANITY)
	inst.Physics:CollidesWith(COLLISION.WORLD)

	inst.Transform:SetSixFaced()

	inst:AddTag("shadowcreature")
	inst:AddTag("monster")
	inst:AddTag("hostile")
	inst:AddTag("shadow")
	inst:AddTag("notraptrigger")
	inst:AddTag("shadow_aligned")


	inst.AnimState:SetBank("shadow_leech")
	inst.AnimState:SetBuild("shadow_leech")
	inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:SetMultColour(1, 1, 1, .5)

	if not TheNet:IsDedicated() then
		-- this is purely view related
		inst:AddComponent("transparentonsanity")
		inst.components.transparentonsanity.most_alpha = .8
		inst.components.transparentonsanity.osc_amp = .1
		inst.components.transparentonsanity:ForceUpdate()
	end

    inst:SetPrefabNameOverride("shadow_leech")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aurafn = CalcSanityAura

	inst:AddComponent("health")
	inst.components.health:SetMaxHealth(TUNING.SHADOW_LEECH_HEALTH)
	inst.components.health.nofadeout = true

	inst:AddComponent("combat")

	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetLoot(LOOT)

	inst:AddComponent("locomotor")
	inst.components.locomotor.runspeed = TUNING.SHADOW_LEECH_RUNSPEED
	inst.components.locomotor:SetTriggersCreep(false)
	inst.components.locomotor.pathcaps = { ignorecreep = true }

	inst:SetStateGraph("SGabyss_leech")
	inst:SetBrain(brain)

	inst.ToggleBrain = ToggleBrain
	inst.OnSpawnedBy = OnSpawnedBy
    inst.AttachTarget = AttachTarget

    inst.__host = nil
    inst.GetHost = GetHost

    inst.StartTrackingTarget = StartTrackingTarget
    inst.StopTrackingTarget = StopTrackingTarget

    inst.ontargetloss = function (target) inst:StopTrackingTarget() end
    inst._on_portal_removed = function ()
        if inst:IsAsleep() then
            inst:Remove()
        else
            inst:StopTrackingTarget()
            inst.components.lootdropper:SetLoot(nil)
            inst:PushEvent("death")
        end
    end

    inst.OnEntityWake = OnEntityWake
    inst.OnEntitySleep = OnEntitySleep

    --inst.OnSave = OnSave
    --inst.OnLoadPostPass = OnLoadPostPass

	return inst
end

return Prefab("abyss_leech", fn, assets, prefabs)
