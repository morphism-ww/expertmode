local prefabs = {
    "dreadstone",
    "nightmarefuel",
    "horrorfuel",
    "voidcloth",
    "shadow_despawn"
}

local brain = require("brains/abysshoplitebrain")




local function fullhelm_onequip(fname, owner)
    owner.AnimState:OverrideSymbol("headbase_hat", fname, "swap_hat")

    owner.AnimState:Hide("HAT")
    owner.AnimState:Hide("HAIR_HAT")
    owner.AnimState:Hide("HAIR_NOHAT")
    owner.AnimState:Hide("HAIR")

    owner.AnimState:Hide("HEAD")
    owner.AnimState:Show("HEAD_HAT")
    owner.AnimState:Hide("HEAD_HAT_NOHELM")
    owner.AnimState:Show("HEAD_HAT_HELM")

    owner.AnimState:HideSymbol("face")
    owner.AnimState:HideSymbol("swap_face")
    owner.AnimState:HideSymbol("beard")
    owner.AnimState:HideSymbol("cheeks")

    owner.AnimState:UseHeadHatExchange(true)
end    
local function FollowFx_ColourChanged(inst, r, g, b, a)
	for i, v in ipairs(inst.fx) do
		v.AnimState:SetAddColour(r, g, b, a)
	end
end

local function voidclothhat_CreateFxFollowFrame(i)
	local inst = CreateEntity()

	--[[Non-networked entity]]
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddFollower()

	inst:AddTag("FX")

	inst.AnimState:SetBank("voidclothhat")
	inst.AnimState:SetBuild("hat_voidcloth")
	inst.anim = "idle"..tostring(i)
	inst.AnimState:PlayAnimation(inst.anim, true)
    inst.AnimState:HideSymbol("scrap")
    inst.AnimState:HideSymbol("scrap2")
	inst:AddComponent("highlightchild")

	inst.persists = false

	return inst
end


local function SpawnFollowFxForOwner(owner, createfn, framebegin, frameend, isfullhelm)
    local follow_symbol = isfullhelm and owner.AnimState:BuildHasSymbol("headbase_hat") and "headbase_hat" or "swap_hat"
	owner.fx = {}
	local frame
	for i = framebegin, frameend do        
		local fx = createfn(i)
		frame = frame or math.random(fx.AnimState:GetCurrentAnimationNumFrames()) - 1
		fx.entity:SetParent(owner.entity)
		fx.Follower:FollowSymbol(owner.GUID, follow_symbol, nil, nil, nil, true, nil, i - 1)
		fx.AnimState:SetFrame(frame)
		fx.components.highlightchild:SetOwner(owner)
		table.insert(owner.fx, fx)
	end
	owner.components.colouraddersync:SetColourChangedFn(FollowFx_ColourChanged)
	
end


local function MakeAnim(inst)
    inst:AddComponent("colouraddersync")
    
    inst.AnimState:Hide("ARM_carry")
    inst.AnimState:Hide("HAT")
    inst.AnimState:Hide("HAIR_HAT")
    inst.AnimState:Show("HAIR_NOHAT")
    inst.AnimState:Show("HAIR")
    inst.AnimState:Show("HEAD")
    inst.AnimState:Hide("HEAD_HAT")
    inst.AnimState:Hide("HEAD_HAT_NOHELM")
    inst.AnimState:Hide("HEAD_HAT_HELM")
    inst.AnimState:HideSymbol("leg")
    inst.AnimState:HideSymbol("foot")

    inst.AnimState:OverrideSymbol("swap_object", "dreadsword", "swap_dreadsword")
    inst.AnimState:Show("ARM_carry")
    inst.AnimState:Hide("ARM_normal")


    --SpawnPrefab("armor_voidcloth_fx"):AttachToOwner(inst)
    inst.AnimState:OverrideSymbol("swap_body", "armor_dreadstone", "swap_body")
    fullhelm_onequip("hat_voidcloth",inst)
    if not TheNet:IsDedicated() then            
        SpawnFollowFxForOwner(inst, voidclothhat_CreateFxFollowFrame, 1, 3, true)
    end

end

local function SetFxOwner(inst, owner)
    if owner ~= nil then
        inst.blade1.entity:SetParent(owner.entity)
        inst.blade2.entity:SetParent(owner.entity)
        inst.blade1.Follower:FollowSymbol(owner.GUID, "swap_object", nil, nil, nil, true, nil, 0, 0)
        inst.blade2.Follower:FollowSymbol(owner.GUID, "swap_object", nil, nil, nil, true, nil, 5, 8)
        inst.blade1.components.highlightchild:SetOwner(owner)
    end
end

local function OnParry(inst, doer, attacker, damage)
    doer.SoundEmitter:PlaySound("dontstarve/creatures/lava_arena/trails/hide_hit")
end

local function EquipWeapon(inst)
    if inst.components.inventory ~= nil and not inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) then
        local weapon = CreateEntity()
        --[[Non-networked entity]]
        weapon.entity:AddTransform()
        weapon:AddComponent("weapon")
        weapon.components.weapon:SetDamage(inst.components.combat.defaultdamage)
        weapon.components.weapon:SetRange(inst.components.combat.attackrange)
       
        weapon:AddComponent("inventoryitem")
        weapon.persists = false
        weapon.components.inventoryitem:SetOnDroppedFn(inst.Remove)
        weapon:AddComponent("equippable")
        weapon:AddTag("nosteal")

        weapon.blade1 = SpawnPrefab("dreadsword_fx")
        weapon.blade2 = SpawnPrefab("dreadsword_fx")
        weapon.blade2.AnimState:PlayAnimation("swap_loop2", true)
        weapon.blade1.AnimState:SetFrame(1)
        weapon.blade2.AnimState:SetFrame(1)

        SetFxOwner(weapon,inst)

        weapon:AddComponent("parryweapon")
        weapon.components.parryweapon:SetParryArc(180)
        --inst.components.parryweapon:SetOnPreParryFn(OnPreParry)
        weapon.components.parryweapon:SetOnParryFn(OnParry)

        inst.components.inventory:Equip(weapon)
    end
end


----------------------------------------------------------------------------------

local function RetargetFn(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local target = inst.components.combat.target
	if target then
		local range = 12
		if target.isplayer and target:GetDistanceSqToPoint(x, y, z) < range * range then
			--Keep target
			return
		end
	end

	--V2C: WARNING: FindClosestPlayerInRange returns 2 values, which
	--              we don't want to return as our 2nd return value.  
	local player--[[, rangesq]] = FindClosestPlayerInRange(x, y, z, TUNING.SHADOWTHRALL_AGGRO_RANGE, true)
	return player
end

local function KeepTargetFn(inst, target)
	return inst.components.combat:CanTarget(target)
		and inst:IsNear(target, TUNING.SHADOWTHRALL_DEAGGRO_RANGE)
end




local function EnterParry(inst)
    inst:AddTag("parrying")
    local weapon2 = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    if weapon2 ~= nil then
        inst.components.combat.redirectdamagefn = function(inst, attacker, damage, weapon, stimuli)
            return ((weapon and weapon:HasTag("s_l_throw")) or 
                weapon2.components.parryweapon:TryParry(inst, attacker, damage, weapon, stimuli))
                and weapon2
                or nil
        end
    end
    inst.components.resistance:AddResistance("explosive")
    inst.components.locomotor.walkspeed = 4
    inst.components.debuffable:Enable(false)
end

local function ExitParry(inst)
    inst:RemoveTag("parrying")
    inst.components.resistance:RemoveResistance("explosive")
    inst.components.combat.redirectdamagefn = nil
    inst.components.locomotor.walkspeed = 7
    inst.components.debuffable:Enable(true)
end

local function fn()
    local inst = CreateEntity()

	inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()

    MakeCharacterPhysics(inst, 50, 1.5)
    RemovePhysicsColliders(inst)
    inst.Physics:SetCollisionGroup(COLLISION.SANITY)
    inst.Physics:CollidesWith(COLLISION.SANITY)

    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("wilson")

    MakeAnim(inst)
    inst.AnimState:SetScale(1.3,1.3,1.3)
    inst.AnimState:PlayAnimation("idle",true)

    --inst:AddTag("notraptrigger")
    inst:AddTag("hostile")
	inst:AddTag("scarytoprey")
	inst:AddTag("shadowthrall")
	inst:AddTag("shadow_aligned")


    inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end	

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.ABYSS_HOPLITE_HEALTH)

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(TUNING.ABYSS_HOPLITE_DAMAGE)
	inst.components.combat:SetAttackPeriod(2)
    inst.components.combat:SetRange(TUNING.DEFAULT_ATTACK_RANGE)
	inst.components.combat:SetRetargetFunction(2, RetargetFn)
	inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat.externaldamagetakenmultipliers:SetModifier(inst, 0.8, "dreadarmor")
    inst.components.combat.hiteffectsymbol = "torso"

    inst:AddComponent("inspectable")

	inst:AddComponent("sanityaura")
	inst.components.sanityaura.aura = -TUNING.SANITYAURA_MED

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = 7
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.pathcaps = { allowocean = true, ignorewalls = true }

    inst:AddComponent("planarentity")

	inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(30)

    inst:AddComponent("resistance")

    inst:AddComponent("planardefense")
	inst.components.planardefense:SetBaseDefense(10)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"voidcloth","nightmarefuel","horrorfuel"})
    inst.components.lootdropper:AddChanceLoot("dreadstone",0.3)

    inst:AddComponent("knownlocations")

    inst:AddComponent("debuffable")
    

    inst:AddComponent("inventory")
    EquipWeapon(inst)

    inst:SetStateGraph("SGabyss_hoplite")
    inst:SetBrain(brain)

    inst.EnterParry = EnterParry
    inst.ExitParry = ExitParry


    return inst
end

return Prefab("abyss_hoplite",fn,nil,prefabs)