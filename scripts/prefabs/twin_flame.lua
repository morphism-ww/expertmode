local assets =
{
	Asset("ANIM", "anim/warg_mutated_breath_fx.zip"),
}

local prefabs =
{
	"twin_flame",
}
--------------------------------------------------------------------------

local AOE_RANGE = 0.9
local AOE_RANGE_PADDING = 3
local AOE_TARGET_TAGS = { "_combat" }
local AOE_TARGET_CANT_TAGS = { "INLIMBO", "invisible", "playerghost", "eyeofterror" }
local MULTIHIT_FRAMES = 10

local function OnUpdateHitbox(inst)
	if not (inst.attacker and inst.attacker.components.combat and inst.attacker:IsValid()) then
		return
	end

	local weapon
	if inst.owner ~= inst.attacker then
		if not (inst.owner and inst.owner:IsValid()) then
			return
		elseif inst.owner.components.weapon then
			weapon = inst.owner
		end
	end

	inst.attacker.components.combat.ignorehitrange = true
	inst.attacker.components.combat.ignoredamagereflect = true
	local tick = GetTick()
	local x, y, z = inst.Transform:GetWorldPosition()
	local radius = AOE_RANGE * inst.scale
	local ents = TheSim:FindEntities(x, 0, z, radius + AOE_RANGE_PADDING, AOE_TARGET_TAGS, AOE_TARGET_CANT_TAGS)
	for i, v in ipairs(ents) do	

		if v ~= inst.attacker and v:IsValid() and not v:IsInLimbo() and v.components.health and not v.components.health:IsDead() then
			
			if not inst.attacker:HasTag("player") or not inst.attacker.components.combat:IsAlly(v) then		

				local range = radius + v:GetPhysicsRadius(0)
				if v:GetDistanceSqToPoint(x, 0, z) < range * range then
					local target_data = inst.targets[v]
					if target_data == nil then
						target_data = {}
						inst.targets[v] = target_data
					end
					if target_data.tick ~= tick then
						target_data.tick = tick
						v:AddDebuff("curse_fire", "curse_fire",{duration=10,upgrade=true})
						--Hit
						if (target_data.hit_tick == nil or target_data.hit_tick + MULTIHIT_FRAMES < tick) and inst.attacker.components.combat:CanTarget(v) then
							target_data.hit_tick = tick
							if v:HasTag("player") then
								v.components.health:DoDelta(-8,false,"curse_fire")
							else
								inst.attacker.components.combat:DoAttack(v, weapon)
							end
						end
					end
				end
			end
		end
	end
	inst.attacker.components.combat.ignorehitrange = false
	inst.attacker.components.combat.ignoredamagereflect = false
end

local function RefreshBrightness(inst)
	local k = math.min(1, inst.brightness:value() / 6)
	inst.AnimState:OverrideBrightness(1 + k * k * 0.5)
end

local function OnUpdateBrightness(inst)
	inst.brightness:set_local(inst.brightness:value() - 1)
	if inst.brightness:value() <= 0 then
		inst.updatingbrightness = false
		inst.components.updatelooper:RemoveOnUpdateFn(OnUpdateBrightness)
	end
	RefreshBrightness(inst)
end

local function OnBrightnessDirty(inst)
	RefreshBrightness(inst)
	if inst.brightness:value() > 0 and inst.brightness:value() < 7 then
		if not inst.updatingbrightness then
			inst.updatingbrightness = true
			inst.components.updatelooper:AddOnUpdateFn(OnUpdateBrightness)
		end
	elseif inst.updatingbrightness then
		inst.updatingbrightness = false
		inst.components.updatelooper:RemoveOnUpdateFn(OnUpdateBrightness)
	end
end

local function StartFade(inst)
	inst.brightness:set(6)
	OnBrightnessDirty(inst)
end

local function OnAnimQueueOver(inst)
	if inst.owner ~= nil and inst.owner.flame_pool ~= nil then
		inst.components.updatelooper:RemoveOnUpdateFn(OnUpdateHitbox)
		inst.targets = nil
		inst.brightness:set(7)
		OnBrightnessDirty(inst)
		inst:RemoveFromScene()
		table.insert(inst.owner.flame_pool, inst)
	else
		inst:Remove()
	end
end

local function KillFX(inst, fadeoption)
	if fadeoption == "nofade" then
		StartFade(inst)
	end
	inst.AnimState:PlayAnimation("flame"..tostring(math.random(3)).."_pst")
	inst.components.updatelooper:RemoveOnUpdateFn(OnUpdateHitbox)
	inst.targets = nil


end

local function SetFXOwner(inst, owner, attacker)
	inst.owner = owner
	inst.attacker = attacker or owner
end


local function RestartFX(inst, scale, fadeoption, targets)
	if inst:IsInLimbo() then
		inst:ReturnToScene()
	end

	local anim = "flame"..tostring(math.random(3))
	if not inst.AnimState:IsCurrentAnimation(anim.."_pre") then
		inst.AnimState:PlayAnimation(anim.."_pre")
		inst.AnimState:PushAnimation(anim.."_loop", true)
	end

	inst.scale = scale or 1
	inst.AnimState:SetScale(math.random() < 0.5 and -inst.scale or inst.scale, inst.scale)

	if fadeoption == "latefade" then
		inst:DoTaskInTime(10 * FRAMES, StartFade)
	elseif fadeoption ~= "nofade" then
		StartFade(inst)
	end

	inst:DoTaskInTime(math.random(16, 20) * FRAMES, KillFX, fadeoption)


	if inst.owner ~= nil then
		inst.targets = targets or {}
		inst.components.updatelooper:AddOnUpdateFn(OnUpdateHitbox)
	end
end

local function OnHit(inst, owner, target)
	if target then
		target:AddDebuff("curse_fire", "curse_fire")
	end
    local p=inst.Transform:GetWorldPosition()
    inst:RestartFX(1.5, "nofade", p)
end

local function OnAnimOver(inst)
    inst:DoTaskInTime(2, inst.Remove)
end

local function OnThrown(inst)
    inst:ListenForEvent("animqueueover", OnAnimOver)
end

local function commonfn(data)
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("warg_mutated_breath_fx")
	inst.AnimState:SetBuild("warg_mutated_breath_fx")
	inst.AnimState:PlayAnimation("flame1_pre")
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	inst.AnimState:SetLightOverride(0.1)

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")

	inst.brightness = net_tinybyte(inst.GUID, "warg_mutated_breath_fx.brightness", "brightnessdirty")
	inst.brightness:set(7)
	--inst.updatingbrightness = false
	OnBrightnessDirty(inst)
	inst.AnimState:SetMultColour(173/255,1,47/255,0.8)
	inst:AddComponent("updatelooper")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst:ListenForEvent("brightnessdirty", OnBrightnessDirty)

		return inst
	end

	MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

	--inst:ListenForEvent("animqueueover", OnAnimQueueOver)
	inst.persists = false

	inst.AnimState:PushAnimation("flame1_loop", true)
	inst.SetFXOwner = SetFXOwner
	inst.RestartFX = RestartFX

	if data then
		data.postinitfn(inst)
	end

	return inst
end

local function flame_postinitfn(inst)
	inst:ListenForEvent("animqueueover", OnAnimQueueOver)

	RestartFX(inst)
end

local function flamefn()
	return commonfn({postinitfn=flame_postinitfn})
end



local function projectile_postinitfn(inst)
	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(100)


	inst:AddComponent("projectile")
    inst.components.projectile:SetSpeed(20)         ---20
    inst.components.projectile:SetHoming(false)
    inst.components.projectile:SetHitDist(2)
    inst.components.projectile:SetOnHitFn(OnHit)
    inst.components.projectile:SetOnMissFn(inst.Remove)
	inst.components.projectile:SetOnThrownFn(OnThrown)
end

local function projectilefn()
	return commonfn({postinitfn=projectile_postinitfn})
end


local function SpawnBreathFX(inst, dist, targets, updateangle)
	if updateangle then
		inst.angle = (inst.entity:GetParent() or inst).Transform:GetRotation() * DEGREES

		if not inst.SoundEmitter:PlayingSound("loop") then
			inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
			inst.SoundEmitter:PlaySound("rifts3/mutated_varg/blast_lp", "loop")
		end
	end

	local fx = table.remove(inst.flame_pool)
	if fx == nil then
		fx = SpawnPrefab("twin_flame")
		fx:SetFXOwner(inst, inst.flamethrower_attacker)
	end

	local scale = (1 + math.random() * 0.25)
	scale = scale * (1+dist/6)

	local fadeoption = (dist < 6 and "nofade") or (dist <= 7 and "latefade") or nil

	local x, y, z = inst.Transform:GetWorldPosition()
	local angle = inst.angle
	x = x + math.cos(angle) * dist
	z = z - math.sin(angle) * dist
	dist = dist / 20
	angle = math.random() * PI2
	x = x + math.cos(angle) * dist
	z = z - math.sin(angle) * dist

	fx.Transform:SetPosition(x, 0, z)
	fx:RestartFX(scale, fadeoption, targets)
end

local function SetFlamethrowerAttacker(inst, attacker)
	inst.flamethrower_attacker = attacker
end

local function OnRemoveEntity(inst)
	if inst.flame_pool ~= nil then
		for i, v in ipairs(inst.flame_pool) do
			v:Remove()
		end
		inst.flame_pool = nil
	end
end

local function KillSound(inst)
	inst.SoundEmitter:KillSound("loop")
end

local function KillFX2(inst)
	for i, v in ipairs(inst.tasks) do
		v:Cancel()
	end
	inst.OnRemoveEntity = nil
	OnRemoveEntity(inst)
	--Delay removal because lingering flame fx still references us for weapon damage
	inst:DoTaskInTime(1, inst.Remove)

	inst.SoundEmitter:PlaySound("rifts3/mutated_varg/blast_pst")
	inst:DoTaskInTime(6 * FRAMES, KillSound)
end

local function throwerfn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()

	inst:AddTag("CLASSIFIED")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

	inst.flame_pool = {}
	inst.ember_pool = {}
	inst.angle = 0

	local targets = {}
	local period = 8 * FRAMES
	inst.tasks =
	{
		inst:DoPeriodicTask(period, SpawnBreathFX, 0 * FRAMES, 3, targets, true),
		inst:DoPeriodicTask(period, SpawnBreathFX, 3 * FRAMES, 5, targets),
		inst:DoPeriodicTask(period, SpawnBreathFX, 6 * FRAMES, 7, targets),
	}

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(250)

	inst.SetFlamethrowerAttacker = SetFlamethrowerAttacker
	inst.KillFX = KillFX2
	inst.OnRemoveEntity = OnRemoveEntity

	inst.persists = false

	return inst
end

local function RestartFX2(inst)
	if inst:IsInLimbo() then
		inst:ReturnToScene()
	end

	local anim = "flame"..tostring(math.random(3))
	if not inst.AnimState:IsCurrentAnimation(anim.."_pre") then
		inst.AnimState:PlayAnimation(anim.."_pre")
		inst.AnimState:PushAnimation(anim.."_loop", true)
	end

	inst.scale =  1
	inst.AnimState:SetScale(math.random() < 0.5 and -inst.scale or inst.scale, inst.scale)


	inst:DoTaskInTime(10, KillFX)


end

local function cursefn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("warg_mutated_breath_fx")
	inst.AnimState:SetBuild("warg_mutated_breath_fx")
	inst.AnimState:PlayAnimation("flame1_pre")
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	inst.AnimState:SetLightOverride(0.1)

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")

	inst.brightness = net_tinybyte(inst.GUID, "warg_mutated_breath_fx.brightness", "brightnessdirty")
	inst.brightness:set(7)
	--inst.updatingbrightness = false
	OnBrightnessDirty(inst)
	inst.AnimState:SetMultColour(173/255,1,47/255,0.8)
	inst:AddComponent("updatelooper")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst:ListenForEvent("brightnessdirty", OnBrightnessDirty)

		return inst
	end

	--inst:ListenForEvent("animqueueover", OnAnimQueueOver)
	inst.persists = false
	MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

	inst.AnimState:PushAnimation("flame1_loop", true)
	inst.RestartFX = RestartFX2
	inst.SetFXOwner = SetFXOwner
	inst:ListenForEvent("animqueueover", OnAnimQueueOver)
	RestartFX2(inst)



	return inst
end
--------------------------------------------------------------------------

return Prefab("twin_flame", flamefn, assets),
	Prefab("twin_flame_projectile", projectilefn, assets),
	Prefab("twin_flamethrower_fx",throwerfn,nil,prefabs)
