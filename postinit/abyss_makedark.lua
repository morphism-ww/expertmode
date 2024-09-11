local star_table = {"stafflight","staffcoldlight","emberlight"}
for i=1,3  do
    AddPrefabPostInit(star_table[i],function(inst)
        inst:AddTag("starlight")
    end)
end
local function Dissipate(inst)
    if inst.dissipating then
        return
    end
    inst.dissipating = true
    inst.SoundEmitter:PlaySound("dontstarve/sanity/shadowhand_snuff")
    inst.SoundEmitter:KillSound("creeping")
    inst.SoundEmitter:KillSound("retreat")
    inst.components.locomotor:Stop()
    inst.components.locomotor:Clear()
    if inst.components.playerprox ~= nil then
        inst:RemoveComponent("playerprox")
    end
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end
    if inst._distance_test_task ~= nil then
        inst._distance_test_task:Cancel()
        inst._distance_test_task = nil
    end
    if inst.arm ~= nil then
        inst.arm.AnimState:PlayAnimation("arm_scare")
    end
    inst.AnimState:PlayAnimation("hand_scare")
    inst:ListenForEvent("animover", inst.Remove)
end

local function DoConsumeFire(inst,fire)
    inst.task = nil
    if fire and fire:IsValid() then
        if fire.components.burnable ~= nil and fire.components.burnable:IsBurning() then
            fire.components.burnable:Extinguish()
        end
        if fire.components.fueled ~= nil and not fire.components.fueled:IsEmpty() then
            fire.components.fueled:MakeEmpty()
        end
        if fire:HasTag("starlight") then
            fire.components.hauntable:DoHaunt(inst)
        end    
    end
    inst.SoundEmitter:PlaySound("dontstarve/sanity/shadowhand_snuff")

    --Retract
    inst.SoundEmitter:KillSound("creeping")
    inst.components.locomotor:Stop()
    inst.components.locomotor:Clear()
    inst.components.locomotor.walkspeed = -10
    inst.components.locomotor:GoToEntity(inst.arm)

    inst.AnimState:PlayAnimation("grab_pst")
    inst:ListenForEvent("animover", inst.Remove)
end

local function ConsumeFire(inst, fire)
    if fire ~= nil then
        if inst.task ~= nil then
            inst.task:Cancel()
            inst.task = nil
        end
        inst.AnimState:PlayAnimation("grab")
        inst.AnimState:PushAnimation("grab_pst", false)

        -- We're removing the on-fire-removed callback, so we also need to stop our position update that tests its location!
        if inst._distance_test_task ~= nil then
            inst._distance_test_task:Cancel()
            inst._distance_test_task = nil
        end
        inst:RemoveEventCallback("onextinguish", inst.dissipatefn, fire)
        inst:RemoveEventCallback("onremove", inst.dissipatefn, fire)
        if inst.components.playerprox ~= nil then
            inst:RemoveComponent("playerprox")
        end
        inst.task = inst:DoTaskInTime(17 * FRAMES, DoConsumeFire,fire)
    end
end

local function DoCreeping(inst)
    inst.task = nil
    inst.components.locomotor.walkspeed = 2
    inst.components.locomotor:PushAction(BufferedAction(inst, inst.fire, ACTIONS.EXTINGUISH), false)
end

local function StartCreeping(inst, delay)
    if inst.task ~= nil then
        inst.task:Cancel()
    end
    inst.task = inst:DoTaskInTime(delay or 0, DoCreeping)
    inst.SoundEmitter:PlaySound("dontstarve/sanity/shadowhand_creep", "creeping")
end

local function Regroup(inst)
    inst.AnimState:PushAnimation("hand_in_loop", true)
    inst.SoundEmitter:KillSound("retreat")
    inst.components.locomotor:Stop()
    inst.components.locomotor:Clear()
    StartCreeping(inst, 2 + math.random() * 3)
end

local function Retreat(inst)
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end
    inst.AnimState:PlayAnimation("scared_loop", true)
    inst.SoundEmitter:KillSound("creeping")
    inst.SoundEmitter:PlaySound("dontstarve/sanity/shadowhand_retreat", "retreat")
    inst.components.locomotor:Stop()
    inst.components.locomotor:Clear()
    inst.components.locomotor.walkspeed = -8
    inst.components.locomotor:PushAction(BufferedAction(inst, inst.arm, ACTIONS.GOHOME, nil, inst.arm:GetPosition()))
end

local function HandleAction(inst, data)
    if data.action ~= nil then
        if data.action.action == ACTIONS.EXTINGUISH then
            ConsumeFire(inst, data.action.target)
        elseif data.action.action == ACTIONS.GOHOME then
            Dissipate(inst)
        end
    end
end

local MAX_ARM_DISTANCE_SQ = 2000
local function FireDistanceTest(inst)
    if inst.fire == nil then
        return
    end

    local fire_x, fire_y, fire_z = inst.fire.Transform:GetWorldPosition()
    local origin = inst.components.knownlocations:GetLocation("origin")
    local fire_distance_sq = distsq(fire_x, fire_z, origin.x, origin.z)
    if fire_distance_sq > MAX_ARM_DISTANCE_SQ then
        Dissipate(inst)
    end
end

local function SetTargetLight(inst, fire)
    if inst.fire ~= nil or fire == nil or inst.dissipating then
        return
    end
    inst.fire = fire

    local pos = inst:GetPosition()
    inst:AddComponent("knownlocations")
    inst.components.knownlocations:RememberLocation("origin", pos)

    inst.arm = SpawnPrefab("shadowhand_arm")
    inst.arm.Transform:SetPosition(pos:Get())
    inst.arm:FacePoint(fire:GetPosition())
    inst.arm.components.stretcher:SetStretchTarget(inst)

    inst:AddComponent("playerprox")
    inst.components.playerprox:SetDist(2, 6)
    inst.components.playerprox:SetOnPlayerNear(Retreat)
    inst.components.playerprox:SetOnPlayerFar(Regroup)

    inst.dissipatefn = function() Dissipate(inst) end
    inst:ListenForEvent("enterlight", inst.dissipatefn, inst.arm)
    inst:ListenForEvent("onextinguish", inst.dissipatefn, fire)
    inst:ListenForEvent("onremove", inst.dissipatefn, fire)
    inst:ListenForEvent("startaction", HandleAction)

    StartCreeping(inst)

    -- Also start a low-frequency distance-testing task, so that if our target
    -- manages to get far away from us, we also dissipate.
    if inst._distance_test_task ~= nil then
        inst._distance_test_task:Cancel()
        inst._distance_test_task = nil
    end
    inst._distance_test_task = inst:DoPeriodicTask(0.5, FireDistanceTest)
end
AddPrefabPostInit("shadowhand",function (inst)
    if not TheWorld.ismastersim then
        return inst
    end
    inst.SetTargetLight = SetTargetLight
end)

AddPrefabPostInit("bomb_lunarplant",function (inst)
    inst:AddTag("supertoughworker")
end)
AddPrefabPostInit("wortox",function (inst)
    local function CanBlinkFromWithMap(pt)
        return not TheWorld.Map:IsGroundTargetBlocked(pt)
    end
    inst.CanBlinkFromWithMap = CanBlinkFromWithMap
end)

AddComponentPostInit("maprevealer",function (self)
    local oldReveal = self.RevealMapToPlayer
    local map = TheWorld.Map
    function self:RevealMapToPlayer(player)
        local x,y,z = self.inst.Transform:GetWorldPosition()
        if not map:NodeAtPointHasTag(x,y,z,"Abyss") then
            oldReveal(self,player)
        end
    end
end)


AddComponentPostInit("teleporter",function (self)
    function self:Activate(doer)
        if not self:IsActive() then
            return false
        end
    
        if self.onActivate ~= nil then
            self.onActivate(self.inst, doer, self.migration_data)
        end
    
        if self.migration_data ~= nil then
            local data = self.migration_data
            if data.worldid ~= TheShard:GetShardId() and Shard_IsWorldAvailable(data.worldid) then
                TheWorld:PushEvent("ms_playerdespawnandmigrate", { player = doer, portalid = nil, worldid = data.worldid, x = data.x, y = data.y, z = data.z })
                return true
            else
                return false
            end
        else 
            local targetTeleporter = self.targetTeleporterTemporary or self.targetTeleporter
            if targetTeleporter ~= nil then
                local target_x, target_y, target_z = targetTeleporter.Transform:GetWorldPosition()
                if TheWorld.Map:NodeAtPointHasTag(target_x, target_y, target_z,"DarkLand") then
                    return false
                end
            end
        end
    
        self:Teleport(doer)
    
        local targetTeleporter = self.targetTeleporterTemporary or self.targetTeleporter
    
        if targetTeleporter.components.teleporter ~= nil then
            if doer:HasTag("player") then
                targetTeleporter.components.teleporter:ReceivePlayer(doer, self.inst)
            elseif doer.components.inventoryitem ~= nil then
                targetTeleporter.components.teleporter:ReceiveItem(doer, self.inst)
            end
        end
    
        if doer.components.leader ~= nil then
            for follower, v in pairs(doer.components.leader.followers) do
                if not (follower.components.follower ~= nil and follower.components.follower.noleashing) then
                    self:Teleport(follower)
                end
            end
        end
    
        --special case for the chester_eyebone: look for inventory items with followers
        if doer.components.inventory ~= nil then
            for k, item in pairs(doer.components.inventory.itemslots) do
                if item.components.leader ~= nil then
                    for follower, v in pairs(item.components.leader.followers) do
                        self:Teleport(follower)
                    end
                end
            end
            -- special special case, look inside equipped containers
            for k, equipped in pairs(doer.components.inventory.equipslots) do
                if equipped.components.container ~= nil then
                    for j, item in pairs(equipped.components.container.slots) do
                        if item.components.leader ~= nil then
                            for follower, v in pairs(item.components.leader.followers) do
                                self:Teleport(follower)
                            end
                        end
                    end
                end
            end
        end
    
        return true
    end
end)
