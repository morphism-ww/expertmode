local assets =
{
    Asset("ANIM", "anim/sand_spike.zip"),
}

local SPIKE_SIZES =
{
    "short",
    "med",
    "tall",
}

local RADIUS =
{
    ["short"] = .12*2,
    ["med"] = .25*2,
    ["tall"] = .3*2,
}

local NUM_VARIATIONS = 7
local DAMAGE_RADIUS_PADDING = 1

local function ChangeToObstacle(inst)
    inst:RemoveEventCallback("animover", ChangeToObstacle)
    local x, y, z = inst.Transform:GetWorldPosition()
    inst.Physics:Stop()
    inst.Physics:SetMass(0)
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.ITEMS)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:Teleport(x, 0, z)
end

local COLLAPSIBLE_WORK_ACTIONS =
{
    CHOP = true,
    DIG = true,
    HAMMER = true,
    MINE = true,
}
local COLLAPSIBLE_TAGS = { "_combat", "pickable", "NPC_workable" }
for k, v in pairs(COLLAPSIBLE_WORK_ACTIONS) do
    table.insert(COLLAPSIBLE_TAGS, k.."_workable")
end
local NON_COLLAPSIBLE_TAGS = { "stalker", "flying", "shadow", "deity", "playerghost", "FX", "NOCLICK", "DECOR", "INLIMBO" }

local function DoDamage(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, 0, z, inst.spikeradius + DAMAGE_RADIUS_PADDING, nil, NON_COLLAPSIBLE_TAGS, COLLAPSIBLE_TAGS)
    for i, v in ipairs(ents) do
        if v:IsValid() then
            local isworkable = false
            if v.components.workable ~= nil then
                local work_action = v.components.workable:GetWorkAction()
                --V2C: nil action for NPC_workable (e.g. campfires)
                --     allow digging spawners (e.g. rabbithole)
                isworkable = (
                    (work_action == nil and v:HasTag("NPC_workable")) or
                    (v.components.workable:CanBeWorked() and work_action ~= nil and COLLAPSIBLE_WORK_ACTIONS[work_action.id])
                )
            end
            if isworkable then
                v.components.workable:Destroy(inst)
                if v:IsValid() and v:HasTag("stump") then
                    v:Remove()
                end
            elseif v.components.pickable ~= nil
                and v.components.pickable:CanBePicked()
                and not v:HasTag("intense") then
				v.components.pickable:Pick(inst)
            elseif v.components.combat ~= nil
                and v.components.health ~= nil
                and not v.components.health:IsDead() then
                if inst.components.combat:IsValidTarget(v) then
                    inst.components.combat:DoAttack(v)
                end
            end
        end
    end
end
local function OnKill2(inst)
    inst:AddTag("NOCLICK")
    inst.Physics:SetActive(false)
    ErodeAway(inst, 1)
end


local function OnKill(inst)
    SpawnPrefab("shadow_despawn").Transform:SetPosition(inst.Transform:GetWorldPosition())
    inst:DoTaskInTime(.5, OnKill2)
end

local function KillSpike(inst)
    if not inst.killed then
        
        inst.killed = true

        if inst.task ~= nil then
            inst.task:Cancel()
            inst.task = nil
        end

        inst:RemoveEventCallback("animover", ChangeToObstacle)


        inst:DoTaskInTime(1, OnKill)

    end
end



local function StartSpike(inst, duration, variation)
    inst.task = inst:DoTaskInTime(duration, KillSpike)



    inst:ListenForEvent("animover", ChangeToObstacle)
    inst.AnimState:PlayAnimation(inst.animname.."_pst")
    inst.AnimState:PushAnimation(inst.animname.."_transform",false)

    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/fossil_spike")

    DoDamage(inst)
end


local function MakeSpikeFn(size)
    local shape = "spike"
    return function()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddPhysics()
        inst.entity:AddNetwork()


        inst.spikesize = size
        inst.animname = inst.spikesize

        inst:SetPrefabNameOverride("dark_spike")

        inst.spikeradius = RADIUS[inst.animname]

        inst.AnimState:SetBank("sand_"..shape)
        inst.AnimState:SetBuild("sand_"..shape)
        inst.AnimState:PlayAnimation(inst.animname.."_pre")
        --inst.AnimState:PlayAnimation(inst.animname.."_glass_idle")
        inst.AnimState:SetMultColour(0,0,0,0.5)

        inst:AddTag("notarget")
        inst:AddTag("groundspike")
        inst:AddTag("fossilspike")

        inst.Physics:SetMass(99999)
        inst.Physics:SetCollisionGroup(COLLISION.SMALLOBSTACLES)
        inst.Physics:ClearCollisionMask()
        inst.Physics:CollidesWith(COLLISION.ITEMS)
        inst.Physics:CollidesWith(COLLISION.CHARACTERS)
        inst.Physics:CollidesWith(COLLISION.WORLD)
        inst.Physics:SetCapsule(inst.spikeradius, 2)

        inst.AnimState:SetScale(1.5,1.5,1.5)

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end


        inst:AddComponent("combat")
        inst.components.combat:SetDefaultDamage(100)
        --inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
        inst:AddComponent("planardamage")
		inst.components.planardamage:SetBaseDamage(35)

        inst.persists = false

        inst.task = inst:DoTaskInTime(0, StartSpike, 10 + 5*math.random())
        inst.KillSpike = KillSpike


        return inst
    end
end

--For searching: glassspike_short, glassspike_med, glassspike_tall

local ret = {}
for i, v in ipairs(SPIKE_SIZES) do
    local name = "darkspike_"..v

    table.insert(ret, Prefab(name, MakeSpikeFn(v), assets))
end

local function RandomFn()
    local inst = MakeSpikeFn(SPIKE_SIZES[math.random(1,3)])()

	return inst
end

return unpack(ret),Prefab("dark_spike", RandomFn, assets)
