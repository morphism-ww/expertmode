local brain = require("brains/firetornadobrain")
local assets =
{
    Asset("ANIM", "anim/tornado.zip"),
}

local function ontornadolifetime(inst)
    inst.task = nil
    inst.sg:GoToState("despawn")
end

local function SetDuration(inst, duration)
    if inst.task ~= nil then
        inst.task:Cancel()
    end
    inst.task = inst:DoTaskInTime(duration, ontornadolifetime)
end
		
local function grow(inst)
	inst.Transform:SetScale(0.1, 0.1, 0.1)
	inst.components.sizetweener:StartTween(3, 1)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

	inst.AnimState:SetFinalOffset(2)
    inst.AnimState:SetBank("tornado")
    inst.AnimState:SetBuild("tornado")
    inst.AnimState:PlayAnimation("tornado_loop", true)
    inst.AnimState:SetMultColour(1,69/255,0,0.8)

    inst.SoundEmitter:PlaySound("dontstarve_DLC001/common/tornado", "spinLoop")

    MakeInventoryPhysics(inst)
    RemovePhysicsColliders(inst)

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end
	
	inst.timetorun = false

    inst:AddComponent("knownlocations")
	
	inst:AddComponent("sizetweener")


    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = 4
    inst.components.locomotor.runspeed = 6

    inst:SetStateGraph("SGfiretornado")
	inst:SetBrain(brain)

    inst.CASTER = nil
    inst.persists = false
	inst.grow = grow
	inst:grow()

    inst.SetDuration = SetDuration
    inst:SetDuration(80)

    return inst
end


return Prefab("fire_tornado", fn, assets)
