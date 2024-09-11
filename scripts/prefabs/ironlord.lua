local brain = require("brains/ironthrallbrain")
local assets =
{
	Asset("ANIM", "anim/living_suit_build.zip"),
	Asset("ANIM", "anim/player_living_suit_morph.zip"),
	Asset("ANIM", "anim/player_living_suit_punch.zip"),
	Asset("ANIM", "anim/player_living_suit_shoot.zip"),
	Asset("ANIM", "anim/player_living_suit_destruct.zip"),
    Asset("ANIM", "anim/player_attack_leap.zip"),
}

SetSharedLootTable("ironlord",
{
    {'gears',           1.0},
    {'gears',           1.0},
    {"cs_iron",         1.0},
    {"cs_iron",         1.0},
    {"cs_iron",         1.0},
    {"cs_iron",         1.0},
    {"cs_iron",         0.5},
    {"cs_iron",         0.5},
    {"purebrilliance",  1.0},
    {"purebrilliance",  1.0},
    {"purebrilliance",   .5},
    {"laser_cannon_blueprint", 1.0}
})

local SCALE = 2
local function PushMusic(inst)
    if ThePlayer == nil or inst:HasTag("death") then
        inst._playingmusic = false
    elseif ThePlayer:IsNear(inst, inst._playingmusic and 40 or 20) then
        inst._playingmusic = true
        ThePlayer:PushEvent("triggeredevent", { name = "alterguardian_phase2",duration = 2 })
    elseif inst._playingmusic and not ThePlayer:IsNear(inst, 50) then
        inst._playingmusic = false
    end
end

local function OnMusicDirty(inst)
    --Dedicated server does not need to trigger music
    if not TheNet:IsDedicated() then
        if inst._musictask ~= nil then
            inst._musictask:Cancel()
        end
        inst._musictask = inst:DoPeriodicTask(1, PushMusic, nil)
        PushMusic(inst)
    end
end
------------------------------------------------------------------------------
local function MakeAnim(inst,anim)
    inst.AnimState:SetBank("wilson")
    inst.AnimState:SetBuild("wx78")
    inst.AnimState:AddOverrideBuild("player_living_suit_morph")	
    

    inst.AnimState:Hide("ARM_carry")
    inst.AnimState:Hide("HAT")
    inst.AnimState:Hide("HAIR_HAT")
    inst.AnimState:Show("HAIR_NOHAT")
    inst.AnimState:Hide("HAIR")
    inst.AnimState:Show("HEAD")
    inst.AnimState:Hide("HEAD_HAT")
    inst.AnimState:Hide("HEAD_HAT_NOHELM")
    inst.AnimState:Hide("HEAD_HAT_HELM")

    inst.AnimState:HideSymbol("hair")
    inst.AnimState:HideSymbol("hair_hat")
    inst.AnimState:HideSymbol("face")
    inst.AnimState:HideSymbol("cheeks")

    --inst.AnimState:OverrideSymbol("headbase", "living_suit_build", "headbase")
    inst.AnimState:OverrideSymbol("torso", "living_suit_build", "torso")
    inst.AnimState:OverrideSymbol("torso_pelvis", "living_suit_build", "torso_pelvis")	
    inst.AnimState:SetScale(SCALE,SCALE,SCALE)
    inst.AnimState:PlayAnimation(anim)
    
end

local function levelup(inst)
    inst.AnimState:AddOverrideBuild("living_suit_build")
    inst.levelup  =true
    --[[inst.AnimState:OverrideSymbol("arm_lower", "living_suit_build", "arm_lower")
    inst.AnimState:OverrideSymbol("arm_upper", "living_suit_build", "arm_upper")
    inst.AnimState:OverrideSymbol("arm_upper_skin", "living_suit_build", "arm_upper_skin")
    inst.AnimState:OverrideSymbol("foot", "living_suit_build", "foot")
    inst.AnimState:OverrideSymbol("hand", "living_suit_build", "hand")
    inst.AnimState:OverrideSymbol("headbase", "living_suit_build", "headbase")
    inst.AnimState:OverrideSymbol("leg", "living_suit_build", "leg")]]
end

local function erode(inst,time, erodein)

    local time_to_erode  = time or 1
    local tick_time = TheSim:GetTickTime()

    inst:StartThread(function()
        local ticks = 0
        while ticks * tick_time < time_to_erode do
            local erode_amount = ticks * tick_time / time_to_erode
            if erodein then
                erode_amount = 1 - erode_amount
            end
            inst.AnimState:SetErosionParams(erode_amount, SHADER_CUTOFF_HEIGHT, -1.0)
            ticks = ticks + 1

            local truetest = erode_amount
            local falsetest = 1-erode_amount
            if erodein then
                truetest = 1- erode_amount
                falsetest = erode_amount
            end

            if inst.shadow == true then
                if math.random() < truetest then
                    if inst.DynamicShadow then
                        inst.DynamicShadow:Enable(false)
                    end
                    inst.shadow = false
                    inst.Light:Enable(false)
                end
            else
                if math.random() < falsetest then
                    if inst.DynamicShadow then
                        inst.DynamicShadow:Enable(true)
                    end
                    inst.shadow = true
                    inst.Light:Enable(true)
                end
            end

            if ticks * tick_time > time_to_erode then
                if erodein then
                    if inst.DynamicShadow then
                        inst.DynamicShadow:Enable(true)
                    end
                    inst.shadow = true
                    inst.Light:Enable(true)
                else
                    if inst.DynamicShadow then
                        inst.DynamicShadow:Enable(false)
                    end
                    inst.shadow = false
                    inst.Light:Enable(false)
                end
            end

            Yield()
        end
    end)
end
----------------------------------------------------------
local function retargetfn(inst)
    local x,y,z=inst.Transform:GetWorldPosition()
    return FindClosestPlayerInRangeSq(x, y, z,	1600, true)
end

local function keeptargetfn(inst,target)
    return  inst.components.combat:CanTarget(target)
end

--------------------------------------------------------------------------
---跳劈
-----------------------------------------------------
local function EquipWeapon(inst)
    inst.AnimState:OverrideSymbol("swap_object", "swap_sword_ancient", "swap_sword_ancient")
    inst.AnimState:Show("ARM_carry")
    inst.AnimState:Hide("ARM_normal")
end

local function EquipGodWeapon(inst)
    inst.awake = true
    inst.components.combat:SetRange(14,6)
    inst.AnimState:SetSymbolAddColour("swap_object",1, 1, 1, 0)
    inst.AnimState:SetSymbolBloom("swap_object")
    inst.AnimState:SetSymbolLightOverride("swap_object",0.5)
end

local function UnEquipWeapon(inst)
    inst.AnimState:Hide("ARM_carry")
    inst.AnimState:Show("ARM_normal")
end
---------------------------------------------------------------------------
---dont_skip
--------------------------------------------------------------------------


local function EnterShield(inst)
    inst.components.debuffable:RemoveOnDespawn()
    if inst._shieldfx ~= nil then
        inst._shieldfx:kill_fx()
    end
    inst._shieldfx = SpawnPrefab("forcefieldfx")
    inst._shieldfx.Transform:SetScale(1.1,1.1,1.1)
    inst._shieldfx.entity:SetParent(inst.entity)
    inst._shieldfx.Transform:SetPosition(0, 0.5, 0)
    inst.components.health.externalabsorbmodifiers:SetModifier(inst._shieldfx, 0.99, "shield")
end



local function ExitShield(inst)
    if inst._shieldfx ~= nil then
        inst._shieldfx:kill_fx()
        inst._shieldfx = nil
    end
end

local function OnAttacked(inst,data)
    if data.attacker and inst.components.combat:InCooldown() then
        inst.components.combat:SetTarget(data.attacker)
    end
end

local function OnHealthDelta(inst,data)
    if (data.oldpercent > 0.5 and data.newpercent <= 0.5) then
        inst:PushEvent("awake")
        
    end
end

local function oncollapse(inst, other)
    if other:IsValid() and other.components.workable ~= nil and other.components.workable:CanBeWorked() then
        SpawnPrefab("collapse_small").Transform:SetPosition(other.Transform:GetWorldPosition())
        other.components.workable:Destroy(inst)
    end
end

local function oncollide(inst, other)
    if other ~= nil and
        (other:HasTag("tree") or other:HasTag("boulder")) and --HasTag implies IsValid
        Vector3(inst.Physics:GetVelocity()):LengthSq() >= 1 then
        inst:DoTaskInTime(2 * FRAMES, oncollapse, other)
    end
end

------------------------------------------------------------------------------
local function OnSave(inst,data)
    data.levelup = inst.levelup
    data.awake  =inst.awake
end

local function OnLoad(inst,data)
    if data then
        if data.awake then
            inst.awake = true
            EquipGodWeapon(inst)
        end
        if data.levelup then
            inst.levelup  =true
            levelup(inst)
            EquipWeapon(inst)
        end
    end
end

-------------------------------------------
local function fn()
	local inst = CreateEntity()

	inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.Transform:SetFourFaced()

    MakeCharacterPhysics(inst, 2000, 1.5)

    MakeAnim(inst,"idle")
    
    inst.DynamicShadow:SetSize(1.3, .6)

    --[[inst:AddComponent("talker")
    inst.components.talker.fontsize = 40
    inst.components.talker.font = TALKINGFONT
    inst.components.talker.colour = Vector3(238 / 255, 69 / 255, 105 / 255)
    inst.components.talker.offset = Vector3(0, -400, 0)
    inst.components.talker.symbol = "fossil_chest"
    inst.components.talker:MakeChatter()]]
    inst._playingmusic = false
    inst._musictask = nil
    OnMusicDirty(inst)

    inst:AddTag("epic")
    inst:AddTag("hostile")
    inst:AddTag("no_rooted")
    inst:AddTag("noteleport")
    inst:AddTag("deity")
    inst:AddTag("laser_immune")
    inst:AddTag("mech")
    inst:AddTag("noepicmusic")

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end	
    
    inst.Physics:SetCollisionCallback(oncollide)
    
	
    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.IRONLORD_HEALTH)
    inst.components.health:SetMaxDamageTakenPerHit(500)
    

    inst:AddComponent("planarentity")

    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(150)
    inst.components.combat:SetAttackPeriod(3)
    inst.components.combat:SetRange(8,6)
    inst.components.combat:SetKeepTargetFunction(keeptargetfn)
    inst.components.combat:SetRetargetFunction(1, retargetfn)


    local stunnable = inst:AddComponent("stunnable")
    stunnable.stun_threshold = 2000
    stunnable.stun_period = 5
    stunnable.stun_duration = 10
    stunnable.stun_resist = 0
    stunnable.stun_cooldown = 20

    inst:AddComponent("timer")

    inst:AddComponent("knownlocations")

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable("ironlord")

    inst:AddComponent("colouradder")
    inst:AddComponent("bloomer")

    inst:AddComponent("truedamage")
    inst.components.truedamage:SetBaseDamage(5)

    inst:AddComponent("debuffable")


    inst.components.timer:StartTimer("killer_cd", 30)

    inst:AddComponent("locomotor") -- locomotor must be constructed before the stategraph
    inst.components.locomotor.walkspeed = 12
    inst.components.locomotor:SetTriggersCreep(false)
    inst.components.locomotor:EnableGroundSpeedMultiplier(false)
    --inst.components.locomotor.pathcaps = { allowocean = true,ignorewalls = true }

    inst:SetStateGraph("SGironlord")
    inst:SetBrain(brain)

    inst.LevelUp = levelup
    inst.EquipWeapon = EquipWeapon
    inst.UnEquipWeapon = UnEquipWeapon
    inst.EquipGodWeapon = EquipGodWeapon

    inst.shootcount = 7
   

    inst:ListenForEvent("stunned",EnterShield)
    inst:ListenForEvent("stun_finished",ExitShield)
    inst:ListenForEvent("healthdelta", OnHealthDelta)
    inst:ListenForEvent("death",ExitShield)

    
    inst:ListenForEvent("attacked", OnAttacked)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
    inst.erode = erode
    
    

    MakePlayerOnlyTarget(inst)

    return inst
end

local function SummonHolyLight(x,z,num,radius)
    
    
    local angle=360*math.random()
    local angle_delta=360/num
    for i=1,num do
        local projectile = SpawnPrefab("alter_light")
        projectile.Transform:SetPosition(x + radius*math.cos(angle*DEGREES), 0, z - radius* math.sin(angle*DEGREES))
        angle = angle + angle_delta
    end
end

local function OnConstructed(inst, doer)
    for i, v in ipairs(CONSTRUCTION_PLANS[inst.prefab]) do
        if inst.components.constructionsite:GetMaterialCount(v.type) < v.amount then
            return -- not completed
        end
    end
    inst:EnableCameraFocus(true)
    TheWorld:PushEvent("ms_setclocksegs", {day = 0, dusk = 0, night = 16})
    TheWorld:PushEvent("ms_setmoonphase", {moonphase = "full", iswaxing = false})
    TheWorld:PushEvent("ms_setmoonphasestyle", {style = "alter_active"})

    local x,y,z = inst.Transform:GetWorldPosition()
    if inst._fxpulse ~= nil then
        inst._fxpulse:Remove()
    end
    inst._fxpulse = SpawnPrefab("positronpulse")
    inst._fxpulse.AnimState:SetScale(4,4,4)
    inst._fxpulse.Transform:SetPosition(x, y, z)

    if inst._fxfront ~= nil then
        inst._fxfront:Remove()
    end
    inst._fxfront = SpawnPrefab("positronbeam_front")
    inst._fxfront.AnimState:SetScale(4,4,4)
    inst._fxfront.Transform:SetPosition(x, y, z)

    if inst._fxback ~= nil then
        inst._fxback:Remove()
    end
    inst._fxback = SpawnPrefab("positronbeam_back")
    inst._fxback.AnimState:SetScale(4,4,4)
    inst._fxback.Transform:SetPosition(x, y, z)

    inst.AnimState:SetDeltaTimeMultiplier(0.2)
    inst.AnimState:PlayAnimation("corpse_revive")
    
    
    TheWorld:DoTaskInTime(1,function ()
        SummonHolyLight(x,z,6,3)
    end)
    TheWorld:DoTaskInTime(2.5,function ()
        SummonHolyLight(x,z,6,6)
    end)
    TheWorld:DoTaskInTime(4,function ()
        SummonHolyLight(x,z,6,6)
    end)
    TheWorld:DoTaskInTime(5.5,function ()
        SummonHolyLight(x,z,6,6)
    end)
    TheWorld:DoTaskInTime(7,function ()
        SummonHolyLight(x,z,6,6)
    end)
    inst:ListenForEvent("animover",function (inst)
        if inst._fxpulse ~= nil then
            inst._fxpulse:KillFX()
            inst._fxpulse = nil
        end
        if inst._fxfront ~= nil or inst._fxback ~= nil then
            if inst._fxback ~= nil then
                inst._fxfront:KillFX()
                inst._fxfront = nil
            end
            if inst._fxback ~= nil then
                inst._fxback:KillFX()
                inst._fxback = nil
            end
        end
        inst:EnableCameraFocus(false)
        local new_inst = ReplacePrefab(inst, "ironlord")
        new_inst.sg:GoToState("morph")
    end)
    --inst:Remove()
end


local function buff_OnSave(inst, data)
    if inst.task ~= nil then
        data.remaining = GetTaskRemaining(inst.task)
    end
end

local function buff_OnLoad(inst, data)
    if data == nil then
        return
    end

    if data.remaining then
        if inst.task ~= nil then
            inst.task:Cancel()
            inst.task = nil
        end

        inst.task = inst:DoTaskInTime(data.remaining, inst.Remove)
    end
end

local function buff_OnLongUpdate(inst, dt)
    if inst.task == nil then
        return
    end

    local remaining = GetTaskRemaining(inst.task) - dt

    inst.task:Cancel()

    if remaining > 0 then
        inst.task = inst:DoTaskInTime(remaining, inst.Remove)
    else
        inst:Remove()
    end
end
local function OnFocusCamera(inst)
    local player = TheFocalPoint.entity:GetParent()
    if player ~= nil then
        --Also push a priority 5 focus to block the gate (priority 4)
        --from grabbing focus in case we are out of range of stalker.
        TheFocalPoint.components.focalpoint:StartFocusSource(inst, "moonawakefocus", player, 0, 30, 5)
    else
        TheFocalPoint.components.focalpoint:StopFocusSource(inst, "moonawakefocus")
    end
end

local function OnCameraFocusDirty(inst)
    if inst._camerafocus:value() then
        TheFocalPoint.components.focalpoint:StartFocusSource(inst, nil, nil, 0, 30, 6)
        if inst._camerafocustask == nil then
            inst._camerafocustask = inst:DoPeriodicTask(0, OnFocusCamera)
            OnFocusCamera(inst)
        end
    else
        if inst._camerafocustask ~= nil then
            inst._camerafocustask:Cancel()
            inst._camerafocustask = nil
        end
        TheFocalPoint.components.focalpoint:StopFocusSource(inst)
    end
end

local function EnableCameraFocus(inst, enable)
    if enable ~= inst._camerafocus:value() then
        inst._camerafocus:set(enable)
        if not TheNet:IsDedicated() then
            OnCameraFocusDirty(inst)
        end
    end
end

local function deathfn()
    local inst = CreateEntity()

	inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.Transform:SetNoFaced()

    MakeObstaclePhysics(inst, 0.5*SCALE)
    
    MakeAnim(inst,"death2_idle")
    inst.AnimState:SetErosionParams(0, 0.1, -1)
    inst:AddTag("laser_immune")
    inst:AddTag("mech")

    inst._camerafocus = net_bool(inst.GUID, "ironlord._camerafocus", "camerafocusdirty")
    inst._camerafocustask = nil

	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		return inst
	end	

    inst:AddComponent("inspectable")

    inst:AddComponent("constructionsite")
    inst.components.constructionsite:SetConstructionPrefab("construction_container")
    inst.components.constructionsite:SetOnConstructedFn(OnConstructed)

    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end

    inst.task = inst:DoTaskInTime(5*480, inst.Remove)

    inst.OnSave = buff_OnSave
    inst.OnLoad = buff_OnLoad
    inst.EnableCameraFocus = EnableCameraFocus
    inst.OnLongUpdate = buff_OnLongUpdate

    return inst
end

return Prefab( "ironlord", fn, assets),
    Prefab("ironlord_death",deathfn,assets)
