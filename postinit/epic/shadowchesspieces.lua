local function retargetfn(inst)
  --retarget nearby players if current target is fleeing or not a player
  local heart = inst.components.follower.leader
  if heart~=nil then
      local x,y,z=heart:GetPosition()
      local players = FindPlayersInRange(x, y, z, 30, true)
      for i, v in ipairs(players) do
          if inst.components.combat:CanTarget(v) then
              return v,true 
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


local function keeptarget(inst)
  local heart = inst.components.follower.leader
  return heart == nil or inst:IsNear(heart, 20)
end

local function rememberheart(inst,data)
    if data.leader~=nil then
        --inst.components.knownlocations:RememberLocation("heart", heart:GetPosition())
        inst.components.follower:StartLeashing()
        --inst.components.health:SetInvincible(true)
    end
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
      end
  end

  lootdropper:SetLoot(loot)
end

local function SummonHeart(inst)
    if inst.level==3 then
      local x,y,z=inst.Transform:GetWorldPosition()
      local heart=SpawnPrefab("corrupt_heart")
      heart.Transform:SetPosition(x,0.5,z)
      heart:PushEvent("summon")
    end
end


AddPrefabPostInit("shadow_rook",function(inst)
    if not TheWorld.ismastersim then return end

    inst:AddComponent("follower")
    inst.components.combat.targetfn =retargetfn
    inst.components.combat:SetKeepTargetFunction(keeptarget)
    inst.components.lootdropper:SetLootSetupFn(lootsetfn)



    inst:ListenForEvent("startfollowing", rememberheart)
    inst:ListenForEvent("death",SummonHeart)
end)

AddPrefabPostInit("shadow_bishop",function(inst)
  if not TheWorld.ismastersim then return end

  inst:AddComponent("follower")
  inst.components.combat.targetfn =retargetfn
  inst.components.combat:SetKeepTargetFunction(keeptarget)
  inst.components.lootdropper:SetLootSetupFn(lootsetfn)


  inst:ListenForEvent("startfollowing", rememberheart)
  inst:ListenForEvent("death",SummonHeart)
end)

AddPrefabPostInit("shadow_knight",function(inst)
  if not TheWorld.ismastersim then return end

  inst:AddComponent("follower")
  inst.components.combat.targetfn =retargetfn
  inst.components.combat:SetKeepTargetFunction(keeptarget)
  inst.components.lootdropper:SetLootSetupFn(lootsetfn)


  inst:ListenForEvent("startfollowing", rememberheart)
  inst:ListenForEvent("death",SummonHeart)
end)


require "behaviours/leash"
local LEASH_MAX_DIST = 8
local LEASH_RETURN_DIST = 6

local function GetHeartPos(inst)
  local heart=inst.components.follower.leader
    return heart~=nil and heart:GetPosition()
end

AddBrainPostInit("shadow_bishopbrain", function(self)
  self.bt.root.children[4]=Leash(self.inst, GetHeartPos, LEASH_MAX_DIST, LEASH_RETURN_DIST)   
end)

AddBrainPostInit("shadow_rookbrain", function(self)
  self.bt.root.children[4]=Leash(self.inst, GetHeartPos, LEASH_MAX_DIST, LEASH_RETURN_DIST)   
end)

AddBrainPostInit("shadow_knightbrain", function(self)
  self.bt.root.children[5]=Leash(self.inst, GetHeartPos, LEASH_MAX_DIST, LEASH_RETURN_DIST)   
end)

AddPrefabPostInit("eye_charge",function(inst)
  if not TheWorld.ismastersim then return end
  inst:AddComponent("weapon")
  inst.components.weapon:SetDamage(100)
end)