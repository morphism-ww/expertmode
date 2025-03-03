require "components/map" --extends Map component

local star_table = {"stafflight","staffcoldlight","emberlight"}
for i=1,3  do
    newcs_env.AddPrefabPostInit(star_table[i],function(inst)
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
newcs_env.AddPrefabPostInit("shadowhand",function (inst)
    if not TheWorld.ismastersim then
        return inst
    end
    inst.SetTargetLight = SetTargetLight
end)

newcs_env.AddPrefabPostInit("bomb_lunarplant",function (inst)
    inst:AddTag("supertoughworker")
end)


newcs_env.AddComponentPostInit("maprevealer",function (self)
    local oldReveal = self.RevealMapToPlayer
    
    function self:RevealMapToPlayer(player)
        local x,y,z = self.inst.Transform:GetWorldPosition()
        if not TheWorld.Map:NodeAtPointHasTag(x,y,z,"Abyss") then
            oldReveal(self,player)
        end
    end
end)

local function SafeEnter(inst,doer)
    if doer.isplayer then
        doer.components.transformlimit:SetState(true)
    end
    --doer:RemoveDebuff("abyss_curse")
end

newcs_env.AddPrefabPostInit("shadowrift_portal",function (inst)
    inst:AddTag("abyss_saveteleport")
    if not TheWorld.ismastersim then
        return inst
    end
    inst:AddComponent("teleporter")
    inst.components.teleporter.offset = 8
    inst.components.teleporter.saveenabled = false
    inst.components.teleporter.onActivate = SafeEnter
end)





newcs_env.AddComponentPostInit("acidlevel",function (self)
    local function DoAcidRainTick(inst, self)
        local rate = 1.5
        if inst.components.rainimmunity ~= nil then
            rate = 0.2
        end
    
        local damage = TUNING.ACIDRAIN_DAMAGE_TIME * TUNING.ACIDRAIN_DAMAGE_PER_SECOND -- Do not apply rate here.
        if inst.components.inventory then
            if inst.components.inventory:EquipHasTag("acidrainimmune") then
                damage = 0.5
            else
                -- Melt worn waterproofer equipment.
                local waterproofers, total_effectiveness = nil, 0
                for slot, item in pairs(inst.components.inventory.equipslots) do
                    if item.components.waterproofer then
                        local effectiveness = item.components.waterproofer:GetEffectiveness()
                        if effectiveness > 0 then
                            if not waterproofers then
                                waterproofers = {}
                            end
                            table.insert(waterproofers, item)
                            total_effectiveness = total_effectiveness + effectiveness
                        end
                    end
                end
                if waterproofers then
                    total_effectiveness = math.clamp(total_effectiveness, 0, 0.8)  ---击穿防水
    
                    local damageabsorbed = total_effectiveness * damage
                    damage = damage - damageabsorbed
    
                    local damagesplit = damageabsorbed / #waterproofers
                    for _, item in ipairs(waterproofers) do
                        self.DoAcidRainDamageOnEquipped(item, damagesplit)
                    end
                end
    
                if damage > 0 then
                    -- Spoil perishables, using rate.
                    inst.components.inventory:ForEachWetableItem(self.DoAcidRainRotOnAllItems, rate * TUNING.ACIDRAIN_PERISHABLE_ROT_PERCENT * TUNING.ACIDRAIN_DAMAGE_TIME)
                end
            end
        end
    
        -- Apply rate counter.
        self:DoDelta(rate * TUNING.ACIDRAIN_DAMAGE_TIME)
    
        -- Adjust damage dealt to health with rate now.
        damage = damage * rate
    
    
        if damage > 0 then -- NOTES(JBK): In case GetOverrideAcidRainTickFn returns a negative value to heal.
            self.DoAcidRainDamageOnHealth(inst, damage)
        end
    end
    function self:OnAcidArea(isacid)
        if isacid then
            if self.inst.acidarea_acid_task == nil then
                self.inst.acidarea_acid_task = self.inst:DoPeriodicTask(TUNING.ACIDRAIN_DAMAGE_TIME, DoAcidRainTick, math.random() * TUNING.ACIDRAIN_DAMAGE_TIME, self)
            end
        elseif self.inst.acidarea_acid_task ~= nil then
            self.inst.acidarea_acid_task:Cancel()
            self.inst.acidarea_acid_task = nil
        end
    end
end)


--地皮锁定
local old_canterraform = Map.CanTerraformAtPoint
function Map:CanTerraformAtPoint(x, y, z)
    if self:NodeAtPointHasTag(x, y, z, "Abyss") then
        return false
    end
    return old_canterraform(self,x,y,z)
end

--雾气
newcs_env.AddSimPostInit(function ()
    if not TheWorld:HasTag("cave") or TheNet:IsDedicated() then
        return
    end

    local _topology = TheWorld.topology
    for i,node in ipairs(_topology.nodes) do
        local story = _topology.ids[i]
        
        if string.find(story,"Hades") or string.find(story,"Iron_Miner") then
            if node.area_emitter == nil then
                if node.area == nil then
                    node.area = 1
                end

                
                local mist = SpawnPrefab("miasama_abyss_fx")
                mist.Transform:SetPosition(node.cent[1], 0, node.cent[2])
                mist.components.emitter.area_emitter = CreateAreaEmitter(node.poly, node.cent)

                local ext = ResetextentsForPoly(node.poly)
                mist.entity:SetAABB(ext.radius, 2)
                mist.components.emitter.density_factor = math.ceil(node.area / 5) / 14
                mist.components.emitter:Emit()
            end
        elseif string.find(story,"Night_Land") then
            local acid_fx = SpawnPrefab("local_acid_spawner")
            acid_fx.area_emitter = FindRandomPointInNode(node.poly, node.cent)
            acid_fx.Transform:SetPosition(node.cent[1],0,node.cent[2])
        end
    end
    
end)


--特殊地震
newcs_env.AddComponentPostInit("quaker",function (self)
    self:SetTagDebris( "notele", {})
    self:SetTagDebris("Abyss",{
        { -- common
            weight = 75,
            loot = {
                "rocks",
                "flint",
                "gelblob_falling"
            },
        },
        { -- uncomon
            weight = 20,
            loot = {
                "goldnugget",
                "nitre",
            },
        },
        { -- rare
            weight = 5,
            loot = {
                "redgem",
                "bluegem",
                "dreadstone",
            },
        },
    })
end)