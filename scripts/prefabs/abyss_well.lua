local assets =
{
    Asset("ANIM", "anim/pig_ruins_well.zip"),      
}

local prefabs = {
    "greengem",
    "redgem",
    "bluegem",
    "yellowgem",
    "orangegem",
    "purplegem",
    "fused_shadeling",
    "abyss_leech",
    "shadow_soul",
    "odd_mushroom"
}


local gems_weights = {
    redgem = 4,
    bluegem = 4,
    purplegem = 3,
    yellowgem = 2,
    orangegem = 2,
    greengem = 1,
}

local function ShouldAcceptItem()
    return true
end

local function give_reward(inst,gems,special_gift)
    inst.AnimState:PlayAnimation("vortex_splash")
    inst.AnimState:PushAnimation("vortex_idle_full")   
    inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/small") 

    local pt = inst:GetPosition()
    if gems > 0 then
        local loots = weighted_random_choices(gems_weights, gems)
        for i ,v in ipairs(loots) do
            inst.components.lootdropper:SpawnLootPrefab(v,pt)
        end
    end

    if special_gift~=nil then
        inst.components.lootdropper:SpawnLootPrefab(special_gift,pt)
    end 

    inst.components.trader:Enable()
end

local VALUE_LOOKUP = {redgem = 30, bluegem = 40, purplegem = 50, dreadstone = 50, 
yellowgem = 60, orangegem = 70, greengem = 80, opalpreciousgem = 120, shadow_soul = 200}

local function OnGetItemFromPlayer(inst, giver, item)
    inst.AnimState:PlayAnimation("vortex_splash")
    inst.AnimState:PushAnimation("vortex_idle_full")

    inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/small") 

    inst.components.trader:Disable()

    -------determine item's value
    local value = VALUE_LOOKUP[item.prefab] or 0


    -------special item based on trigger_specialtrade from the last trade
    local special_gift 
    if item:HasTag("mushroom") and inst.trigger_specialtrade then
        special_gift = "odd_mushroom"
    elseif value == 0 then ---punish
        special_gift = math.random()<0.5 and "abyss_leech" or "fused_shadeling_quickfuse_bomb"
    end

    -----override the specialtrade 
    inst.trigger_specialtrade = value == 200

    ----give key only once!!!
    if inst.haskey and inst.trigger_specialtrade then
        inst.haskey = false
        special_gift = "void_key"
    end


    value = value + math.random()*25

    --every 50 units of value -> 1 gem
    local gems = math.floor(value/50)

    inst:DoTaskInTime(1,give_reward,gems,special_gift)
end

local function OnSave(inst,data)
    if not inst.haskey then
        data.nokey = true
    end
end

local function OnLoad(inst,data)
    if data~=nil then
        inst.haskey = not data.nokey
    end
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.AnimState:SetBuild("pig_ruins_well")
    inst.AnimState:SetBank("pig_ruins_well")
    inst.AnimState:PlayAnimation("vortex_idle_full", true)
--     
    MakePondPhysics(inst,2)

    inst:AddTag("watersource")		

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.trigger_specialtrade = false
    inst.haskey = true
    
    inst:AddComponent("inspectable")
    
    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_LARGE

    inst:AddComponent("lootdropper")

    inst:AddComponent("trader")
    inst.components.trader:SetAcceptTest(ShouldAcceptItem)
    inst.components.trader:SetOnAccept(OnGetItemFromPlayer)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad


    return inst
end

return Prefab("abyss_endswell",fn,assets,prefabs)

