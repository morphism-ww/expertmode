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
    "dreadstone",
    "dreaddragon",
    "shadow_soul"
}

local function ShouldAcceptItem1(inst,item)
    return item.components.currency or item.prefab == "goldnugget" or item.prefab == "dubloon" or item.prefab == "oinc" or item.prefab == "oinc10" or item.prefab == "oinc100"
end

local function ShouldAcceptItem2()
    return true
end

local function OnGetItemFromPlayer1(inst,giver,item)
    local value = 0
    if item.prefab == "oinc" then
        value = 1
    elseif item.prefab == "oinc10" then
        value = 10
    elseif item.prefab == "oinc100" then
        value = 100        
    elseif item.prefab == "goldnugget" then
        value = 20
    elseif item.prefab == "dubloon" then
        value = 5
    end

    inst.AnimState:PlayAnimation("splash")
    inst.AnimState:PushAnimation("idle_full",true)   
    inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/small") 

    inst:DoTaskInTime(1, function()
        if math.random() * 25 < value then
            if giver.components.poisonable ~= nil then
                giver.components.poisonable:WearOff()
            end
            if giver.components.health and  giver.components.health:GetPercent() < 1 then
                giver.components.health:DoDelta( value*5 ,false,inst.prefab)
                giver:PushEvent("celebrate")
            end           
        end
    end)
end
local function OnGetItemFromPlayer2(inst, giver, item)
    inst.AnimState:PlayAnimation("vortex_splash")
    inst.AnimState:PlayAnimation("vortex_empty")
    inst.AnimState:PushAnimation("vortex_idle_full")

    inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/small") 

    local value = 1
    if item.prefab == "dreadstone" then
        value = 100
    elseif item:HasTag("gem") then
        value = 50               
    else
        giver.components.combat:GetAttacked(nil, 300, nil, "darkness")
    end
    local should_give_key
    if item.prefab=="shadow_soul" and not inst.nokey then
        should_give_key = true
        value = 500
    end     
    
    value = value + math.random()*100		

    inst:DoTaskInTime(1, function(inst)
        local x,y,z = inst.Transform:GetWorldPosition()
        local gems = 0
        if value < 100 then
            if math.random() <= 0.6 then
                SpawnPrefab("dreaddragon").Transform:SetPosition(x,y,z)
            else
                SpawnPrefab("fused_shadeling").Transform:SetPosition(x,y,z)
            end
        elseif value < 150 then
            gems = 1
        elseif value < 200 then
            gems = 2
        else
            gems = 5
        end    

        if gems > 0 then
            inst.AnimState:PlayAnimation("vortex_splash")
            inst.AnimState:PushAnimation("vortex_idle_full")   
            inst.SoundEmitter:PlaySound("turnoftides/common/together/water/splash/small")                
            
            for i = 1,gems do
                inst.components.lootdropper:DropLoot()
            end
            if should_give_key then
                inst.nokey = true
                inst.components.lootdropper:SpawnLootPrefab("void_key")
            end 
        end
    end)
end

local function OnSave(inst,data)
    data.nokey = inst.nokey
end

local function OnLoad(inst,data)
    inst.nokey = data and data.nokey
end


local function MakeWell(name,anim,accepttest,onacceptfn)
    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        inst.AnimState:SetBuild("pig_ruins_well")
        inst.AnimState:SetBank("pig_ruins_well")
        inst.AnimState:PlayAnimation(anim, true)
--     
        MakePondPhysics(inst,2)

		inst:AddTag("watersource")		

		inst.entity:SetPristine()

		if not TheWorld.ismastersim then
			return inst
		end	
        
        inst:AddComponent("sanityaura")
        inst.components.sanityaura.aura = -TUNING.SANITYAURA_LARGE

        inst:AddComponent("lootdropper")
        inst.components.lootdropper:AddRandomLoot("redgem", 3)
        inst.components.lootdropper:AddRandomLoot("bluegem", 3)
        inst.components.lootdropper:AddRandomLoot("purplegem", 2)
        inst.components.lootdropper:AddRandomLoot("yellowgem", 2)
        inst.components.lootdropper:AddRandomLoot("orangegem", 2)
        inst.components.lootdropper:AddRandomLoot("greengem", 1)
        inst.components.lootdropper.numrandomloot = 1

        inst:AddComponent("trader")
        inst.components.trader:SetAcceptTest(accepttest)
        inst.components.trader:SetOnAccept(onacceptfn)
        --inst.components.trader:SetOnRefuse(OnRefuseItem)

        inst:AddComponent("inspectable")

        inst.OnSave = OnSave
        inst.OnLoad = OnLoad
        --anim:SetTime(math.random() * anim:GetCurrentAnimationLength())

        return inst
    end
    return Prefab(name,fn,assets,prefabs)
end
    
return MakeWell("abyss_fountain","idle_full",ShouldAcceptItem1,OnGetItemFromPlayer1),
    MakeWell("abyss_endswell","vortex_idle_full",ShouldAcceptItem2,OnGetItemFromPlayer2)

