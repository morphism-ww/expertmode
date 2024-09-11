local assets =
{
    Asset("ANIM", "anim/shadow_thrall_wings.zip"),
}
local function healthDoDelta(self,amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    local old_percent = self:GetPercent()
    if not (afflicter and afflicter.isplayer and amount>300) and amount>0 then
        return 0
    end
    self:SetVal(self.currenthealth + amount, cause, afflicter)

    self.inst:PushEvent("healthdelta", { oldpercent = old_percent, newpercent = self:GetPercent(), overtime = overtime, cause = cause, afflicter = afflicter, amount = amount })
    return amount
end

local function OnlyPlayer(player,inst)
    return player.isplayer
end


---------------------------------------------------------------------------------
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

local function OnColourChanged(inst, r, g, b, a)
	for i, v in ipairs(inst.highlightchildren) do
		v.AnimState:SetAddColour(r, g, b, a)
	end
end

local function MakeBuild(inst)
    --inst.AnimState:OverrideSymbol("hood", "hat_voidcloth", "swap_hat")
    

    --inst.AnimState:HideSymbol("hood_tip")

    --[[inst.AnimState:ShowSymbol("swap_face")
    inst.AnimState:ShowSymbol("face")
    inst.AnimState:Hide("HAT")
    inst.AnimState:Hide("HAIR_HAT")
    inst.AnimState:Hide("HAIR_NOHAT")
    inst.AnimState:Hide("HAIR")
    inst.AnimState:Hide("HEAD")
    inst.AnimState:Show("HEAD_HAT")
    inst.AnimState:Hide("HEAD_HAT_NOHELM")
    inst.AnimState:Show("HEAD_HAT_HELM")

    inst.AnimState:HideSymbol("face")
    inst.AnimState:HideSymbol("swap_face")
    inst.AnimState:HideSymbol("beard")
    inst.AnimState:UseHeadHatExchange(true)
    inst.AnimState:HideSymbol("cheeks")]]
    --inst.AnimState:HideSymbol("leg")
    
    SpawnPrefab("armor_voidcloth_fx"):AttachToOwner(inst)
    SpawnPrefab("voidclothhat_fx"):AttachToOwner(inst)

    inst:AddComponent("colouraddersync")

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

		inst.components.colouraddersync:SetColourChangedFn(OnColourChanged)
	end
end



local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    MakeCharacterPhysics(inst, 10, 1.5)
    RemovePhysicsColliders(inst)
    inst.Physics:SetCollisionGroup(COLLISION.SANITY)
    inst.Physics:CollidesWith(COLLISION.SANITY)
    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("shadow_thrall_wings")
	inst.AnimState:SetBuild("shadow_thrall_wings")
	inst.AnimState:PlayAnimation("idle", true)
	inst.AnimState:SetSymbolLightOverride("fx_red", 1)
	inst.AnimState:SetSymbolLightOverride("fx_red_particle", 1)
	inst.AnimState:SetSymbolLightOverride("wingend_red", 1)

    
    MakeBuild(inst)

    inst:AddComponent("talker")
    inst.components.talker.fontsize = 40
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.colour = Vector3(238 / 255, 69 / 255, 105 / 255)
    inst.components.talker.offset = Vector3(0, -400, 0)
    inst.components.talker.symbol = "fossil_chest"
    inst.components.talker:MakeChatter()

    inst:AddTag("epic")
    inst:AddTag("hostile")
    inst:AddTag("notraptrigger")
    inst:AddTag("noteleport")
    inst:AddTag("shadow")
    inst:AddTag("god")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end	

	
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.SHAODWMFZ_HEALTH)
    inst.components.health.DoDelta = healthDoDelta
    inst.components.health:SetMaxDamageTakenPerHit(300)
    inst.components.health.destroytime = 2
    --inst.components.health:SetAbsorptionAmount(0.5)
    --inst.components.health.nofadeout = true

    inst:AddComponent("planarentity")

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(100)
    inst.components.combat:SetAttackPeriod(3)
    inst.components.combat:SetRange(18)
    inst.components.combat.shouldavoidaggrofn = OnlyPlayer


    --[[local stunnable = inst:AddComponent("stunnable")
    stunnable.stun_threshold = 500
    stunnable.stun_period = 5
    stunnable.stun_duration = 20
    stunnable.stun_resist = 0
    stunnable.stun_cooldown = 0]]

    --inst:AddComponent("inventory")

    inst:AddComponent("timer")
    inst:AddComponent("knownlocations")

    inst:AddComponent("lootdropper")

    inst:AddComponent("colouradder")
    inst:AddComponent("bloomer")

    inst:AddComponent("truedamage")
    inst.components.truedamage:SetBaseDamage(5)


    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = 6
    inst.components.locomotor.runspeed = 8
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { allowocean = true, ignorewalls = true }

    return inst
end


return Prefab("cs_shadow_queen", fn, assets)