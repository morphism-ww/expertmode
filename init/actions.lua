local AddComponentAction = AddComponentAction
local AddAction = AddAction
local AddComponentPostInit = AddComponentPostInit
local CHARGE_KEYMAP = GLOBAL[GetModConfigData("charge_control",true)]
local CHARGE_MODE = GetModConfigData("charge_mode",true)

GLOBAL.setfenv(1,GLOBAL)


local HIGH_ACTION_PRIORITY = 10
local function ArriveAnywhere()
    return true
end


--TEST
--[[TheInput:AddKeyHandler(function (key,down)
    local flag = down and "true" or "false"
    c_announce(string.format("key: %d",key)..flag)
end)

TheInput:AddMouseButtonHandler(function (button,down)
    local flag = down and "true" or "false"
    c_announce(string.format("mouse: %d",button)..flag)
end)

TheInput:AddGeneralControlHandler(function (control, digitalvalue, analogvalue)
    print("control:",control,digitalvalue,analogvalue)
end)]]


AddAction("LAVASPIT","spit",function(act)
    if act.doer and act.target and act.doer.prefab == "newcs_dragoon" then
        local spit = SpawnPrefab("newcs_dragoonspit")
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


AddComponentPostInit("playeractionpicker",function (self)
    local old_fn = self.GetPointSpecialActions
    function self:GetPointSpecialActions(pos, useitem, right, usereticulepos)
        if self.inst.components.playercontroller:IsControlPressed(CONTROL_FORCE_INSPECT) then
            return {}
        end
        return old_fn(self,pos,useitem,right,usereticulepos)
    end
end)


local function GetActionForKeyhanle(inst,pos)
    if not CanEntitySeePoint(inst, pos:Get()) then
        return
    end
    local hat = inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    local act
    if hat~=nil then
        if hat:HasTag("playercharge") then
            act = ACTIONS.LUNGE 
        elseif hat:HasTag("shadowdodge") then
            act = ACTIONS.SHADOWDODGE
        end
    end
    local actionfilter = inst.components.playeractionpicker.actionfilter
    if act~=nil and (actionfilter == nil or actionfilter(inst, act)) then
        return BufferedAction(inst, nil, act, nil, pos)
    end
end

AddComponentPostInit("playercontroller", function(self)
    local old_activate = self.Activate
    local old_deactivate = self.Deactivate
    function self:Activate()
        old_activate(self)
        if self.handler~=nil then
            self.newcs_keyhandler = TheInput:AddKeyDownHandler(CHARGE_KEYMAP,(function() self:NewCS_keyhandle() end))
        end
    end
    function self:Deactivate()
        old_deactivate(self)
        if self.newcs_keyhandler~=nil then
            self.newcs_keyhandler:Remove()
            self.newcs_keyhandler = nil
        end
    end
    function self:NeWCS_Remote_keyhandle(position)
        if self.ismastersim and self:IsEnabled() and self.newcs_keyhandler == nil then
            local act = GetActionForKeyhanle(self.inst,position)
            if act~=nil then
                self:DoAction(act)
            end
        end
    end
    function self:NewCS_keyhandle()
        if IsPaused() then
            return
        end
    
        local isenabled, ishudblocking = self:IsEnabled()
        if not isenabled or ishudblocking then
            return
        end
        local position
        if CHARGE_MODE then
            position = TheInput:GetWorldPosition()
        else
            local theta = self.inst.Transform:GetRotation()*DEGREES
            local offset = Vector3(8 * math.cos( theta ), 0, -8 * math.sin( theta ))    
            position = self.inst:GetPosition() + offset
        end
        
        local act = GetActionForKeyhanle(self.inst,position)
        if act == nil then
            return
        end
        if not self.ismastersim then
            
            local platform, pos_x, pos_z = self:GetPlatformRelativePosition(position.x, position.z)
            if self.locomotor == nil then
				if act.action.pre_action_cb ~= nil then
					act.action.pre_action_cb(act)
				end
                SendModRPCToServer(GetModRPC("The_NewConstant","KeyHandle"),pos_x,pos_z,platform, platform ~= nil)
            elseif self:CanLocomote() then
                act.preview_cb = function()
                    SendModRPCToServer(GetModRPC("The_NewConstant","KeyHandle"),pos_x,pos_z,platform, platform ~= nil)
                end
            end
        end
        self:DoAction(act)
    end
end)

-----------------------------------------------------------------
----传送塔
-----------------------------------------------------------------
local townportal = Action({ priority=12, rmb=true, distance=2, mount_valid=true })
townportal.id = "DOTOWNPORTAL"
townportal.str = "使用传送塔"
townportal.fn = function(act)
    return true
end


AddAction(townportal)  

local townportal_map = Action({ priority=HIGH_ACTION_PRIORITY, customarrivecheck=ArriveAnywhere, rmb=true, mount_valid=true, map_action=true, closes_map=true, })
townportal_map.id = "DOTOWNPORTAL_MAP"
townportal_map.str = "使用传送塔"

townportal_map.fn = function(act)
    return true
end
AddAction(townportal_map)

AddComponentAction("POINT","teleporter", function (inst, doer, pos, actions, right)  
    if right and inst.prefab == "townportaltalisman" and inst:HasTag("donotautopick") then
        table.insert(actions, ACTIONS.DOTOWNPORTAL)
    end
end)

local MAP_SELECT_WORMHOLE_MUST = { "CLASSIFIED", "globalmapicon", "townportaltrackericon" }
ACTIONS_MAP_REMAP[ACTIONS.DOTOWNPORTAL.code] = function(act, targetpos)
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
                local act_remap = BufferedAction(doer, nil, ACTIONS.DOTOWNPORTAL_MAP, act.invobject, targetpos)
                return act_remap
            end
        end
    end
end


--------------wardrobe------------------

ACTIONS.CHANGEIN.priority = 3



ACTIONS.BLINK_MAP.customarrivecheck = function (inst,dest)
    local x,y,z = dest:GetPoint()
    return not (TheWorld.Map:NodeAtPointHasTag(x,y,z,"Abyss") or IsEntInAbyss(inst))
end


----------------lunge-------------

local lunge = AddAction("LUNGE","突刺",function(act)
    act.doer:ForceFacePoint(act:GetActionPoint())
    act.doer.sg:GoToState("playerlunge")
    return true
end)
lunge.distance = 20
lunge.priority = 11





ACTIONS.JUMPIN.priority = 10
ACTIONS.USEITEM.mount_valid = true
--------------dodge---------------

local dodge = AddAction("SHADOWDODGE","影走",function (act)
    local pt = act:GetActionPoint()
	if pt then
		act.doer:ForceFacePoint(pt)
		return true
	end
	return false
end)
dodge.invalid_hold_action = true
dodge.distance = 20


------------------------------------------------------


ACTIONS.CASTAOE.pre_action_cb = function (act)
    if act.invobject and act.invobject:HasTag("locomote_atk") then
        act.options.instant = true
    end
end


local magic_action_list = {"BLINK","CASTSPELL","CAST_SPELLBOOK","USEMAGICTOOL","USESPELLBOOK","READ"}
for k,name in ipairs(magic_action_list) do
    local oldfn = ACTIONS[name].fn
    ACTIONS[name].fn = function (act)
        if act.doer == nil then
            return oldfn(act)
        end
        if act.doer:HasDebuff("buff_mooncurse") then
            return  false
        end
        local pt = act.doer:IsValid() and act.doer:GetPosition() or act:GetActionPoint()
        if pt~=nil and act.doer then
            for k,v in ipairs(TheSim:FindEntities(pt.x, 0, pt.z,16,{"magic_blocker"})) do
                if act.doer.components.combat~=nil and act.doer.components.sanity then
                    act.doer.components.sanity:GetSoulAttacked(v, 20)
                    act.doer.components.combat:GetAttacked(v,50,nil,"darkness") 
                end
                return false    
            end 
        end
        return oldfn(act)
    end
end

local old_castaoe = ACTIONS.CASTAOE.fn
local cast_states = {"castspell","book_repeatcast","book","repeatcastspellmind","castspellmind"}
local function InCastState(sg)
    return table.contains(cast_states,sg.currentstate)
end

ACTIONS.CASTAOE.fn = function(act)
    if act.doer == nil then
        return old_castaoe(act)
    end
    local pt = act.doer:IsValid() and act.doer:GetPosition() or act:GetActionPoint()
    if pt~=nil and act.doer.sg~=nil and InCastState(act.doer.sg) then
        for k,v in ipairs(TheSim:FindEntities(pt.x, 0, pt.z,16,{"magic_blocker"})) do
            if act.doer.components.combat~=nil then
                act.doer.components.combat:GetAttacked(v,50,nil,"darkness") 
            end
            return false    
        end
    end
    return old_castaoe(act)
end


local aurumite_repair = AddAction("AURUMITE_REPAIR","修补",function(act)
    if act.target ~= nil then

        local material = act.invobject
        if material ~= nil and material.components.aurumiterepair ~= nil then
            return material.components.aurumiterepair:Repair(act.target,act.doer)
        end

    end
end)
aurumite_repair.mount_valid = true


AddComponentAction("USEITEM","aurumiterepair",function(inst, doer, target, actions, right)
    if right and inst:HasTag("mythical_repairer") then
        if doer.replica.rider ~= nil and doer.replica.rider:IsRiding() then
            if not (target.replica.inventoryitem ~= nil and target.replica.inventoryitem:IsGrandOwner(doer)) then
                return
            end
        elseif doer.replica.inventory ~= nil and doer.replica.inventory:IsHeavyLifting() then
            return
        end
        if target:HasTag("mythical") then
            table.insert(actions, ACTIONS.AURUMITE_REPAIR)
        end
    end
end)