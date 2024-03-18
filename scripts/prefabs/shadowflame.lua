local shadowassets =
{
    Asset("ANIM", "anim/shadow_fire_fx.zip"),
    Asset("SOUND", "sound/common.fsb"),
}


local prefabs =
{
    "firefx_light",
    "willow_shadow_fire_explode",
}

local shadowfirelevels =
{
    {anim="anim1", sound="meta3/willow/shadowflame", radius=2, intensity=.8, falloff=.33, colour = {253/255,179/255,179/255}, soundintensity=.1},
    {anim="anim2",                                   radius=2, intensity=.8, falloff=.33, colour = {253/255,179/255,179/255}, soundintensity=.1},
    {anim="anim3",                                   radius=2, intensity=.8, falloff=.33, colour = {253/255,179/255,179/255}, soundintensity=.1},
    {anim="anim3",                                   radius=2, intensity=.8, falloff=.33, colour = {253/255,179/255,179/255}, soundintensity=.1},
}



local CLOSERANGE = 1

local TARGETS_MUST = {"_health"}
local TARGETS_CANT = { "INLIMBO", "flight", "shadow_aligned", "invisible", "noattack", "notarget","minotaur","wall","chess","shadow" }

local FLAME_MUST = {"shadow_flame"}

local function settarget(inst,target,life,source)
    local maxdeflect = 30

    if life > 0 then

        inst.shadowfire_task = inst:DoTaskInTime(0.2,function()

            local theta = inst.Transform:GetRotation() * DEGREES
            local radius = CLOSERANGE

            if not (source and source.components.combat and source:IsValid()) then
                target = nil
                inst.shadow_ember_target = nil
            elseif target == nil or not source.components.combat:CanTarget(target) then
                target = nil
                inst.shadow_ember_target = nil

                local x, y, z = inst.Transform:GetWorldPosition()
                local ents = TheSim:FindEntities(x, y, z, 20, TARGETS_MUST, TARGETS_CANT)
                if #ents > 0 then
                    local targets = {}
                    local flameents = TheSim:FindEntities(x, y, z, 20, FLAME_MUST)
                    for i, flame in ipairs(flameents) do
                        if flame.shadow_ember_target then
                            targets[flame.shadow_ember_target] = true
                        end
                    end

                    for i, ent in ipairs(ents) do
                        if not targets[ent] and
                                ent.components.combat~=nil and
                                source.components.combat:CanTarget(ent)
                        then
                            target = ent
                            inst.shadow_ember_target = target
                            break
                        end
                    end
                end
            end

            if target then
                local dist = inst:GetDistanceSqToInst(target)

                if dist<CLOSERANGE*CLOSERANGE then

                    local blast = SpawnPrefab("willow_shadow_fire_explode")
                    local pos = Vector3(target.Transform:GetWorldPosition())
                    blast.Transform:SetPosition(pos.x,pos.y,pos.z)

                    local weapon = inst

                    source.components.combat.ignorehitrange = true
                    source.components.combat.ignoredamagereflect = true

                    source.components.combat:DoAttack(target, weapon)

                    source.components.combat.ignorehitrange = false
                    source.components.combat.ignoredamagereflect = false

                    theta = nil
                else
                    local pt = Vector3(target.Transform:GetWorldPosition())
                    local angle = inst:GetAngleToPoint(pt.x,pt.y,pt.z)
                    local anglediff = angle - inst.Transform:GetRotation()
                    if anglediff > 180 then
                        anglediff = anglediff - 360
                    elseif anglediff < -180 then
                        anglediff = anglediff + 360
                    end
                    if math.abs(anglediff) > maxdeflect then
                        anglediff = math.clamp(anglediff, -maxdeflect, maxdeflect)
                    end

                    theta = (inst.Transform:GetRotation() + anglediff) * DEGREES
                end
            else
                if not inst.currentdeflection then
                    inst.currentdeflection = {time = math.random(1,10), deflection = maxdeflect * ((math.random() *2)-1) }
                end
                inst.currentdeflection.time = inst.currentdeflection.time -1
                if inst.currentdeflection.time then
                    inst.currentdeflection = {time = math.random(1,10), deflection = maxdeflect * ((math.random() *2)-1) }
                end

                theta =  (inst.Transform:GetRotation() + inst.currentdeflection.deflection) * DEGREES
            end

            if theta  then
                local offset = Vector3(radius * math.cos( theta ), 0, -radius * math.sin( theta ))
                local newpos = Vector3(inst.Transform:GetWorldPosition()) + offset
                local newangle = inst:GetAngleToPoint(newpos.x,newpos.y,newpos.z)

                local fire = SpawnPrefab("shadow_flame")
                fire.Transform:SetRotation(newangle)
                fire.Transform:SetPosition(newpos.x,newpos.y,newpos.z)
                fire:settarget(target,life-1, source)
            end
        end)
    elseif life==0 then
        local x, y, z = inst.Transform:GetWorldPosition()
        local tent = SpawnPrefab("bigshadowtentacle")
        tent.Transform:SetPosition(x,y,z)
        tent:PushEvent("arrive")
    end
end

local function shadowfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("shadow_fire_fx")
    inst.AnimState:SetBuild("shadow_fire_fx")
    inst.AnimState:PlayAnimation("anim"..math.random(1,3),false)

    inst.AnimState:SetMultColour(0, 0, 0, .8)
    inst.AnimState:SetFinalOffset(3)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("shadow_flame")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("firefx")
    inst.components.firefx.levels = shadowfirelevels

    inst.components.firefx:SetLevel(math.random(1,4))

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(75)



    inst:ListenForEvent("animover", function()
        if inst.AnimState:IsCurrentAnimation("anim1") or inst.AnimState:IsCurrentAnimation("anim2") or inst.AnimState:IsCurrentAnimation("anim3") then
            inst:Remove()
        end
    end)

    inst.settarget = settarget

    return inst
end



local TARGETS_ONEOF = { "hostile", "_combat" }
local PLAYER_TARGETS_CANT = { "INLIMBO", "flight", "player", "invisible", "noattack", "notarget" }


local function settarget2(inst,target,life,source)
    local maxdeflect = 60

    if life > 0 then

        inst.shadowfire_task = inst:DoTaskInTime(0.1,function()

            local theta = inst.Transform:GetRotation() * DEGREES
            local radius = CLOSERANGE

			if not (source and source.components.combat and source:IsValid()) then
				target = nil
				inst.shadow_ember_target = nil
			elseif target == nil or not source.components.combat:CanTarget(target) then
				target = nil
                inst.shadow_ember_target = nil

				local x, y, z = inst.Transform:GetWorldPosition()
				local ents = TheSim:FindEntities(x, y, z, 16, TARGETS_MUST, PLAYER_TARGETS_CANT, TARGETS_ONEOF)
                if #ents > 0 then
					local targets = {}
					local flameents = TheSim:FindEntities(x, y, z, 20, FLAME_MUST)
					for i, flame in ipairs(flameents) do
						if flame.shadow_ember_target then
							targets[flame.shadow_ember_target] = true
						end
					end

					for i, ent in ipairs(ents) do
						if not targets[ent] and
							(	ent:HasTag("hostile") or
								(ent.components.combat and ent.components.combat:TargetIs(source))
							) and
							not (ent.components.follower and ent.components.follower:GetLeader() == source) and
							source.components.combat:CanTarget(ent)
                        then
							target = ent
							inst.shadow_ember_target = target
							break
                        end
                    end
                end
            end

			if target then
                local dist = inst:GetDistanceSqToInst(target)

                if dist<CLOSERANGE*CLOSERANGE then

                    local blast = SpawnPrefab("willow_shadow_fire_explode")
                    local pos = Vector3(target.Transform:GetWorldPosition())
                    blast.Transform:SetPosition(pos.x,pos.y,pos.z)

                    inst.components.combat:DoAttack(target)

                    theta = nil
                else
                    local pt = Vector3(target.Transform:GetWorldPosition())
                    local angle = inst:GetAngleToPoint(pt.x,pt.y,pt.z)
                    local anglediff = angle - inst.Transform:GetRotation()
                    if anglediff > 180 then
                        anglediff = anglediff - 360
                    elseif anglediff < -180 then
                        anglediff = anglediff + 360
                    end
                    if math.abs(anglediff) > maxdeflect then
                        anglediff = math.clamp(anglediff, -maxdeflect, maxdeflect)
                    end

                    theta = (inst.Transform:GetRotation() + anglediff) * DEGREES
                end
            else
                if not inst.currentdeflection then
                    inst.currentdeflection = {time = math.random(1,10), deflection = maxdeflect * ((math.random() *2)-1) }
                end
                inst.currentdeflection.time = inst.currentdeflection.time -1
                if inst.currentdeflection.time then
                    inst.currentdeflection = {time = math.random(1,10), deflection = maxdeflect * ((math.random() *2)-1) }
                end

                theta =  (inst.Transform:GetRotation() + inst.currentdeflection.deflection) * DEGREES
            end

            if theta  then
                local offset = Vector3(radius * math.cos( theta ), 0, -radius * math.sin( theta ))
                local newpos = Vector3(inst.Transform:GetWorldPosition()) + offset
                local newangle = inst:GetAngleToPoint(newpos.x,newpos.y,newpos.z)

                local fire = SpawnPrefab("void_flame")
                fire.Transform:SetRotation(newangle)
                fire.Transform:SetPosition(newpos.x,newpos.y,newpos.z)
                fire:settarget(target,life-1, source)
            end
        end)

    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("shadow_fire_fx")
    inst.AnimState:SetBuild("shadow_fire_fx")
    inst.AnimState:PlayAnimation("anim"..math.random(1,3),false)

    inst.AnimState:SetMultColour(0, 0, 0, .8)
    inst.AnimState:SetFinalOffset(3)

    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst:AddTag("shadow_flame")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("firefx")
    inst.components.firefx.levels = shadowfirelevels

    inst.components.firefx:SetLevel(math.random(1,4))

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(20)
    inst:AddComponent("planardamage")
    inst.components.planardamage:SetBaseDamage(10)


    inst:ListenForEvent("animover", function()
        if inst.AnimState:IsCurrentAnimation("anim1") or inst.AnimState:IsCurrentAnimation("anim2") or inst.AnimState:IsCurrentAnimation("anim3") then
            inst:Remove()
        end
    end)

    inst.settarget = settarget2

    return inst
end


return Prefab("shadow_flame", shadowfn, shadowassets, prefabs),
  Prefab("void_flame", fn, shadowassets, prefabs)
