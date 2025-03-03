require "prefabutil"
local assets =
{
	Asset("ANIM", "anim/wagstaff_thumper.zip"),
	Asset("SOUND", "sound/wagstaff.fsb"),
}

local prefabs = {
	"collapse_small"
}

local function TurnOn(inst)
	inst.sg:GoToState("raise")
end

local function OnHammered(inst, worker)
	inst.components.lootdropper:DropLoot()
	local fx = SpawnPrefab("collapse_small")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("metal")
	inst:Remove()
end

local function OnHit(inst)
	if inst.sg:HasStateTag("idle") then
		inst.sg:GoToState("hit_low")
	end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	inst.entity:AddSoundEmitter()

	MakeObstaclePhysics(inst, 1)

	inst.AnimState:SetBank("wagstaff_thumper")
	inst.AnimState:SetBuild("wagstaff_thumper")
	inst.AnimState:PlayAnimation("idle")

	
    inst:AddTag("metal")
	inst:AddTag("structure")

	MakeSnowCoveredPristine(inst)

	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("inspectable")

	inst:AddComponent("machine")
	inst.components.machine.turnonfn = TurnOn

	inst:AddComponent("lootdropper")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(OnHammered)
	inst.components.workable:SetOnWorkCallback(OnHit)

    inst:AddComponent("groundpounder")
	inst.components.groundpounder:UseRingMode()
	inst.components.groundpounder.workefficiency = 7
    inst.components.groundpounder.damageRings = 1
    inst.components.groundpounder.destructionRings = 4
	inst.components.groundpounder.radiusStepDistance = 5
    inst.components.groundpounder.ringDelay = 0.4

	inst:AddComponent("combat")

	MakeSnowCovered(inst)

	inst:SetStateGraph("SGthumper")

	return inst
end


return Prefab("quaker", fn, assets,prefabs),
	MakePlacer("quaker_placer", "wagstaff_thumper", "wagstaff_thumper", "idle")