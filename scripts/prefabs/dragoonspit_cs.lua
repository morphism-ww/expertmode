local assets=
{
	Asset("ANIM", "anim/lava_vomit.zip"),
}

local INTENSITY = .7

local function fade_in(inst)
    inst.components.fader:StopAll()
    inst.components.fader:Fade(0, INTENSITY, 5*FRAMES, function(v) inst.Light:SetIntensity(v) end)
end

local function fade_out(inst)
    inst.components.fader:StopAll()
    inst.components.fader:Fade(INTENSITY, 0, 5*FRAMES, function(v) inst.Light:SetIntensity(v) end, function() inst.Light:Enable(false) end)
end

local function Extinguish(inst)
    local x,y,z = inst.Transform:GetWorldPosition()
    SpawnPrefab("charcoal").Transform:SetPosition(x,y,z)
	SpawnPrefab("ash").Transform:SetPosition(x,y,z)
    inst:Remove()
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()

    inst.AnimState:SetBank("lava_vomit")
    inst.AnimState:SetBuild("lava_vomit")
    inst.AnimState:PlayAnimation("dump")
    inst.AnimState:PushAnimation("idle_loop")
    inst.AnimState:SetBloomEffectHandle( "shaders/anim.ksh" )


    local light = inst.entity:AddLight()
    light:SetFalloff(.5)
    light:SetIntensity(INTENSITY)
    light:SetRadius(1)
    light:Enable(true)
    light:SetColour(200/255, 100/255, 170/255)
    

	inst.entity:SetPristine()
		
    if not TheWorld.ismastersim then
        return inst
    end
    
    inst.persists = false

    inst:AddComponent("fader")

    MakeSmallPropagator(inst)
    inst.components.propagator.heatoutput = 50
    inst.components.propagator.decayrate = 0
    inst.components.propagator:Flash()
    inst.components.propagator:StartSpreading()

    inst:AddComponent("colourtweener")

    inst.cooltask = inst:DoTaskInTime(20, function(inst)
    	inst.AnimState:PushAnimation("cool", false)
    	fade_out(inst)
    end)
    
    inst:ListenForEvent("animqueueover", function(inst)
   		inst.AnimState:SetPercent("cool", 1)
        inst.components.propagator:StopSpreading()
        inst.components.colourtweener:StartTween({0,0,0,0}, 7, Extinguish)
    end)
      
    fade_in(inst)



    return inst
end

return Prefab( "dragoonspit_cs", fn, assets)