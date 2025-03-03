local function fireball_onhit(inst,attacker,target)
    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 4, {"_combat"}, { "INLIMBO" ,"FX" ,"player","burnt"})
    for i, v in ipairs(ents) do
        if v:IsValid() and v.components.burnable ~= nil then
            v.components.burnable:Ignite(true,attacker)
        end
    end
    SpawnPrefab("explode_small").Transform:SetPosition(x,y,z)
end

local function cursefire_onhit(inst,attacker,target)
    if target and target:IsValid() then
		target:AddDebuff("buff_cursefire", "buff_cursefire")
	end
end



local function CreateTailFx(data)
    local inst = CreateEntity()

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false


    inst.entity:AddTransform()
    inst.entity:AddAnimState()


    MakeInventoryPhysics(inst)
    inst.Physics:ClearCollisionMask()

    inst.AnimState:SetBank(data.bank)
    inst.AnimState:SetBuild(data.build)
    inst.AnimState:PlayAnimation("disappear")
    inst.AnimState:SetFinalOffset(-1)
    if data.add_colour then
        inst.AnimState:SetAddColour(unpack(data.add_colour))
    end
    if data.mult_colour then
        inst.AnimState:SetMultColour(unpack(data.mult_colour))
    end
    if data.light_override then
        inst.AnimState:SetLightOverride(data.light_override)
    end

    inst:ListenForEvent("animover", inst.Remove)

    return inst
end

local function OnUpdateProjectileTail(inst)
    local tail_values = inst.tail_values
    local x, y, z = inst.Transform:GetWorldPosition()
    for tail,_ in pairs(inst.tails) do
        tail:ForceFacePoint(x, y, z)
    end
    if inst.entity:IsVisible() then
        local tail = CreateTailFx(tail_values)
        local rot = inst.Transform:GetRotation()
        tail.Transform:SetRotation(rot)
        rot = rot * DEGREES
        local offsangle = math.random() * 2 * PI
        local offsradius = (math.random() * .2 + .2) * (tail_values.scale or 1)
        local hoffset = math.cos(offsangle) * offsradius
        local voffset = math.sin(offsangle) * offsradius
        tail.Transform:SetPosition(x + math.sin(rot) * hoffset, y + voffset, z + math.cos(rot) * hoffset)
        if tail_values.speed then
        	tail.Physics:SetMotorVel(tail_values.speed * (.2 + math.random() * .3), 0, 0)
        end
        inst.tails[tail] = true
        inst:ListenForEvent("onremove", function(tail)
            inst.tails[tail] = nil
        end, tail)
        tail:ListenForEvent("onremove", function(inst)
            tail.Transform:SetRotation(tail.Transform:GetRotation() + math.random() * 30 - 15)
        end, inst)
    end
end

local function MakeProjectile(name, bank, build,anim, data, onhit, hit_fx)
    local assets = {
        Asset("ANIM", "anim/"..build..".zip"),
    }
    local prefabs = hit_fx ~= nil and { hit_fx } or nil
	--------------------------------------------------------------------------
	local function OnHit(inst, attacker, target)
        if hit_fx then
            local hit_fx = SpawnPrefab(hit_fx)
            hit_fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        end
		if onhit then
            onhit(inst,attacker,target)
        end
		inst:Remove()
	end
	--------------------------------------------------------------------------
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        MakeProjectilePhysics(inst)

        inst.AnimState:SetBank(bank)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation(anim,data.loop)

        local SCALE = data.scale or 1
        inst.AnimState:SetScale(SCALE,SCALE,SCALE)

        if data.add_colour then
			inst.AnimState:SetAddColour(unpack(data.add_colour))
		end
		if data.mult_colour then
			inst.AnimState:SetMultColour(unpack(data.mult_colour))
		end

		inst.AnimState:SetLightOverride(data.light_override or 1)

        --[[if data.shader then
            inst.AnimState:SetBloomEffectHandle(data.shader)
        end
        if data.onground then
            inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
            inst.AnimState:SetLayer(LAYER_BACKGROUND)
            inst.AnimState:SetSortOrder(3)
        end]]
        if data.has_tail then
			inst.tail_values = {
			    bank  = bank,
			    build = build or bank,
                speed           = data.speed,
                add_colour      = data.add_colour,
                mult_colour     = data.mult_colour,
                light_override  = data.light_override,
                final_offset    = -1,
			}
		    inst.CreateTail = CreateTailFx
		    inst.OnUpdateProjectileTail = OnUpdateProjectileTail
		    ------------------------------------------
	    	--inst._hastail = net_bool(inst.GUID, tostring(inst.prefab).."._hastail", "hastaildirty")
	    	------------------------------------------
			if not TheNet:IsDedicated() then
				inst.tails = {}

                inst:DoPeriodicTask(0, OnUpdateProjectileTail)
			end
			------------------------------------------
		end

        inst:AddTag("projectile")
        inst:AddTag("NOCLICK")
		
        if not TheWorld.ismastersim then
            return inst
        end

        inst.persists = false

        inst:AddComponent("projectile")
        inst.components.projectile:SetSpeed(data.speed or 30)
        inst.components.projectile:SetRange(data.range or 30)
        inst.components.projectile:SetHitDist(1)
        inst.components.projectile:SetOnHitFn(OnHit)
        inst.components.projectile:SetOnMissFn(inst.Remove)
        inst.components.projectile:SetHoming(false)

        
        if data.damage then
            inst:AddComponent("weapon")
            inst.components.weapon:SetDamage(data.damage)
        end
        
        inst:DoTaskInTime(15,inst.Remove)
		
		------------------------------------------
        return inst
    end
	--------------------------------------------------------------------------
    return Prefab(name, fn, assets, prefabs)
end

return 
MakeProjectile("cs_fireball_projectile", "fireball_fx", "fireball_2_fx", "idle_loop", {speed = 20,has_tail = true},fireball_onhit, "cs_fireball_hit_fx"),
MakeProjectile("cursefire_projectile", "gooball_fx", "gooball_fx", "idle_loop", {speed = 24,has_tail = true,mult_colour = {.2, 1, 0, 0.8},scale = 1.4,damage = 200,range = 36,loop = true},cursefire_onhit),
MakeProjectile("twin_laser","metal_hulk_projectile","metal_hulk_projectile","spin_loop",{scale = 0.7, damage = 150, range = 40,loop = true}),
MakeProjectile("darkball_projectile","lavaportal_fx","lavaarena_portal_fx","portal_loop",{speed = 20, damage = 30,loop = true,scale = 0.3})