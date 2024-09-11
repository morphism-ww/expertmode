require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.GOHOME, "action"),
}


local events =
{
    EventHandler("attacked", function(inst)
        if not (inst.sg:HasStateTag("attack") or inst.sg:HasStateTag("hit") or inst.sg:HasStateTag("noattack") or inst.components.health:IsDead())
            and not CommonHandlers.HitRecoveryDelay(inst,4,1) then
            inst.sg:GoToState("hit")
        end
    end),
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    EventHandler("doattack", function(inst, data)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead())
            and (data.target ~= nil and data.target:IsValid()) then
            inst.sg:GoToState("attack", data.target)
        end
    end),
    EventHandler("wave_atk",function(inst)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
            if inst.dread then
                inst.sg:GoToState("wave_attack2")
            else
                inst.sg:GoToState("wave_attack")
            end    
            
        end
    end),
    EventHandler("fire_atk",function(inst)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
            inst.sg:GoToState("shadowfire")
        end
    end),
    EventHandler("teleport_atk",function (inst)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
            inst.sg:GoToState("teleport_attack",inst.components.combat.target)
        end
    end),
    CommonHandlers.OnLocomote(false, true),
}

local function onattackreflected(inst)
	inst.sg.statemem.attackreflected = true
end

local function FinishExtendedSound(inst, soundid)
    inst.SoundEmitter:KillSound("sound_"..tostring(soundid))
    inst.sg.mem.soundcache[soundid] = nil
    if inst.sg.statemem.readytoremove and next(inst.sg.mem.soundcache) == nil then
        inst:Remove()
    end
end

local function PlayExtendedSound(inst, soundname)
    if inst.sg.mem.soundcache == nil then
        inst.sg.mem.soundcache = {}
        inst.sg.mem.soundid = 0
    else
        inst.sg.mem.soundid = inst.sg.mem.soundid + 1
    end
    inst.sg.mem.soundcache[inst.sg.mem.soundid] = true
    inst.SoundEmitter:PlaySound(inst.sounds[soundname], "sound_"..tostring(inst.sg.mem.soundid))
    inst:DoTaskInTime(5, FinishExtendedSound, inst.sg.mem.soundid)
end

local function OnAnimOverRemoveAfterSounds(inst)
    if inst.sg.mem.soundcache == nil or next(inst.sg.mem.soundcache) == nil then
        inst:Remove()
    else
        inst:Hide()
        inst.sg.statemem.readytoremove = true
    end
end

local function TryShadowFire(inst,target,pos)
    local startangle
    if pos~=nil then
        startangle = inst:GetAngleToPoint(pos.x,pos.y,pos.z)*DEGREES
    else
        startangle=0
    end
    local burst = 3
    --[[local pct=doer.components.health:GetPercent()
    if pct<0.1 then
        burst=8
    elseif pct<0.2 then
        burst=6
    end]]
    local radius = 2
    local lifetime = inst.dread and 25 or 15
    local anglelist={startangle-PI/2,startangle,startangle+PI/2}
    for i=1,burst do
        
        local theta = anglelist[i]
        local offset = Vector3(radius * math.cos( theta ), 0, -radius * math.sin( theta ))

        local newpos = Vector3(inst.Transform:GetWorldPosition()) + offset
        
        local fire = SpawnPrefab("shadow_flame")
        fire.Transform:SetRotation(theta/DEGREES)
        fire.Transform:SetPosition(newpos.x,newpos.y,newpos.z)
        
        if inst.dread then
            fire:settargetdread(target,lifetime,inst)
            fire.components.weapon:SetDamage(120)
        else
            fire:settarget(target,lifetime,inst)
        end    
    end
end
local function TryShadowWave(inst,target)
    local position=inst:GetPosition()
    --totalangle=360
    local anglePerWave=30
    local x, y, z = target.Transform:GetWorldPosition()
    local rot = inst:GetAngleToPoint(x, y, z)
    for i = -1, 1 do
        local angle = rot + (i * anglePerWave)
        local offset_direction = Vector3(math.cos(angle*DEGREES), 0, -math.sin(angle*DEGREES)):Normalize()
        local wavepos = position + (offset_direction * 2)
        local wave = SpawnPrefab("shadowwave")
        wave.Transform:SetPosition(wavepos:Get())
        wave.Transform:SetRotation(angle)
        wave.Physics:SetMotorVel(14, 0, 0)
    end
end


local function TryWave2(inst,angle)
    local position=inst:GetPosition()
    --totalangle=360
    local anglePerWave = 360/8
    local rot = angle
    for i = 1, 8 do
        local offset_direction = Vector3(math.cos(rot*DEGREES), 0, -math.sin(rot*DEGREES)):Normalize()
        local wavepos = position + (offset_direction * 2)
        local wave = SpawnPrefab("shadowwave")
        wave.Transform:SetPosition(wavepos:Get())
        wave.Transform:SetRotation(rot)
        rot = rot + anglePerWave
        wave.Physics:SetMotorVel(14, 0, 0)
    end
end
local states =
{
    State{
        name = "idle",
        tags = { "idle", "canrotate" },

        onenter = function(inst)
            if inst.wantstodespawn then
                local t = GetTime()
                if t > inst.components.combat:GetLastAttackedTime() + 5 then
                    local target = inst.components.combat.target
                    if target == nil or
                        target.components.combat == nil or
                        not target.components.combat:IsRecentTarget(inst) or
                        t > 10 then
                        inst.sg:GoToState("disappear")
                        return
                    end
                end
            end
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("idle", true)

        end,
    },

    State{
        name = "attack",
        tags = { "attack", "busy" },

        onenter = function(inst, target)
            inst.sg.statemem.target = target
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk")
            PlayExtendedSound(inst, "attack_grunt")
        end,

        timeline =
        {
            FrameEvent(10, function(inst) PlayExtendedSound(inst, "attack") end),
			FrameEvent(20, function(inst)
				--The stategraph event handler is delayed, so it won't be
				--accurate for detecting attacks due to damage reflection
				inst:ListenForEvent("attacked", onattackreflected)
				inst.components.combat:DoAttack(inst.sg.statemem.target)
				inst:RemoveEventCallback("attacked", onattackreflected)
			end),
			FrameEvent(12, function(inst)
				if inst.sg.statemem.attackreflected and not inst.components.health:IsDead() then
					inst.sg:GoToState("hit")
				end
			end),
        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                if math.random() < .333 then
                    inst.components.combat:SetTarget(nil)
                    inst.sg:GoToState("taunt")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },
    State{
        name = "teleport_attack",
        tags = { "attack", "busy" },

        onenter = function(inst, target)
            inst.sg.statemem.target = target
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("disappear")
            inst.AnimState:PushAnimation("atk",false)
            PlayExtendedSound(inst, "attack_grunt")
        end,

        timeline =
        {
            FrameEvent(20, function(inst) 
                PlayExtendedSound(inst, "attack") 
                if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                    inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())
                    inst.sg.statemem.targetpos = inst.sg.statemem.target:GetPosition()
                end
            end),
            FrameEvent(25,function (inst)
                if inst.sg.statemem.targetpos then
                    inst.Physics:Teleport(inst.sg.statemem.targetpos:Get())
                end
            end),
			FrameEvent(45, function(inst)
				inst.components.combat:DoAttack(inst.sg.statemem.target)
			end),

        },

        events =
        {
            EventHandler("animqueueover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },
    State{
        name = "shadowfire",
        tags = {"attack", "busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("taunt")
            inst.SoundEmitter:PlaySound(inst.sounds.attack_grunt)
        end,

        timeline=
        {
            TimeEvent(25*FRAMES, function(inst)
                local target=inst.components.combat.target
                if target~=nil then
                    TryShadowFire(inst,target,target:GetPosition())
                end
            end),
        },

        events=
        {
            EventHandler("animover", function(inst)
                inst.components.timer:StartTimer("fire_cd",TUNING.SHAODWDRAGON_FIRECD)
                if math.random() < .333 then
                    inst.sg:GoToState("taunt")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },
    State{
        name = "wave_attack",
        tags = {"attack", "busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk")
            inst.SoundEmitter:PlaySound(inst.sounds.attack_grunt)
        end,

        timeline=
        {
            TimeEvent(25*FRAMES, function(inst)
                local target=inst.components.combat.target
                if target~=nil and target:IsValid() then
                    TryShadowWave(inst,target)
                end
            end),
        },

        events=
        {
            EventHandler("animover", function(inst)
                inst.components.timer:StartTimer("wave_cd",TUNING.SHAODWDRAGON_WAVECD)
                if math.random() < .333 then
                    --inst.components.combat:SetTarget(nil)
                    inst.sg:GoToState("taunt")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },
    State{
        name = "wave_attack2",
        tags = {"attack", "busy"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("taunt")
            inst.SoundEmitter:PlaySound(inst.sounds.attack_grunt)
            local target = inst.components.combat.target
            if target and target:IsValid() then
                inst.sg.statemem.rot = inst:GetAngleToPoint(target.Transform:GetWorldPosition())
            end
        end,

        timeline=
        {
            TimeEvent(20*FRAMES,function (inst)
                if inst.sg.statemem.rot then
                    TryWave2(inst,inst.sg.statemem.rot)
                end 
            end),
            TimeEvent(40*FRAMES,function (inst)
                if inst.sg.statemem.rot then
                    TryWave2(inst,inst.sg.statemem.rot+360/16)
                end 
            end)
        },
        events=
        {
            EventHandler("animover", function(inst)
                inst.components.timer:StartTimer("wave_cd",11)
                if math.random() < .333 then
                    --inst.components.combat:SetTarget(nil)
                    inst.sg:GoToState("taunt")
                else
                    inst.sg:GoToState("idle")
                end
            end),
        },
    },    
    State{
        name = "hit",
        tags = { "busy", "hit" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("disappear")
            CommonHandlers.UpdateHitRecoveryDelay(inst)
        end,

        events =
        {
            EventHandler("animover", function(inst)
                local pos=inst:GetPosition()
                local offset = FindWalkableOffset(pos, 2*PI*math.random(),8+4*math.random(), 8)
                if offset then
                    pos = pos + offset
                    inst.Transform:SetPosition(pos:Get())
                end
                inst.sg:GoToState("appear")
            end),
        },
    },

    State{
        name = "taunt",
        tags = { "busy" },

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("taunt")
            PlayExtendedSound(inst, "taunt")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "appear",
        tags = { "busy" },

        onenter = function(inst)
            inst.AnimState:PlayAnimation("appear")
            inst.Physics:Stop()
            PlayExtendedSound(inst, "appear")
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end)
        },
    },

    State{
        name = "death",
        tags = { "busy" },

        onenter = function(inst)
            PlayExtendedSound(inst, "death")
            inst.AnimState:PlayAnimation("disappear")
            inst.Physics:Stop()
            RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(inst:GetPosition())
            inst:AddTag("NOCLICK")
            inst.persists = false
        end,

        events =
        {
            EventHandler("animover", OnAnimOverRemoveAfterSounds),
        },

        onexit = function(inst)
            inst:RemoveTag("NOCLICK")
        end
    },

    State{
        name = "disappear",
        tags = { "busy", "noattack" },

        onenter = function(inst)
            PlayExtendedSound(inst, "death")
            inst.AnimState:PlayAnimation("disappear")
            inst.Physics:Stop()
            inst:AddTag("NOCLICK")
            inst.persists = false
        end,

        events =
        {
            EventHandler("animover", OnAnimOverRemoveAfterSounds),
        },

        onexit = function(inst)
            inst:RemoveTag("NOCLICK")
        end,
    },

    State{
        name = "action",
        onenter = function(inst, playanim)
            inst.Physics:Stop()
            inst:PerformBufferedAction()
        end,

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
}
CommonStates.AddWalkStates(states)

return StateGraph("shadowdragon", states, events, "appear", actionhandlers)
