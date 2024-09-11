local move_shoot= Action({priority=-10, canforce=true, invalid_hold_action=true, do_not_locomote=true})
move_shoot.id="MOVE_SHOOT"
move_shoot.str="射击"
move_shoot.fn= function(act)
    act.doer.components.combat:DoAttack(act.target)
    return true
end

AddAction(move_shoot)    


AddComponentAction("EQUIPPED","move_attack",
    function(inst, doer,target, actions, right)
    if not right and doer.replica.combat ~= nil
            and not target:HasTag("wall") -- 目标不是墙
            and doer.replica.combat:CanTarget(target) -- doer可以把target作为目标
            and not doer.replica.combat:IsAlly(target) then
        table.insert(actions, ACTIONS.MOVE_SHOOT)
    end 
end,"the_new_constant")

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.MOVE_SHOOT,"move_shoot"))

AddStategraphState("wilson",
State{
    name = "move_shoot",
    tags = {  "notalking", "autopredict","attack","abouttoattack" },

    onenter = function(inst)
        if inst.components.combat:InCooldown() then
            inst.sg:RemoveStateTag("abouttoattack")
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
})