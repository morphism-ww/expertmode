local function onhit1(inst, attacker)
    
    inst.SoundEmitter:PlaySound("dontstarve/common/blackpowder_explo")

    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 5, {"_combat"}, { "INLIMBO", "eyeofterror","flight", "invisible", "notarget", "noattack"})
    for i, v in ipairs(ents) do
        if v:IsValid() and v.components.health ~= nil and not v.components.health:IsDead() then
            v:AddDebuff("vulnerability_hex","vulnerability_hex",{duration = 10})
            v.components.combat:GetAttacked(attacker,300,nil,nil,{["planar"] = 40})
        end
    end

    SpawnPrefab("brimstone_blast_fx").Transform:SetPosition(x,y,z)
    
    inst:Remove()
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
    inst.AnimState:SetBloomEffectHandle(resolvefilepath("shaders/red_shader.ksh"))

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

local function MakeProjectile(name, bank, build,anim, data, onhit)
    local assets = {
        Asset("ANIM", "anim/"..build..".zip"),
    }
    
	--------------------------------------------------------------------------
	
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
        inst.AnimState:PlayAnimation(anim)

        local SCALE = data.scale or 1
        inst.AnimState:SetScale(SCALE,SCALE,SCALE)

        if data.add_colour then
			inst.AnimState:SetAddColour(unpack(data.add_colour))
		end
		if data.mult_colour then
			inst.AnimState:SetMultColour(unpack(data.mult_colour))
		end

		inst.AnimState:SetLightOverride(data.light_override or 1)

        
        inst.AnimState:SetBloomEffectHandle(resolvefilepath("shaders/red_shader.ksh"))
        

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

        inst:AddComponent("linearprojectile")
        inst.components.linearprojectile:SetHorizontalSpeed(25)
        inst.components.linearprojectile:SetRange(28)
        inst.components.linearprojectile:SetOnHit(onhit)
        inst.components.linearprojectile:SetOnMiss(onhit)
        table.insert(inst.components.linearprojectile.notags,"eyeofterror")
        
        inst:DoTaskInTime(5,inst.Remove)
		
		------------------------------------------
        return inst
    end
	--------------------------------------------------------------------------
    return Prefab(name, fn, assets, prefabs)
end

return MakeProjectile("brimstone_fire", "fireball_fx", "fireball_2_fx", "idle_loop", {has_tail = true,mult_colour = {169/255, 36/255, 30/255, 1},scale = 1.2},onhit1)