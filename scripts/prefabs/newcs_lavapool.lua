local assets =
{
	Asset("ANIM", "anim/lava_pool.zip"),
}

local prefabs =
{
    "ash",
    "rocks",
    "charcoal",
    "rock1",
    "newcs_obsidian",
}

local function OnExtinguish(inst,data)
    local x,y,z = inst.Transform:GetWorldPosition()
    if data.smotherer 
    and (data.smotherer:HasTag("watersource") or data.smotherer.components.wateryprotection~=nil) 
    or data.resetpropagator then
        for i = 1, math.random(2) do
            local obsidian = SpawnPrefab("newcs_obsidian")
            obsidian.Transform:SetPosition(x, y, z)
        end
    end
    
    local radius = 1
    local things = {"rocks", "rocks", "ash", "ash", "charcoal"}
    for i = 1, #things do
        local thing = SpawnPrefab(things[i])
        thing.Transform:SetPosition(x + radius * UnitRand(), y, z + radius * UnitRand())
    end

    inst.AnimState:ClearBloomEffectHandle()

    ErodeAway(inst,0.5)
end



local function OnUpdateFueled(inst)
    if inst.components.burnable ~= nil and inst.components.fueled ~= nil then
        inst.components.burnable:SetFXLevel(inst.components.fueled:GetCurrentSection(), inst.components.fueled:GetSectionPercent())
    end
end

local PROPAGATE_RANGES = { 1, 2, 3, 3 }
local HEAT_OUTPUTS = { 2, 5, 5, 10 }

local function OnFuelChange(newsection, oldsection, inst)
    if newsection <= 0 then
        
        inst:RemoveComponent("cooker")
        inst:RemoveComponent("propagator")
        inst.persists = false
        inst:AddTag("NOCLICK")
        inst.components.burnable:Extinguish()
    else
        if not inst.components.burnable:IsBurning() then
            inst.components.burnable:Ignite()
        end

        inst.components.burnable:SetFXLevel(newsection, inst.components.fueled:GetSectionPercent())
        inst.components.propagator.propagaterange = PROPAGATE_RANGES[newsection]
        inst.components.propagator.heatoutput = HEAT_OUTPUTS[newsection]
    end
end



local function OnInit(inst)
    if inst.components.burnable ~= nil then
        inst.components.burnable:FixFX()
    end
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddLight()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()

    --MakePondPhysics(inst, 0.6)
    
    inst.AnimState:SetBank("lava_pool")
    inst.AnimState:SetBuild("lava_pool")
    inst.AnimState:PlayAnimation("dump")
    inst.AnimState:PushAnimation("idle_loop")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst:AddTag("lavapool")
    inst:AddTag("wildfireprotected")

    --cooker (from cooker component) added to pristine state for optimization
    inst:AddTag("cooker")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("inspectable")

    inst:AddComponent("cooker")

    inst:AddComponent("burnable")
    inst.components.burnable:AddBurnFX("campfirefire", Vector3(0, 0, 0))
    
    -- inst.components.burnable:MakeNotWildfireStarter()
    --inst.components.burnable:SetOnExtinguishFn(OnExtinguish)
    inst:ListenForEvent("onextinguish",OnExtinguish)

    inst:AddComponent("propagator")
    inst.components.propagator.damagerange = 2
    inst.components.propagator.damages = true


    inst:AddComponent("fueled")
    inst.components.fueled.maxfuel = 3*TUNING.FIREPIT_FUEL_START
    inst.components.fueled:SetSections(4)
    inst.components.fueled:SetUpdateFn(OnUpdateFueled)
    inst.components.fueled:SetSectionCallback(OnFuelChange)
    inst.components.fueled:InitializeFuelLevel(3*TUNING.CAMPFIRE_FUEL_START )  --0.75

    inst:DoTaskInTime(0, OnInit)

    return inst
end

return Prefab("newcs_lavapool", fn, assets, prefabs)
