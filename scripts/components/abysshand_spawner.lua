--------------------------------------------------------------------------
--[[ AbyssHandSpawner class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

    assert(TheWorld.ismastersim, "Abysshand spawner should not exist on client")
    
    --------------------------------------------------------------------------
    --[[ Constants ]]
    --------------------------------------------------------------------------
    
    local INTERVAL = 30
    local VARIANCE = 30
    local RETRY_INTERVAL = 5
    local RETRY_VARIANCE = 5
    local MAX_HANDS_PER_FIRE = 2
    
    --------------------------------------------------------------------------
    --[[ Member variables ]]
    --------------------------------------------------------------------------
    
    --Public
    self.inst = inst
    
    --Private
    local _map = TheWorld.Map
    local _players = {}
    local _fueltags = {}
    local _fires = {}
    local _boattargets = {}
    --------------------------------------------------------------------------
    --[[ Private member functions ]]
    --------------------------------------------------------------------------
    
    
    local function StopTracking(ent, fireguid)
        if _fires[fireguid] ~= nil then
            table.removearrayvalue(_fires[fireguid], ent)
            if #_fires[fireguid] <= 0 then
                _fires[fireguid] = nil
            end
        end
    end
    
    local function StartTracking(ent, fireguid)
        if _fires[fireguid] == nil then
            _fires[fireguid] = { ent }
        else
            table.insert(_fires[fireguid], ent)
        end
        inst:ListenForEvent("onremove", function() StopTracking(ent, fireguid) end, ent)
    end
    
    local Reschedule
    
    local function Retry(player, params)
        Reschedule(player, params, RETRY_INTERVAL + RETRY_VARIANCE * math.random())
    end
    
    --local NEARFIRE_MUST_TAGS = { "lightsource" }
    local NEARFIRE_CANT_TAGS = { "INLIMBO","shadowlevel" }

    local function shouldKill(inst,player)
        return not (inst.components.riftspawner and inst.components.riftspawner:GetShadowRiftsEnabled() or
            player:HasTag("playerghost"))
    end

    local function ShouldSpawn(player)
        return player.components.areaaware:CurrentlyInTag("DarkLand")
    end
    
    local function SpawnHand(player, params)
    
        if #params.ents > 0 or not ShouldSpawn(player) then
            --Already spawned, or player is too young, try again next time
            Reschedule(player, params)
            return
        end
        local no_killer = true
        if shouldKill(inst,player) then
            local theta = math.random() * PI2
            local px,py,pz = player.Transform:GetWorldPosition()
            local eye = SpawnPrefab("abyss_eye")
            eye.Transform:SetPosition(px + 12*math.cos(theta),0,pz-12*math.sin(theta))
            eye:SetTarget(player)
            no_killer = false
        end

        local sanity = player.replica.sanity:IsInsanityMode() and player.replica.sanity:GetPercent() or 1
        if no_killer and sanity<0.5 then
            
            local radius = 5 + math.random() * 15
            local theta = math.random() * PI2
            local x, y, z = player.Transform:GetWorldPosition()
            local x1 = x + radius * math.cos(theta)
            local z1 = z - radius * math.sin(theta)
            local light = TheSim:GetLightAtPoint(x1, 0, z1)
            if light <= .1 then
                local ent = SpawnPrefab("abyss_eye")
                ent.Transform:SetPosition(x1, 0, z1)
            end    
        end

        -- this is for land and fire.
        local fire = FindEntity(player, 40, nil,nil, NEARFIRE_CANT_TAGS, _fueltags)
        if fire == nil then
            --No fire nearby, retry with delay
            Retry(player, params)
            return
        end
        local firehandcount = _fires[fire.GUID] ~= nil and #_fires[fire.GUID] or 0
        if firehandcount >= MAX_HANDS_PER_FIRE then
            --Max hands for this fire, try again next time
            Reschedule(player, params)
            return
        end
        local count = math.min(math.random(2), MAX_HANDS_PER_FIRE - firehandcount)
        local radius = 8
        local x, y, z = fire.Transform:GetWorldPosition()
        for i = 1, count * 2 do
            local angle = math.random() * PI2
            local result_offset = FindValidPositionByFan(angle, radius, 10, function(offset)
                local x1 = x + offset.x
                local z1 = z + offset.z
                return  _map:IsPassableAtPoint(x1, 0, z1)
                    and not _map:IsPointNearHole(Vector3(x1, 0, z1))
            end)
            if result_offset ~= nil then
                local ent = SpawnPrefab("shadowhand")
                ent.Transform:SetPosition(x + result_offset.x, 0, z + result_offset.z)
                ent:SetTargetLight(fire)
                table.insert(params.ents, ent)
                player:ListenForEvent("onremove", function(ent) table.removearrayvalue(params.ents, ent) end, ent)
                StartTracking(ent, fire.GUID)
                if #params.ents >= count then
                    break
                end
            end
        
        end
        if #params.ents > 0 then
            Reschedule(player, params)
        else
            --Nothing spawned, retry with delay
            Retry(player, params)
        end
    end
    
    Reschedule = function(player, params, delay, time)
        params.time = time or GetTime()
        params.delay = delay or (INTERVAL + VARIANCE * math.random())
        params.task = player:DoTaskInTime(params.delay, SpawnHand, params)
    end
    local function Start(player, params, time)
        if params.task == nil then
            Reschedule(player, params, params.delay, time)
        end
    end
    
    local function Stop(player, params, time)
        if params.task ~= nil then
            params.task:Cancel()
            params.task = nil
            params.delay = time ~= nil and math.max(0, params.delay + params.time - time) or nil
        end
    end
    
    --------------------------------------------------------------------------
    --[[ Private event handlers ]]
    --------------------------------------------------------------------------
    
    
    local function OnPlayerJoined(inst, player)
        if _players[player] ~= nil then
            return
        end
        local time = GetTime()
        if next(_players) == nil then
            for k, v in pairs(_players) do
                Start(k, v, time)
            end
        end
        _players[player] = { ents = {} }
        Start(player, _players[player])
    end
    
    local function OnPlayerLeft(inst, player)
        if _players[player] == nil then
            return
        end
        Stop(player, _players[player])
        _players[player] = nil
    end
    
    --------------------------------------------------------------------------
    --[[ Initialization ]]
    --------------------------------------------------------------------------
    
    --Initialize variables
    for k, v in pairs(FUELTYPE) do
        if v ~= FUELTYPE.USAGE then --Not a real fuel
            table.insert(_fueltags, v.."_fueled")
        end
    end
    table.insert(_fueltags,"starlight")
    
    for i, v in ipairs(AllPlayers) do
        OnPlayerJoined(inst, v)
    end
    
    --Register events
    inst:ListenForEvent("ms_playerjoined", OnPlayerJoined)
    inst:ListenForEvent("ms_playerleft", OnPlayerLeft)
    
    --------------------------------------------------------------------------
    --[[ Debug ]]
    --------------------------------------------------------------------------
    
    function self:GetDebugString()
        local count = 0
        for k, v in pairs(_players) do
            count = count + #v.ents
        end
        if count > 0 then
            return count == 1 and "1 shadowhand" or (tostring(count).." shadowhands")
        end
    end
    
    --------------------------------------------------------------------------
    --[[ End ]]
    --------------------------------------------------------------------------
    
end)