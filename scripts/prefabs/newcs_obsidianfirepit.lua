require "prefabutil"

local assets = {
    Asset("ANIM", "anim/firepit_obsidian.zip"),
}

local prefabs = {
    "obsidianfirefire",
    "collapse_small",
    "ash",
    "charcoal",
}    

local function onhammered(inst, worker)
    inst.components.lootdropper:DropLoot()
    local x, y, z = inst.Transform:GetWorldPosition()
    SpawnPrefab("ash").Transform:SetPosition(x, y, z)
    local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(x, y, z)
    fx:SetMaterial("stone")
    inst:Remove()
end

local function onhit(inst, worker)
    inst.AnimState:PlayAnimation("hit")
    inst.AnimState:PushAnimation("idle")
end

local function onextinguish(inst)
    if inst.components.fueled ~= nil then
        inst.components.fueled:InitializeFuelLevel(0)
    end
end

local function ontakefuel(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
end


local function onfuelchange(newsection, oldsection, inst, doer)
    if newsection <= 0 then
        inst.components.burnable:Extinguish()
		if inst.queued_charcoal then
			inst.components.lootdropper:SpawnLootPrefab("charcoal")
            inst.components.lootdropper:SpawnLootPrefab("charcoal")
            inst.queued_charcoal = nil
		end
    else
        if not inst.components.burnable:IsBurning() then
            inst.components.burnable:Ignite(nil, nil, doer)
        end
        inst.components.burnable:SetFXLevel(newsection, inst.components.fueled:GetSectionPercent())

        if newsection == inst.components.fueled.sections then
			inst.queued_charcoal = true
		end
    end
end

local SECTION_STATUS = {
    "OUT",
    "EMBERS",
    "LOW",
    "NORMAL",
    "HIGH",
}

local function getstatus(inst)
    return SECTION_STATUS[inst.components.fueled:GetCurrentSection()+1]
end

local function onbuilt(inst)
    inst.AnimState:PlayAnimation("place")
    inst.AnimState:PushAnimation("idle", false)
    inst.SoundEmitter:PlaySound("dontstarve/common/fireAddFuel")
end

local function OnHaunt(inst, haunter)
    if math.random() <= TUNING.HAUNT_CHANCE_RARE and
        inst.components.fueled ~= nil and
        not inst.components.fueled:IsEmpty() then
        inst.components.fueled:DoDelta(TUNING.MED_FUEL)
        inst.components.hauntable.hauntvalue = TUNING.HAUNT_SMALL
        return true
    end
    return false
end

local function OnInit(inst)
    if inst.components.burnable ~= nil then
        inst.components.burnable:FixFX()
    end
end

local function OnSave(inst, data)
    data.queued_charcoal = inst.queued_charcoal or nil
end

local function OnLoad(inst, data)
    if data ~= nil and data.queued_charcoal then
		inst.queued_charcoal = true
    end
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()
  
    MakeObstaclePhysics(inst, .3)

    inst.MiniMapEntity:SetIcon("firepit.png")
    inst.MiniMapEntity:SetPriority(1)

    inst.AnimState:SetBank("firepit_obsidian")
    inst.AnimState:SetBuild("firepit_obsidian")
    inst.AnimState:PlayAnimation("idle", false)

    inst:AddTag("campfire")
    inst:AddTag("structure")
    inst:AddTag("wildfireprotected")

    -- cooker (from cooker component) added to pristine state for optimization
    inst:AddTag("cooker")

    -- for storytellingprop component
	inst:AddTag("storytellingprop")

	
    inst.entity:SetPristine()
  
    if not TheWorld.ismastersim then
        return inst
    end

    -----------------------
    inst:AddComponent("burnable")
    inst.components.burnable:AddBurnFX("obsidianfirefire", Vector3(0, .4, 0))
    inst:ListenForEvent("onextinguish", onextinguish)
    
    -------------------------
    inst:AddComponent("lootdropper")
    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)    

    -------------------------
    inst:AddComponent("cooker")
    -------------------------
    inst:AddComponent("fueled")
    inst.components.fueled.maxfuel = 2*TUNING.FIREPIT_FUEL_MAX
    inst.components.fueled.accepting = true
    inst.components.fueled:SetSections(4)
    inst.components.fueled.bonusmult = 4
    inst.components.fueled.ontakefuelfn = ontakefuel
    inst.components.fueled:SetSectionCallback(onfuelchange)
    inst.components.fueled:InitializeFuelLevel(TUNING.FIREPIT_FUEL_START)

    inst:AddComponent("storytellingprop")

    inst:AddComponent("rainimmunity")

    -----------------------------

    inst:AddComponent("hauntable")
    inst.components.hauntable.cooldown = TUNING.HAUNT_COOLDOWN_HUGE
    inst.components.hauntable:SetOnHauntFn(OnHaunt)
    
    -----------------------------
    
    inst:AddComponent("inspectable")
    inst.components.inspectable.getstatus = getstatus

    inst:ListenForEvent("onbuilt", onbuilt)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    inst:DoTaskInTime(0, OnInit)

    --inst.restart_firepit
    
    return inst
end

return Prefab("newcs_obsidianfirepit", fn, assets, prefabs),
        MakePlacer("newcs_obsidianfirepit_placer", "firepit", "firepit", "preview")
