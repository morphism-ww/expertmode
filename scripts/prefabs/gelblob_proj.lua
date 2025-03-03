local assets =
{
    Asset("ANIM", "anim/gelblob.zip"),
}


local DAMAGE_MUST_TAGS = {"_combat","locomotor"}
local DAMAGE_CANT_TAGS = {"playerghost","shadow","shadow_aligned","INLIMBO", "notarget", "noattack", "flight","vigorbuff"}

local function OnHit(inst, attacker)
    inst.AnimState:SetScale(2,2,2)
    inst.AnimState:PlayAnimation("splash_impact")
	inst:ListenForEvent("animover", inst.Remove)
	inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/poison_drop")

	local x, y, z = inst.Transform:GetWorldPosition()
	for i, v in ipairs(TheSim:FindEntities(x, 0, z, 6, DAMAGE_MUST_TAGS, DAMAGE_CANT_TAGS)) do
        if v:IsValid() and not (v.components.health~=nil and v.components.health:IsDead()) then
            local range = 4 + v:GetPhysicsRadius(0)
			if v:GetDistanceSqToPoint(x, 0, z) < range * range then
                v:AddDebuff("buff_slimed","buff_slimed")
                if v.components.combat:CanBeAttacked() then
                    v:PushEvent("attacked", { attacker = attacker, damage = 0})
                end
            end
        end
    end
end



local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
    inst.entity:AddPhysics()

    inst.Physics:SetMass(1)
    inst.Physics:SetFriction(0)
    inst.Physics:SetDamping(0)
    inst.Physics:SetRestitution(.5)
    inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
    inst.Physics:SetCapsule(.2, .2)


    inst.AnimState:SetBank("gelblob")
	inst.AnimState:SetBuild("gelblob")
    inst.AnimState:PlayAnimation("splash_loop", true)
	inst.AnimState:SetFinalOffset(2)

    inst:AddTag("FX")
    inst:AddTag("projectile")


    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("complexprojectile")
    inst.components.complexprojectile:SetGravity(-50)
    inst.components.complexprojectile:SetHorizontalSpeed(25)
    inst.components.complexprojectile:SetLaunchOffset(Vector3(0.2,2.5,0))
    inst.components.complexprojectile:SetOnHit(OnHit)


    return inst
end


local function fxfn()
    local inst = CreateEntity()

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst:AddTag("FX")
	inst:AddTag("NOCLICK")

	inst.AnimState:SetBank("gelblob")
	inst.AnimState:SetBuild("gelblob")
	inst.AnimState:PlayAnimation("blob_attach_end_pre")
    inst.AnimState:PushAnimation("blob_attach_end_loop")
	inst.AnimState:SetFinalOffset(2)

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end

    inst.persists = false
    return inst
end
local function startfalling(inst)
    inst.prefab = "mole"
end

local function DoAOE(inst)

    inst.prefab = "gelblob_falling"

    inst.AnimState:SetScale(2,2,2)
    inst.AnimState:PlayAnimation("splash_impact")
	inst:ListenForEvent("animover", inst.Remove)

	local x, y, z = inst.Transform:GetWorldPosition()
	for i, v in ipairs(TheSim:FindEntities(x, 0, z, 6, DAMAGE_MUST_TAGS, DAMAGE_CANT_TAGS)) do
        if v:IsValid() and not (v.components.health~=nil and v.components.health:IsDead()) then
            local range = 4 + v:GetPhysicsRadius(0)
			if v:GetDistanceSqToPoint(x, 0, z) < range * range then
                v:AddDebuff("buff_slimed","buff_slimed",{duration = 15})
            end
        end
    end

end

local function dropfn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)


    inst.AnimState:SetBank("gelblob")
	inst.AnimState:SetBuild("gelblob")
    inst.AnimState:PlayAnimation("blob_idle_med", true)
	

    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("startfalling",startfalling)
    inst:ListenForEvent("stopfalling",DoAOE)

    inst.persists = false

    return  inst
end


return Prefab("gelblob_proj", fn, assets),
    Prefab("gelblob_slimed_fx",fxfn,assets),
    Prefab("gelblob_falling",dropfn,assets)
