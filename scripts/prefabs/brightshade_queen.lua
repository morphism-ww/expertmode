local assets =
{
    Asset("ANIM", "anim/lunarthrall_plant_front.zip"),
    Asset("ANIM", "anim/lunarthrall_plant_back.zip"),
    Asset("MINIMAP_IMAGE", "brightshade_queen"),
}


local prefabs =
{
    "lunarthrall_plant_back",
    "lunarthrall_plant_gestalt",
    "lunarplant_husk",
    "lunarthrall_plant_vine",
    "lunarthrall_plant_vine_end",
}

local loot = {
    "lunarplant_husk",
    "lunarplant_husk",
    "lunarplant_husk",
    "lunarplant_husk",
    "plantmeat",
    "plantmeat",
    "plantmeat",
    "plantmeat",
    "purebrilliance",
    "purebrilliance",
    "purebrilliance",
    "purebrilliance",
    "lunarlight_blueprint"
}

local function customPlayAnimation(inst,anim,loop)
    inst.AnimState:PlayAnimation(anim,loop)
    if inst.back then
        inst.back.AnimState:PlayAnimation(anim,loop)
    end
end

local function customPushAnimation(inst,anim,loop)
    inst.AnimState:PushAnimation(anim,loop)
    if inst.back then
        inst.back.AnimState:PushAnimation(anim,loop)
    end
end

local function customSetRandomFrame(inst)
    local frame = math.random(inst.AnimState:GetCurrentAnimationNumFrames()) -1
    inst.AnimState:SetFrame(frame)
    
    if inst.back then
        inst.back.AnimState:SetFrame(frame)
    end
end


local function spawnback(inst)
    local back = SpawnPrefab("lunarthrall_plant_back")
    back.AnimState:SetFinalOffset(-1)
    inst.back = back
	table.insert(inst.highlightchildren, back)

    back:ListenForEvent("death", function()
        local self = inst.components.burnable
        if self ~= nil and self:IsBurning() and not self.nocharring then
            back.AnimState:SetMultColour(.2, .2, .2, 1)
        end
    end, inst)

    if math.random() < 0.5 then
        inst.AnimState:SetScale(-1,1)
        back.AnimState:SetScale(-1,1)
    end
    local color = .6 + math.random() * .4
    inst.tintcolor = color
    inst.AnimState:SetMultColour(color, color, color, 1)
    back.AnimState:SetMultColour(color, color, color, 1)

	back.entity:SetParent(inst.entity)
    inst.components.colouradder:AttachChild(back)
end

local function infest(inst,target)
    if target then
        
        if target.components.pickable then
            target.components.pickable.caninteractwith = false
        end

        if target.components.growable then
            target.components.growable:Pause("lunarthrall_plant")
        end
        
        target:AddTag("NOCLICK")

        inst.components.entitytracker:TrackEntity("targetplant", target)
        target.lunarthrall_plant = inst
        inst.Transform:SetPosition(target.Transform:GetWorldPosition())
        local bbx1, bby1, bbx2, bby2 = target.AnimState:GetVisualBB()
        local bby = bby2 - bby1
        if bby < 2 then
            inst.targetsize = "short"
        elseif bby < 4 then
            inst.targetsize = "med"
        else
            inst.targetsize = "tall"
        end
        inst:customPlayAnimation("idle_"..inst.targetsize )
        inst.AnimState:SetFrame(math.random(inst.AnimState:GetCurrentAnimationNumFrames()) - 1)
    end
end

local function deinfest(inst)
    local target = inst.components.entitytracker:GetEntity("targetplant")
    if target then
        if target.components.pickable then
            target.components.pickable.caninteractwith = true
        end
        if target.components.growable then
            target.components.growable:Resume("lunarthrall_plant")
        end            
        target:RemoveTag("NOCLICK")
    end
end

local function playSpawnAnimation(inst)
    inst.sg:GoToState("spawn")
end

local function OnLoadPostPass(inst)

    if inst.components.entitytracker:GetEntity("targetplant") then
        inst:infest(inst.components.entitytracker:GetEntity("targetplant"),true)
    end
end


local function OnDeath(inst)
    inst:killvines()
    inst.components.brightshadespawner:KillAllMinions()
    local target = inst.components.entitytracker:GetEntity("targetplant")
    if target then
        target.lunarthrall_plant = nil
    end    
    if inst.waketask then
        inst.waketask:Cancel()
        inst.waketask = nil
    end
    if inst.resttask then
        inst.resttask:Cancel()
        inst.resttask = nil
    end    
    inst.components.lootdropper:DropLoot()
    inst:customPlayAnimation("death_"..inst.targetsize )
    inst:ListenForEvent("animover", function()
        if inst.AnimState:IsCurrentAnimation("death_"..inst.targetsize) then
            inst:Remove()
        end
    end)
end

local function OnRemove(inst)
    inst:deinfest()
    inst:killvines()
end

local function vineremoved(inst,vine,killed)
    for i,localvine in ipairs(inst.vines)do
        if localvine == vine then
            table.remove(inst.vines,i)
            if not killed then
                inst.vinelimit = inst.vinelimit + 1
            end
			break
        end
    end
end

local function OnWakeTask(inst)
	inst.waketask = nil
	inst.wake = nil
	inst.tired = nil
	inst.vinelimit = 4
	inst.sg:GoToState("attack")
end

local function OnRestTask(inst)
	inst.resttask = nil

	if not inst.components.health:IsDead() then
		inst.sg:GoToState("tired_wake")

		if inst.waketask ~= nil then
			inst.waketask:Cancel()
		end
		inst.waketask = inst:DoTaskInTime(TUNING.LUNARTHRALL_PLANT_WAKE_TIME, OnWakeTask)
	end
end

local function vinekilled(inst,vine)
    for i,localvine in ipairs(inst.vines)do
        if localvine == vine then
            vineremoved(inst,vine, true)
            if inst.vinelimit <= 0 and #inst.vines <= 0 then
                if not inst.components.health:IsDead() then
                    inst.sg:GoToState("tired_pre")
                end
				if inst.waketask ~= nil then
					inst.waketask:Cancel()
					inst.waketask = nil
				end
				if inst.resttask ~= nil then
					inst.resttask:Cancel()
				end
				inst.resttask = inst:DoTaskInTime(TUNING.LUNARTHRALL_PLANT_REST_TIME + (math.random()*1), OnRestTask)
            end
        end
    end  
end

local function killvines(inst)
    for i,localvine in ipairs(inst.vines)do
        if localvine:IsValid() then
            localvine.components.health:Kill()
        end
    end
end

local function OnAttacked(inst,data)
    if data.attacker then
        if (
                not inst.components.combat.target 
                or (inst.components.combat.target ~= data.attacker and not inst.components.timer:TimerExists("targetswitched"))
            ) 
            and not data.attacker.components.complexprojectile
            and not data.attacker.components.projectile then

			inst.components.timer:StopTimer("targetswitched")
            inst.components.timer:StartTimer("targetswitched",20)
            inst.components.combat:SetTarget(data.attacker)
        end
    end
end




local TARGET_MUST_TAGS = { "_combat", "character" }
local TARGET_CANT_TAGS = { "INLIMBO","lunarthrall_plant", "lunarthrall_plant_end" }
local function Retarget(inst)
    --print("RETARGET")
    if not inst.no_targeting then
        local target = FindEntity(
            inst,
            20,
            function(guy)
                if inst.tired then
                    return nil
                end
            
                return inst.components.combat:CanTarget(guy)
            end,
            TARGET_MUST_TAGS,
            TARGET_CANT_TAGS
        )

        if inst.vinelimit > 0  then
            if target then

                local pos = Vector3(inst.Transform:GetWorldPosition())

                local theta = math.random()*2*PI
                local radius = TUNING.LUNARTHRALL_PLANT_MOVEDIST
                local offset = Vector3(radius * math.cos( theta ), 0, -radius * math.sin( theta ))
                pos = pos + offset

                if TheWorld.Map:IsVisualGroundAtPoint(pos.x,pos.y,pos.z) then

                    local vine = SpawnPrefab("lunarthrall_plant_vine_end")
                    vine.Transform:SetPosition(pos.x,pos.y,pos.z)
                    vine.Transform:SetRotation(inst:GetAngleToPoint(pos.x, pos.y, pos.z))
                    vine.sg:RemoveStateTag("nub")
                    if inst.tintcolor then
                        vine.AnimState:SetMultColour(inst.tintcolor, inst.tintcolor, inst.tintcolor, 1)
                        vine.tintcolor = inst.tintcolor
                    end

    				inst.components.colouradder:AttachChild(vine)

                    vine.parentplant = inst
                    table.insert(inst.vines,vine)
                    inst.vinelimit = inst.vinelimit -1
                    inst:DoTaskInTime(0,function() vine:ChooseAction() end)

                    return target
                end
            end
        end
    end
end

local function keeptargetfn(inst, target)
   return target ~= nil
        and target:GetDistanceSqToInst(inst) < TUNING.LUNARTHRALL_PLANT_GIVEUPRANGE* TUNING.LUNARTHRALL_PLANT_GIVEUPRANGE
        and target.components.combat ~= nil
        and target.components.health ~= nil
        and not target.components.health:IsDead()
        and not (inst.components.follower ~= nil and
                (inst.components.follower.leader == target or inst.components.follower:IsLeaderSame(target)))
end

local function CreateFlame()
    local inst = CreateEntity()

    inst:AddTag("FX")
    --[[Non-networked entity]]
    if not TheWorld.ismastersim then
        inst.entity:SetCanSleep(false)
    end
    inst.persists = false

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddFollower()

    inst.AnimState:SetBank("lunarthrall_plant")
    inst.AnimState:SetBuild("lunarthrall_plant_front")
    inst.AnimState:PlayAnimation("gestalt_fx", true)
	inst.AnimState:SetMultColour(1, 1, 1, 0.6)
	inst.AnimState:SetLightOverride(0.1)
    inst.AnimState:SetFrame( math.random(inst.AnimState:GetCurrentAnimationNumFrames()) -1)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    return inst
end

local function onlostminionfn(inst,minion)
    if not inst.components.health:IsDead() then
        inst.sg:GoToState("tired_pre")
    end
    if inst.waketask ~= nil then
        inst.waketask:Cancel()
        inst.waketask = nil
    end
    if inst.resttask ~= nil then
        inst.resttask:Cancel()
    end
    inst.resttask = inst:DoTaskInTime(TUNING.LUNARTHRALL_PLANT_REST_TIME + (math.random()*5), OnRestTask)
end

---------------------------------------------

local function SetMedium(inst)
    
end

local function SetLarge(inst)
    inst.components.health:SetMaxHealth(TUNING.LUNARTHRALL_PLANT_QUEEN_HEALTH[2])
    inst.Transform:SetScale(3.5,3.5,3.5)

    inst.components.brightshadespawner.shouldspawn = true
    inst.components.brightshadespawner:StartNextSpawn()
    
    inst.queen=true
    inst.vinelimit=0

    --inst.icon.MiniMapEntity:SetIcon("lunarrift_portal_max1.png")
end
local Absorption_list={0,0.2,0.8,0.9}
local function UpdateLevel(inst)
    local num = inst.components.brightshadespawner.numminions

    local level
    if num>6 then
        level=4
    elseif num>5 then
        level=3
    elseif num>3 then
        level=2
    else
        level=1
    end

    inst.components.health:SetAbsorptionAmount(Absorption_list[level])
    
end

local function GetMedGrowTime(inst)
    return TUNING.TOTAL_DAY_TIME
end

local function GetLargeGrowTime(inst)
    return 10
end


local growth_stages =
{
    { name = "med",     time = GetMedGrowTime,      fn = SetMedium        },
    { name = "large",   time = GetLargeGrowTime,    fn = SetLarge         },
}


local function summonholylight(inst)
    local target = inst.components.combat.target
    if inst.queen and target and target:IsValid() then
        SpawnPrefab("sporecloud").Transform:SetPosition(target.Transform:GetWorldPosition())
    end
end

local function cloudOnSpawned(inst, cloud)
    local heading_angle = PI2*math.random()
    local radius=6+6*math.random()
    local pos = Vector3(inst.Transform:GetWorldPosition())
    pos.x = pos.x + radius*math.cos(heading_angle*DEGREES)
    pos.y = pos.y
    pos.z = pos.z - radius*math.sin(heading_angle*DEGREES)
    cloud.Transform:SetPosition(pos.x, pos.y, pos.z)
end

local function nofreeze(inst)
    return inst.queen and not inst.tired
end

local function onEndAura(inst)
    local queen = FindEntity(
            inst,
            25,
            function(guy)
                return guy.prefab=="lunarthrall_plant_queen"
            end
        )
    if queen==nil or queen.components.health:IsDead() then
        inst.components.sanity:EnableLunacy(false, "brightshade_queen")
    end    
end

local function onnear(inst, player)
    if player.components.sanity ~= nil and player.components.sanity.mode == SANITY_MODE_INSANITY then
        player.components.sanity:EnableLunacy(true, "brightshade_queen")
        player:DoPeriodicTask(5, onEndAura)
    end
end

local function CheckPlayers(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x,y,z,24,true)
    for i, v in ipairs(players) do
        onnear(inst, v)
    end
end


local function TryStartCorrupt(inst)
    if inst.queen and TheWorld.components.lunarthrall_plantspawner then
        TheWorld.components.lunarthrall_plantspawner:PushInvade()
    end
end

local function show_minimap(inst)
    -- Create a global map icon so the minimap icon is visible to other players as well.
    inst.icon = SpawnPrefab("globalmapicon")
    inst.icon:TrackEntity(inst)
    inst.icon.MiniMapEntity:SetPriority(21)

end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.entity:AddNetwork()

	MakeObstaclePhysics(inst, .8)
	inst:SetPhysicsRadiusOverride(.4) --V2C: WARNING intentionally reducing range for incoming attacks; make sure everyone can still reach!

    inst.MiniMapEntity:SetIcon("brightshade_queen.tex")
    inst.MiniMapEntity:SetCanUseCache(false)
    inst.MiniMapEntity:SetDrawOverFogOfWar(true)
    inst.MiniMapEntity:SetPriority(22)

    inst.AnimState:SetBank("lunarthrall_plant")
    inst.AnimState:SetBuild("lunarthrall_plant_front")
    inst.AnimState:PlayAnimation("idle_med", true)
    inst.AnimState:SetFinalOffset(1)
   
    inst.Transform:SetScale(2,2,2)

    inst.customPlayAnimation = customPlayAnimation
    inst.customPushAnimation = customPushAnimation
    inst.customSetRandomFrame = customSetRandomFrame

    inst:AddTag("plant")
    inst:AddTag("epic")
    inst:AddTag("PyreToxinImmune")
    inst:AddTag("lunar_aligned")
    inst:AddTag("hostile")
    inst:AddTag("lunarthrall_plant")
    inst:AddTag("retaliates")
    inst:AddTag("NPCcanaggro")
    inst:AddTag("noauradamage")
    inst:AddTag("brightmareboss")

	inst.highlightchildren = {}

    inst.entity:SetPristine()

    inst.targetsize = "med"

    if not TheNet:IsDedicated() then
        inst.flame = CreateFlame()
        inst.flame.entity:SetParent(inst.entity)
        inst.flame.Follower:FollowSymbol(inst.GUID, "follow_gestalt_fx", nil, nil, nil, true)
    end

    if not TheWorld.ismastersim then
        return inst
    end

    inst:customSetRandomFrame()

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.LUNARTHRALL_PLANT_QUEEN_HEALTH[1])
    inst.components.health.fire_damage_scale=0
    inst.components.health:StartRegen(40, 5)

    inst:AddComponent("combat")
    inst.components.combat:SetRetargetFunction(1, Retarget)
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)
    inst.components.combat:SetDefaultDamage(TUNING.LUNARTHRALL_PLANT_QUEEN_DAMAGE)

	inst:AddComponent("planarentity")
	inst:AddComponent("planardamage")
	inst.components.planardamage:SetBaseDamage(TUNING.LUNARTHRALL_PLANT_PLANAR_DAMAGE)

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetLoot(loot)

    inst:AddComponent("inspectable")
    inst:AddComponent("entitytracker")

    inst:AddComponent("colouradder")
    inst:AddComponent("timer")    

    inst:AddComponent("growable")
    inst.components.growable.stages = growth_stages
    inst.components.growable.growoffscreen = true
    inst.components.growable:SetStage(1)
    inst.components.growable:StartGrowing()

    inst:AddComponent("brightshadespawner")
    inst.components.brightshadespawner.shouldspawn = false
    inst.components.brightshadespawner.onlostminionfn = onlostminionfn


    inst:AddComponent("periodicspawner")
    inst.components.periodicspawner:SetPrefab("sporecloud")
    inst.components.periodicspawner:SetRandomTimes(15, 20)
    inst.components.periodicspawner:SetDensityInRange(20, 5)
    inst.components.periodicspawner:SetMinimumSpacing(8)
    inst.components.periodicspawner:SetOnSpawnFn(cloudOnSpawned)
    inst.components.periodicspawner:Start()

    inst:AddComponent("sanityaura")
    inst.components.sanityaura.aura = TUNING.SANITYAURA_LARGE

    inst:ListenForEvent("death", OnDeath)
    inst:ListenForEvent("onremove",OnRemove)
    inst:ListenForEvent("attacked",OnAttacked)
    inst:ListenForEvent("minionchange",UpdateLevel)


    inst.vines = {}
    inst.vinekilled = vinekilled
    inst.vineremoved = vineremoved
    inst.killvines = killvines
    inst.vinelimit = 4

    inst.infest = infest
    inst.deinfest = deinfest

    inst.queen = false


    inst:DoPeriodicTask(15,summonholylight)
    inst:DoPeriodicTask(3, CheckPlayers)

    inst:WatchWorldState("cycles", TryStartCorrupt)

    inst.playSpawnAnimation = playSpawnAnimation
    inst.OnLoadPostPass = OnLoadPostPass
    MakeMediumFreezableCharacter(inst)
    inst.components.freezable:SetRedirectFn(nofreeze)

    inst:SetStateGraph("SGlunarthrall_plant")


	spawnback(inst)

    inst.icon = SpawnPrefab("globalmapicon")
    inst.icon:TrackEntity(inst)
    inst.icon.MiniMapEntity:SetPriority(0)

    return inst
end



return Prefab("lunarthrall_plant_queen", fn, assets, prefabs)