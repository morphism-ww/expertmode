local assets =
{
    Asset( "ANIM", "anim/wave_rogue.zip" ),
}


local function dropweapon(inst)
    if inst.sg:HasStateTag("parrying") then
        return
    end
    local item = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    local pos
    if item ~= nil then
        pos = inst:GetPosition()
        pos.y = TUNING.KNOCKBACK_DROP_ITEM_HEIGHT_HIGH
        inst.components.inventory:DropItem(item, true, true, pos)
    end
end

local function DoSplash(inst)
    local pos = inst:GetPosition()
    if not inst.hit then
        local players = FindPlayersInRange(pos.x, pos.y, pos.z, 2, true)
        if next(players)~=nil then
            inst.hit = true
            inst:RemoveComponent("updatelooper")
            --inst.components.updatelooper:RemoveOnUpdateFn(DoSplash)
            for i, v in ipairs(players) do
                if v:IsValid() then
                    local moisture = v.components.moisture
                    if moisture ~= nil then
                        local waterproofness = moisture:GetWaterproofness()
                        moisture:DoDelta(SPLASH_WETNESS * (1 - waterproofness))

                        local entity_splash = SpawnPrefab("splash")
                        entity_splash.Transform:SetPosition(v.Transform:GetWorldPosition())
                    end
                    dropweapon(v)
                    v:PushEvent("knockback", { knocker = inst, radius =1,strengthmult=1.5})
                end
            end
        end
    end
    --inst:DoTaskInTime(0.3,inst.Remove)
end

local function TogglePhysics(inst,other)
    inst.Physics:SetCollisionCallback(nil)
    --inst.Physics:ClearCollisionMask()
    --inst.Physics:CollidesWith(COLLISION.GROUND)
    inst.Physics:SetActive(false)
    inst:Hide()

    inst:DoTaskInTime(0.1,inst.Remove)
end


local function oncollidewave(inst,other)
    if inst.activate and other~=nil and other:IsValid() and other.isplayer then
        inst.activate = false
        
        local moisture = other.components.moisture
        if moisture ~= nil then
            local waterproofness = moisture:GetWaterproofness()
            moisture:DoDelta(30 * (1 - waterproofness))
            local entity_splash = SpawnPrefab("splash")
            entity_splash.Transform:SetPosition(other.Transform:GetWorldPosition())
        end
        dropweapon(other)
        other:PushEvent("knockback", { knocker = inst, radius = 1.2, strengthmult = 1.2})
        inst:DoTaskInTime(2*FRAMES,inst.Remove)
    end
end


local function MakeWave(name,colours,scale)
    scale = scale or 1
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddNetwork()
        inst.entity:AddAnimState()

        inst.Transform:SetFourFaced()

        inst.AnimState:SetBuild("wave_rogue")
        inst.AnimState:SetBank("wave_rogue")
        inst.AnimState:PlayAnimation("idle", true)

        local phys = inst.entity:AddPhysics()
        phys:SetFriction(0)
        phys:SetDamping(0)
        phys:SetRestitution(0)
        phys:SetCollisionGroup(COLLISION.OBSTACLES)
        phys:ClearCollisionMask()
        phys:CollidesWith(COLLISION.CHARACTERS)
        phys:SetCapsule(1.2*scale, 1)
        phys:SetCollides(false)

        inst:AddTag("FX")

        inst.AnimState:SetMultColour(unpack(colours))
        inst.AnimState:SetScale(scale,scale,scale)
        
        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst.persists = false

        inst.activate = true

        inst.Physics:SetCollisionCallback(oncollidewave)
        --inst:AddComponent("thief")

        inst:DoTaskInTime(3,inst.Remove)

        return  inst
    end
    return Prefab(name,fn,assets)
end


return MakeWave("shadowwave",{0,0,0,0.5}),
    MakeWave("lunarwave",{0,1,1,1},1.2)
