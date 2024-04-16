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

local function TryToShadowhop(act, act_pos)
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
    if TryToShadowhop(act,act_pos) then
        act.doer.sg:GoToState("portal_jumpin", {dest = act_pos})
        return true
    end
end


AddAction(shadowhip)



AddComponentAction("POINT","shadowlevel", function (inst, doer, pos, actions, right)
            local x,y,z = pos:Get()
            local armor = doer.replica.inventory:GetEquippedItem(EQUIPSLOTS.BODY)
            if right and (TheWorld.Map:IsAboveGroundAtPoint(x,y,z) or TheWorld.Map:GetPlatformAtPoint(x,z) ~= nil) and not TheWorld.Map:IsGroundTargetBlocked(pos)
                    and not doer:HasTag("steeringboat") and not doer:HasTag("rotatingboat")
                    and inst:HasTag("shadowhip")
                    and armor~=nil and armor.prefab=="armor_voidcloth" then
                table.insert(actions, ACTIONS.SHADOWHIP)
            end
        end)

-----------------------------------------------------------------
----传送塔
-----------------------------------------------------------------
local townportal= Action({ priority=12, rmb=true, distance=2, mount_valid=true })
townportal.id="TOWNPORTAL"
townportal.str="使用传送塔"
townportal.fn= function(act)
    return true
end


AddAction(townportal)     



AddComponentAction("POINT","teleporter", function (inst, doer, pos, actions, right)  
    if right and inst:HasTag("donotautopick") then
        table.insert(actions, ACTIONS.TOWNPORTAL)
    end
end)


local BLINK_MAP_MUST = { "townportal"}
ACTIONS_MAP_REMAP[ACTIONS.TOWNPORTAL.code] = function(act, targetpos)
    local doer = act.doer
    if doer == nil then
        return nil
    end
    if TheWorld.Map:IsVisualGroundAtPoint(targetpos.x, targetpos.y, targetpos.z,BLINK_MAP_MUST) then
        local ents = TheSim:FindEntities(targetpos.x, targetpos.y, targetpos.z, 16)
        local revealer
        for _, v in ipairs(ents) do
            if v.prefab=="townportal" then
                revealer = v
                break
            end    
        end
        if revealer == nil then
            return nil
        end
        
        targetpos.x, targetpos.y, targetpos.z = revealer.Transform:GetWorldPosition()
        local act_remap = BufferedAction(doer, revealer, ACTIONS.TOSS_MAP, act.invobject, targetpos)
        return act_remap
    end
end


ACTIONS.TOSS_MAP.stroverridefn = function(act)
    return act.doer ~= nil and act.invobject ~= nil and (act.invobject.CanTossOnMap ~= nil and act.invobject:CanTossOnMap(act.doer) and STRINGS.ACTIONS.TOSS) 
    or (act.invobject:HasTag("townportaltalisman") and "使用传送塔") or nil
end

local function ActionCanMapToss(act)
    if act.doer ~= nil and act.invobject ~= nil and act.invobject.CanTossOnMap ~= nil then
        return act.invobject:CanTossOnMap(act.doer)
    end
    return false
end

ACTIONS.TOSS_MAP.fn = function(act)
    if ActionCanMapToss(act) then
        act.from_map = true
        return ACTIONS.TOSS.fn(act)
    end
    if act.doer ~= nil and act.invobject ~= nil and act.invobject:HasTag("townportaltalisman") then
        act.doer:CloseMinimap()
        act.invobject.components.teleporter:Target(act.target)
        act.doer.sg:GoToState("entertownportal", { teleporter = act.invobject })
        return true
    end
end



--[[AddClassPostConstruct("screens/mapscreen",function (self)

end)]]

--[[AddComponentPostInit("playercontroller", function(self)
    function self:GetMapActions(position)
        -- NOTES(JBK): In order to not interface with the playercontroller too harshly and keep that isolated from this system here
        --             it is better to get what the player could do at their location as a quick check to make sure the actions done
        --             here will not interfere with actions done without the map up.
        local LMBaction, RMBaction = nil, nil
    
        local pos = self.inst:GetPosition()
    
        self.inst.checkingmapactions = true -- NOTES(JBK): Workaround flag to not add function argument changes for this task and lets things opt-in to special handling.
    
        local lmbact = self.inst.components.playeractionpicker:GetLeftClickActions(pos)[1]
        
        LMBaction = self:RemapMapAction(lmbact, position)
    
        local rmbact = self.inst.components.playeractionpicker:GetRightClickActions(pos)[1]
        RMBaction = self:RemapMapAction(rmbact, position)
        print(RMBaction~=nil)
        self.inst.checkingmapactions = nil
    
        return LMBaction, RMBaction
    end
end)]]
