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
	"dragoon",
	"rocks",
	"groundpound_fx",
	"groundpoundring_fx",
	"firerainshadow",
}

SetSharedLootTable( 'dragoonegg',
{
    {'flint',     1.0},
    {'flint',     0.5},
    {'rocks',     1.0},
    {'rocks',     0.5},
    {'rocks',     0.3},
	{'obsidian',  0.5},
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
		local dragoon = SpawnPrefab("dragoon")
		dragoon.Transform:SetPosition(inst.Transform:GetWorldPosition())
--		dragoon.components.combat:SuggestTarget(ThePlayer)
		dragoon.sg:GoToState("taunt")
		inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
		inst:Remove()
	end)
end

local function groundfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddSoundEmitter()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst.AnimState:SetBuild("draegg")
	inst.AnimState:SetBank("meteor")
	inst.AnimState:PlayAnimation("egg_idle")
	inst:AddTag("dragoonegg")
	MakeObstaclePhysics(inst, 1.)
	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst:AddComponent("inspectable")
	inst:AddComponent("lootdropper")
	inst.components.lootdropper:SetChanceLootTable("dragoonegg")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.MINE)
	inst.components.workable:SetWorkLeft(ROCKS_MINE*3)
	
	inst.components.workable:SetOnFinishCallback(
		function(inst, worker)
			inst.SoundEmitter:PlaySound("dontstarve/wilson/rock_break")
			inst.components.lootdropper:DropLoot()
			inst:Remove()
		end)

	inst:DoTaskInTime(0.25 * DRAGOONEGG_HATCH_TIMER, cracksmall)
	inst:DoTaskInTime(0.5 * DRAGOONEGG_HATCH_TIMER, crackmed)
	inst:DoTaskInTime(0.75 * DRAGOONEGG_HATCH_TIMER, crackbig)
	inst:DoTaskInTime(DRAGOONEGG_HATCH_TIMER, hatch)
	
	
	return inst
end

-------
local function TryToSpawnEgg(inst, map, x, y, z)
    -- if IsSurroundedByLandTile(x, y, z, 2) then
    -- Now changes with world overhang
    if map:IsSurroundedByLand(x, y, z, 2) then
        local lava = SpawnPrefab("dragoonegg")
        lava.AnimState:PlayAnimation("egg_crash")
        lava.AnimState:PushAnimation("egg_idle", false)
        lava.AnimState:PlayAnimation("egg_idle")
        lava.Transform:SetPosition(x, y, z)
    end
    inst:Remove()
end

local function DoStep(inst)
	local _map = TheWorld.Map
	local x, y, z = inst.Transform:GetWorldPosition()
	local pos=Vector3(x,y,z)


    local tile = _map:GetTileAtPoint(x, y, z)


    local invalid_land = _map:GetPlatformAtPoint(x, y, z) ~= nil

    if invalid_land or IsLandTile(tile) then
        inst.SoundEmitter:PlaySound("ia/common/volcano/rock_smash")
        inst.components.groundpounder.numRings = 4
        inst.components.groundpounder.burner = true
		inst.components.groundpounder.groundpoundFn = invalid_land and inst.Remove or function(_inst) TryToSpawnEgg(_inst, _map, x, y, z) end
        -- IsSurroundedByLandTile(x, y, z, 2)
        -- Now changes with world overhang
    elseif IsOceanTile(tile) then
        SpawnAttackWaves(pos, 0, 2, 8,360)
        inst.SoundEmitter:PlaySound("ia/common/volcano/rock_splash")
        --inst.components.groundpounder.numRings = 0
        inst.components.groundpounder.burner = true
        --inst.components.groundpounder.groundpoundfx = nil
		inst.components.groundpounder.groundpoundFn = inst.Remove
    end
	inst.components.groundpounder:GroundPound()
end



local function StartStep(inst)
	local shadow = SpawnPrefab("firerainshadow")
	shadow.Transform:SetPosition(inst.Transform:GetWorldPosition())
	shadow.Transform:SetRotation(math.random(0, 360))--(GetRotation(inst))
	inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/bomb_fall")
	inst:DoTaskInTime(VOLCANO_FIRERAIN_WARNING - (7*FRAMES), DoStep)
	inst:DoTaskInTime(VOLCANO_FIRERAIN_WARNING - (17*FRAMES), function(inst)
		inst:Show()
		local x, y, z = inst.Transform:GetWorldPosition()
		local ground = TheWorld.Map:GetTileAtPoint(x, y, z)
		if ground == WORLD_TILES.IMPASSABLE or IsOceanTile(ground) then
			inst.AnimState:PlayAnimation("idle")
		else
			inst.AnimState:PlayAnimation("egg_crash_pre")
		end
	end)
end

local function GroundPound(self, pt)
	pt = pt or self.inst:GetPosition()
	local tile = TheWorld.Map:GetTileAtPoint(pt.x, 0, pt.z)

	if self.groundpoundringfx and not IsOceanTile(tile) then
		local ring = SpawnPrefab(self.groundpoundringfx)
		ring.Transform:SetScale(self.ring_fx_scale, self.ring_fx_scale, self.ring_fx_scale)
		ring.Transform:SetPosition(pt:Get())
	end
	local points = self:GetPoints(pt)
	local delay = 0
	self.ignoreEnts = nil
	for i = 1, self.numRings do
		self.inst:DoTaskInTime(delay, function()
			self:DestroyPoints(points[i], i <= self.destructionRings, i <= self.damageRings)
			if i == self.numRings and self.groundpoundFn then
				self.groundpoundFn(self.inst)
			end
		end)

		delay = delay + self.ringDelay
	end
end

local function DestroyPoints(self, points, breakobjects, dodamage)
	local getEnts = breakobjects or dodamage

	for k,v in pairs(points) do
		local ents = nil
		if getEnts then
			ents = TheSim:FindEntities(v.x, v.y, v.z, 4, nil, { "FX", "NOCLICK", "DECOR", "INLIMBO" ,"dragoonegg"})
		end
		if ents and breakobjects then
		    -- first check to see if there's crops here, we want to work their farm
		    for k2,v2 in pairs(ents) do
		        if v2 and self.burner and v2.components.burnable and not v2:HasTag("fire") and not v2:HasTag("burnt") and not v2:HasTag("wildfireprotected") then
		        	v2.components.burnable:Ignite()
		        end
		    	-- Don't net any insects when we do work
		        if v2 and self.destroyer and v2.components.workable and v2.components.workable.workleft > 0 and v2.components.workable.action ~= ACTIONS.NET then
	        	    v2.components.workable:Destroy(self.inst)
				end
		        if v2 and self.destroyer and v2.components.crop then
			    	-- print("Has Crop:",v2)
	        	    v2.components.crop:ForceHarvest()
				end
				if v2 ~= nil and v2:HasTag("boat") then
					v2.components.health:DoDelta(-50)
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

		if TheWorld.Map then
			local ground = TheWorld.Map:GetTileAtPoint(v.x, 0, v.z)

			if ground == WORLD_TILES.IMPASSABLE or IsOceanTile(ground) then
				-- Maybe do some water fx here?
			else
				if self.groundpoundfx then
					SpawnPrefab(self.groundpoundfx).Transform:SetPosition(v.x, 0, v.z)
				end
			end
		end
	end
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
	
	inst:AddComponent("groundpounder")
	inst.components.groundpounder.numRings = 4
	inst.components.groundpounder.ringDelay = 0.1
	inst.components.groundpounder.initialRadius = 1
	inst.components.groundpounder.radiusStepDistance = 2
	inst.components.groundpounder.pointDensity = .25
	inst.components.groundpounder.damageRings = 1
	inst.components.groundpounder.destructionRings = 1
	inst.components.groundpounder.destroyer = true
	inst.components.groundpounder.burner = true
	inst.components.groundpounder.ring_fx_scale = 0.75
	inst.components.groundpounder.GroundPound = GroundPound
	inst.components.groundpounder.DestroyPoints = DestroyPoints

	inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(VOLCANO_FIRERAIN_DAMAGE)

	inst.DoStep = DoStep
	inst.StartStep = StartStep

	inst:Hide()

	return inst
end


return Prefab( "dragoonegg", groundfn, assets, prefabs),
	   Prefab( "dragoonegg_falling", fallingfn, assets, prefabs)
