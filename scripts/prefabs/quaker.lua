require "prefabutil"
local assets =
{
	Asset("ANIM", "anim/wagstaff_thumper.zip"),
	Asset("SOUND", "sound/wagstaff.fsb"),
}

local prefabs =
{

}

local function TurnOn(inst)
	inst.sg:GoToState("raise")
end

local function TurnOff(inst)
	--inst.sg:GoToState("idle")
end


local function CanInteract(inst)
	if inst.components.machine.ison then
		return false
	end
	return true
end

local function GetStatus(inst, viewer)
	if inst.on then
		return "ON"
	else
		return "OFF"
	end
end


local function OnSave(inst, data)
    local refs = {}

    return refs
end

local function OnLoad(inst, data)

end


local function OnBuilt(inst)
	inst.sg:GoToState("place")
end


local function OnHammered(inst, worker)
	if inst:HasTag("fire") and inst.components.burnable then
		inst.components.burnable:Extinguish()
	end

	inst.components.lootdropper:DropLoot()
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_metal")
	TurnOff(inst, true)
	inst:Remove()
end

local function OnHit(inst, dist)
	if inst.sg:HasStateTag("idle") then
		inst.sg:GoToState("hit_low")
	end
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	local anim = inst.entity:AddAnimState()
	inst.entity:AddNetwork()
	inst.entity:AddSoundEmitter()


    inst:AddTag("groundpoundimmune")
    inst:AddTag("metal")
	MakeObstaclePhysics(inst, 1)

	anim:SetBank("wagstaff_thumper")
	anim:SetBuild("wagstaff_thumper")
	anim:PlayAnimation("idle")


	inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.on = false


	inst:AddComponent("machine")
	inst.components.machine.turnonfn = TurnOn
	inst.components.machine.turnofffn = TurnOff
	--inst.components.machine.caninteractfn = CanInteract
	inst.components.machine.cooldowntime = 0.5

	inst:AddComponent("lootdropper")

	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
	inst.components.workable:SetWorkLeft(4)
	inst.components.workable:SetOnFinishCallback(OnHammered)
	inst.components.workable:SetOnWorkCallback(OnHit)

    inst:AddComponent("groundpounder")
  	inst.components.groundpounder.destroyer = true
    inst.components.groundpounder.damageRings = 2
    inst.components.groundpounder.destructionRings = 4
    inst.components.groundpounder.numRings = 5

	inst:AddComponent("combat")
    inst.components.combat.defaultdamage = 0
	--inst.OnSave = OnSave
    --inst.OnLoad = OnLoad

	inst:ListenForEvent("onbuilt", OnBuilt)

	
	inst:SetStateGraph("SGthumper")

	return inst
end



return Prefab("quaker", fn, assets, prefabs),
MakePlacer("quaker_placer", "wagstaff_thumper", "wagstaff_thumper", "idle")