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
						v:AddDebuff("curse_fire", "curse_fire")
						--Hit
						if (target_data.hit_tick == nil or target_data.hit_tick + MULTIHIT_FRAMES < tick) and inst.attacker.components.combat:CanTarget(v) then
							target_data.hit_tick = tick
							if v:HasTag("player") then
								v.components.health:DoDelta(-10,false,"curse_fire")
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


local function flamefn()
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

	inst.persists = false

	inst.AnimState:PushAnimation("flame1_loop", true)
	inst.SetFXOwner = SetFXOwner
	inst.RestartFX = RestartFX

	inst:ListenForEvent("animqueueover", OnAnimQueueOver)

	RestartFX(inst)

	return inst
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

local function buff_OnTick(inst,target)
    if target~=nil and target.components.health~=nil and not target.components.health:IsDead() then
        target.components.health:DoDelta(-2,true,"curse_fire")	
    end
end

local function OnAttached(inst, target, followsymbol, followoffset)
    inst.entity:SetParent(target.entity)
	if target.isplayer then
		inst.Follower:FollowSymbol(target.GUID, "torso", 0, 0, 0)
	end
    inst:ListenForEvent("death", function()
        inst.components.debuff:Stop()
    end, target)
	inst.task = inst:DoPeriodicTask(0.5, buff_OnTick, nil, target)
end

local function OnExtended(inst, target,followsymbol, followoffset, data)

    inst.components.timer:StopTimer("buffover")
    inst.components.timer:StartTimer("buffover", 15)
    
end

local function OnTimerDone(inst, data)
    if data.name == "buffover" then
        inst.components.debuff:Stop()
    end
end

local function OnDetached(inst, target)
	if inst.task~=nil then
		inst.task:Cancel()
		inst.task = nil
	end
	inst:Remove()
end

local function bufffn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddFollower()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")

    inst.AnimState:SetBank("warg_mutated_breath_fx")
	inst.AnimState:SetBuild("warg_mutated_breath_fx")
	inst.AnimState:PlayAnimation("flame1_loop", true)
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	inst.AnimState:SetFinalOffset(2)
	inst.AnimState:SetLightOverride(0.1)

	inst.AnimState:SetMultColour(173/255,1,47/255,0.8)


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("debuff")
    inst.components.debuff:SetAttachedFn(OnAttached)
    inst.components.debuff:SetExtendedFn(OnExtended)
    inst.components.debuff:SetDetachedFn(OnDetached)
	
    inst:AddComponent("timer")
    inst.components.timer:StartTimer("buffover",15)
    inst:ListenForEvent("timerdone", OnTimerDone)


    return inst
end

local function SpawnBreathFX2(inst, dist, targets, updateangle)
	if updateangle then
		inst.angle = (inst.entity:GetParent() or inst).Transform:GetRotation() * DEGREES

		if not inst.SoundEmitter:PlayingSound("loop") then
			inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
			inst.SoundEmitter:PlaySound("rifts3/mutated_varg/blast_lp", "loop")
		end
	end

	local fx = table.remove(inst.flame_pool)
	if fx == nil then
		fx = SpawnPrefab("warg_mutated_breath_fx")
		fx:SetFXOwner(inst, inst.flamethrower_attacker)
	end

	local scale = (2+ 0.5*math.random())
	if dist < 10 then
		scale = scale * 1.1
	elseif dist <16 then
		scale = scale * 1.3
	else
		scale = scale * 1.5
	end		

	local fadeoption = (dist < 8 and "nofade") or (dist <= 14 and "latefade") or nil

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


local function alter_throwerfn()
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
		inst:DoPeriodicTask(period, SpawnBreathFX2, 0 * FRAMES, 4, targets, true),
		inst:DoPeriodicTask(period, SpawnBreathFX2, 3 * FRAMES, 8, targets, true),
		inst:DoPeriodicTask(period, SpawnBreathFX2, 6 * FRAMES, 12, targets, true),
		inst:DoPeriodicTask(period, SpawnBreathFX2, 9 * FRAMES, 18, targets, true),
		inst:DoPeriodicTask(period, SpawnBreathFX2, 9 * FRAMES, 24, targets, true),
	}

	inst:AddComponent("weapon")
	inst.components.weapon:SetDamage(100)

	inst.SetFlamethrowerAttacker = SetFlamethrowerAttacker
	inst.KillFX = KillFX2
	inst.OnRemoveEntity = OnRemoveEntity

	inst.persists = false

	return inst
end

--------------------------------------------------------------------------

return Prefab("twin_flame", flamefn, assets),
	Prefab("twin_flamethrower_fx",throwerfn,nil,prefabs),
	Prefab("curse_fire",bufffn,assets),
	Prefab("huge_flame_thrower",alter_throwerfn)
