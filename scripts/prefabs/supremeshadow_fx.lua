local echo_assets =
{
	Asset("ANIM",  "anim/roar_fx.zip")
}

local function  echofn()
	local inst = CreateEntity()

	inst:AddTag("FX")
	

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddNetwork()

	inst.AnimState:SetBank("roar_fx")
	inst.AnimState:SetBuild("roar_fx")
	inst.AnimState:PlayAnimation("scream")


	--inst.AnimState:SetFinalOffset(3)
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst.persists = false
    inst:ListenForEvent("animover",inst.Remove)

	return inst
end


------------------------------------------------------------
local shadowfireball_assets = {
	Asset("ANIM", "anim/lavaarena_firestaff_meteor.zip"),
	Asset("ANIM", "anim/lavaarena_fire_fx.zip"),
}

local VOLCANO_FIRERAIN_WARNING = 2
local SMASHABLE_WORK_ACTIONS =
{
    CHOP = true,
    DIG = true,
    HAMMER = true,
    MINE = true,
}
local SMASHABLE_TAGS = { "_combat", "_inventoryitem", "NPC_workable" }
for k, v in pairs(SMASHABLE_WORK_ACTIONS) do
    table.insert(SMASHABLE_TAGS, k.."_workable")
end

local NON_SMASHABLE_TAGS = { "INLIMBO", "playerghost", "shadow","FX","deity","shadowcreature","shadowthrall","abysscreature" }

local function DoAOEAttack(inst)
    inst.SoundEmitter:PlaySound("dontstarve/impacts/lava_arena/meteor_strike")
	
    local x, y, z = inst.Transform:GetWorldPosition()

	
	SpawnPrefab("firemeteor_splash_fx2").Transform:SetPosition(x,0,z)

	local hitradius = 4.5
	local ents = TheSim:FindEntities(x, y, z, hitradius + 3, nil, NON_SMASHABLE_TAGS, SMASHABLE_TAGS)
	for i, v in ipairs(ents) do

		if v:IsValid() and not (v.components.health ~= nil and v.components.health:IsDead()) then
			local range = hitradius + v:GetPhysicsRadius(.5)
            local dsq_to_laser = v:GetDistanceSqToPoint(x, y, z)
            if dsq_to_laser < range * range then
				local isworkable = false
					if v.components.workable ~= nil then
						local work_action = v.components.workable:GetWorkAction()
						--V2C: nil action for NPC_workable (e.g. campfires)
						isworkable =
							(   work_action == nil and v:HasTag("NPC_workable") ) or
							(   v.components.workable:CanBeWorked() and
								(   work_action == ACTIONS.CHOP or
									work_action == ACTIONS.HAMMER or
									work_action == ACTIONS.MINE or
									(   work_action == ACTIONS.DIG and
										v.components.spawner == nil and
										v.components.childspawner == nil
									)
								)
							)
					end
				if isworkable then
					v.components.workable:Destroy(inst)

					-- Completely uproot trees.
					if v:HasTag("stump") then
						v:Remove()
					end
				elseif inst.components.combat:CanTarget(v) then
					v.components.combat:GetAttacked(inst, 100, nil, nil,{["planar"] = 30})
					if  v.isplayer then
						v:AddDebuff("buff_cursefire","buff_cursefire")
					end
				end
			end		
        end
	end
	inst:Remove()
end

local function OnImpact(inst)
	inst.AnimState:PushAnimation("crash_pst",false)
	inst:RemoveEventCallback("animover",OnImpact)
	inst:DoTaskInTime(3*FRAMES, DoAOEAttack)
end

local function DoFall(inst)
	inst:DoTaskInTime(0.5,function ()
		inst.AnimState:PlayAnimation("crash")
		inst:Show()
	end)
end


local function meteorfn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddNetwork()


    inst.AnimState:SetBank("lavaarena_firestaff_meteor")
	inst.AnimState:SetBuild("lavaarena_firestaff_meteor")
	--inst.AnimState:PlayAnimation("crash")
	inst.AnimState:SetSymbolAddColour("starbase",160/255,32/255,240/255,1)
	inst.AnimState:SetSymbolMultColour("base",0,0,0,1)
	inst.AnimState:SetSymbolMultColour("trail",0,0,0,1)
	inst.AnimState:SetSymbolLightOverride("starbase", 0.5)
	inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

	inst:AddTag("FX")

	--inst.triggerfx = net_event(inst.GUID,"fireball.pingfx")
	if not TheNet:IsDedicated() then
		inst.pingfx = SpawnPrefab("reticuleaoe")
		inst.pingfx.AnimState:SetMultColour( .5, 0, 0, 1 )
		inst:DoTaskInTime(0,function ()
			inst.pingfx.Transform:SetPosition(inst.Transform:GetWorldPosition())
			inst.pingfx:DoTaskInTime(2,inst.pingfx.Remove)
		end)
	end


	inst.entity:SetPristine()
	------------------------------------------
	if not TheWorld.ismastersim then
        return inst
    end

	inst.persists = false

	inst:AddComponent("combat")

	inst:Hide()
	inst:ListenForEvent("animover", OnImpact)

	inst:DoTaskInTime(0,DoFall)
	return inst
end


return Prefab("shadowecho_fx",echofn,echo_assets),
	Prefab("shadowfireball",meteorfn,shadowfireball_assets)