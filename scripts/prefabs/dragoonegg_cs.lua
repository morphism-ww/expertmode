local assets=
{
	Asset("ANIM", "anim/dragoon_egg.zip"),
}

local ROCKS_MINE = 6
local DRAGOONEGG_HATCH_TIMER = 10
local VOLCANO_FIRERAIN_WARNING = 2
local VOLCANO_FIRERAIN_DAMAGE = 200


local prefabs = 
{
	"dragoon_cs",
	"rocks",
	"flint",
	"obsidian",
	"groundpound_fx",
	"firerainshadow_cs",
}

SetSharedLootTable( 'dragoonegg',
{
    {'flint',     1.0},
    {'flint',     0.5},
    {'rocks',     1.0},
    {'rocks',     0.5},
	{'obsidian',  1},
})

local function cracksound(inst, loudness) --is this worth a stategraph?
	inst:DoTaskInTime(11*FRAMES, function(inst)
		inst.SoundEmitter:PlaySound("dontstarve_DLC002/creatures/dragoon/meteor_shake")
	end)
	inst:DoTaskInTime(24*FRAMES, function(inst)
		inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC002/creatures/dragoon/meteor_land", {loudness=loudness})
	end)
end

local function cracksmall(inst)
	inst.AnimState:PlayAnimation("crack_small")
	inst.AnimState:PushAnimation("crack_small_idle", true)
	cracksound(inst, 0.2)
end

local function crackmed(inst)
	inst.AnimState:PlayAnimation("crack_med")
	inst.AnimState:PushAnimation("crack_med_idle", true)
	cracksound(inst, 0.5)
end

local function crackbig(inst)
	inst.AnimState:PlayAnimation("crack_big")
	inst.AnimState:PushAnimation("crack_big_idle", true)
	cracksound(inst, 0.7)
end

local function hatch(inst)
	inst.AnimState:PlayAnimation("egg_hatch")
	
	-- inst:ListenForEvent("animover", function(inst) 
	inst:DoTaskInTime(1, function()
		local dragoon = SpawnPrefab("dragoon_cs")
		dragoon.Transform:SetPosition(inst.Transform:GetWorldPosition())
		dragoon.sg:GoToState("taunt")
		inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
		inst:Remove()
	end)
end

local function OnWork(inst)
	inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
	local pt = inst:GetPosition()
	SpawnPrefab("rock_break_fx").Transform:SetPosition(pt.x, pt.y, pt.z)
	inst.components.lootdropper:DropLoot(pt)
	inst:Remove()	
end

local function groundfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddSoundEmitter()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, 1)

	inst.AnimState:SetBuild("draegg")
	inst.AnimState:SetBank("meteor")
	inst.AnimState:PlayAnimation("egg_idle")

	inst:AddTag("meteor_protection")

	
	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("inspectable")
	
	inst:AddComponent("groundpounder")
	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("dragoonegg")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.MINE)
	inst.components.workable:SetWorkLeft(ROCKS_MINE)
	inst.components.workable:SetOnFinishCallback(OnWork)


	inst:DoTaskInTime(0.25 * DRAGOONEGG_HATCH_TIMER, cracksmall)
	inst:DoTaskInTime(0.5 * DRAGOONEGG_HATCH_TIMER, crackmed)
	inst:DoTaskInTime(0.75 * DRAGOONEGG_HATCH_TIMER, crackbig)
	inst:DoTaskInTime(DRAGOONEGG_HATCH_TIMER, hatch)
	
	
	return inst
end

-------
local function TryToSpawnEgg(inst)
	local x,y,z = inst.Transform:GetWorldPosition()

	local lava = SpawnPrefab("dragoonegg_cs")
	lava.AnimState:PlayAnimation("egg_crash")
	lava.AnimState:PushAnimation("egg_idle")
	lava.Transform:SetPosition(x, y, z)
    inst:Remove()
end

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
local NON_SMASHABLE_TAGS = { "INLIMBO", "playerghost", "meteor_protection","dragoonegg" }

local function onexplode(inst,spawnegg)
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
	if spawnegg then
		TryToSpawnEgg(inst)
	end
	inst:Remove()
end		



local function DoStep(inst)
	local _map = TheWorld.Map
	local x, y, z = inst.Transform:GetWorldPosition()
	local pos = Vector3(x,y,z)

	if _map:IsVisualGroundAtPoint(x,0,z) then
		inst.SoundEmitter:PlaySound("ia/common/volcano/rock_smash")
		onexplode(inst,true)
	else
		local platform = inst:GetCurrentPlatform()
		if platform ~= nil and platform:IsValid() and platform:HasTag("boat") then
			platform.components.health:DoDelta(-50)
			platform:PushEvent("spawnnewboatleak", {pt = pos, leak_size = "med_leak", playsoundfx = true})
		end
		SpawnAttackWaves(pos, 0, 2, 8,360)
        inst.SoundEmitter:PlaySound("ia/common/volcano/rock_splash")
		onexplode(inst)
	end
end



local function StartStep(inst)
	local x, y, z = inst.Transform:GetWorldPosition()

	local shadow = SpawnPrefab("firerainshadow_cs")
	shadow.Transform:SetPosition(x,y,z)
	shadow.Transform:SetRotation(math.random(360))
	inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/bomb_fall")

	inst:DoTaskInTime(VOLCANO_FIRERAIN_WARNING - (7*FRAMES), DoStep)
	inst:DoTaskInTime(VOLCANO_FIRERAIN_WARNING - (17*FRAMES), 
	function(inst)
		inst:Show()
		if TheWorld.Map:IsVisualGroundAtPoint(x,y,z) then
			inst.AnimState:PlayAnimation("egg_crash_pre")
		else
			inst.AnimState:PlayAnimation("idle")
		end
	end)
end


local function fallingfn()
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

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(VOLCANO_FIRERAIN_DAMAGE)

	inst.DoStep = DoStep
	inst.StartStep = StartStep
	inst:AddComponent("groundpounder")

	inst:Hide()

	return inst
end


return Prefab( "dragoonegg_cs", groundfn, assets, prefabs),
	   Prefab( "dragoonegg_falling_cs", fallingfn, assets, prefabs)
