local function RetargetFn(inst)
    --retarget nearby players if current target is fleeing or not a player
    local heart = inst.components.follower.leader
    if heart ~= nil then
      local x, y, z = heart:GetPosition()
      local players = FindPlayersInRange(x, y, z, 30, true)
      for i, v in ipairs(players) do
        if inst.components.combat:CanTarget(v) then
            return v, true
        end
      end
  end
  
    local target = inst.components.combat.target
    if target ~= nil then
        local dist = TUNING[string.upper(inst.prefab)].RETARGET_DIST
        if target:HasTag("player") and inst:IsNear(target, dist) or not inst:IsNearPlayer(dist, true) then
            return
        end
        target = nil
    end
  
    local x, y, z = inst.Transform:GetWorldPosition()
    local players = FindPlayersInRange(x, y, z, TUNING.SHADOWCREATURE_TARGET_DIST, true)
    local rangesq = math.huge
    for i, v in ipairs(players) do
        local distsq = v:GetDistanceSqToPoint(x, y, z)
        if distsq < rangesq and inst.components.combat:CanTarget(v) then
            rangesq = distsq
            target = v
        end
    end
    return target, true
end

local function lootsetfn(lootdropper)
    local loot = {}
  
    if lootdropper.inst.level >= 2 then
        for i = 1, math.random(2, 3) do
            table.insert(loot, "nightmarefuel")
        end

        if lootdropper.inst.level >= 3 then
            table.insert(loot, "nightmarefuel")
            --TODO: replace with shadow equipment drops
            table.insert(loot, "armor_sanity")
            table.insert(loot, "nightsword")
            if IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) then
                table.insert(loot, GetRandomBasicWinterOrnament())
            end
            table.insert(loot,"corrupt_heart")
        end
    end
    lootdropper:SetLoot(loot)
end

local function rememberheart(inst, data)
    if data.leader ~= nil then
        inst.components.follower:StartLeashing()
        inst.components.health:SetAbsorptionAmount(1)
        inst:AddTag("NOCLICK")
        inst:AddTag("notarget")
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
    if inst.components.follower.leader == nil then
        inst._despawntask = inst:DoTaskInTime(TUNING.SHADOW_CHESSPIECE_DESPAWN_TIME, OnDespawn)
    end
end

require ("behaviours/leash")

local LEASH_MAX_DIST = 5
local LEASH_RETURN_DIST = 4

local function GetHeartPos(inst)
    local heart = inst.components.follower.leader
    return heart ~= nil and heart:GetPosition()
end

local function LevelUpNearByChess(inst)
    -- trigger all near by shadow chess pieces to level up
    if not inst.persists then
      return
    end
    local pos = inst:GetPosition()
    local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, 25, { "shadowchesspiece" })
    for i, v in ipairs(ents) do
        if v ~= inst and not v.components.health:IsDead() then
            v:PushEvent("levelup", { source = inst })
        end
    end

    if inst.persists then
        inst.persists = false
        inst.components.lootdropper:DropLoot(pos)
    end
end


for k,v in ipairs({"shadow_bishop","shadow_knight","shadow_rook"}) do
    newcs_env.AddPrefabPostInit(v,function (inst)
        inst:AddTag("ignorewalkableplatformdrowning")
        inst.Physics:ClearCollisionMask()
        inst.Physics:CollidesWith(COLLISION.GROUND)
        if not TheWorld.ismastersim then return end

        inst:AddComponent("follower")
        inst.components.combat.targetfn = RetargetFn
        inst.components.lootdropper:SetLootSetupFn(lootsetfn)
        inst.components.locomotor.pathcaps.allowocean = true
        inst.OnEntitySleep = OnEntitySleep
        inst.components.drownable.enabled = false
        inst:ListenForEvent("startfollowing", rememberheart)
        
        inst:WatchWorldState("isalterawake", inst.Remove)
    end)

    newcs_env.AddBrainPostInit(v.."brain", function (self)
        table.insert(self.bt.root.children, 1, WhileNode(function ()
            return self.inst.components.follower.leader ~= nil and self.inst.shouldprotect
        end, "Protect Heart",
            ParallelNode {
                WaitNode(10),
                Leash(self.inst, GetHeartPos, LEASH_MAX_DIST, LEASH_RETURN_DIST)
            })
        )
    end)

    newcs_env.AddStategraphPostInit(v,function (sg)
        local deathTimeline = sg.states.death.timeline
        local evolved_deathTimeline = sg.states.evolved_death.timeline
        deathTimeline[#deathTimeline-1].fn = LevelUpNearByChess
        evolved_deathTimeline[#evolved_deathTimeline-1].fn = LevelUpNearByChess

        sg.states.appear.onexit = function (inst)
            if TheWorld.state.isalterawake then
                inst.persists = false
                inst.components.health:Kill()
            end
        end
    end)
end