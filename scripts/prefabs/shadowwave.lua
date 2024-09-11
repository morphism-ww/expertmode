local rogueassets =
{
    Asset( "ANIM", "anim/wave_rogue.zip" ),
}

local SPLASH_WETNESS = 30

local function DoSplash(inst)
    local pos = inst:GetPosition()
    if not inst.hit then
        local players = FindPlayersInRange(pos.x, pos.y, pos.z, 2, true)
        if #players>0 then
            inst.hit = true
            inst.components.updatelooper:RemoveOnUpdateFn(DoSplash)
            for i, v in ipairs(players) do
                if v:IsValid() then
                    local moisture = v.components.moisture
                    if moisture ~= nil then
                        local waterproofness = moisture:GetWaterproofness()
                        moisture:DoDelta(SPLASH_WETNESS * (1 - waterproofness))

                        local entity_splash = SpawnPrefab("splash")
                        entity_splash.Transform:SetPosition(v:GetPosition():Get())
                    end
                    v:PushEvent("knockback", { knocker = inst, radius =1,strengthmult=1.5,propsmashed=true})
                end
            end
        end
    end
    --inst:DoTaskInTime(0.3,inst.Remove)
end

local function DoSplash2(inst)
    local pos = inst:GetPosition()
    if not inst.hit then
        local players = FindPlayersInRange(pos.x, pos.y, pos.z, 2.2, true)
        if #players>0 then
            inst.components.updatelooper:RemoveOnUpdateFn(DoSplash2)
            inst.hit = true

            for i, v in ipairs(players) do
                local moisture = v.components.moisture
                if moisture ~= nil then
                    local waterproofness = moisture:GetWaterproofness()
                    moisture:DoDelta(40 * (1 - 0.5*waterproofness))

                    local entity_splash = SpawnPrefab("splash")
                    entity_splash.Transform:SetPosition(v:GetPosition():Get())
                end

                v:PushEvent("knockback", { knocker = inst, radius =1,   strengthmult=2,   propsmashed=true})
            end
        end
    end
    --inst:DoTaskInTime(0.3,inst.Remove)
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
    inst.Physics:SetFriction(0)
    inst.Physics:SetDamping(0)
    inst.Physics:SetRestitution(0)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
    inst.Physics:SetSphere(1.2)
    phys:SetCollides(false)

	return inst
end


local function shadowfn()
    local inst=commonfn()

    inst.AnimState:SetMultColour(0,0,0,0.5)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("updatelooper")
    inst.components.updatelooper:AddOnUpdateFn(DoSplash)

    inst.checkhittask = inst:DoPeriodicTask(0.1, DoSplash)
    inst:DoTaskInTime(3,inst.Remove)



    return inst
end

local function lunarfn()
    local inst=commonfn()
    inst.AnimState:SetMultColour(0,1,1,1)
    inst.Transform:SetScale(1.2,1.2,1.2)
    
    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    --inst:AddComponent("thief")

    inst:AddComponent("updatelooper")
    inst.components.updatelooper:AddOnUpdateFn(DoSplash2)

    inst:DoTaskInTime(2.5,inst.Remove)

    return inst
end


return Prefab("shadowwave", shadowfn ,rogueassets),
     Prefab("lunarwave", lunarfn ,rogueassets)
