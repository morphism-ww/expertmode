local assets =
{
    Asset("ANIM", "anim/moonstorm_lightningstrike.zip"),
}

local LIGHTNING_MAX_DIST_SQ = 140*140

local function PlayThunderSound(lighting)
	if not lighting:IsValid() or TheFocalPoint == nil then
		return
	end

    local pos = Vector3(lighting.Transform:GetWorldPosition())
    local pos0 = Vector3(TheFocalPoint.Transform:GetWorldPosition())
   	local diff = pos - pos0
    local distsq = diff:LengthSq()

	local k = math.max(0, math.min(1, distsq / LIGHTNING_MAX_DIST_SQ))
	local intensity = math.min(1, k * 1.1 * (k - 2) + 1.1)
	if intensity <= 0 then
		return
	end

    local minsounddist = 10
    local normpos = pos
   	if distsq > minsounddist * minsounddist then
       	--Sound needs to be played closer to us if lightning is too far from player
        local normdiff = diff * (minsounddist / math.sqrt(distsq))
   	    normpos = pos0 + normdiff
    end

    local inst = CreateEntity()

    --[[Non-networked entity]]

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()

    inst.Transform:SetPosition(normpos:Get())
    inst.SoundEmitter:PlaySound("dontstarve/rain/thunder_close", nil, intensity, true)

    inst:Remove()
end

local function StartFX(inst)
	for i, v in ipairs(AllPlayers) do
		local distSq = v:GetDistanceSqToInst(inst)
		local k = math.max(0, math.min(1, distSq / LIGHTNING_MAX_DIST_SQ))
		local intensity = -(k-1)*(k-1)*(k-1)				--k * 0.8 * (k - 2) + 0.8

		--print("StartFX", k, intensity)
		if intensity > 0 then
			v:ScreenFlash(intensity <= 0.05 and 0.05 or intensity)
			v:ShakeCamera(CAMERASHAKE.FULL, .7, .02, intensity / 3)
		end
	end
end

local AREAATTACK_MUST_TAGS = { "_combat" }
local AREA_EXCLUDE_TAGS = { "INLIMBO", "notarget", "noattack", "flight", "invisible", "playerghost", "brightmare" }

local function spawnglass(inst)
    if inst._aguard~=nil then
        local x,y,z = inst.Transform:GetWorldPosition()
        local ents = TheSim:FindEntities(x, 0, z, 5, AREAATTACK_MUST_TAGS, AREA_EXCLUDE_TAGS)
        for i, v in ipairs(ents) do
            if v~=inst._aguard and v:IsValid() and not v:IsInLimbo() and
                not (v.components.health ~= nil and v.components.health:IsDead()) and
                inst._aguard.components.combat:CanTarget(v)
            then
                v:AddDebuff("buff_mooncurse","buff_mooncurse")
                v.components.combat:GetAttacked(inst,TUNING.ALTERGUARDIAN_PHASE2_LIGHTNING_DAMAGE,nil,"electric")
            end
        end
    end
end

local function SetOwner(inst, aguard)
    inst._aguard = aguard
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()
    inst.entity:AddSoundEmitter()

    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    inst.AnimState:SetLightOverride(1)
    inst.AnimState:SetBank("Moonstorm_LightningStrike")
    inst.AnimState:SetBuild("moonstorm_lightningstrike")
    inst.AnimState:PlayAnimation("strike")

    inst.SoundEmitter:PlaySound("dontstarve/rain/thunder_close", nil, nil, true)

    inst:AddTag("FX")

    --Dedicated server does not need to spawn the local sfx
    if not TheNet:IsDedicated() then
		inst:DoTaskInTime(0, PlayThunderSound)
	end

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:DoTaskInTime(0, StartFX) -- so we can use the position to affect the screen flash

    inst.entity:SetCanSleep(false)
    inst.persists = false
    inst:DoTaskInTime(.5, inst.Remove)

    inst.SetOwner = SetOwner
    
    inst:DoTaskInTime(0, function() spawnglass(inst) end)

    return inst
end

return Prefab("moon_lightning2", fn, assets)