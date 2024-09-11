local assets =
{   
    Asset("ANIM", "anim/eyeofterror_action.zip"),
    Asset("ANIM", "anim/eyeofterror_basic.zip"),
    Asset("ANIM", "anim/calamityeye.zip"),
}

local brain = require("brains/calamityeyebrain")

local MODE = {
    LEASH_SHOOT = 0,
    SPIN_SHOOT = 1,
    LEASH = 2,
}

local PHASES = {
    {
        hp = 0.7,
        fn = function (inst)
            inst:trigger_BulletHell()
            inst.minhealth = 0.4*TUNING.CALAMITA_HEALTH
            --inst.components.health:SetMinHealth(0.5*TUNING.CALAMITA_HEALTH)
        end
    },
    {
        hp = 0.4,
        fn = function (inst)
            inst.components.health:SetInvincible(true)
            inst:AddTag("NOCLICK")
            TheNet:Announce("兄弟重生!")
            inst:SummonTwins()
            inst.minhealth = 0.1*TUNING.CALAMITA_HEALTH
            inst.AnimState:SetMultColour(1,1,1,0.5)
        end
    },
    {
        hp = 0.35,
        fn = function (inst)
            inst:summon_soulseeker()
            inst.components.health:SetInvincible(true)
            
            TheNet:Announce("你成功给我留下了深刻的印象,留下了最深刻的印象...")
            --inst.components.health:SetMinHealth(0)
        end
    },
    {
        hp = 0.1,
        fn = function (inst)
            inst:trigger_BulletHell()
            inst.minhealth = 0
            --inst.components.health:SetMinHealth(0)
        end
    }
}

--MUSIC------------------------------------------------------------------------
local function PushMusic(inst)
    if ThePlayer == nil or inst:HasTag("INLIMBO") then
        inst._playingmusic = false
    elseif ThePlayer:IsNear(inst, inst._playingmusic and 60 or 20) then
        inst._playingmusic = true
        ThePlayer:PushEvent("triggeredevent", { name = "calamitas_clone", duration = 5 })
    elseif inst._playingmusic and not ThePlayer:IsNear(inst, 64) then
        inst._playingmusic = false
    end
end

local function OnMusicDirty(inst)
    if not TheNet:IsDedicated() then
        if inst._musictask ~= nil then
            inst._musictask:Cancel()
        end
        inst._musictask = inst:DoPeriodicTask(1, PushMusic, 0.5)
    end
end

-------------------------------------------------------------------------------

local function RetargetFn(inst)
	

	local x, y, z = inst.Transform:GetWorldPosition()
	local target = inst.components.combat.target
	if target ~= nil then
		local range = 18 + target:GetPhysicsRadius(0)
		if target.isplayer and target:GetDistanceSqToPoint(x, y, z) < range * range then
			--Keep target
			return
		end
	end

	--V2C: WARNING: FindClosestPlayerInRange returns 2 values, which
	--              we don't want to return as our 2nd return value.  
	local player--[[, rangesq]] = FindClosestPlayerInRange(x, y, z, 40, true)
	return player
end

local function KeepTargetFn(inst, target)
	if not inst.components.combat:CanTarget(target) then
		return false
	end
	local x, y, z = inst.Transform:GetWorldPosition()
	local rangesq = 40*40
    return target:GetDistanceSqToPoint(x, y, z) < rangesq
end


local function OnAttacked(inst,data)
    if data.attacker then
        inst.components.combat:SetTarget(data.attacker)
    end    
end

------------------------------------------------------


local function PlotRangeAttack(inst)
    inst.formation = math.random()*360
    if inst.components.combat.target~=nil then
        inst.formation = inst.components.combat.target:GetAngleToPoint(inst.Transform:GetWorldPosition())
    end

    if inst.mode == MODE.LEASH_SHOOT or inst.components.health:IsInvincible() then
        inst.mode = MODE.SPIN_SHOOT
        inst.components.locomotor.walkspeed = 10
        inst.formationradius = 14
        ---TODO
    else
        inst.components.locomotor.walkspeed = 8
        inst.mode = MODE.LEASH_SHOOT
        inst.formationradius = 12
    end
end

local function ChooseAttack(inst,data)
    if data.target and data.target:IsValid() then
        --inst.components.combat:StartAttack()
        if inst.mode == MODE.LEASH_SHOOT then
            inst.components.combat:OverrideCooldown(1)
            local proj = SpawnPrefab("hellblasts")

            local p = math.random()
            inst.formation = inst.formation + (p>0.5 and 1 or -1 )*(20*p+20)
            inst.formationradius = inst.formationradius + 4*math.random()-2
            proj.Transform:SetPosition(inst.Transform:GetWorldPosition())
            proj.components.projectile:Throw(inst, data.target, inst)
        elseif inst.mode == MODE.SPIN_SHOOT then
            inst.formation = inst.formation + 180*math.random()-90
            inst.components.combat:RestartCooldown()  ---DEFAULT 
            local proj = SpawnPrefab("brimstone_fire")
            proj.Transform:SetPosition(inst.Transform:GetWorldPosition())
            proj.components.linearprojectile:LineShoot(data.target:GetPosition(),inst)
        end
    end
end

local function ClearRecentlyCharged(inst)
    inst._recentlycharged = nil
end

local function OnCollide(inst, other)
	--other should be validated before reaching here now
	--assert(other ~= nil and other:IsValid())
    if not other.components.health or other.components.health:IsDead() then
        return
    end

    -- Lazy initialize the recently charged list if it doesn't exist yet.
    -- If it does, check if there's an existing timestamp for this "other".
    local current_time = GetTime()
    local prev_value = nil
    if inst._recentlycharged == nil then
        inst._recentlycharged = {}
    else
        prev_value = inst._recentlycharged[other]
    end

    -- If we had a timestamp for this "other" and hit it too recently, don't hit it again.
    if prev_value ~= nil and prev_value - current_time < 2 then
        return
    end
    inst._recentlycharged[other] = current_time

    other:AddDebuff("vulnerability_hex","vulnerability_hex")
    inst.components.combat:DoAttack(other)
end
------------------------------------------------------
local x_rot = true
local Hell_Size = 50
local Hell_Size_Half = 25
local function DoWave(inst)
    inst.bullethell_laststartattacktime = GetTime()
    local centerpos 
    local target = inst.components.combat.target
    if target and target:IsValid() then
        centerpos = target:GetPosition()
    else
        centerpos = inst:GetPosition()
    end
    
    if x_rot then
        for i = 1, math.random(12,15) do
            local offset = Hell_Size*math.random()-Hell_Size_Half

            local proj = SpawnPrefab("hellblasts")
            inst.bullethell[proj] = true 
            proj.Transform:SetPosition(centerpos.x+offset,0,centerpos.z+(i>6 and 1 or -1)*(Hell_Size_Half + math.random()))
            proj:Trigger(i>6 and 90 or -90)
                     
        end
    else
        for i = 1, math.random(12,15) do
            local offset = Hell_Size*math.random()-Hell_Size_Half
            
            local proj = SpawnPrefab("hellblasts")
            inst.bullethell[proj] = true 
            proj.Transform:SetPosition(centerpos.x+(i>6 and 1 or -1)*(Hell_Size_Half + math.random()),0,centerpos.z+offset)
            proj:Trigger(i>6 and -180 or 0)
        end
    end
    x_rot = not x_rot
end
local function TryWave(inst)
    if inst.bullethell_laststartattacktime~=nil then
        local time_since_doattack = GetTime() - inst.bullethell_laststartattacktime
		
		if time_since_doattack > 2 then
			DoWave(inst)
		end
    else
        DoWave(inst)
    end    
end

local function KillWave(inst)
    inst.mode = 1
    inst:RemoveTag("notarget")
    inst.components.health:SetInvincible(false)
    for k in pairs(inst.bullethell) do
        inst.bullethell[k] = nil
        k:Remove()
    end
    inst.bullethell_laststartattacktime = nil
end
local function trigger_BulletHell(inst)
    inst.mode = MODE.LEASH
    inst:AddTag("notarget")
    inst.components.health:SetInvincible(true)
end

local function summon_soulseeker(inst)
    inst.components.circlecenter:Start()
end

local function hookup_twin_listeners(inst, twin)
	inst:ListenForEvent("death", function(t)
        local et = inst.components.entitytracker
        local t1 = et:GetEntity("twin1")
        local t2 = et:GetEntity("twin2")
        if (t1 == nil or t1.components.health:IsDead()) and (t2 == nil or t2.components.health:IsDead()) then
            inst.components.health:SetInvincible(false)
            inst.hastwins = false
            inst.AnimState:SetMultColour(1,1,1,1)
            inst:RemoveTag("NOCLICK")
        end
    end, twin)
    twin.components.entitytracker:TrackEntity("twin", inst)
end

local TWINS_SPAWN_OFFSET = 10
local function get_spawn_positions(inst, targeted_player)
    local manager_position = inst:GetPosition()
    local player_position = targeted_player:GetPosition()
    local manager_to_player = (player_position - manager_position):Normalize()

    local offset_unit = manager_to_player:Cross(Vector3(0, 1, 0)):Normalize()

    local offset1_angle = math.atan2(offset_unit.z, offset_unit.x)
    local twin1_offset = FindWalkableOffset(player_position, offset1_angle, TWINS_SPAWN_OFFSET, nil, false, true, nil, true, true)
        or (offset_unit * TWINS_SPAWN_OFFSET)

    local offset2_angle = offset1_angle + PI
    local twin2_offset = FindWalkableOffset(player_position, offset2_angle, TWINS_SPAWN_OFFSET, nil, false, true, nil, true, true)
        or (offset_unit * -1 * TWINS_SPAWN_OFFSET)

    return player_position + twin1_offset,player_position + twin2_offset
end

local function SummonTwins(inst)
    local twin1spawnpos, twin2spawnpos = get_spawn_positions(inst,inst.components.combat.target or inst)

    local twin1 = SpawnPrefab("twinofterror1")
    twin1.components.health:SetMaxHealth(6000)
	twin1.persists = false
    twin1.components.combat:SetRange(24)
    twin1.forcequickshoot = true
    
    twin1.components.locomotor.walkspeed =  12
    inst.components.entitytracker:TrackEntity("twin1", twin1)
    twin1.sg:GoToState("flyback")
    --twin1:PushEvent("health_transform")
    twin1.Transform:SetPosition(twin1spawnpos:Get())
    
    hookup_twin_listeners(inst, twin1)

    local twin2 = SpawnPrefab("twinofterror2")
    twin2.components.health:SetMaxHealth(6000)
	twin2.persists = false
    twin2.components.locomotor.walkspeed =  10
    twin2.sg:GoToState("flyback")
	twin2:PushEvent("health_transform")
    inst.components.entitytracker:TrackEntity("twin2", twin2)
    twin2.Transform:SetPosition(twin2spawnpos:Get())
    
    inst.hastwins = true
    hookup_twin_listeners(inst, twin2)
end

local function nodmgshielded(self, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
    local old_percent = self:GetPercent()

    if self:IsInvincible() then
        return 0
    end
    
    amount = (amount> -400) and amount or -400

    self:SetVal(self.currenthealth + amount, cause, afflicter)

    self.inst:PushEvent("healthdelta", { oldpercent = old_percent, newpercent = self:GetPercent(), overtime = overtime, cause = cause, afflicter = afflicter, amount = amount })

    return amount
end



local function SetHealthVal(self,val, cause, afflicter)
    local old_health = self.currenthealth
    local max_health = self:GetMaxWithPenalty()
    local min_health = math.min(self.inst.minhealth, max_health)

    if val > max_health then
        val = max_health
    end

    if val <= min_health then
        self.currenthealth = min_health
        self.inst:PushEvent("minhealth", { cause = cause, afflicter = afflicter })
    else
        self.currenthealth = val
    end

    if old_health > 0 and self.currenthealth <= 0 then
        -- NOTES(JBK): Make sure to keep the events fired up to date with the explosive component.
        --Push world event first, because the entity event may invalidate itself
        --i.e. items that use .nofadeout and manually :Remove() on "death" event
        TheWorld:PushEvent("entity_death", { inst = self.inst, cause = cause, afflicter = afflicter })
        self.inst:PushEvent("death", { cause = cause, afflicter = afflicter })

		--[[Here, check if killing player or monster
        local notify_type = (self.inst.isplayer and "TotalPlayersKilled") or "TotalEnemiesKilled"
        NotifyPlayerProgress(notify_type, 1, afflicter)]]

        --V2C: If "death" handler removes ourself, then the prefab should explicitly set nofadeout = true.
        --     Intentionally NOT using IsValid() here to hide those bugs.
        
        self.inst:AddTag("NOCLICK")
        self.inst.persists = false
        self.inst:DoTaskInTime(self.destroytime or 2, ErodeAway)
        
    end
end

---------------------------------------------------------------------
local function UpdateFade(inst,dt)
    inst.t = inst.t + dt
    if inst.t < 0.3 then
		local k = 1 - inst.t / 0.3
		k = k * k
		inst.AnimState:SetMultColour(1, 1, 1, k)
	else
		inst:Remove()
	end
end

local function CreateTailFx()
    local inst = CreateEntity()

	inst:AddTag("FX")
	--[[Non-networked entity]]
	if not TheWorld.ismastersim then
		inst.entity:SetCanSleep(false)
	end
	inst.persists = false

	inst.entity:AddTransform()
	inst.entity:AddAnimState()
    inst.AnimState:SetScale(1.2,1.2,1.2)

    inst.Transform:SetSixFaced()
	--inst.entity:AddFollower()


    inst.AnimState:SetBank("eyeofterror")
    inst.AnimState:SetBuild("eyeofterror_basic")
    inst.AnimState:OverrideSymbol("ball_mouth","calamityeye","ball_mouth")
    inst.AnimState:OverrideSymbol("vein_bottom","calamityeye","vein_bottom")
    inst.AnimState:OverrideSymbol("tentacle","calamityeye","tentacle")

    inst.AnimState:Hide("ball_eye")
    inst.AnimState:Hide("mouth")
    inst.AnimState:Hide("eye")
    inst.AnimState:HideSymbol("veins_ol")
    
    inst.AnimState:PlayAnimation("charge_loop",true)
    
    inst.t = 0
    inst:AddComponent("updatelooper")
    inst.components.updatelooper:AddOnUpdateFn(UpdateFade)

    return inst
end

local function OnUpdateTail(inst)
    
    local tail = CreateTailFx()
    tail.Transform:SetRotation(inst.Transform:GetRotation())
    tail.Transform:SetPosition(inst.Transform:GetWorldPosition())
end

local function ChangeTail(inst)
    if inst._tail:value() then
        if inst.tailtask==nil then
            inst.tailtask = inst:DoPeriodicTask(0.1,OnUpdateTail)
        end
    else
        if inst.tailtask~=nil then
            inst.tailtask:Cancel()
            inst.tailtask = nil
        end
    end    
end
---------------------------------------------------------------
local function OnEntityWake(inst)
    if inst._despawntask ~= nil then
        inst._despawntask:Cancel()
        inst._despawntask = nil
    end
end

local function OnDespawn(inst)
    inst._despawntask = nil
    if inst:IsAsleep() and not inst.components.health:IsDead() then
        inst:Remove()
    end
end

local function OnEntitySleep(inst)
    if inst._despawntask ~= nil then
        inst._despawntask:Cancel()
    end
    inst._despawntask = inst:DoTaskInTime(10, OnDespawn)
end

local function OnSave(inst,data)
    data.minhealth = inst.minhealth
end

local function OnLoad(inst,data)
    inst.minhealth = data~=nil and data.minhealth or 0.7*TUNING.CALAMITA_HEALTH
end
-------------------------------------------------------------------
local function OnDeath(inst)
    inst._lightreset:push()
    local et = inst.components.entitytracker
        local t1 = et:GetEntity("twin1")
        local t2 = et:GetEntity("twin2")
    if t1~=nil then
        et:ForgetEntity("twin1") 
        t1:Remove()
        t1 = nil
    end
    if t2~=nil then
        et:ForgetEntity("twin2") 
        t2:Remove()
        t2 = nil
    end
    inst.components.circlecenter:Kill()
    TheWorld:PushEvent("overrideambientlighting", nil)
end

local function ClientResetLight(inst)
    TheWorld:PushEvent("overrideambientlighting", nil)
end


local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst.Transform:SetSixFaced()

    MakeTinyFlyingCharacterPhysics(inst, 2000, 1.5)

    --inst.AnimState:SetBank("calamitas_clone")
    --inst.AnimState:SetBuild("calamitas_clone")
    inst.AnimState:SetBank("eyeofterror")
    inst.AnimState:SetBuild("eyeofterror_basic")
    inst.AnimState:OverrideSymbol("ball_mouth","calamityeye","ball_mouth")
    inst.AnimState:OverrideSymbol("ball_eye","calamityeye","ball_mouth")
    inst.AnimState:OverrideSymbol("vein_bottom","calamityeye","vein_bottom")

    inst.AnimState:OverrideSymbol("tentacle","calamityeye","tentacle")
    inst.AnimState:SetSymbolBloom("tentacle",resolvefilepath("shaders/red_shader.ksh"))
    inst.AnimState:SetSymbolLightOverride("vein_bottom",0.2)
    inst.AnimState:SetSymbolLightOverride("tentacle",0.5)

    
    inst.AnimState:Hide("ball_eye")
    inst.AnimState:Hide("mouth")
    inst.AnimState:Hide("eye")
    inst.AnimState:Hide("tounge")
    inst.AnimState:HideSymbol("veins_ol")
    inst.AnimState:SetScale(1.2,1.2,1.2)
    
    inst.AnimState:PlayAnimation("walk_loop",true)

    inst:AddTag("calamita")
    inst:AddTag("flying")
    inst:AddTag("epic")
    inst:AddTag("hostile")
    inst:AddTag("ignorewalkableplatformdrowning")
    inst:AddTag("largecreature")
    inst:AddTag("noteleport")
    inst:AddTag("noepicmusic")
    inst:AddTag("eyeofterror")
    inst:AddTag("shadow_aligned")
    
    if not TheNet:IsDedicated() then
        inst:ListenForEvent("taildirty",ChangeTail)
    end

    inst._tail = net_bool(inst.GUID,"calamityeye_tail","taildirty")
    
    inst._playingmusic = false
    inst._musictask = nil
    OnMusicDirty(inst)

    inst._lightreset = net_event(inst.GUID,"calamityeye._lightset")
    TheWorld:PushEvent("overrideambientlighting", Point(1, 69 / 255, 0))

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        --inst:ListenForEvent("musicdirty", OnMusicDirty)
        inst:ListenForEvent("calmityeye._lightreset",ClientResetLight)
        return inst
    end

    ------------------------------------------
    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = 10
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor:SetStrafing(true)
    inst.components.locomotor.pathcaps = { allowocean = true }



    ------------------------------------------
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.CALAMITA_HEALTH)
    inst.components.health.DoDelta = nodmgshielded
    inst.components.health.SetVal = SetHealthVal
    inst.components.health.disable_penalty = true

    ------------------------------------------
    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(250)
    inst.components.combat:SetRange(25)
    inst.components.combat:SetAttackPeriod(2)
    inst.components.combat:SetRetargetFunction(1, RetargetFn)
    inst.components.combat:SetKeepTargetFunction(KeepTargetFn)
    inst.components.combat.hiteffectsymbol = "swap_fire"
    --inst.components.combat.onhitotherfn = BurnTarget

    ------------------------------------------
    inst:AddComponent("lootdropper")
    --inst.components.lootdropper:SetLoot({"thurible","armorskeleton","skeletonhat"})
    
    --inst:AddComponent("spawnfader")
    ------------------------------------------
    inst:AddComponent("inspectable")

    ------------------------------------------
    inst:AddComponent("circlecenter")
    inst.components.circlecenter.OnLostTeam = function (inst)
        inst.components.health:SetInvincible(false)
    end

    inst:AddComponent("entitytracker")

    inst:AddComponent("healthtrigger")
    for i, v in pairs(PHASES) do
		inst.components.healthtrigger:AddTrigger(v.hp, v.fn)
	end

    ------------------------------------------
    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = -TUNING.SANITYAURA_HUGE

    inst:AddComponent("planarentity")

    inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(40)

    inst.mode = 1
    inst.formation = 0
    inst.formationradius = 14
    inst.minhealth = 0.7*TUNING.CALAMITA_HEALTH

    inst._soundpath = "terraria1/eyeofterror/"
    inst.bullethell = {}

    inst.PlotRangeAttack = PlotRangeAttack
    inst.OnCollide = OnCollide
    inst.ClearRecentlyCharged = ClearRecentlyCharged
    inst.TryWave = TryWave
    inst.KillWave = KillWave
    inst.trigger_BulletHell = trigger_BulletHell
    inst.summon_soulseeker = summon_soulseeker
    inst.SummonTwins = SummonTwins

    inst.OnEntityWake = OnEntityWake
    inst.OnEntitySleep = OnEntitySleep
    ------------------------------------------
    -- Events here.
    inst:ListenForEvent("attacked", OnAttacked)
    inst:ListenForEvent("doattack", ChooseAttack)
    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("onremove",OnDeath)

    inst:SetStateGraph("SGcalamityeye")
    inst:SetBrain(brain)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad

    return inst
end



return Prefab("calamityeye",fn,assets)