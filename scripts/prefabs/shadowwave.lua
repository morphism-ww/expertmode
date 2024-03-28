local rogueassets =
{
    Asset( "ANIM", "anim/wave_rogue.zip" ),
}

local SPLASH_WETNESS = 30

local function DoSplash(inst)
    local wave_splash = SpawnPrefab("wave_splash")
    local pos = inst:GetPosition()
    wave_splash.Transform:SetPosition(pos.x, pos.y, pos.z)
    wave_splash.Transform:SetRotation(inst.Transform:GetRotation())
    local players = FindPlayersInRange(pos.x, pos.y, pos.z, 4, true)
    for i, v in ipairs(players) do
        if not v:HasTag("playerghost") then
            local moisture = v.components.moisture
            if moisture ~= nil then
                local waterproofness = moisture:GetWaterproofness()
                moisture:DoDelta(SPLASH_WETNESS * (1 - waterproofness))

                local entity_splash = SpawnPrefab("splash")
                entity_splash.Transform:SetPosition(v:GetPosition():Get())
            end
            if v.components.health~=nil then
                v.components.health:DoDelta(-10)
            end
            v:PushEvent("knockback", { knocker = inst, radius =1,strengthmult=1.5,propsmashed=true})
        end
    end
    inst.Physics:ClearCollisionMask()
    inst:DoTaskInTime(0.1,inst.Remove)
end

local function DoSplash2(inst)
    local wave_splash = SpawnPrefab("wave_splash")
    local pos = inst:GetPosition()
    wave_splash.Transform:SetPosition(pos.x, pos.y, pos.z)
    wave_splash.Transform:SetRotation(inst.Transform:GetRotation())
    local players = FindPlayersInRange(pos.x, pos.y, pos.z, 4, true)
    for i, v in ipairs(players) do
        if not v:HasTag("playerghost") then
            local moisture = v.components.moisture
            if moisture ~= nil then
                local waterproofness = moisture:GetWaterproofness()
                moisture:DoDelta(50 - 40*waterproofness)

                local entity_splash = SpawnPrefab("splash")
                entity_splash.Transform:SetPosition(v:GetPosition():Get())
            end
            inst.components.thief:StealItem(v)
            inst.components.thief:StealItem(v)
            inst.components.combat:DoAttack(v)
            v:PushEvent("knockback", { knocker = inst, radius = 1,strengthmult=2,propsmashed=true})
        end
    end
    inst.Physics:ClearCollisionMask()
    inst:DoTaskInTime(0.1,inst.Remove)
end


local function oncollidewave_shadow(inst, other)
    if other and other:HasTag("character") then
        DoSplash(inst)
    end
end

local function oncollidewave_lunar(inst, other)
    if other and other:HasTag("character") then
        DoSplash2(inst)
    end
end

local function commonfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddNetwork()
    inst.entity:AddAnimState()

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBuild("wave_rogue")
	inst.AnimState:SetBank("wave_rogue")
    inst.AnimState:PlayAnimation("idle", true)
    inst.AnimState:SetMultColour(0,0,0,0.5)


    local phys = inst.entity:AddPhysics()
    phys:SetSphere(1)
    phys:SetCollisionGroup(COLLISION.OBSTACLES)
    phys:ClearCollisionMask()
    phys:CollidesWith(COLLISION.CHARACTERS)
    phys:SetCollides(false)

    inst:AddTag("wave")
    inst:AddTag("FX")


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false


    inst.OnEntitySleep = inst.Remove

    inst:DoTaskInTime(3,inst.Remove)

	return inst
end


local function shadowfn()
    local inst=commonfn()
    inst.AnimState:SetMultColour(0,0,0,0.5)
    if not TheWorld.ismastersim then
        return inst
    end
    inst.Physics:SetCollisionCallback(oncollidewave_shadow)
    return inst
end

local function lunarfn()
    local inst=commonfn()
    inst.AnimState:SetMultColour(0,1,1,1)
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(100)
    inst.components.combat.playerdamagepercent = .5
    inst.components.combat:SetRange(5,5)

    inst:AddComponent("thief")
    inst.Physics:SetCollisionCallback(oncollidewave_lunar)
    return inst
end


return Prefab("shadowwave", shadowfn ,rogueassets),
     Prefab("lunarwave", lunarfn ,rogueassets)
