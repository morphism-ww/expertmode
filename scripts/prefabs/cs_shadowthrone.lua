local assets =
{
	Asset("ANIM", "anim/maxwell_throne.zip"),
}

local prefabs = {
    "planar_key",
    "shadow_despawn",
    "stageusher_attackhand"
}

local function ShouldAcceptItem(inst, item)
    return item.prefab == "alterguardianhatshard"
end

local function OnGetItemFromPlayer(inst,giver,item)
    local x,y,z = inst.Transform:GetWorldPosition()
    inst.components.trader:Disable()
    SpawnPrefab("shadow_despawn").Transform:SetPosition(x+3,0,z+3)
    inst:DoTaskInTime(0.3,function ()
        SpawnPrefab("planar_key").Transform:SetPosition(x+3,0,z+3)
    end)
end

local function OnSave(inst,data)
    data.enable = inst.components.trader.enabled
end

local function OnLoad(inst,data)
    if data and not data.enable then
        inst.components.trader:Disable()
    end
end

local function OnRefuseItem(inst, giver)
    local ipos = inst:GetPosition()
    local tpos = giver:GetPosition()
    local unit_target_vec = (tpos - ipos):GetNormalized()

    local attack_hand = SpawnPrefab("stageusher_attackhand")
    attack_hand.Transform:SetPosition((ipos + unit_target_vec*0.5):Get())
    attack_hand:SetOwner(inst)
    attack_hand:SetCreepTarget(giver)
end

local function CreateBlocker()
    local inst = CreateEntity()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    inst.entity:AddTransform()

    inst.entity:SetCanSleep(false)
    inst.persists = false

    inst:SetGroundTargetBlockerRadius(20)
    inst:SetTerraformExtraSpacing(16)

    return inst
end

local function fn()
    local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()


    inst.AnimState:SetBank("throne")
    inst.AnimState:SetBuild("maxwell_throne")
    inst.AnimState:PlayAnimation("idle")

    --inst.Transform:SetFourFaced()
    inst:AddTag("notarget")
	inst:AddTag("structure")
    inst:AddTag("shadow")

    local blocker = CreateBlocker()
    blocker.entity:SetParent(inst.entity)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
		return inst
	end

    inst:AddComponent("inspectable") 
    
    local trader = inst:AddComponent("trader")
    trader:SetAcceptTest(ShouldAcceptItem)
    trader.onaccept = OnGetItemFromPlayer
    trader.onrefuse = OnRefuseItem


    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -20

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(200)
    inst.components.combat:SetAttackPeriod(TUNING.STAGEUSHER_ATTACK_PERIOD)
    inst.components.combat:SetRange(TUNING.STAGEUSHER_ATTACK_RANGE)
    inst.components.combat.ignorehitrange = true
    inst.components.combat.canattack = false

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad


    return inst
end

return Prefab( "cs_shadowthrone", fn, assets, prefabs) 