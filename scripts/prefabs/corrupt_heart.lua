local assets =
{
    Asset("ANIM", "anim/shadowheart.zip"),
	Asset("ANIM", "anim/umbrella_voidcloth.zip"),
}
local brain=require("brains/corrupt_heartbrain")


local function DoSpawnChess(inst,type)
    local x,y,z=inst.Transform:GetWorldPosition()
    local angle = math.random() * PI2
    x = x + 6 * math.cos(angle)
    z = z - 6 * math.sin(angle)
    
    local chess = SpawnPrefab(type)
    chess.Transform:SetPosition(x, 0, z)
	inst.components.leader:AddFollower(chess)
	chess:PushEvent("levelup", { source = inst })
	chess.components.health:SetInvincible(true)
    --inst.components.commander:AddSoldier(chess)
end




local WAVE_FX_LEN = 0.5
local function WaveFxOnUpdate(inst, dt)
	inst.t = inst.t + dt

	if inst.t < WAVE_FX_LEN then
		local k = 1 - inst.t / WAVE_FX_LEN
		k = k * k
		inst.AnimState:SetMultColour(1, 1, 1, k)
		k = (2 - 1.7 * k) * (inst.scalemult or 1)
		inst.AnimState:SetScale(k, k)
	else
		inst:Remove()
	end
end

local function CreateWaveFX()
	local inst = CreateEntity()

	inst:AddTag("FX")
	--[[Non-networked entity]]
	inst.entity:SetCanSleep(false)
	inst.persists = false

	inst.entity:AddTransform()
	inst.entity:AddAnimState()

	inst.AnimState:SetBank("umbrella_voidcloth")
	inst.AnimState:SetBuild("umbrella_voidcloth")
	inst.AnimState:PlayAnimation("barrier_rim")
	inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)
	inst.AnimState:SetLayer(LAYER_BACKGROUND)
	inst.AnimState:SetSortOrder(3)

	inst:AddComponent("updatelooper")
	inst.components.updatelooper:AddOnUpdateFn(WaveFxOnUpdate)
	inst.t = 0
	inst.scalemult = .75
	WaveFxOnUpdate(inst, 0)

	return inst
end

local function CreateDomeFX()
	local inst = CreateEntity()

	inst:AddTag("FX")
	--[[Non-networked entity]]
	inst.entity:SetCanSleep(false)
	inst.persists = false

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()

	inst.AnimState:SetBank("umbrella_voidcloth")
	inst.AnimState:SetBuild("umbrella_voidcloth")
	inst.AnimState:PlayAnimation("barrier_dome")
	inst.AnimState:SetFinalOffset(7)

	inst:AddComponent("updatelooper")
	inst.components.updatelooper:AddOnUpdateFn(WaveFxOnUpdate)
	inst.t = 0
	WaveFxOnUpdate(inst, 0)

	inst.persists = false

	return inst
end


local function beat(inst)
    --inst.AnimState:PlayAnimation("idle")
    inst.SoundEmitter:PlaySound("dontstarve/sanity/shadow_heart")
    inst.beattask = inst:DoTaskInTime(.75 + math.random() * .75, beat)
end



local function start_the_battle(inst)
	inst:DoTaskInTime(2,function ()
	local x,y,z=inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 40, nil,nil,{"shadowchesspiece","lightsource"})
    for i, v in ipairs(ents) do
		if not (v:HasTag("structure") or v:HasTag("inventoryitem")) then
			v:Remove()
		end
    end
	DoSpawnChess(inst,"shadow_rook")
	DoSpawnChess(inst,"shadow_knight")
	DoSpawnChess(inst,"shadow_bishop")
	end)
end



local function dont_leave(inst)
	local x,y,z=inst.Transform:GetWorldPosition()
	local players=FindPlayersInRange(x,y,z,40,true)
	for i,v in ipairs(players) do
		if not inst:IsNear(v, 24) then
			v:AddDebuff("mindcontroller", "mindcontroller");
		end
	end
end

local function retargetfn(inst)
	local target
    local x, y, z = inst.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x, y, z, 24, true)
    local rangesq = 100
    for i, v in ipairs(players) do
        local distsq = v:GetDistanceSqToPoint(x, y, z)
        if distsq < rangesq and inst.components.combat:CanTarget(v) then
            rangesq = distsq
            target = v
        end
    end
    return target, true
end

local function DoShoot(inst,pos)
	inst.components.combat:StartAttack()
	local x, y, z = inst.Transform:GetWorldPosition()

	local dir
	if pos ~= nil then
		inst:ForceFacePoint(pos)
		dir = inst.Transform:GetRotation() * DEGREES
	end

	--local targets = {} --shared table for the whole patch of particles
	--local sfx = {} --shared table so we only play sfx once for the whole batch
	local proj = SpawnPrefab("shadowthrall_projectile_fx")
	proj.Physics:Teleport(x, y, z)
	proj.components.complexprojectile:Launch(pos, inst)

	dir = dir + PI
	local pos1 = Vector3(0, 0, 0)
	for i = 0, 5 do
		local theta = dir + TWOPI / 5 * i
		pos1.x = pos.x + 2 * math.cos(theta)
		pos1.z = pos.z - 2 * math.sin(theta)
		local proj = SpawnPrefab("shadowthrall_projectile_fx")
		proj.Physics:Teleport(x, y, z)
		proj.components.complexprojectile:Launch(pos1, inst)
	end
end

local function do_corrupt(inst,data)
	if data.target~=nil and data.stimuli=="shadow" then
		data.target:AddDebuff("exhaustion","exhaustion",{duration=10})
		data.target:AddDebuff("weak","weak",{duration=60,speed=0.7})
		data.target:AddDebuff("vulnerable","vulnerable",{duration=30})
	end
end


local function CLIENT_TriggerFX(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	CreateWaveFX().Transform:SetPosition(x, 0, z)
	local fx = CreateDomeFX()
	fx.Transform:SetPosition(x, 0, z)
	fx.SoundEmitter:PlaySound("meta2/voidcloth_umbrella/barrier_activate")
end

local function SERVER_TriggerFX(inst)
	inst.triggerfx:push()
	if not TheNet:IsDedicated() then
		CLIENT_TriggerFX(inst)
	end
end

local function do_echo(inst)
	SERVER_TriggerFX(inst)
end

local function OnAttacked(inst)
    if inst.components.health:GetPercent() <0.3 and not inst.atphase2 then
        inst.atphase2 = true
		for k,v in pairs(inst.components.leader.followers) do
			k:PushEvent("levelup", { source = inst })
		end
    end
end

local function World_reset(inst)
	TheWorld:PushEvent("overrideambientlighting", nil)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
	inst.entity:AddLight()

    MakeObstaclePhysics(inst, 1)
    inst.Transform:SetScale(5,5,5)

    inst.AnimState:SetBank("shadowheart")
    inst.AnimState:SetBuild("shadowheart")
    inst.AnimState:PlayAnimation("idle")
    --inst.AnimState:SetMultColour(1, 1, 1, 0.5)

	inst.Light:SetRadius(20)
    inst.Light:SetIntensity(0.9)
    inst.Light:SetFalloff(0.8)
    inst.Light:SetColour(1, 1, 1)
    inst.Light:Enable(true)
	inst.Light:EnableClientModulation(true)
	
	inst.triggerfx = net_event(inst.GUID, "voidcloth_umbrella.triggerfx")

    inst:AddTag("epic")
    inst:AddTag("hostile")
    inst:AddTag("notraptrigger")
    inst:AddTag("shadow_aligned")
    inst:AddTag("shadowheart")


	inst:ListenForEvent("death",World_reset)
	TheWorld:PushEvent("overrideambientlighting", Point(0, 0, 0))
	
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
		inst:DoTaskInTime(0, inst.ListenForEvent, "voidcloth_umbrella.triggerfx", CLIENT_TriggerFX)
        return inst
    end

    inst.level = 5

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(9999)
	inst.components.health:SetMaxDamageTakenPerHit(150)

    inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(100)
	inst.components.combat:SetRetargetFunction(3, retargetfn)
	inst.components.combat:SetAttackPeriod(6)
	inst.components.combat.ignorehitrange=true

	inst:AddComponent("timer")

	

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot({"shadowheart","armor_sanity","armor_sanity"})

	inst:AddComponent("leader")

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_HUGE

    inst.beattask = inst:DoTaskInTime(.75 + math.random() * .75, beat)    

    --inst.beattask2 = inst:DoTaskInTime(1, beat2)
	inst.DoEcho=do_echo

	inst:ListenForEvent("summon",start_the_battle)
	--inst:ListenForEvent("doattack",ChooseAttack)

	inst:ListenForEvent("onhitother",do_corrupt)
	inst:ListenForEvent("attacked", OnAttacked)


	inst:DoPeriodicTask(0.3,dont_leave)
	inst:SetBrain(brain)
	inst:SetStateGraph("SGcorrupt_heart")
	

    return inst
end


return Prefab("corrupt_heart", fn, assets)