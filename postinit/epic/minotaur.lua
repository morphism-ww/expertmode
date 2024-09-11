require "behaviours/chaseandram"
local function shadowremains(inst)
    local pct=inst.components.health:GetPercent()
    if  pct< 0.3 and not inst.atphase3 then
        inst.atphase3 = true
    end
    if pct<0.6 and inst.shadow==nil then
        inst.shadow = SpawnPrefab("leechterror")
        inst.shadow:SetHost(inst,"innerds")
    end
end

local DESTROYSTUFF_IGNORE_TAGS = { "INLIMBO", "mushroomsprout", "NET_workable" }
local BOUNCESTUFF_MUST_TAGS = { "_inventoryitem" }
local BOUNCESTUFF_CANT_TAGS = { "locomotor", "INLIMBO" }

local function ClearRecentlyBounced(inst, other)
    inst.sg.mem.recentlybounced[other] = nil
end

local function SmallLaunch(inst, launcher, basespeed)
    local hp = inst:GetPosition()
    local pt = launcher:GetPosition()
    local vel = (hp - pt):GetNormalized()
    local speed = basespeed * 2 + math.random() * 2
    local angle = math.atan2(vel.z, vel.x) + (math.random() * 20 - 10) * DEGREES
    inst.Physics:Teleport(hp.x, .1, hp.z)
    inst.Physics:SetVel(math.cos(angle) * speed, 1.5 * speed + math.random(), math.sin(angle) * speed)

    launcher.sg.mem.recentlybounced[inst] = true
    launcher:DoTaskInTime(.6, ClearRecentlyBounced, inst)
end

local function BounceStuff(inst)
    if inst.sg.mem.recentlybounced == nil then
        inst.sg.mem.recentlybounced = {}
    end
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 6, BOUNCESTUFF_MUST_TAGS, BOUNCESTUFF_CANT_TAGS)
    for i, v in ipairs(ents) do
        if v:IsValid() and not (v.components.inventoryitem.nobounce or inst.sg.mem.recentlybounced[v]) and v.Physics ~= nil and v.Physics:IsActive() then
            local distsq = v:GetDistanceSqToPoint(x, y, z)
            local intensity = math.clamp((36 - distsq) / 27, 0, 1)
            SmallLaunch(v, inst, intensity)
        end
    end
end


local function TryShadowFire(inst, doer,pos)
    local startangle
    if pos~=nil then
        startangle = inst:GetAngleToPoint(pos.x,pos.y,pos.z)*DEGREES
    else
        startangle=0
    end
    local burst=5
    --[[local pct=doer.components.health:GetPercent()
    if pct<0.1 then
        burst=8
    elseif pct<0.2 then
        burst=6
    end]]
    for i=1,burst do
        local radius = 2
        local theta = startangle + (PI*2/burst*i) - (PI*2/burst)
        local offset = Vector3(radius * math.cos( theta ), 0, -radius * math.sin( theta ))

        local newpos = Vector3(inst.Transform:GetWorldPosition()) + offset
        local fire = SpawnPrefab("shadow_flame")
        fire.Transform:SetRotation(theta/DEGREES)
        fire.Transform:SetPosition(newpos.x,newpos.y,newpos.z)
        fire:settarget(nil,30,doer)
    end
end


local function OnHitOther(inst, data)
	if data.target ~= nil and inst.sg:HasStateTag("runningattack") then
        data.target:PushEvent("knockback", { knocker = inst, radius = 1, strengthmult = 2})
    end

end


AddPrefabPostInit("minotaur",function(inst)

    if not TheWorld.ismastersim then return end
    inst.components.freezable:SetResistance(8)
    inst.components.sleeper:SetResistance(12)

    inst.components.combat:SetAreaDamage(4, 0.8)

    inst:DoTaskInTime(0, shadowremains)
    inst:ListenForEvent("attacked", shadowremains)
    inst:ListenForEvent("onhitother",OnHitOther)
end)

AddStategraphState("minotaur",
State{
        name = "stun2",
        tags = {"busy","stunned"},

        onenter = function(inst,data)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("stun_jump_pre")
            inst.sg.statemem.leapattack=data.doleap
        end,

        timeline=
        {
            TimeEvent(12*FRAMES, function(inst)
            local target=inst.components.combat.target
            if target~=nil and inst.sg.statemem.leapattack then
                inst.sg.mem.leapcount=math.random(3,5)
                inst.sg:GoToState("leap_attackloop_pre",target)
            end
        end),
        },

        events=
        {
            EventHandler("animover", function(inst)

                inst.components.timer:StartTimer("endstun", TUNING.MINOTAUR_STUNTIME)
                inst:StopBrain()
                inst.sg:GoToState("shadowfire_loop")
            end),
        },
    })
AddStategraphState("minotaur",
    State{
        name = "shadowfire_loop",
        tags = {"busy","stunned"},

        onenter = function(inst, data)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("stun_hit",true)
            local target = inst.components.combat.target
            if target~=nil then
                inst.sg.statemem.targetpos = Vector3(target.Transform:GetWorldPosition())
            end
            inst.sg:SetTimeout(12)
        end,

        timeline=
        {
            TimeEvent(12*FRAMES, function(inst)
                TryShadowFire(inst,inst,inst.sg.statemem.targetpos)
            end)
        },
        ontimeout=function(inst)
            inst.sg:GoToState("shadowfire_loop")
        end
    })
AddStategraphState("minotaur",
    State{
        name = "leap_attackloop_pre",
        tags = {"attack", "busy","leapattack"},

        onenter = function(inst,target)
            inst.hasrammed = true
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("jump_atk_pre")
            inst.sg.statemem.startpos = inst:GetPosition()
            inst:DoTaskInTime(0.4,function()
                if inst:IsValid() and not inst.components.health:IsDead() and inst.sg and inst.sg:HasStateTag("leapattack") then
                    if target~=nil and target:IsValid() then
                        inst.sg.statemem.targetpos = target:GetPosition()
                        inst:ForceFacePoint(inst.sg.statemem.targetpos)
                    else
                        local range = 6 -- overshoot range
                        local theta = inst.Transform:GetRotation()*DEGREES
                        local offset = Vector3(range * math.cos( theta ), 0, -range * math.sin( theta ))
                        inst.sg.statemem.targetpos = Vector3(inst.sg.statemem.startpos.x + offset.x, 0, inst.sg.statemem.startpos.z + offset.z)
                    end
                end
            end)
            inst.sg:SetTimeout(0.8)
        end,
        ontimeout = function(inst)
            inst.sg:GoToState("leap_attackloop", inst.sg.statemem.targetpos)
        end    
    })
AddStategraphState("minotaur",
        State{
        name = "leap_attackloop",
        tags = {"attack", "busy", "leapattack"},

        onenter = function(inst,pos)

            inst.sg.statemem.targetpos =pos
            inst.AnimState:PlayAnimation("jump_atk_loop")
            inst.components.locomotor:Stop()

            inst.sg.statemem.startpos = inst:GetPosition()

            inst.components.combat:StartAttack()

            inst:ForceFacePoint(inst.sg.statemem.targetpos)

            local range = 2
            local theta = inst.Transform:GetRotation()*DEGREES
            local offset = Vector3(range * math.cos( theta ), 0, -range * math.sin( theta ))
            local newloc = Vector3(inst.sg.statemem.targetpos.x + offset.x, 0, inst.sg.statemem.targetpos.z + offset.z)

            local time = inst.AnimState:GetCurrentAnimationLength()
            local dist = math.sqrt(distsq(inst.sg.statemem.startpos.x, inst.sg.statemem.startpos.z, newloc.x, newloc.z))
            local vel = dist/time

            inst.sg.statemem.vel = vel

            inst.components.locomotor:EnableGroundSpeedMultiplier(false)
            inst.Physics:SetMotorVelOverride(vel,0,0)

            inst.Physics:ClearCollisionMask()
            inst.Physics:CollidesWith(COLLISION.WORLD)
        end,

		timeline =
		{
			FrameEvent(8, function(inst) inst.SoundEmitter:PlaySound("ancientguardian_rework/minotaur2/groundpound") end),
			FrameEvent(14, function(inst)
				inst.components.groundpounder:GroundPound()
				BounceStuff(inst)
			end),
		},

        onexit = function(inst)
            inst.Physics:ClearMotorVelOverride()

            inst.components.locomotor:Stop()
            inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            inst.sg.statemem.startpos = nil
            inst.sg.statemem.targetpos = nil

			inst:OnChangeToObstacle()
        end,

        events=
        {
            EventHandler("animover", function(inst)
                if inst.sg.mem.leapcount~=nil and inst.sg.mem.leapcount>0 and inst.components.combat:HasTarget() then
                    inst.sg.mem.leapcount=inst.sg.mem.leapcount-1
                    inst.sg:GoToState("leap_attackloop_pre",inst.components.combat.target)
                else
                    inst.sg:GoToState("stun2",{doleap=false})
                end
            end )
        },
    }
)
AddStategraphPostInit("minotaur",function(sg)
    sg.events["collision_stun"].fn=function(inst,data)
        if data.light_stun == true then
            inst.sg:GoToState("hit")
        elseif inst.atphase3 then
            inst.sg:GoToState("stun2",{doleap=true})
        elseif data.land_stun == true then
            inst.sg:GoToState("stun",{land_stun=true})
        else
            inst.sg:GoToState("stun")
        end
    end

    sg.states.leap_attack.events["animover"].fn=function(inst)
        if inst.atphase3 then
            inst.sg:GoToState("stun2",{doleap=true})
        elseif inst:jumpland() then
            inst.sg:GoToState("leap_attack_pst")
        else
            inst.sg:GoToState("stun",{land_stun=true})
        end
    end
    sg.states.death.onenter = function(inst)
        inst.components.locomotor:StopMoving()
        inst.AnimState:PlayAnimation("death")
        
        if inst.persists then
            local chest = SpawnPrefab("minotaurchestspawner")
            chest.Transform:SetPosition(inst.Transform:GetWorldPosition())
            for i = 1, 8 do
                if chest:PutBackOnGround(TILE_SCALE * i) then
                    break
                end
            end
            chest.minotaur = inst
            inst.components.lootdropper:DropLoot()
        end
        inst.persists = false
        inst:AddTag("NOCLICK")
    end
end)


--[[local chest_loot =
{
    {item = {"armorruins"}, count = 1},
    {item = {"ruinshat"}, count = 1},
    {item = {"ruins_bat"}, count = 1},
    {item = {"orangestaff","yellowstaff"}, count = 1},
    {item = {"orangeamulet", "yellowamulet"}, count = 1},
    {item = {"yellowgem"}, count = {6, 8}},
    {item = {"orangegem"}, count = {6, 8}},
    {item = {"greengem"}, count = {6, 8}},
    {item = {"thulecite"}, count = { 16,20 }},
    {item = {"thulecite_pieces"}, count = {30, 38 }},
    {item = {"yellowstaff"}, count = 1},
}]]

local chest_loot =
{
    {item = {"armorruins", "ruinshat", "ruins_bat"}, count = 1},
    {item = {"orangestaff", "yellowstaff"}, count = 1},
    {item = {"orangeamulet", "yellowamulet"}, count = 1},
    {item = {"yellowgem"}, count = {2, 4}},
    {item = {"orangegem"}, count = {2, 4}},
    {item = {"greengem"}, count = {2, 3}},
    {item = {"thulecite"}, count = {8, 14}},
    {item = {"thulecite_pieces"}, count = {12, 36}},
    {item = {"gears"}, count = {3, 6}},
    {item = {"maze_key"}, count = {7, 10}},
}


local function dospawnchest(inst, loading)
    local chest = SpawnPrefab("minotaurchest")
    local x, y, z = inst.Transform:GetWorldPosition()
    chest.Transform:SetPosition(x, 0, z)

    --Set up chest loot
    chest.components.container:GiveItem(SpawnPrefab("atrium_key"))

    local loot_keys = {}
    for i, _ in ipairs(chest_loot) do
        table.insert(loot_keys, i)
    end
	local max_loots = math.min(#chest_loot, chest.components.container.numslots - 1)
    --loot_keys = PickSome(math.random(max_loots - 2, max_loots), loot_keys)

    for _, i in ipairs(loot_keys) do
        local loot = chest_loot[i]
        local item = SpawnPrefab(loot.item[math.random(#loot.item)])
        if item ~= nil then
            if type(loot.count) == "table" and item.components.stackable ~= nil then
                item.components.stackable:SetStackSize(math.random(loot.count[1], loot.count[2]))
            end
            chest.components.container:GiveItem(item)
        end
    end
    --

    if not chest:IsAsleep() then
        chest.SoundEmitter:PlaySound("dontstarve/common/ghost_spawn")

        local fx = SpawnPrefab("statue_transition_2")
        if fx ~= nil then
            fx.Transform:SetPosition(x, y, z)
            fx.Transform:SetScale(1, 2, 1)
        end

        fx = SpawnPrefab("statue_transition")
        if fx ~= nil then
            fx.Transform:SetPosition(x, y, z)
            fx.Transform:SetScale(1, 1.5, 1)
        end
    end

    if inst.minotaur ~= nil and inst.minotaur:IsValid() and inst.minotaur.sg:HasStateTag("death") then
        inst.minotaur.MiniMapEntity:SetEnabled(false)
        inst.minotaur:RemoveComponent("maprevealable")
    end

    if not loading then
        inst:Remove()
    end
end

local function OnLoadChest(inst)
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
        dospawnchest(inst, true)
        inst.persists = false
        inst:DoTaskInTime(0, inst.Remove)
    end
end


AddPrefabPostInit("minotaurchestspawner",function (inst)
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end    
    inst.task = inst:DoTaskInTime(3, dospawnchest)
    inst.OnLoad = OnLoadChest
end)

local function OnUnlock(inst)
    if inst.components.klaussacklock~=nil then
        inst:RemoveComponent("klaussacklock")
    end
	
	inst.SoundEmitter:PlaySound("dontstarve/quagmire/common/safe/key")

	inst.components.container.canbeopened = true

    inst._isunlocked = true

    SpawnPrefab("pandorachest_reset").Transform:SetPosition(inst.Transform:GetWorldPosition())
end

local function OnUseKey(inst, key, doer)
	if not key:IsValid() or key.components.klaussackkey == nil or inst._isunlocked then
		return false, nil, false
	elseif key.components.klaussackkey.keytype ~= inst.keyid then
		return false, "QUAGMIRE_WRONGKEY", false
	end

	OnUnlock(inst)

	return true, nil, true
end

local function onsave(inst, data)
    data._isunlocked = inst._isunlocked
end

local function onload(inst, data)
    if data ~= nil and data._isunlocked then
        inst._isunlocked = true
        OnUnlock(inst)
    end
end

AddPrefabPostInit("pandoraschest",function(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    
    inst.components.container.canbeopened = false


    inst:AddComponent("klaussacklock")
	inst.components.klaussacklock:SetOnUseKey(OnUseKey)

    inst.keyid = "maze_key"

    inst.OnSave = onsave    
    inst.OnLoad = onload

    inst:ListenForEvent("resetruins", function()
        inst._isunlocked = false
        inst.components.container.canbeopened = false

        if inst.components.klaussacklock==nil then
            inst:AddComponent("klaussacklock")
	        inst.components.klaussacklock:SetOnUseKey(OnUseKey)
        end    
    end,TheWorld)    
end)