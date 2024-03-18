AddAction(
    "LAVASPIT",
    "spit",
    function(act)
        if act.doer and act.target and act.doer.prefab == "dragoon" then
            local spit = SpawnPrefab("dragoonspit")
            local x, y, z = act.doer.Transform:GetWorldPosition()
            local downvec = TheCamera:GetDownVec()
            local offsetangle = math.atan2(downvec.z, downvec.x) * (180 / math.pi)
            while offsetangle > 180 do
                offsetangle = offsetangle - 360
            end
            while offsetangle < -180 do
                offsetangle = offsetangle + 360
            end
            local offsetvec =
               Vector3(math.cos(offsetangle * DEGREES), -.3, math.sin(offsetangle * DEGREES)) *
                1.7
            spit.Transform:SetPosition(x + offsetvec.x, y + offsetvec.y, z + offsetvec.z)
            spit.Transform:SetRotation(act.doer.Transform:GetRotation())
        end
    end
)


---------------------------------------------
--暗影跳跃
---------------------------------------------
local function AllowShadowHip(doer)
    local armor = doer.replica.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    if armor~=nil and armor.prefab=="armor_voidcloth" then
        local item = armor.components.container:GetItemInSlot(1)
        if item~=nil then
            armor.components.container:RemoveItem(item, false):Remove()
            return true
        end
    end
    return false
end

local function EnoughShadow(weapon)
    return weapon~=nil and weapon.components.shadowlevel and weapon.components.shadowlevel.level>1
end

local function TryToSoulhop(act, act_pos)
    return act.doer ~= nil
    and act_pos ~= nil
    and AllowShadowHip(act.doer)
    and EnoughShadow(act.invobject)
end

local shadowhip= Action({ priority=12, rmb=true, distance=20, mount_valid=true })
shadowhip.id="SHADOWHIP"
shadowhip.str="暗影跳跃"
shadowhip.fn= function(act)
	local act_pos = act:GetActionPoint()
    if TryToSoulhop(act,act_pos) then
        act.doer.sg:GoToState("portal_jumpin", {dest = act_pos})
        return true
    end
end


AddAction(shadowhip)



AddComponentAction("POINT","shadowlevel", function (inst, doer, pos, actions, right, target)
            local x,y,z = pos:Get()
            local armor = doer.replica.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
            if right and (TheWorld.Map:IsAboveGroundAtPoint(x,y,z) or TheWorld.Map:GetPlatformAtPoint(x,z) ~= nil) and not TheWorld.Map:IsGroundTargetBlocked(pos)
                    and not doer:HasTag("steeringboat") and not doer:HasTag("rotatingboat")
                    and inst:HasTag("shadowhip")
                    and armor~=nil and armor.prefab=="armor_voidcloth" then
                table.insert(actions, ACTIONS.SHADOWHIP)
            end
        end)

--[[local function ArriveAnywhere()
    return true
end


local townportal_map=Action({ priority=10, customarrivecheck=ArriveAnywhere, rmb=true, mount_valid=true, map_action=true, })
townportal_map.id="TOWNPORTAL_MAP"
townportal_map.stroverridefn=function(act) return "使用传送塔" end

local function ActionCanMapTeleport(act)
    return act.doer~=nil
    --and act.dore.components.
end



townportal_map.fn=function(act)
    local act_pos = act:GetActionPoint()
    if ActionCanMapTeleport(act) and TryToSoulhop(act,act_pos) then
        act.doer.sg:GoToState("portal_jumpin", {dest = act_pos, from_map = true,})
        TheNet:Announce("success")
        return true
    end
    TheNet:Announce("fail")
    return false
end

AddAction(townportal_map)

--global("ACTIONS_MAP_REMAP")

local BLINK_MAP_MUST = { "CLASSIFIED", "globalmapicon", "fogrevealer" }
ACTIONS_MAP_REMAP[ACTIONS.TOWNPORTAL.code] = function(act, targetpos)
    local doer = act.doer
    if doer == nil then
        return nil
    end
    if doer.item_portal then
        return nil
    end
    if not TheWorld.Map:IsVisualGroundAtPoint(targetpos.x, targetpos.y, targetpos.z) then
        local ents = TheSim:FindEntities(targetpos.x, targetpos.y, targetpos.z, PLAYER_REVEAL_RADIUS * 0.4, BLINK_MAP_MUST)
        local revealer
        local MAX_WALKABLE_PLATFORM_DIAMETERSQ = TUNING.MAX_WALKABLE_PLATFORM_RADIUS * TUNING.MAX_WALKABLE_PLATFORM_RADIUS * 4 -- Diameter.
        for _, v in ipairs(ents) do
            if doer:GetDistanceSqToInst(v) > MAX_WALKABLE_PLATFORM_DIAMETERSQ then
                -- Ignore close boats because the range for aim assist is huge.
                revealer = v
                break
            end
        end
        if revealer == nil then
            return nil
        end
        targetpos.x, targetpos.y, targetpos.z = revealer.Transform:GetWorldPosition()
        if revealer._target ~= nil then
            -- Server only code.
            local boat = revealer._target:GetCurrentPlatform()
            if boat == nil then
                return nil
            end
            targetpos.x, targetpos.y, targetpos.z = boat.Transform:GetWorldPosition()
        end
    end
    local act_remap = BufferedAction(doer, nil, ACTIONS.TOWNPORTAL_MAP, act.invobject, targetpos)
    return act_remap
end]]

--[[AddClassPostConstruct("screens/mapscreen", function(self)
    local old_ProcessRMBDecorations = self.ProcessRMBDecorations
    function self:ProcessRMBDecorations(...)
        if old_ProcessRMBDecorations then
            old_ProcessRMBDecorations(self, ...)
        end
        if not self.owner:HasTag("soulstealer") and self.decorationdata and self.decorationdata.rmbents then
            if self.decorationdata.rmbents[1] then
                self.decorationdata.rmbents[1]:Hide()
            end
            if self.decorationdata.rmbents[2] then
                self.decorationdata.rmbents[2]:Hide()
            end
            if self.decorationdata.rmbents[3] then
                self.decorationdata.rmbents[3]:Hide()
            end
        end
    end
end)
AddClassPostConstruct("components/playeractionpicker", function(self)
    local old_DoGetMouseActions = self.DoGetMouseActions
    function self:DoGetMouseActions(...)
        local useitem = self.inst.replica.inventory and self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
        local lmb, rmb = nil, nil
        if old_DoGetMouseActions then
            lmb, rmb = old_DoGetMouseActions(self, ...)
        end
        if rmb ~= nil and
            rmb.action and
            rmb.action == ACTIONS.TOWNPORTAL_MAP and
            rmb.doer and
            not rmb.doer:HasTag("soulstealer") and
            (useitem == nil or (useitem ~= nil and useitem.replica.equippable and not useitem.replica.equippable._mj_blinkstaff:value()))
            then
            rmb = nil
        end
        return lmb, rmb
    end
end)]]