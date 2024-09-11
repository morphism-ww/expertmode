AddAction("LAVASPIT","spit",function(act)
    if act.doer and act.target and act.doer.prefab == "dragoon_cs" then
        local spit = SpawnPrefab("dragoonspit_cs")
        local x, y, z = act.doer.Transform:GetWorldPosition()
        local downvec = TheCamera:GetDownVec()
		local offsetangle = math.atan2(downvec.z, downvec.x) * (180/math.pi)
		
		while offsetangle > 180 do offsetangle = offsetangle - 360 end
		while offsetangle < -180 do offsetangle = offsetangle + 360 end
		local offsetvec = Vector3(math.cos(offsetangle*DEGREES), -.3, math.sin(offsetangle*DEGREES)) * 1.7
		spit.Transform:SetPosition(x+offsetvec.x, y+offsetvec.y, z+offsetvec.z)
        spit.Transform:SetRotation(act.doer.Transform:GetRotation())
    end
end)

local function GetCommonPointSpecialActions(inst, pos, useitem, right)
	if not right then
        local hat = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
        if hat~=nil then
            if hat:HasTag("playercharge") then
                return { ACTIONS.LUNGE }
            elseif hat:HasTag("shadowdodge") then
                return  {ACTIONS.SHADOWDODGE}
            end
        end
    end
	return {}
end

AddComponentPostInit("playeractionpicker",function (self)
    function self:GetPointSpecialActions(pos, useitem, right, usereticulepos)
        --V2C: usereticulepos is new
        --     pos2 may be returned (when usereticulepos is true)
        --     keep support for legacy pointspecialactionsfn, which won't have the pos2 return
        if self.inst.components.playercontroller:IsControlPressed(CONTROL_FORCE_INSPECT) then
            local actions, pos2 = GetCommonPointSpecialActions(self.inst, pos, useitem, right)
            return self:SortActionList(actions, usereticulepos and pos2 or pos, useitem)
        elseif self.pointspecialactionsfn then
            local actions, pos2 = self.pointspecialactionsfn(self.inst, pos, useitem, right, usereticulepos)
            return self:SortActionList(actions, usereticulepos and pos2 or pos, useitem)
        end
        return {}
    end
end)


-----------------------------------------------------------------
----传送塔
-----------------------------------------------------------------
local townportal = Action({ priority=12, rmb=true, distance=2, mount_valid=true })
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

local MAP_SELECT_WORMHOLE_MUST = { "CLASSIFIED", "globalmapicon", "townportaltrackericon" }
ACTIONS_MAP_REMAP[ACTIONS.TOWNPORTAL.code] = function(act, targetpos)
    local doer = act.doer
    if doer == nil then
        return nil
    end
    local rx,_,rz = doer.Transform:GetWorldPosition()
    if TheWorld.Map:IsVisualGroundAtPoint(targetpos.x, targetpos.y, targetpos.z) then
        
        local ents = TheSim:FindEntities(targetpos.x, targetpos.y, targetpos.z, 12, MAP_SELECT_WORMHOLE_MUST)
        for _, ent in ipairs(ents) do
            local ex, ey, ez = ent.Transform:GetWorldPosition()
            if ex ~= rx and ez ~= rz then
                local act_remap = BufferedAction(doer, nil, ACTIONS.TOSS_MAP, act.invobject, targetpos)
                return act_remap
            end
        end
    end
end


ACTIONS.TOSS_MAP.stroverridefn = function(act)
    return act.doer ~= nil and act.invobject ~= nil and (act.invobject.CanTossOnMap ~= nil and act.invobject:CanTossOnMap(act.doer) and STRINGS.ACTIONS.TOSS) 
    or (act.invobject:HasTag("townportaltalisman") and STRINGS.ACTIONS.TOWNPORTAL) or nil
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
        local pt = act:GetActionPoint()
        local town_portal
        local ents = TheSim:FindEntities(pt.x, 0, pt.z, 12, {"townportal"},{"townportaltalisman"})
        if ents[1]~=nil then
            act.invobject.components.teleporter:Target(ents[1])
            act.doer.sg:GoToState("entertownportal", { teleporter = act.invobject })
            return true
        else
            act.doer.sg:GoToState("idle")
            return false
        end    
    end
end

--------------wardrobe------------------

ACTIONS.CHANGEIN.priority = 3


local oldblink = ACTIONS.BLINK.fn
ACTIONS.BLINK.fn = function(act)
    if act.doer:HasDebuff("moon_curse") then
        return false
    end
	return oldblink(act)
end


----------------lunge-------------

local lunge = AddAction("LUNGE","突刺",function(act)
    act.doer:ForceFacePoint(act:GetActionPoint())
    act.doer.sg:GoToState("playerlunge")
    return true
end)
lunge.distance = 20
lunge.priority = 11





ACTIONS.JUMPIN.priority = 2

--------------dodge---------------

local dodge = AddAction("SHADOWDODGE","影走",function (act)
    act.doer:ForceFacePoint(act:GetActionPoint())
    return true
end)
dodge.distance = 20
dodge.priority = 11


------------------------------------------------------


ACTIONS.CASTAOE.pre_action_cb = function (act)
    if act.invobject and act.invobject:HasTag("locomote_atk") then
        act.options.instant = true
    end
end



AddComponentAction("EQUIPPED","complexprojectile",function(inst, doer, target, actions, right)
    if right and not (doer.components.playercontroller ~= nil and doer.components.playercontroller.isclientcontrollerattached) then
        local targetpos = target:GetPosition()
        if (not TheWorld.Map:IsGroundTargetBlocked(targetpos) or inst:HasTag("supertoughworker")) and
            (inst.CanTossInWorld == nil or inst:CanTossInWorld(doer, targetpos)) and
            (inst.replica.equippable == nil or not inst.replica.equippable:IsRestricted(doer) and not inst.replica.equippable:ShouldPreventUnequipping()) and
            not (inst:HasTag("special_action_toss") or inst:HasTag("deployable")) then

            table.insert(actions, ACTIONS.TOSS)
        end
    end
end)

