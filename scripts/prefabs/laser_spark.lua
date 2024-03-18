local assets =
{
    Asset("ANIM", "anim/charged_particle.zip"),
}

local prefabs =
{
    "moonstorm_spark_shock_fx",
}

local brain = require "brains/sporebrain"


local SPARK_CANT_TAGS = { "playerghost", "INLIMBO","wall","structure","chess","laser_immune","shadow"}

local function dospark(inst)
    if inst:IsInLimbo() then
        print(debugstack())
    end
    local fx = inst:SpawnChild("moonstorm_spark_shock_fx")
    inst.sparktask = inst:DoTaskInTime(5/30, function()
        inst.Light:SetRadius(3)
        local pos = Vector3(inst.Transform:GetWorldPosition())
        local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 7,{"_health"}, SPARK_CANT_TAGS)
        if #ents > 0 then
            for i, ent in ipairs(ents)do
                if ent.components.combat ~= nil and (ent.components.inventory == nil or not ent.components.inventory:IsInsulated()) then
                    ent.components.combat:GetAttacked(inst, 20, nil, "electric")
                end
            end
        end
        inst:DoTaskInTime(0.5,function()
            inst.Light:SetRadius(3)
        end)
        inst.sparktask = inst:DoTaskInTime(3 + math.random(), dospark)
    end)

end

local function depleted(inst)
    inst:PushEvent("death")
    inst:RemoveTag("spore") -- so crowding no longer detects it
    inst.persists = false
    -- clean up when offscreen, because the death event is handled by the SG
    inst:DoTaskInTime(3, inst.Remove)
end

local SPORE_TAGS = {"spore"}
local function checkforcrowding(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local spores = TheSim:FindEntities(x,y,z, 6, SPORE_TAGS)
    if #spores > TUNING.MUSHSPORE_MAX_DENSITY then
        inst.components.perishable:SetPercent(0)
    else
        inst.crowdingtask = inst:DoTaskInTime(TUNING.MUSHSPORE_DENSITY_CHECK_TIME + math.random()*TUNING.MUSHSPORE_DENSITY_CHECK_VAR, checkforcrowding)
    end
end




local function onload(inst)
    -- If we loaded, then just turn the light on
    inst.Light:Enable(true)
    inst.DynamicShadow:Enable(true)
end


local function OnWake(inst)
    if not inst.sparktask then
        inst.sparktask = inst:DoTaskInTime(3 + math.random(), dospark)
    end
end

local function OnSleep(inst)
    if inst.sparktask then
        inst.sparktask:Cancel()
        inst.sparktask = nil
    end
    inst.SoundEmitter:KillSound("idle_LP")
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
	inst.entity:AddDynamicShadow()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

	--MakeCharacterPhysics(inst, 1, .5)
    MakeFlyingCharacterPhysics(inst, 1, .5)

    inst.AnimState:SetBuild("charged_particle")
    inst.AnimState:SetBank("charged_particle")
    inst.AnimState:Hide("cp_blob")
    inst.AnimState:PlayAnimation("idle_flight_loop", true)
    inst.AnimState:SetMultColour(1,0,0,0.5)


    inst.DynamicShadow:Enable(false)

    inst.Light:SetColour(111/255, 111/255, 227/255)
    inst.Light:SetIntensity(0.75)
    inst.Light:SetFalloff(0.5)
    inst.Light:SetRadius(1.5)
    inst.Light:Enable(true)

    inst.DynamicShadow:SetSize(.8, .5)

    inst:AddTag("moonstorm_spark")
    inst:AddTag("spore")


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    --[[inst.shadow=SpawnPrefab("ancient_hulk_orbspark")
    inst.shadow.entity:SetParent(inst.entity)
    inst.shadow.entity:AddFollower():FollowSymbol(inst.GUID, "cp_blob", 0, 0, 0)]]

    inst:AddComponent("knownlocations")


    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor.walkspeed = 5



    inst:AddComponent("perishable")
    inst.components.perishable:SetPerishTime(25)
    inst.components.perishable:StartPerishing()
    inst.components.perishable:SetOnPerishFn(depleted)




    inst.OnEntityWake = OnWake
    inst.OnEntitySleep = OnSleep

    inst:SetStateGraph("SGspore")
    inst:SetBrain(brain)

    -- note: the first check is faster, because this might be from dropping a stack
    inst.crowdingtask = inst:DoTaskInTime(1 + math.random()*TUNING.MUSHSPORE_DENSITY_CHECK_VAR, checkforcrowding)

    inst.sparktask = inst:DoTaskInTime(3 + math.random(), dospark)
    
    inst.OnLoad = onload

    return inst
end

return Prefab("laser_spark", fn, assets, prefabs)
