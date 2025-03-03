local assets =
{
	Asset("ANIM", "anim/ia_meteor.zip"),
	Asset("ANIM", "anim/ia_meteor_shadow.zip")
}

local prefabs =
{
	"newcs_lavapool",
    "groundpound_fx",
    "newcs_firerainshadow",
    "burntground"
}

local easing = require("easing")

local VOLCANO_FIRERAIN_WARNING = 2
local SMASHABLE_WORK_ACTIONS =
{
    CHOP = true,
    DIG = true,
    HAMMER = true,
    MINE = true,
}
local SMASHABLE_TAGS = { "_combat", "_inventoryitem", "NPC_workable" }
for k, v in pairs(SMASHABLE_WORK_ACTIONS) do
    table.insert(SMASHABLE_TAGS, k.."_workable")
end
local NON_SMASHABLE_TAGS = { "INLIMBO", "playerghost", "meteor_protection","FX" }

local function onexplode(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/meteor_impact")

    local x, y, z = inst.Transform:GetWorldPosition()

	local ents = TheSim:FindEntities(x, y, z, 4, nil, NON_SMASHABLE_TAGS, SMASHABLE_TAGS)
	for i, v in ipairs(ents) do
		--V2C: things "could" go invalid if something earlier in the list
		--     removes something later in the list.
		--     another problem is containers, occupiables, traps, etc.
		--     inconsistent behaviour with what happens to their contents
		--     also, make sure stuff in backpacks won't just get removed
		--     also, don't dig up spawners
		if v:IsValid() and not v:IsInLimbo() then
			if v.components.workable ~= nil then
				if v.components.workable:CanBeWorked() and not (v.sg ~= nil and v.sg:HasStateTag("busy")) then
					local work_action = v.components.workable:GetWorkAction()
					--V2C: nil action for NPC_workable (e.g. campfires)
					if (    (work_action == nil and v:HasTag("NPC_workable")) or
							(work_action ~= nil and SMASHABLE_WORK_ACTIONS[work_action.id]) ) and
						(work_action ~= ACTIONS.DIG
						or (v.components.spawner == nil and
							v.components.childspawner == nil)) then
						v.components.workable:WorkedBy(inst, inst.workdone or 20)
					end
				end
			elseif v.components.combat ~= nil then
				v.components.combat:GetAttacked(inst, 250)
			end
        end
	end
	if TheWorld.components.dockmanager ~= nil then
        TheWorld.components.dockmanager:DamageDockAtPoint(x, y, z, 50)
    end
	SpawnPrefab("groundpound_fx").Transform:SetPosition(x, 0, z)
	inst:Remove()
end		

local VOLCANO_FIRERAIN_DAMAGE = 150

local function DoStep(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local world = TheWorld

	if world.Map:IsOceanAtPoint(x, y, z, true) then
		inst.SoundEmitter:PlaySound("ia/common/volcano/rock_smash")
		
		local platform = inst:GetCurrentPlatform()
		if platform ~= nil and platform:IsValid() and platform:HasTag("boat") then
			platform.components.health:DoDelta(-VOLCANO_FIRERAIN_DAMAGE*0.5)
			platform:PushEvent("spawnnewboatleak", {pt = pos, leak_size = "med_leak", playsoundfx = true})
		else
			SpawnAttackWaves(Vector3(x,y,z), 0, 2, 8,360)
		end
		
		--onexplode(inst,true)
		inst.components.groundpounder.fxRings = 0
		inst.components.groundpounder:GroundPound()

	elseif world.Map:IsLandTileAtPoint(x, y, z) then

		if world.Map:IsDockAtPoint(x, y, z) then
			if world.components.dockmanager ~= nil then
				world.components.dockmanager:DamageDockAtPoint(x, y, z, VOLCANO_FIRERAIN_DAMAGE)
			end
		elseif world.Map:IsSurroundedByLand(x, 0, z, 2) then
			if math.random()<0.4 then
				SpawnPrefab("newcs_lavapool").Transform:SetPosition(x,y,z)
			else
				SpawnPrefab("burntground").Transform:SetPosition(x,y,z)
			end
		end

		inst.SoundEmitter:PlaySound("ia/common/volcano/rock_splash")

		inst.components.groundpounder.burner = true
		inst.components.groundpounder:GroundPound()
        
	end
end


local function StartStep(inst)

	local x, y, z = inst.Transform:GetWorldPosition()
	local shadow = SpawnPrefab("newcs_firerainshadow")
	shadow.Transform:SetPosition(x,y,z)
	shadow.Transform:SetRotation(math.random(360))
	inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/bomb_fall")

	inst:DoTaskInTime(VOLCANO_FIRERAIN_WARNING - (5*FRAMES), DoStep)
	inst:DoTaskInTime(VOLCANO_FIRERAIN_WARNING - (14*FRAMES), 
	function(inst)
		inst:Show()
		inst.AnimState:PlayAnimation("idle")
		inst.persists = false

		inst:ListenForEvent("animover", inst.Remove)
		inst.OnEntitySleep = inst.Remove
	end)
end

local function firerainfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst.Transform:SetFourFaced()

	inst.AnimState:SetBank("meteor")
	inst.AnimState:SetBuild("ia_meteor")

	inst:AddTag("FX")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("groundpounder")
	inst.components.groundpounder:UseRingMode()
	inst.components.groundpounder.ringDelay = 0.1
	inst.components.groundpounder.radiusStepDistance = 2
	inst.components.groundpounder.damageRings = 2
	inst.components.groundpounder.destructionRings = 3
	inst.components.groundpounder.destroyer = true

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(VOLCANO_FIRERAIN_DAMAGE)

	inst.DoStep = DoStep
	inst.StartStep = StartStep

	inst:Hide()

	return inst
end

local StartingScale = 2
local TimeToImpact = 2

local function LerpIn(inst)
	local s = easing.inExpo(inst:GetTimeAlive(), 1, 1 - StartingScale, TimeToImpact)

	inst.Transform:SetScale(s,s,s)
	if s >= StartingScale then
		inst.sizeTask:Cancel()
		inst.sizeTask = nil
	end
end

local function OnRemove(inst)
	if inst.sizeTask~=nil then
		inst.sizeTask:Cancel()
		inst.sizeTask = nil
	end
end


local function shadowfn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	
	inst.AnimState:SetBank("meteor_shadow")
	inst.AnimState:SetBuild("ia_meteor_shadow")
	inst.AnimState:PlayAnimation("idle")
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(3)

	inst.AnimState:SetMultColour(0,0,0,0)
	inst.Transform:SetScale(2,2,2)

	inst:AddTag("FX")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
        return inst
    end

	inst.persists = false
	
	inst:AddComponent("colourtweener")
	inst.components.colourtweener:StartTween({0,0,0,1}, TimeToImpact, inst.Remove)

	inst.OnRemoveEntity = OnRemove

	inst.sizeTask = inst:DoPeriodicTask(FRAMES, LerpIn)

	return inst
end



local assets_firemeteor = {
    Asset("ANIM", "anim/lavaarena_firestaff_meteor.zip"),
	Asset("ANIM", "anim/lavaarena_fire_fx.zip"),
}

local meteorprefabs = {
	"firemeteor_splash_fx"
}

local NON_SMASHABLE_TAGS_PVE = { "INLIMBO", "player", "meteor_protection","FX" }

local function DoAOEAttack(inst)
    inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/meteor_strike")
	
    local x, y, z = inst.Transform:GetWorldPosition()
	SpawnPrefab("firemeteor_splash_fx").Transform:SetPosition(x,0,z)

	local shouldattack = inst.caster and inst.caster.isplayer and not inst.caster.components.health:IsDead()
	local hitradius = 4
	local ents = TheSim:FindEntities(x, y, z, hitradius + 3, nil, NON_SMASHABLE_TAGS_PVE, SMASHABLE_TAGS)
	for i, v in ipairs(ents) do

		if v:IsValid() and not (v.components.health ~= nil and v.components.health:IsDead()) then
			local range = hitradius + v:GetPhysicsRadius(.5)
            local dsq_to_laser = v:GetDistanceSqToPoint(x, y, z)
            if dsq_to_laser < range * range then
				local isworkable = false
					if v.components.workable ~= nil then
						local work_action = v.components.workable:GetWorkAction()
						--V2C: nil action for NPC_workable (e.g. campfires)
						isworkable =
							(   work_action == nil and v:HasTag("NPC_workable") ) or
							(   v.components.workable:CanBeWorked() and
								(   work_action == ACTIONS.CHOP or
									work_action == ACTIONS.HAMMER or
									work_action == ACTIONS.MINE or
									(   work_action == ACTIONS.DIG and
										v.components.spawner == nil and
										v.components.childspawner == nil
									)
								)
							)
					end
				if isworkable then
					v.components.workable:WorkedBy(shouldattack and inst.caster or inst,10)

					-- Completely uproot trees.
					if v:HasTag("stump") then
						v:Remove()
					end
				elseif not v:IsInLimbo() and v:IsValid() then
					if v.components.fueled == nil and
						v.components.burnable ~= nil and
						not v.components.burnable:IsBurning() and
						not v:HasTag("burnt") then
						v.components.burnable:Ignite()
					end			
					if shouldattack and inst.caster.components.combat:CanTarget(v) then
						v.components.combat:GetAttacked(inst.caster, 100)
					end	
				end
			end		
        end
	end

	if TheWorld.components.dockmanager ~= nil then
        TheWorld.components.dockmanager:DamageDockAtPoint(x, y, z, 50)
    end
	
	inst:Remove()
end

local function OnImpact(inst)
	inst.AnimState:PushAnimation("crash_pst",false)
	inst:DoTaskInTime(3*FRAMES, DoAOEAttack)
end

local function CreatesplashbaseFx(shadow)
	local inst = CreateEntity()

	inst:AddTag("FX")
	--[[Non-networked entity]]
	inst.entity:SetCanSleep(false)
	inst.persists = false

	inst.entity:AddTransform()
	
	inst.entity:AddAnimState()
	inst.AnimState:SetBank("lavaarena_fire_fx")
	inst.AnimState:SetBuild("lavaarena_fire_fx")
	inst.AnimState:PlayAnimation("firestaff_ult_projection")
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(3)
	if shadow then
		inst.AnimState:SetAddColour(160/255,32/255,240/255,1)
	end

	inst:ListenForEvent("animover",inst.Remove)
	return inst
end

local function CreatesplashFx()
	local inst = CreateEntity()

	inst:AddTag("FX")
	--[[Non-networked entity]]
	inst.entity:SetCanSleep(false)
	inst.persists = false

	inst.entity:AddTransform()
	
	inst.entity:AddAnimState()
	inst.AnimState:SetBank("lavaarena_fire_fx")
	inst.AnimState:SetBuild("lavaarena_fire_fx")
	inst.AnimState:PlayAnimation("firestaff_ult")
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetFinalOffset(1)

	inst:ListenForEvent("animover",inst.Remove)
	return inst
end




local function meteorfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()


    inst.AnimState:SetBank("lavaarena_firestaff_meteor")
	inst.AnimState:SetBuild("lavaarena_firestaff_meteor")
	inst.AnimState:PlayAnimation("crash")
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

	inst:AddTag("FX")


	inst.entity:SetPristine()
	------------------------------------------
	if not TheWorld.ismastersim then
        return inst
    end

	inst.persists = false


	inst:ListenForEvent("animover", OnImpact)
	return inst
end


local function createshadowflamefx()
	local inst = CreateEntity()

	inst:AddTag("FX")
	--[[Non-networked entity]]
	inst.entity:SetCanSleep(false)
	inst.persists = false

	inst.entity:AddTransform()
	
	inst.entity:AddAnimState()
	inst.AnimState:SetBank("lavaarena_player_teleport")
	inst.AnimState:SetBuild("lavaarena_player_teleport")
	inst.AnimState:PlayAnimation("idle")
	inst.AnimState:SetScale(1.5,1.5,1.5)
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

	inst:ListenForEvent("animover",inst.Remove)
	return inst
end

local function startfx(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	
	local fx2 = CreatesplashbaseFx()
	fx2.Transform:SetPosition(x,0,z)

	local fx1 =CreatesplashFx()
	fx1.Transform:SetPosition(x,0,z)
	
end


local function splashfx()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddNetwork()

	--Dedicated server does not need to spawn the local fx
	if not TheNet:IsDedicated() then
		--Delay one frame so that we are positioned properly before starting the effect
		--or in case we are about to be removed

		inst:DoTaskInTime(0, startfx)
	end


	inst:AddTag("FX")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.persists = false
	inst:DoTaskInTime(1, inst.Remove)

	return inst
end


local function startfx2(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	
	local fx2 = CreatesplashbaseFx(true)
	fx2.Transform:SetPosition(x,0,z)

	--local fx1 =createshadowflamefx()
	--fx1.Transform:SetPosition(x,0,z)
	
end


local function splashfx2()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddNetwork()

	--Dedicated server does not need to spawn the local fx
	if not TheNet:IsDedicated() then
		--Delay one frame so that we are positioned properly before starting the effect
		--or in case we are about to be removed

		inst:DoTaskInTime(0, startfx2)
	end


	inst:AddTag("FX")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.persists = false
	inst:DoTaskInTime(1, inst.Remove)

	return inst
end



return Prefab("newcs_firerain", firerainfn, assets, prefabs),
		Prefab("newcs_firerainshadow", shadowfn, assets, prefabs),
		Prefab("firerain_summon",meteorfn,assets_firemeteor,meteorprefabs),
		Prefab("firemeteor_splash_fx",splashfx,assets_firemeteor),
		Prefab("firemeteor_splash_fx2",splashfx2,assets_firemeteor)
