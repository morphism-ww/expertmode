local assets =
{
    Asset("ANIM", "anim/shadowheart.zip"),
}

local brain = require("brains/corrupt_heartbrain")

local prefabs = {
	"shadow_bishop",
	"shadow_rook",
	"shadow_knight",
	"nightmarefuel",
	"armor_sanity",
	"nightsword",
	"darkball_projectile",
	"sanity_lower",
	"shadow_trap",
	"shadowecho_fx"
}

local PHASES = {
	{
		hp = 0.6,
		fn = function(inst)

            for k,v in pairs(inst.components.leader.followers) do
				k.shouldprotect = k.prefab~="shadow_knight"
			end
		end,
	},
	{
		hp = 0.3,
		fn = function(inst)

            for k,v in pairs(inst.components.leader.followers) do
				k.shouldprotect = k.prefab~="shadow_bishop"
			end
		end,
	},
}

local function DoSpawnChess(inst,type,stopbrain)
    local x,y,z=inst.Transform:GetWorldPosition()
    local angle = math.random() * PI2
    x = x + 6 * math.cos(angle)
    z = z - 6 * math.sin(angle)
    
    local chess = SpawnPrefab(type)
    chess.Transform:SetPosition(x, 0, z)
	inst.components.leader:AddFollower(chess)
	
	chess:PushEvent("levelup", { source = inst })
	--[[if stopbrain then
		chess:DoTaskInTime(2,chess.StopBrain)
	end]]
	chess.shouldprotect = stopbrain
	
	return chess
    --inst.components.commander:AddSoldier(chess)
end




local function beat(inst)
    inst.AnimState:PlayAnimation("idle")
    inst.SoundEmitter:PlaySound("dontstarve/sanity/shadow_heart")
    inst.beattask = inst:DoTaskInTime(.75 + math.random() * .75, beat)
end

local function DoPowerUp(inst)
	inst.components.health:SetMaxHealth(inst.power*3000+TUNING.CORRUPT_HEART_HEALTH)
	inst.components.combat:SetAttackPeriod(6-0.5*inst.power)
	inst.echodamage = 40 + 20*inst.power

end

local function startbattle(inst)
	
	local x,y,z=inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 40, {"shadowchesspiece"})
	inst.power = math.min(math.floor(0.5*#ents + 0.5),4)
    for i, v in ipairs(ents) do
		if v:IsValid() then
			SpawnPrefab("shadow_despawn").Transform:SetPosition(v.Transform:GetWorldPosition())
			v:Remove()
		end
    end
	if inst.power>1 then
		DoPowerUp(inst)
	end
	
	inst:DoSpawnChess("shadow_rook")
	inst:DoSpawnChess("shadow_knight",true)
	inst:DoSpawnChess("shadow_bishop",true)
	
end


local function retargetfn(inst)
	local target
    local x, y, z = inst.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x, y, z, 36, true)
    local rangesq = math.huge
    for i, v in ipairs(players) do
        local distsq = v:GetDistanceSqToPoint(x, y, z)
        if distsq < rangesq and inst.components.combat:CanTarget(v) then
            rangesq = distsq
            target = v
        end
    end
    return target, true
end



local function do_echo(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
    
    local players = FindPlayersInRangeSq(x, y, z, TUNING.CORRUPT_HEART_RANGESQ, true)
	for i, v in ipairs(players) do
		if v.components.combat:GetAttacked(inst,inst.echodamage) then
			v:AddDebuff("exhaustion","exhaustion",{duration = 10})
			v:AddDebuff("vulnerable","vulnerable")
		end
	end
end

local function dont_leave(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	local players = FindPlayersInRange(x,y,z,50,true)
	for i,v in ipairs(players) do
		if v:IsValid() and not v:IsNear(inst, 26) then
			local px,py,pz = v.Transform:GetWorldPosition()
			SpawnPrefab("stalker_shield").Transform:SetPosition(1.02*(px-x)+x,0,1.02*(pz-z)+z)
			--v.Physics:Teleport(x,y,z)
		end
	end
	local ents = TheSim:FindEntities(x, y, z, 60, {"lightsource"},{"player","blocker","shadowheart"})
	for k,v in ipairs(ents) do
		if v:HasTag("starlight") then
			v.components.hauntable:DoHaunt(inst)
		else
			v:ForceDarkness(inst)
		end		
	end
	if inst.components.leader.numfollowers == 0 then
		inst:StartBattle()
	end
end

local function StartField(inst)
	--TheWorld:ForceDarkWorld(true)
	--inst.reset_light:set(true)
	TheWorld:PushEvent("ms_setclocksegs", {day = 0, dusk = 0, night = 16})
	TheWorld:PushEvent("ms_setmoonphase", {moonphase = "new", iswaxing = false})
	TheWorld:PushEvent("ms_lockmoonphase", {lock = true})
	inst.fieldtask = inst:DoPeriodicTask(8*FRAMES, dont_leave)
end


local function KillField(inst)
	--inst.reset_light:set(false)
	--TheWorld:PushEvent("ms_setclocksegs", {day = 0, dusk = 0, night = 16})
	TheWorld:PushEvent("ms_setmoonphase", {moonphase = "full", iswaxing = false})
	TheWorld:PushEvent("ms_lockmoonphase", {lock = false})
	--TheWorld:ForceDarkWorld(false)
	if inst.fieldtask~=nil then
		inst.fieldtask:Cancel()
	end
end

local function TryForceDark(inst)
	if not inst.components.health:IsDead() then
		TheWorld:PushEvent("ms_setclocksegs", {day = 0, dusk = 0, night = 16})
	end		
	
end


local function OnLoadPostPass(inst)
	if not inst.components.health:IsDead() then
        local healthpct = inst.components.health:GetPercent()
	        for i = #PHASES, 1, -1 do
		    local v = PHASES[i]
		    if healthpct <= v.hp then
			    v.fn(inst)
			    break
		    end
	    end
    end
end


local function KillFollower(inst,chess)
	chess.persists = false
	chess.components.health:SetVal(0)
end

local function OnSave(inst,data)
	data.power = inst.power
end

local function OnLoad(inst,data)
	if data~=nil then
		inst.power = data.power or 1
		if inst.power>1 then
			DoPowerUp(inst)
		end
	end
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
	

    MakeObstaclePhysics(inst, 2)
    --inst.Transform:SetScale(5,5,5)

    inst.AnimState:SetBank("shadowheart")
    inst.AnimState:SetBuild("shadowheart")
    inst.AnimState:PlayAnimation("idle")
	inst.AnimState:SetScale(5,5,5)
    inst.AnimState:SetMultColour(1, 1, 1, 0.5)

	
	
	inst.reset_light = net_bool(inst.GUID, "corruptheart.reset_light","corruptheart_darkdirty")

    inst:AddTag("epic")
	inst:AddTag("nosinglefight_l")
    inst:AddTag("hostile")
    inst:AddTag("notraptrigger")
    inst:AddTag("shadow_aligned")
    inst:AddTag("shadowheart")
	inst:AddTag("lightcontroller")
	inst:AddTag("ignorewalkableplatformdrowning")
	
	inst.entity:AddLight()
	inst.Light:SetRadius(22)
    inst.Light:SetIntensity(0.9)
    inst.Light:SetFalloff(0.9)
    inst.Light:SetColour(1, 1, 1)
    inst.Light:Enable(true)
	inst.Light:EnableClientModulation(true)
	
	
	
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
		--inst:DoTaskInTime(0, inst.ListenForEvent, "corruptheart_darkdirty", World_reset)
        return inst
    end

    inst.level = 4
	inst.power = 1

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.CORRUPT_HEART_HEALTH)
	

    inst:AddComponent("combat")
	inst.components.combat:SetDefaultDamage(75)
	inst.components.combat:SetRetargetFunction(3, retargetfn)
	inst.components.combat:SetAttackPeriod(6)
	inst.components.combat:SetRange(TUNING.CORRUPT_HEART_ATTACKRANGE)
	--inst.components.combat.ignorehitrange = true

	inst.echodamage = 40

	inst:AddComponent("timer")

	inst:AddComponent("drownable")

	local loots = {}
	for i = 1,10 do
		table.insert(loots,"armor_sanity")
		table.insert(loots,"nightsword")
	end
    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(loots)

	inst:AddComponent("leader")
	inst.components.leader.onremovefollower = KillFollower

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_LARGE

	inst:AddComponent("resistance")
	inst.components.resistance:AddResistance("shadowchesspiece")

    inst.beattask = inst:DoTaskInTime(.75 + math.random() * .75, beat)    

    --inst.beattask2 = inst:DoTaskInTime(1, beat2)
	inst.OnLoadPostPass = OnLoadPostPass
	inst.DoEcho = do_echo
	inst.DoSpawnChess = DoSpawnChess
	inst.StartBattle = startbattle
	

	inst:AddComponent("healthtrigger")
    for i, v in pairs(PHASES) do
		inst.components.healthtrigger:AddTrigger(v.hp, v.fn)
	end

	
	inst:SetBrain(brain)
	inst:SetStateGraph("SGcorrupt_heart")

	inst:WatchWorldState("isalterawake", function (inst)
		KillField(inst)
		inst:Remove()
	end)
	inst:WatchWorldState("cycles", TryForceDark)
	inst:ListenForEvent("death",KillField)
	--inst:ListenForEvent("attacked", OnAttacked)
	inst.components.timer:StartTimer("echo_cd",20)

	inst:DoTaskInTime(0,StartField)

	inst.OnSave = OnSave
	inst.OnLoad = OnLoad

    return inst
end


return Prefab("corrupt_heart", fn, assets, prefabs)