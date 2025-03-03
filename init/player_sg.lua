local AddStategraphEvent = AddStategraphEvent
local AddStategraphActionHandler = AddStategraphActionHandler
local AddStategraphState = AddStategraphState
local AddStategraphPostInit = AddStategraphPostInit
GLOBAL.setfenv(1,GLOBAL)

local TIMEOUT = 2

---stun_protect  moving_attack
local function DoHurtSound(inst)
    if inst.hurtsoundoverride ~= nil then
        inst.SoundEmitter:PlaySound(inst.hurtsoundoverride, nil, inst.hurtsoundvolume)
    elseif not inst:HasTag("mime") then
        inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/")..(inst.soundsname or inst.prefab).."/hurt", nil, inst.hurtsoundvolume)
    end
end
local function OnRemoveCleanupTargetFX(inst)
    if inst.sg.statemem.targetfx.KillFX ~= nil then
        inst.sg.statemem.targetfx:RemoveEventCallback("onremove", OnRemoveCleanupTargetFX, inst)
        inst.sg.statemem.targetfx:KillFX()
    else
        inst.sg.statemem.targetfx:Remove()
    end
end
local function DoMountSound(inst, mount, sound, ispredicted)
    if mount ~= nil and mount.sounds ~= nil then
        inst.SoundEmitter:PlaySound(mount.sounds[sound], nil, nil, ispredicted)
    end
end

local function ToggleOffPhysics(inst)
    inst.sg.statemem.isphysicstoggle = true
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
end

local function ToggleOnPhysics(inst)
    inst.sg.statemem.isphysicstoggle = nil
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.WORLD)
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.SMALLOBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.GIANTS)
end

AddStategraphPostInit("wilson", function(sg)

    local old_attacked = sg.events["attacked"].fn
    sg.events["attacked"].fn = function (inst,data)
        if inst._stunprotecter:Get() then
            inst.sg:AddStateTag("nointerrupt")
        end
        old_attacked(inst,data)
    end
    
    sg.events.knockback.fn = function(inst, data)
        if not inst.components.health:IsDead() then
            if inst:HasTag("wereplayer") then
                inst.sg.mem.laststuntime = GetTime()
                if data ~= nil then
                    data = shallowcopy(data)
                    data.repeller = data.knocker
                    inst.sg:GoToState("repelled", data)
                else
                    inst.sg:GoToState("hit")
                end
            elseif inst.sg:HasStateTag("parrying") then
                inst.sg.statemem.parrying = true
                inst.sg:GoToState("parry_knockback", {
                    timeleft =
                        (inst.sg.statemem.task ~= nil and GetTaskRemaining(inst.sg.statemem.task)) or
                        (inst.sg.statemem.timeleft ~= nil and math.max(0, inst.sg.statemem.timeleft + inst.sg.statemem.timeleft0 - GetTime())) or
                        inst.sg.statemem.parrytime,
                    knockbackdata = data,
                    isshield = inst.sg.statemem.isshield,
                })
            elseif inst.components.rider:IsRiding() and inst.components.rider:TryResist() then
                inst.sg:GoToState("repelled",{repeller =data.knocker, radius = data.radius})
            else
                inst.sg:GoToState((data.forcelanded or inst.components.inventory:EquipHasTag("heavyarmor") or inst:HasTag("heavybody")) and "knockbacklanded" or "knockback", data)
            end
        end
    end


    sg.states["death_hosted"].events["animover"].fn = function (inst)
        if inst.AnimState:AnimDone() then
            inst.sg:GoToState("death",{hosted=true})
        end
    end

    sg.states["devoured"].timeline = {
        TimeEvent(0.5, function(inst)
            inst.components.newcs_talisman:TryKillThreat(inst.sg.statemem.attacker)
        end),
    }

    local actionhandlers = sg.actionhandlers
    local Attack_Old = actionhandlers[ACTIONS.ATTACK].deststate

    actionhandlers[ACTIONS.ATTACK].deststate=function(inst, action)
        inst.sg.mem.localchainattack = not action.forced or nil
        local playercontroller = inst.components.playercontroller
        local attack_tag =
            playercontroller ~= nil and
            playercontroller.remote_authority and
            playercontroller.remote_predicting and
            "abouttoattack" or
            "attack"
        if not (inst.sg:HasStateTag(attack_tag) and action.target == inst.sg.statemem.attacktarget or inst.components.health:IsDead()) then
            local weapon = inst.components.combat ~= nil and inst.components.combat:GetWeapon() or nil
            if weapon~=nil then
                if weapon:HasTag("quick_attack") then
                    return "quick_attack"
                elseif weapon:HasTag("scythe_attack")  then
                    return  "scythe_attack"
                end    
            end
            
        end
        return  Attack_Old(inst,action)
    end    
    actionhandlers[ACTIONS.CHOP].deststate = function (inst)
        if inst:HasTag("beaver") then
            return not inst.sg:HasStateTag("gnawing") and "gnaw" or nil
        end
        return not inst.sg:HasStateTag("prechop")
            and (inst:HasTag("laserworker") and "laserwork"
            or (inst.sg:HasStateTag("chopping") and
                "chop" or
                "chop_start"))
            or nil
    end

    actionhandlers[ACTIONS.MINE].deststate = function (inst)
        if inst:HasTag("beaver") then
            return not inst.sg:HasStateTag("gnawing") and "gnaw" or nil
        end
        return not inst.sg:HasStateTag("premine")
            and (inst:HasTag("laserworker") and "laserwork"
            or (inst.sg:HasStateTag("mining") and
                "mine" or
                "mine_start"))
            or nil
    end

    actionhandlers[ACTIONS.HAMMER].deststate = function (inst)
        if inst:HasTag("beaver") then
            return not inst.sg:HasStateTag("gnawing") and "gnaw" or nil
        end
        return not inst.sg:HasStateTag("prehammer")
            and (inst:HasTag("laserworker") and "laserwork"
            or (inst.sg:HasStateTag("hammering") and
                "hammer" or
                "hammer_start"))
            or nil
    end
end)

AddStategraphPostInit("wilson_client",function (sg)
    local actionhandlers = sg.actionhandlers
    local ClientAttack_Old = actionhandlers[ACTIONS.ATTACK].deststate
    actionhandlers[ACTIONS.ATTACK].deststate=function(inst, action)
        if not (inst.sg:HasStateTag("attack") and action.target == inst.sg.statemem.attacktarget or IsEntityDead(inst)) then
            local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equip~=nil then
                if equip:HasTag("quick_attack") then
                    return "quick_attack"
                elseif equip:HasTag("scythe_attack") then
                    return  "scythe_attack"
                end
            end    
            
        end
        return  ClientAttack_Old(inst,action)
    end
    actionhandlers[ACTIONS.CHOP].deststate = function (inst)
        if inst:HasTag("beaver") then
            return not (inst.sg:HasStateTag("gnawing") or inst:HasTag("gnawing")) and "gnaw" or nil
        end
        return not (inst.sg:HasStateTag("prechop") or inst:HasTag("c"))
            and (inst:HasTag("laserworker") and "laserwork" or "chop_start") or nil
    end 
    actionhandlers[ACTIONS.MINE].deststate = function (inst)
        if inst:HasTag("beaver") then
            return not (inst.sg:HasStateTag("gnawing") or inst:HasTag("gnawing")) and "gnaw" or nil
        end
        return not (inst.sg:HasStateTag("premine") or inst:HasTag("premine"))
            and (inst:HasTag("laserworker") and "laserwork" or "mine_start") or nil
    end
    actionhandlers[ACTIONS.HAMMER].deststate = function (inst)
        if inst:HasTag("beaver") then
            return not (inst.sg:HasStateTag("gnawing") or inst:HasTag("gnawing")) and "gnaw" or nil
        end
        return not (inst.sg:HasStateTag("prehammer") or inst:HasTag("prehammer"))
            and (inst:HasTag("laserworker") and "laserwork" or "hammer_start") or nil
    end   
end)


AddStategraphState("wilson",State{
    name = "scythe_attack",
    tags = {"attack", "notalking", "abouttoattack", "autopredict","nointerrupt"},

    onenter = function(inst)
        if inst.components.combat:InCooldown() then
            inst.sg:RemoveStateTag("abouttoattack")
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle", true)
            return
        end
        inst.components.combat:StartAttack()
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("scythe_pre")
        inst.AnimState:PushAnimation("scythe_loop", false)
        local buffaction = inst:GetBufferedAction()
        local target = buffaction ~= nil and buffaction.target or nil
        
        inst.components.combat:SetTarget(target)
        inst.components.locomotor:Stop()
  

        if target ~= nil then
            inst.components.combat:BattleCry()
            if target:IsValid() then
                inst:FacePoint(target:GetPosition())
                inst.sg.statemem.attacktarget = target
                inst.sg.statemem.retarget = target
            end
        end
    end,

    timeline =
    {
        FrameEvent(12, function(inst) inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh") end),
        FrameEvent(13, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
            inst:PerformBufferedAction()
            inst.sg:RemoveStateTag("abouttoattack")
        end),
        FrameEvent(18, function(inst)
            inst.sg:RemoveStateTag("attack")
        end),
        FrameEvent(22, function(inst)
            inst.sg:GoToState("idle", true)
        end),
    },

    events =
    {   EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
    },
    onexit = function(inst)
        inst.components.combat:SetTarget(nil)
        if inst.sg:HasStateTag("abouttoattack") then
            inst.components.combat:CancelAttack()
        end
    end,
})


AddStategraphState("wilson_client",State{
    name = "scythe_attack",
    tags = {"attack", "notalking", "autopredict","nointerrupt"},

    onenter = function(inst)
        local combat = inst.replica.combat
        if combat:InCooldown() then
            inst.sg:RemoveStateTag("abouttoattack")
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle", true)
            return
        end

        combat:StartAttack()
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("scythe_pre")
        inst.AnimState:PushAnimation("scythe_loop", false)
        local buffaction = inst:GetBufferedAction()
        if buffaction ~= nil then
            inst:PerformPreviewBufferedAction()

            if buffaction.target ~= nil and buffaction.target:IsValid() then
                inst:FacePoint(buffaction.target:GetPosition())
                inst.sg.statemem.attacktarget = buffaction.target
                inst.sg.statemem.retarget = buffaction.target
            end
        end
    end,

    timeline =
    {
        FrameEvent(12, function(inst) inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh") end),
        FrameEvent(13, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
            inst:ClearBufferedAction()
            inst.sg:RemoveStateTag("abouttoattack")
        end),
        FrameEvent(18, function(inst)
            inst.sg:RemoveStateTag("attack")
        end),
        FrameEvent(22, function(inst)
            inst.sg:GoToState("idle", true)
        end),
    },

    events =
    {   EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
    },
    onexit = function(inst)
        if inst.sg:HasStateTag("abouttoattack") then
            inst.replica.combat:CancelAttack()
        end
    end,
})

AddStategraphState("wilson",State{
    name = "laserwork",
    tags = { "prehammer","premine","prechop", "working" },
    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.sg.statemem.action = inst:GetBufferedAction()
        inst.AnimState:PlayAnimation("toolpunch")
        inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon", nil, nil, true)
    end,
    timeline =
    {
        TimeEvent(7 * FRAMES, function(inst)
            if inst.sg.statemem.action ~= nil then
                local target = inst.sg.statemem.action.target
                if target ~= nil and target:IsValid() then
                    if inst.sg.statemem.action.action == ACTIONS.MINE then
                        PlayMiningFX(inst, target)
                    elseif inst.sg.statemem.action.action == ACTIONS.HAMMER then
                        inst.sg.statemem.rmb = true
                        inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
                    end
                end
            end
            inst:PerformBufferedAction()
        end),

        TimeEvent(8 * FRAMES, function(inst)
            inst.sg:RemoveStateTag("prehammer")
            inst.sg:RemoveStateTag("premine")
            inst.sg:RemoveStateTag("prechop")
        end),

        TimeEvent(10 * FRAMES, function(inst)
            if inst.sg.statemem.action == nil or
                inst.sg.statemem.action.action == nil or
                inst.components.playercontroller == nil then
                return
            end
            if inst.sg.statemem.rmb then
                if not inst.components.playercontroller:IsAnyOfControlsPressed(
                        CONTROL_SECONDARY,
                        CONTROL_CONTROLLER_ALTACTION) then
                    return
                end
            elseif not inst.components.playercontroller:IsAnyOfControlsPressed(
                        CONTROL_PRIMARY,
                        CONTROL_ACTION,
                        CONTROL_CONTROLLER_ACTION) then
                return
            end
            if inst.sg.statemem.action:IsValid() and
                inst.sg.statemem.action.target ~= nil and
                inst.sg.statemem.action.target.components.workable ~= nil and
                inst.sg.statemem.action.target.components.workable:CanBeWorked() and
                inst.sg.statemem.action.target.components.workable:GetWorkAction() == inst.sg.statemem.action.action and
                CanEntitySeeTarget(inst, inst.sg.statemem.action.target) then
                --No fast-forward when repeat initiated on server
                inst.sg.statemem.action.options.no_predict_fastforward = true
                inst:ClearBufferedAction()
                inst:PushBufferedAction(inst.sg.statemem.action)
            end
        end),
    },

    events =
    {   
        EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end),
    },
})



AddStategraphState("wilson_client",State{
    name = "laserwork",
    tags = { "prehammer","premine","prechop", "working" },
    server_states = { "laserwork" },
    onenter = function(inst)
        inst.components.locomotor:Stop()
        if not inst.sg:ServerStateMatches() then
            inst.AnimState:PlayAnimation("toolpunch")
        end
        inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon", nil, nil, true)
        inst:PerformPreviewBufferedAction()
        inst.sg:SetTimeout(TIMEOUT)
    end,
    onupdate = function(inst)
        if inst.sg:ServerStateMatches() then
            if inst.entity:FlattenMovementPrediction() then
                inst.sg:GoToState("idle", "noanim")
            end
        elseif inst.bufferedaction == nil then
            inst.sg:GoToState("idle")
        end
    end,

    ontimeout = function(inst)
        inst:ClearBufferedAction()
        inst.sg:GoToState("idle")
    end,
})

AddStategraphActionHandler("wilson",ActionHandler(ACTIONS.LUNGE,"playerlunge_start"))
AddStategraphActionHandler("wilson_client",ActionHandler(ACTIONS.LUNGE,"playerlunge_start"))

AddStategraphState("wilson_client",State{
    name = "playerlunge_start",
    tags = { "doing", "busy", "nointerrupt" },
    server_states = { "playerlunge_start", "playerlunge" },

    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("atk_pre")
        --inst.AnimState:PushAnimation("lunge_lag", false)
        inst:PerformPreviewBufferedAction()
        inst.sg:SetTimeout(2)
    end,


    onupdate = function(inst)
        if inst.sg:ServerStateMatches() then
            inst.sg:GoToState("idle", "noanim")
        elseif inst.bufferedaction == nil then
            inst.sg:GoToState("idle")
        end
    end,

    ontimeout = function(inst)
        inst.sg:GoToState("idle")
    end,
})

AddStategraphState("wilson",State{
    name = "playerlunge_start",
    tags = { "charge", "doing", "busy", "nointerrupt", "nomorph" },

    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("atk_pre")
        --inst:ForceFacePoint(inst.bufferedaction:GetActionPoint())
    end,

    events =
    {

        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                if inst.AnimState:IsCurrentAnimation("atk_pre") then
                    inst:PerformBufferedAction()
                    --inst.sg:GoToState("playerlunge")
                else
                    
                    inst.sg:GoToState("idle")
                end
            end
        end),
    },
})

AddStategraphState("wilson",State{
    name = "playerlunge",
    tags = { "charge",  "busy", "nointerrupt" ,"nopredict"},

    onenter = function(inst)
        inst.components.health:SetInvincible(true)
       
        inst.AnimState:PlayAnimation("lunge_pst")
        
        inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/fireball")
        local x, y, z = inst.Transform:GetWorldPosition()
        local theta = inst.Transform:GetRotation() * DEGREES
        local cos_theta = math.cos(theta)
        local sin_theta = math.sin(theta)
        local map = TheWorld.Map
        local pt = Vector3(0, 0, 0)
        local success = false
        for i = 12.5, 7,-0.5 do
            pt.x = x + cos_theta * (i - 0.5)
            pt.z = z - sin_theta * (i - 0.5)
            if map:IsPassableAtPoint(pt:Get()) then
                pt.x = x + cos_theta * (i + 0.5)
                pt.z = z - sin_theta * (i + 0.5)
                if map:IsPassableAtPoint(pt:Get()) then
                    pt.x = x + cos_theta * i
                    pt.z = z - sin_theta * i
                    if not map:IsPointNearHole(pt) then
                        success = true
                        break
                    end
                end
            end
        end
        if not success then
            for i = 6.5, 0.5, -0.5 do
                pt.x = x + cos_theta * (i - 0.5)
                pt.z = z - sin_theta * (i - 0.5)
                if map:IsPassableAtPoint(pt:Get()) then
                    pt.x = x + cos_theta * (i + 0.5)
                    pt.z = z - sin_theta * (i + 0.5)
                    if map:IsPassableAtPoint(pt:Get()) then
                        pt.x = x + cos_theta * i
                        pt.z = z - sin_theta * i
                        if not map:IsPointNearHole(pt) then
                            success = true
                            break
                        end
                    end
                end
            end
        end
        inst.Physics:Stop()
        if success then
            x, y, z = pt:Get()
            inst.Physics:Teleport(x, y, z)
        else
            inst.sg:GoToState("idle")
        end
        
        local fx = SpawnPrefab("spear_wathgrithr_lightning_lunge_fx")
        fx.Transform:SetPosition(x, 0, z)
        fx.Transform:SetRotation(inst:GetRotation())

        inst.components.bloomer:PushBloom("lunge", "shaders/anim.ksh", -2)
        inst.components.colouradder:PushColour("lunge", 1, 1, 0, 0)
        inst.sg.statemem.flash = 1
    end,

    onupdate = function(inst)
        if inst.sg.statemem.flash and inst.sg.statemem.flash > 0 then
            inst.sg.statemem.flash = math.max(0, inst.sg.statemem.flash - .1)
            inst.components.colouradder:PushColour("lunge", inst.sg.statemem.flash, inst.sg.statemem.flash, 0, 0)
        end
    end,


    timeline =
    {
        TimeEvent(12 * FRAMES, function(inst)
            inst.components.bloomer:PopBloom("lunge")
        end),
    },

    events =
    {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end),
    },

    onexit = function(inst)

        inst.components.health:SetInvincible(false)
        inst.components.bloomer:PopBloom("lunge")
        inst.components.colouradder:PopColour("lunge")
    end,
})

AddStategraphActionHandler("wilson",ActionHandler(ACTIONS.SHADOWDODGE,"shadowdodge_pre"))
AddStategraphActionHandler("wilson_client",ActionHandler(ACTIONS.SHADOWDODGE,"shadowdodge"))

AddStategraphActionHandler("wilson",ActionHandler(ACTIONS.DOTOWNPORTAL_MAP,"entertownportal2"))

AddStategraphActionHandler("wilson",ActionHandler(ACTIONS.AURUMITE_REPAIR, "dolongaction"))
AddStategraphActionHandler("wilson_client",ActionHandler(ACTIONS.AURUMITE_REPAIR, "dolongaction"))

AddStategraphState("wilson",State{
    name = "entertownportal2",
    tags = { "doing", "busy", "nopredict", "nomorph", "nodangle" },

    onenter = function(inst)
        ToggleOffPhysics(inst)
        inst.Physics:Stop()
        inst.components.locomotor:Stop()
        
        local buffaction = inst:GetBufferedAction()
        if buffaction ~= nil and buffaction.pos ~= nil and buffaction.invobject then
            local pt = buffaction:GetActionPoint()
            local ents = TheSim:FindEntities(pt.x, 0, pt.z, 12, {"townportal"},{"townportaltalisman"})
            if ents[1]~=nil then
                --act.invobject.components.teleporter.targetTeleporterTemporary = ents[1]
                inst.sg.statemem.teletarget = ents[1]
                
                inst.sg.statemem.target = buffaction.invobject
            end    
        end        
        inst.sg.statemem.teleportarrivestate = "exittownportal_pre"

        inst.AnimState:PlayAnimation("townportal_enter_pre")

        inst.sg.statemem.fx = SpawnPrefab("townportalsandcoffin_fx")
        inst.sg.statemem.fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    end,

    timeline =
    {
        TimeEvent(8 * FRAMES, function(inst)
            inst.sg.statemem.isteleporting = true
            inst.components.health:SetInvincible(true)
            if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(false)
            end
            inst.DynamicShadow:Enable(false)
        end),
        TimeEvent(18 * FRAMES, function(inst)
            inst:Hide()
        end),
        TimeEvent(26 * FRAMES, function(inst)
            inst:ClearBufferedAction()
            if inst.sg.statemem.target ~= nil and inst.sg.statemem.teletarget~=nil 
                and inst.sg.statemem.target.components.teleporter:UseTemporaryExit(inst, inst.sg.statemem.teletarget) then
                inst:Hide()
                inst.sg.statemem.fx:KillFX()
            else
                inst.sg:GoToState("exittownportal")
            end
            
            
        end),
    },

    onexit = function(inst)
        inst.sg.statemem.fx:KillFX()

        if inst.sg.statemem.isphysicstoggle then
            ToggleOnPhysics(inst)
        end

        if inst.sg.statemem.isteleporting then
            inst.components.health:SetInvincible(false)
            --[[if inst.components.playercontroller ~= nil then
                inst.components.playercontroller:Enable(true)
            end]]
            inst:Show()
            inst.DynamicShadow:Enable(true)
        end
    end,
})



AddStategraphState("wilson", State
{
    name = "shadowdodge_pre",
    tags = {"busy"},

    onenter = function(inst)
        --dumptable(inst:GetBufferedAction(),1,1,1)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("wortox_portal_jumpin_pre")  
    end,
    timeline =
    {
        FrameEvent(3, function(inst)
            if not inst:PerformBufferedAction() then
                inst.sg:GoToState("idle")
                return
            end
            inst.components.sanity:GetSoulAttacked(nil, 3)
            --@V2C:
            --Start physics early; normally done in "dash" state with "nopredict".
            --Prevents client from seeing slight snapback before dashing forward.
            --Must manually update client's position (using Teleport) if interrupted.
            inst.Physics:SetMotorVel(30, 0, 0)

            inst.components.colouradder:ForceMultColor(0.25, 0.25, 0.25, 1)
            
        end)
    },
    events =
    {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("shadowdodge")
            end
        end),
    },
    onexit = function(inst)
        
        local x, y, z = inst.Transform:GetWorldPosition()
        inst.Physics:Stop()
        inst.Physics:Teleport(x, 0, z)
        
        inst.components.colouradder:ClearMultColor()
            
        
    end,
})
AddStategraphState("wilson", State
{
    name = "shadowdodge",
    tags = { "busy", "jumping", "nopredict", "noattack", "iframeskeepaggro" },

    onenter = function(inst)
        inst.Physics:SetMotorVel(30, 0, 0)


        inst.components.health:SetInvincible(true)
        --[[if inst.components.playercontroller then
            inst.components.playercontroller:Enable(false)
        end]]
        inst.components.colouradder:ForceMultColor(0,0,0,0)
        inst.DynamicShadow:Enable(false)
        inst.AnimState:PlayAnimation("wortox_portal_jumpin")
        ToggleOffPhysics(inst)
        --inst.sg.statemem.isphysicstoggle = true
        --inst.Physics:SetCollisionMask(COLLISION.WORLD)

        --player hidden via 0 alpha instead of Hide(), so that we can still see silhoutte child
        --inst.sg.statemem.silhoutte = SpawnPrefab("woby_dash_silhouette_fx")
        --inst.sg.statemem.silhoutte.entity:SetParent(inst.entity)

        local fx = SpawnPrefab("woby_dash_shadow_fx")
        fx.AnimState:SetFrame(3)
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        --fx:SetFxOwner(inst) --don't track owner, keep fx stationary
        fx.SoundEmitter:PlaySound("meta5/woby/shadow_dash_out")

    end,

    timeline =
    {
        FrameEvent(2, function(inst)
            local x, y, z = inst.Transform:GetWorldPosition()
            local fx = SpawnPrefab("woby_dash_shadow_fx")
            fx.AnimState:PlayAnimation("woby_teleport_fx_small"..tostring(math.random(2)))
            fx.Transform:SetPosition(x, y, z)
            fx:SetFxOwner(inst)
            --fx:SetFxOwner(inst) --don't track owner, keep fx stationary
            fx.SoundEmitter:PlaySound("meta5/woby/shadow_dash_in")
        end),
        FrameEvent(5, PlayFootstep),
        FrameEvent(7, function(inst)
            inst.sg.statemem.dashing = true
            inst.sg:GoToState("shadowdodge_pst", true)
            inst.sg.statemem.isphysicstoggle = true
        end),
    },


    onexit = function(inst)
        

        inst.components.health:SetInvincible(false)
        --[[if inst.components.playercontroller then
            inst.components.playercontroller:Enable(true)
        end]]
        inst.DynamicShadow:Enable(true)
        ToggleOnPhysics(inst)
        if not inst.sg.statemem.dashing then
            inst.components.colouradder:ClearMultColor()
            inst.Physics:Stop()
        end
        --inst.sg.statemem.silhoutte:Remove()
    end,
})

AddStategraphState("wilson", State
{
    name = "shadowdodge_pst",
    tags = {"jumping", "nopredict","busy"},

    onenter = function(inst)
        inst.AnimState:PlayAnimation("run_pst")
    end,
    timeline =
    {
        FrameEvent(0, function(inst)
            inst.Physics:SetMotorVel(16, 0, 0)
            inst.components.colouradder:ForceMultColor(0.1,0.1,0.1,1)
        end),
        FrameEvent(1, function(inst)
            inst.Physics:SetMotorVel(12, 0, 0)
            inst.components.colouradder:ForceMultColor(0.3,0.3,0.3,1)
        end),
        FrameEvent(2, function(inst)
            inst.Physics:SetMotorVel(8, 0, 0)
            inst.components.colouradder:ForceMultColor(0.6,0.6,0.6,1)            
        end),
        FrameEvent(3, function(inst)
            inst.Physics:SetMotorVel(4, 0, 0)
            --inst.components.colouradder:ClearMultColor()
            
        end),
        FrameEvent(4, function(inst) inst.Physics:SetMotorVel(2, 0, 0) end),
        FrameEvent(5, function(inst) inst.Physics:SetMotorVel(1, 0, 0) end),
        FrameEvent(6, function(inst)
            inst.sg:AddStateTag("idle")
            inst.sg:AddStateTag("canrotate")
            inst.Physics:Stop()
        end),
    },
    events =
    {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end ),
    },
    onexit = function(inst)
        
        inst.Physics:Stop()
        inst.components.colouradder:ClearMultColor()
    end,
})

AddStategraphState("wilson_client", State
{
    name = "shadowdodge",
    tags = {"busy"},
    server_states = { "shadowdodge_pre", "shadowdodge","shadowdodge_pst" },

    onenter = function(inst)
        
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("wortox_portal_jumpin_pre")

        inst.AnimState:PushAnimation("wortox_portal_jumpin_lag", false)
        inst:PerformPreviewBufferedAction()

        inst.sg:SetTimeout(2)
    end,
    onupdate = function(inst)
        if inst.sg:ServerStateMatches() then
            if inst.entity:FlattenMovementPrediction() then
                
                inst.sg:GoToState("idle", "noanim")
            end
        elseif inst.bufferedaction == nil then
            inst.sg:GoToState("idle")
        end
    end,
    ontimeout = function(inst)
        inst:ClearBufferedAction()
        inst.sg:GoToState("idle")
    end,
})