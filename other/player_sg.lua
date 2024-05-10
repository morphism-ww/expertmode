---stun_protect  moving_attack
local function DoHurtSound(inst)
    if inst.hurtsoundoverride ~= nil then
        inst.SoundEmitter:PlaySound(inst.hurtsoundoverride, nil, inst.hurtsoundvolume)
    elseif not inst:HasTag("mime") then
        inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/")..(inst.soundsname or inst.prefab).."/hurt", nil, inst.hurtsoundvolume)
    end
end


AddStategraphPostInit("wilson", function(sg)
    --no_stun--
    local old_attackedfn=sg.events["attacked"].fn
    sg.events["attacked"].fn=function(inst,data)
        if not inst.components.health:IsDead() and not inst.sg:HasStateTag("drowning") then
            if inst:HasTag("stun_immune") then
                inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
                DoHurtSound(inst)
            else
               old_attackedfn(inst,data)
            end
        end
    end
    sg.actionhandlers[ACTIONS.ATTACK].deststate=function(inst, action)
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
            return (weapon == nil and "attack")
                or (weapon:HasTag("quick_attack") and "quick_attack")
                or (weapon:HasTag("scythe_attack") and "scythe_attack")
                or (weapon:HasOneOfTags({"blowdart", "blowpipe"}) and "blowdart")
                or (weapon:HasTag("slingshot") and "slingshot_shoot")
                or (weapon:HasTag("thrown") and "throw")
                or (weapon:HasTag("pillow") and "attack_pillow_pre")
                or (weapon:HasTag("propweapon") and "attack_prop_pre")
                or (weapon:HasTag("multithruster") and "multithrust_pre")
                or (weapon:HasTag("helmsplitter") and "helmsplitter_pre")
                or "attack"
        end
    end    
    --moving_attack--
    --local old_attack=sg.events["attack"].fn
end)

AddStategraphPostInit("wilson_client",function (sg)
    sg.actionhandlers[ACTIONS.ATTACK].deststate=function(inst, action)
        if not (inst.sg:HasStateTag("attack") and action.target == inst.sg.statemem.attacktarget or IsEntityDead(inst)) then
            local equip = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if equip == nil then
                return "attack"
            end
            local inventoryitem = equip.replica.inventoryitem
            return (not (inventoryitem ~= nil and inventoryitem:IsWeapon()) and "attack")
                or (equip:HasTag("quick_attack") and "quick_attack")
                or (equip:HasTag("scythe_attack") and "scythe_attack")
                or (equip:HasOneOfTags({"blowdart", "blowpipe"}) and "blowdart")
                or (equip:HasTag("slingshot") and "slingshot_shoot")
                or (equip:HasTag("thrown") and "throw")
                or (equip:HasTag("pillow") and "attack_pillow_pre")
                or (equip:HasTag("propweapon") and "attack_prop_pre")
                or "attack"
        end
    end    
end)
--[[AddStategraphState("wilson",
State{
    name = "move_shoot",
    tags = {  "notalking", "autopredict","attack","abouttoattack" },

    onenter = function(inst)
        if inst.components.combat:InCooldown() then
            --inst.sg:RemoveStateTag("abouttoattack")
            inst:ClearBufferedAction()
            inst.sg:GoToState("idle", true)
            return
        end
        local buffaction = inst:GetBufferedAction()
        local target = buffaction ~= nil and buffaction.target or nil
        local equip = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        inst.components.combat:SetTarget(target)
        inst.components.combat:StartAttack()
        --inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("dart")
        inst.AnimState:SetFrame(3)

        inst.sg:SetTimeout(2*FRAMES)

        if target ~= nil and target:IsValid() then
            inst:FacePoint(target.Transform:GetWorldPosition())
            inst.sg.statemem.attacktarget = target
            inst.sg.statemem.retarget = target
        end

        inst:PerformBufferedAction()
    end,


    ontimeout = function(inst)
        inst.sg:RemoveStateTag("attack")
        inst.sg:AddStateTag("idle")
    end,

    events =
    {
        EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("animqueueover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end),
    },

    onexit = function(inst)
        inst.components.combat:SetTarget(nil)
        if inst.sg:HasStateTag("abouttoattack") then
            inst.components.combat:CancelAttack()
        end
    end,
})]]

AddStategraphState("wilson",
State{
    name = "quick_attack",
    tags = { "attack", "notalking", "abouttoattack", "autopredict" },

    onenter = function(inst)
        local buffaction = inst:GetBufferedAction()
        local target = buffaction ~= nil and buffaction.target or nil
        
        inst.components.combat:SetTarget(target)
        inst.components.locomotor:Stop()
  

        inst.AnimState:SetDeltaTimeMultiplier(1.8)
        inst.AnimState:PlayAnimation("atk_pre")
        inst.AnimState:PushAnimation("atk", false)
        inst.sg:SetTimeout(6*FRAMES)

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
        TimeEvent(4 * FRAMES, function(inst)
            inst:PerformBufferedAction()
            inst.sg:RemoveStateTag("abouttoattack")
        end),
    },
    ontimeout = function(inst)
        inst.sg:RemoveStateTag("attack")
        inst.sg:AddStateTag("idle")
    end,

    events =
    {
        EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("animqueueover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end),
    },

    onexit = function(inst)
        inst.AnimState:SetDeltaTimeMultiplier(1)
        inst.components.combat:SetTarget(nil)
        if inst.sg:HasStateTag("abouttoattack") then
            inst.components.combat:CancelAttack()
        end
    end,
})        

AddStategraphState("wilson_client",
State{
    name = "quick_attack",
    tags = { "attack", "notalking", "abouttoattack" },

    onenter = function(inst)
        inst.components.locomotor:Stop()

        inst.AnimState:SetDeltaTimeMultiplier(1.8)
        inst.AnimState:PlayAnimation("atk_pre")
        inst.AnimState:PushAnimation("atk", false)
        local buffaction = inst:GetBufferedAction()
        if buffaction ~= nil then
            inst:PerformPreviewBufferedAction()

            if buffaction.target ~= nil and buffaction.target:IsValid() then
                inst:FacePoint(buffaction.target:GetPosition())
                inst.sg.statemem.attacktarget = buffaction.target
                inst.sg.statemem.retarget = buffaction.target
            end
        end

        inst.sg:SetTimeout(6*FRAMES)
    end,
    timeline =
    {
        TimeEvent(4 * FRAMES, function(inst)
            inst:ClearBufferedAction()
            inst.sg:RemoveStateTag("abouttoattack")
        end),
    },
    ontimeout = function(inst)
        inst.sg:RemoveStateTag("attack")
        inst.sg:AddStateTag("idle")
    end,
    events =
    {
        EventHandler("animqueueover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end),
        EventHandler("equip", function(inst) inst.sg:GoToState("idle") end),
        EventHandler("unequip", function(inst) inst.sg:GoToState("idle") end),
    },

    onexit = function(inst)
        inst.AnimState:SetDeltaTimeMultiplier(1)
        if inst.sg:HasStateTag("abouttoattack") then
            inst.replica.combat:CancelAttack()
        end
    end,    
})


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


AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.ANCIENT_CHOP,"chop_attack"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.ANCIENT_CHOP,"chop_attack"))

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.OPEN_PORTAL,"give"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.OPEN_PORTAL,"give"))