local assets_robin =
{
    Asset("ANIM", "anim/mutated_robin.zip"),
    Asset("ANIM", "anim/bird_mutant_spitter_build.zip"),
}

local function OnDeath(inst)
    inst.AnimState:PlayAnimation("death")
    inst.SoundEmitter:PlaySound("rifts2/thrall_generic/vocalization_death")
    inst.SoundEmitter:PlaySound("rifts2/thrall_generic/death_cloth")

    inst:AddTag("NOCLICK")
    inst:RemoveEventCallback("death", OnDeath)
    inst:ListenForEvent("animover", inst.Remove)
end


local function DoCast(inst,target)
	inst.AnimState:PlayAnimation("cast")
	inst.AnimState:PushAnimation("walk_loop", true)
	inst.SoundEmitter:PlaySound("rifts2/thrall_wings/cast_f0")
	inst.SoundEmitter:PlaySound("rifts2/thrall_generic/vocalization_big")
	if target ~= nil and target:IsValid() then
		inst._target = target
		inst._targetpos = target:GetPosition()
		inst:ForceFacePoint(inst._targetpos)
	end
	inst:DoTaskInTime(0.8,function (inst)
		local x, y, z = inst.Transform:GetWorldPosition()
		local pos = inst._targetpos
		if inst._target ~= nil then
			if inst._target:IsValid() then
				pos.x, pos.y, pos.z = inst._target.Transform:GetWorldPosition()
			end
			inst._target = nil
		end
		local dir
		if pos ~= nil then
			inst:ForceFacePoint(pos)
			dir = inst.Transform:GetRotation() * DEGREES
		else
			dir = inst.Transform:GetRotation() * DEGREES
			pos = Vector3(x + 8 * math.cos(dir), 0, z - 8 * math.sin(dir))
		end

		local targets = {} --shared table for the whole patch of particles
		local sfx = {} --shared table so we only play sfx once for the whole batch
		local proj = SpawnPrefab("shadowthrall_projectile_fx")
		proj.Physics:Teleport(x, y, z)
		proj.targets = targets
		proj.components.complexprojectile.usehigharc = false
		proj.components.complexprojectile:SetHorizontalSpeed(20)
		proj.components.complexprojectile:SetGravity(-20)
		proj.sfx = sfx
		proj.components.complexprojectile:Launch(pos, inst)

		dir = dir + PI
		local pos1 = Vector3(0, 0, 0)
		for i = 0, 2 do
			local theta = dir + TWOPI / 3 * i
			pos1.x = pos.x + 2 * math.cos(theta)
			pos1.z = pos.z - 2 * math.sin(theta)
			local proj = SpawnPrefab("shadowthrall_projectile_fx")
			proj.Physics:Teleport(x, y, z)
			proj.targets = targets
			proj.sfx = sfx
			proj.components.complexprojectile.usehigharc = false
			proj.components.complexprojectile:SetHorizontalSpeed(20)
			proj.components.complexprojectile:SetGravity(-20)
			proj.components.complexprojectile:Launch(pos1, inst)
		end
	end)
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

	inst.AnimState:SetBank("shadow_thrall_wings")
	inst.AnimState:SetBuild("shadow_thrall_wings")
	inst.AnimState:PlayAnimation("fx_flame", true)
	inst.AnimState:SetSymbolLightOverride("fx_flame_red", 1)
	inst.AnimState:SetSymbolLightOverride("fx_red", 1)
	inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()))

	return inst
end

local function CreateFabricFx()
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

	inst.AnimState:SetBank("shadow_thrall_wings")
	inst.AnimState:SetBuild("shadow_thrall_wings")
	inst.AnimState:PlayAnimation("fx_fabric", true)
	inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()))

	return inst
end

local function CreateCapeFx()
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

	inst.AnimState:SetBank("shadow_thrall_wings")
	inst.AnimState:SetBuild("shadow_thrall_wings")
	inst.AnimState:PlayAnimation("fx_cape_front", true)
	inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()))

	return inst
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("shadow_thrall_wings")
	inst.AnimState:SetBuild("shadow_thrall_wings")
	inst.AnimState:PlayAnimation("walk_loop", true)
	inst.AnimState:SetSymbolLightOverride("fx_red", 1)
	inst.AnimState:SetSymbolLightOverride("fx_red_particle", 1)
	inst.AnimState:SetSymbolLightOverride("wingend_red", 1)
    --inst.AnimState:SetBloomEffectHandle(resolvefilepath("shaders/red_shader.ksh"))


	--Dedicated server does not need to spawn the local fx
	if not TheNet:IsDedicated() then
		local flames = CreateFlameFx()
		flames.entity:SetParent(inst.entity)
		flames.Follower:FollowSymbol(inst.GUID, "fx_flame_swap", nil, nil, nil, true)

		local fabric = CreateFabricFx()
		fabric.entity:SetParent(inst.entity)
		fabric.Follower:FollowSymbol(inst.GUID, "fx_fabric_swap", nil, nil, nil, true)

		local cape = CreateCapeFx()
		cape.entity:SetParent(inst.entity)
		cape.Follower:FollowSymbol(inst.GUID, "cape_front_swap", nil, nil, nil, true)

		inst.highlightchildren = { flames, fabric, cape }

	end

    inst:AddTag("hostile")
    inst:AddTag("eyeofterror")
    inst:AddTag("notraptrigger")
	inst:AddTag("shadow_aligned")
    inst.controller_priority_override_is_targeting_player = true

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(1200)
    inst.components.health.nofadeout = true

    inst:AddComponent("planarentity")

    inst:AddComponent("combat")

	inst.DoCast = DoCast

    inst:ListenForEvent("death", OnDeath)
    

    return inst
end

return Prefab("soul_seeker",fn,assets_robin)