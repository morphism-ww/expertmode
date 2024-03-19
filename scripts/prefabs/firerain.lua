local IsOceanTile = IsOceanTile
local IsLandTile = IsLandTile
local assets =
{
	Asset("ANIM", "anim/ia_meteor.zip"),
	Asset("ANIM", "anim/ia_meteor_shadow.zip")
}

local prefabs =
{
	"lavapool",
    "groundpound_fx",
    "groundpoundring_fx",
    "firerainshadow",
    "meteor_impact"
}

local function DoStep(inst)
    local _world = TheWorld
	local _map = _world.Map
	local x, y, z = inst.Transform:GetWorldPosition()
	local pos=Vector3(x,y,z)

    local remove = false

    local tile = _map:GetTileAtPoint(x, y, z)

    local invalid_land = _map:GetPlatformAtPoint(x, y, z) ~= nil

    if invalid_land or IsLandTile(tile) then
        inst.SoundEmitter:PlaySound("ia/common/volcano/rock_smash")
        inst.components.groundpounder.numRings = 4
        inst.components.groundpounder.burner = true
        -- IsSurroundedByLandTile(x, y, z, 2)
        -- Now changes with world overhang
        if not invalid_land and _map:IsSurroundedByLand(x, y, z, 1) then
			if math.random() < 0.5 then
				local lavapool = SpawnPrefab("lavapool")
				lavapool.Transform:SetPosition(x, y, z)
			else
				local impact = SpawnPrefab("meteor_impact")
				impact.components.timer:StartTimer("remove", TUNING.TOTAL_DAY_TIME * 2)
				impact.Transform:SetPosition(x, y, z)
			end
		end
    elseif IsOceanTile(tile) then
        SpawnAttackWaves(pos, 0, 2, 8,360)
        inst.SoundEmitter:PlaySound("ia/common/volcano/rock_splash")
        inst.components.groundpounder.burner = false
        inst.components.groundpounder.groundpoundfx = nil
    end

    if not remove then
        inst.components.groundpounder:GroundPound()
    end
end

local function StartStep(inst)
	local shadow = SpawnPrefab("firerainshadow")
	shadow.Transform:SetPosition( inst.Transform:GetWorldPosition() )
	shadow.Transform:SetRotation( math.random(0, 360) )--(GetRotation(inst))
	inst.SoundEmitter:PlaySound("ia/common/bomb_fall")
	inst:DoTaskInTime(2 - 5 * FRAMES, function() inst:DoStep() end)
	inst:DoTaskInTime(2 - 14 * FRAMES, function()
		inst:Show()
		inst.AnimState:PlayAnimation("idle")
		inst:ListenForEvent("animover",inst.Remove)
	end)
end



--[[local function DestroyPoints(self, points, breakobjects, dodamage)
	local getEnts = breakobjects or dodamage

	for k,v in pairs(points) do
		local ents = nil
		if getEnts then
			ents = TheSim:FindEntities(v.x, v.y, v.z, 4, nil, { "FX", "NOCLICK", "DECOR", "INLIMBO" ,"dragoonegg"})
		end
		if ents and breakobjects then
		    -- first check to see if there's crops here, we want to work their farm
		    for k2,v2 in pairs(ents) do
		        if v2 and self.burner and v2.components.burnable and not v2:HasTag("fire") and not v2:HasTag("burnt") then
		        	v2.components.burnable:Ignite()
		        end
		    	-- Don't net any insects when we do work
		        if v2 and self.destroyer and v2.components.workable and v2.components.workable.workleft > 0 and v2.components.workable.action ~= ACTIONS.NET then
	        	    v2.components.workable:Destroy(self.inst)
			end
		        if v2 and self.destroyer and v2.components.crop then
			    	print("Has Crop:",v2)
	        	    v2.components.crop:ForceHarvest()
				end
		    end
		end
		if ents and dodamage then
		    for k2,v2 in pairs(ents) do
		    	if not self.ignoreEnts then
		    		self.ignoreEnts = {}
		    	end
		    	if not self.ignoreEnts[v2.GUID] then --If this entity hasn't already been hurt by this groundpound

			        if v2 and v2.components.health and not v2.components.health:IsDead() and
			        self.inst.components.combat:CanTarget(v2) then
			            self.inst.components.combat:DoAttack(v2, nil, nil, nil, self.groundpounddamagemult)
			        end
			        self.ignoreEnts[v2.GUID] = true --Keep track of which entities have been hit
			    end
		    end
		end

		if self.groundpoundfx and TheWorld.Map:IsPassableAtPoint(v.x,0,v.z)then
			SpawnPrefab(self.groundpoundfx).Transform:SetPosition(v.x, 0, v.z)
		end
	end
end]]

local function firerainfn()
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	local sound = inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	trans:SetFourFaced()
	anim:SetBank("meteor")
	anim:SetBuild("ia_meteor")

	inst:AddTag("FX")
	inst:AddTag("explosive")

	if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("groundpounder")
	inst.components.groundpounder.numRings = 4
	inst.components.groundpounder.ringDelay = 0.1
	inst.components.groundpounder.initialRadius = 1
	inst.components.groundpounder.radiusStepDistance = 2
	inst.components.groundpounder.pointDensity = .25
	inst.components.groundpounder.damageRings = 3
	inst.components.groundpounder.platformPushingRings=4
	inst.components.groundpounder.destructionRings = 3
	inst.components.groundpounder.destroyer = true
	inst.components.groundpounder.burner = true
	inst.components.groundpounder.ring_fx_scale = 0.75
	inst.components.groundpounder.noTags={ "FX", "NOCLICK", "DECOR", "INLIMBO" ,"dragoonegg"}


	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(200)

	inst.DoStep = DoStep
	inst.StartStep = StartStep

	inst:Hide()

	return inst
end

local easing = require("easing")
local function LerpIn(inst)
	local s = easing.inExpo(inst:GetTimeAlive(), 1, 1 - inst.StartingScale, inst.TimeToImpact)

	inst.Transform:SetScale(s,s,s)
	if s >= inst.StartingScale then
		inst.sizeTask:Cancel()
		inst.sizeTask = nil
	end
end

local function OnRemove(inst)
	if inst.sizeTask then
		inst.sizeTask:Cancel()
		inst.sizeTask = nil
	end
end

local function Impact(inst)
	inst:Remove()
end

local function shadowfn()
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()

	anim:SetBank("meteor_shadow")
	anim:SetBuild("ia_meteor_shadow")
	anim:PlayAnimation("idle")
	anim:SetOrientation(ANIM_ORIENTATION.OnGround)
	anim:SetLayer(LAYER_BACKGROUND)
	anim:SetSortOrder(3)
	inst.entity:AddNetwork()

	inst:AddTag("FX")

	if not TheWorld.ismastersim then
        return inst
    end

	inst.persists = false

	local s = 2
	inst.StartingScale = s
	inst.Transform:SetScale(s,s,s)
	inst.TimeToImpact = 2

	inst:AddComponent("colourtweener")
	inst.AnimState:SetMultColour(0,0,0,0)
	inst.components.colourtweener:StartTween({0,0,0,1}, inst.TimeToImpact, Impact)

	inst.OnRemoveEntity = OnRemove

	inst.sizeTask = inst:DoPeriodicTask(FRAMES, LerpIn)

	return inst
end


local function StartStep2(inst)
	local shadow = SpawnPrefab("firerainshadow")
	shadow.Transform:SetPosition( inst.Transform:GetWorldPosition() )
	shadow.Transform:SetRotation( math.random(0, 360) )--(GetRotation(inst))
	inst.SoundEmitter:PlaySound("ia/common/bomb_fall")
	inst:DoTaskInTime(1.2, function()
		inst:Show()
		inst.components.groundpounder:GroundPound()
		inst.AnimState:PlayAnimation("idle")
		inst:ListenForEvent("animover",inst.Remove)
	end)
end
local function summonfn()
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	local sound = inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	trans:SetFourFaced()
	anim:SetBank("meteor")
	anim:SetBuild("ia_meteor")

	inst:AddTag("FX")
	inst:AddTag("explosive")

	if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("groundpounder")
	inst.components.groundpounder.numRings = 3
	inst.components.groundpounder.initialRadius = 1
	inst.components.groundpounder.radiusStepDistance = 2
	inst.components.groundpounder.pointDensity = .25
	inst.components.groundpounder.damageRings = 1
	inst.components.groundpounder.destructionRings = 1
	inst.components.groundpounder.destroyer = true
	inst.components.groundpounder.burner = true
	inst.components.groundpounder.noTags = { "FX", "NOCLICK", "DECOR", "INLIMBO" ,"player"}
	inst.components.groundpounder.ring_fx_scale = 0.75
	--inst.components.groundpounder.DestroyPoints = DestroyPoints

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(80)

	inst.StartStep = StartStep2

	inst:Hide()

	return inst
end

return Prefab("firerain", firerainfn, assets, prefabs),
		Prefab("firerainshadow", shadowfn, assets, prefabs),
		Prefab("firerain_summon",summonfn,assets,prefabs)
