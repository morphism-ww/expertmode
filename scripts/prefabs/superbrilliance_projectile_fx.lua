local assets =
{
	Asset("ANIM", "anim/brilliance_projectile_fx.zip")
}


local SPEED = 16
local BOUNCE_RANGE = 15
local BOUNCE_SPEED = 16

local function PlayAnimAndRemove(inst, anim)
	inst.AnimState:PlayAnimation(anim)
	if not inst.removing then
		inst.removing = true
		inst:ListenForEvent("animover", inst.Remove)
	end
end

local function OnThrown(inst, owner, target, attacker)
	inst.owner = owner
	if inst.bounces == nil then
		local hat = attacker ~= nil and attacker.components.inventory ~= nil and attacker.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD) or nil
		inst.bounces = hat ~= nil and hat.prefab == "lunarplanthat" and TUNING.TRUE_STAFF_SETBONUS_BOUNCES or TUNING.TRUE_STAFF_BOUNCES   --bounce
		inst.initial_hostile = target ~= nil and target:IsValid() and target:HasTag("hostile")
	end
end

local BOUNCE_ATLEAST_TAGS = { "_combat" }
local BOUNCE_NO_TAGS = { "INLIMBO", "wall", "notarget", "player", "companion", "flight", "invisible", "noattack", "hiding" }

local function TryBounce(inst, x, z, attacker, target)
	if attacker.components.combat == nil or not attacker:IsValid() then
		inst:Remove()
		return
	end
	local newtarget, newrecentindex, newhostile
	for i, v in ipairs(TheSim:FindEntities(x, 0, z, BOUNCE_RANGE, nil, BOUNCE_NO_TAGS,BOUNCE_ATLEAST_TAGS)) do
		if v ~= target and v.entity:IsVisible() and
			not (v.components.health ~= nil and v.components.health:IsDead()) and
			attacker.components.combat:CanTarget(v) and not attacker.components.combat:IsAlly(v)
			then
			local vhostile = v:HasTag("hostile")
			local vrecentindex
			if inst.recenttargets ~= nil then
				for i1, v1 in ipairs(inst.recenttargets) do
					if v == v1 then
						vrecentindex = i1
						break
					end
				end
			end
			if inst.initial_hostile and not vhostile and vrecentindex == nil and v.components.locomotor == nil then
				--attack was initiated against a hostile target
				--skip if non-hostile, can't move, and has never been targeted
			elseif newtarget == nil then
				newtarget = v
				newrecentindex = vrecentindex
				newhostile = vhostile
			elseif vhostile and not newhostile then
				newtarget = v
				newrecentindex = vrecentindex
				newhostile = vhostile
			elseif vhostile or not newhostile then
				if vrecentindex == nil then
					if newrecentindex ~= nil or (newtarget.prefab ~= target.prefab and v.prefab == target.prefab) then
						newtarget = v
						newrecentindex = vrecentindex
						newhostile = vhostile
					end
				elseif newrecentindex ~= nil and vrecentindex < newrecentindex then
					newtarget = v
					newrecentindex = vrecentindex
					newhostile = vhostile
				end

			end
		elseif v:HasTag("mushroomsprout") then
			newtarget=v
		end
	end


	if newtarget ~= nil then
		inst.Physics:Teleport(x, 0, z)
		inst:Show()
		inst.components.projectile:SetSpeed(BOUNCE_SPEED)
		if inst.recenttargets ~= nil then
			if newrecentindex ~= nil then
				table.remove(inst.recenttargets, newrecentindex)
			end
			table.insert(inst.recenttargets, target)
		else
			inst.recenttargets = { target }
		end
		inst.components.projectile:SetBounced(true)
		inst.components.projectile.overridestartpos = Vector3(x, 0, z)
		inst.components.projectile:Throw(inst.owner, newtarget, attacker)
	else
		inst:Remove()
	end
end

local function OnHit(inst, attacker, target)
	if attacker==nil or attacker.components.combat == nil or not attacker:IsValid() then
		inst:Remove()
		return
	end
	local x, y, z = inst.Transform:GetWorldPosition()

	local ents = TheSim:FindEntities(x, y, z, 3, {"_combat"}, { "INLIMBO" ,"FX" ,"player","noattack","invisible"})
    for i, v in ipairs(ents) do
        if v:IsValid() and v.components.combat ~= nil and not (v.components.health ~= nil and v.components.health:IsDead()) then
			v.components.combat:SuggestTarget(attacker)
			v.components.combat:GetAttacked(inst, 0, nil, nil,{["planar"] = TUNING.TRUE_STAFF_EXPLOSIVE})
        end
    end
	
	SpawnPrefab("bomb_lunarplant_explode_fx").Transform:SetPosition(x, y, z)

	if inst.bounces ~= nil and inst.bounces > 1 then
		inst.bounces = inst.bounces - 1
		inst.Physics:Stop()
		inst:Hide()
		inst:DoTaskInTime(.1, TryBounce, x, z, attacker, target)
	else
		inst:Remove()
	end
end

local function OnMiss(inst, attacker, target)
	if not inst.AnimState:IsCurrentAnimation("disappear") then
		PlayAnimAndRemove(inst, "disappear")
	end
end

local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	MakeInventoryPhysics(inst)
	RemovePhysicsColliders(inst)

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")

	inst.AnimState:SetBank("brilliance_projectile_fx")
	inst.AnimState:SetBuild("brilliance_projectile_fx")
	inst.AnimState:PlayAnimation("idle_loop", true)
	inst.AnimState:SetSymbolMultColour("light_bar", 1, 1, 1, .5)
	inst.AnimState:SetSymbolBloom("light_bar")
	--inst.AnimState:SetSymbolBloom("pb_energy_loop")
	inst.AnimState:SetSymbolBloom("glow")
	--inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
	inst.AnimState:SetLightOverride(.5)

	--projectile (from projectile component) added to pristine state for optimization
	inst:AddTag("projectile")

	inst:AddTag("explosive")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end	

	
	inst:AddComponent("projectile")
	inst.components.projectile:SetSpeed(SPEED)
	inst.components.projectile:SetRange(25)
	inst.components.projectile:SetOnThrownFn(OnThrown)
	inst.components.projectile:SetOnHitFn(OnHit)
	inst.components.projectile:SetOnMissFn(OnMiss)


	inst.persists = false

	return inst
end



return Prefab("superbrilliance_projectile_fx", fn, assets)
