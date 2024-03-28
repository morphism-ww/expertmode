--------------------------------------------------------------------------
--[[ Ancient_defender class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "Ancient_Defender should not exist on client")

--------------------------------------------------------------------------
--[[ Constants ]]
--------------------------------------------------------------------------

local NON_INSANITY_MODE_DESPAWN_INTERVAL = 0.1
local NON_INSANITY_MODE_DESPAWN_VARIANCE = 0.1

local OCEAN_SPAWN_ATTEMPTS = 4

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst

--Private

local _players = {}



--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------

local UpdateSpawn

local function StopTracking(player, params, ent)
    table.removearrayvalue(params.ents, ent)

    if params.targetpop ~= #params.ents then
        if params.spawntask == nil then
            params.spawntask = player:DoTaskInTime(TUNING.SANITYMONSTERS_SPAWN_INTERVAL + TUNING.SANITYMONSTERS_SPAWN_VARIANCE * math.random(), UpdateSpawn, params)
        end
    elseif params.spawntask ~= nil then
        params.spawntask:Cancel()
        params.spawntask = nil
    end
end

local function StartTracking(player, params, ent)
    table.insert(params.ents, ent)
    ent.spawnedforplayer = player

    inst:ListenForEvent("onremove", function()
        if _players[player] == params then
            StopTracking(player, params, ent)
        end
    end, ent)

    inst:ListenForEvent("entitysleep", function()
        inst:DoTaskInTime(0, function() ent:Remove() end)
    end, ent)

    ent:ListenForEvent("onremove", function()
        ent.spawnedforplayer = nil
        ent.persists = false
        ent.wantstodespawn = true
    end, player)
end


local function SpawnLandShadowCreature(player)
    return SpawnPrefab("shadowdragon")
end


function self:SpawnShadowCreature(player, params)
    params = params or _players[player]

    local x, y, z = player.Transform:GetWorldPosition()
    local boat = player:GetCurrentPlatform()
    if player.components.sanity:GetPercent() < .2  then
        local angle = math.random() * 2 * PI
        x = x + 10 * math.cos(angle)
        z = z - 10 * math.sin(angle)
        local ent = SpawnLandShadowCreature(player)
        ent.Transform:SetPosition(x, 0, z)
        StartTracking(player, params, ent)
    end
end

UpdateSpawn = function(player, params)
    if params.targetpop > #params.ents then
        self:SpawnShadowCreature(player, params)

        --Reschedule spawning if we haven't reached our target population
        params.spawntask =
            params.targetpop ~= #params.ents
            and player:DoTaskInTime(5, UpdateSpawn, params)
            or nil
    elseif params.targetpop < #params.ents then
        --Remove random monsters until we reach our target population
        local toremove = {}
        for i, v in ipairs(params.ents) do
            if not v.wantstodespawn then
                table.insert(toremove, v)
            end
        end

        for i = #toremove, params.targetpop + 1, -1 do
            local ent = table.remove(toremove, math.random(i))
            ent.persists = false
            ent.wantstodespawn = true
        end

        --Don't reschedule spawning
        params.spawntask = nil
    else
        --Don't reschedule spawning
        params.spawntask = nil
    end
end

local function StartSpawn(player, params)
    if params.spawntask == nil then
        params.spawntask = player:DoTaskInTime(0, UpdateSpawn, params)
    end
end

local function StopSpawn(player, params)
    if params.spawntask ~= nil then
        params.spawntask:Cancel()
        params.spawntask = nil
    end
end

--[[local function GetArea(player)
    local x,y,z=player.Transform:GetWorldPosition()
    local node, node_index = TheWorld.Map:FindVisualNodeAtPoint(x, y, z)
    return node~=nil and node.tags~=nil and table.contains(node.tags, "Nightmare")
end]]

local function UpdatePopulation(player, params)
	local is_insanity_mode = player.components.sanity:IsInsanityMode()

    local canspawn= is_insanity_mode and not player.components.sanity.inducedinsanity and player.components.areaaware:CurrentlyInTag("Nightmare")
    local maxpop = 0
    local inc_chance = 0
    local dec_chance = 0
    local targetpop = params.targetpop
    local sanity = is_insanity_mode and player.components.sanity:GetPercent() or 1

    if sanity > 0.2 then
        --We're pretty sane. Clean up the monsters
        maxpop = 0
    elseif sanity > 0.1 and canspawn then
        --Have at most one monster, sometimes
        maxpop = 1
        if targetpop >= maxpop then
            dec_chance = 0.2
        else
            inc_chance = 0.2
        end
    elseif sanity > 0.0 and canspawn then
        maxpop = 2
        if targetpop >= maxpop then
            dec_chance = 0
        elseif targetpop <= 0 then
            inc_chance = 1
        else
            inc_chance = 1
            dec_chance = 0
        end
    elseif canspawn then
        maxpop = 3
        if targetpop >= maxpop then
            dec_chance = 0
        elseif targetpop <= 0 then
            inc_chance = 1
        else
            inc_chance = 1
            dec_chance = 0
        end
    end

    --Figure out our new target
    if targetpop > maxpop then
        targetpop = targetpop - 1
    elseif inc_chance > 0 and math.random() < inc_chance then
        if targetpop < maxpop then
            targetpop = targetpop + 1
        end
    elseif dec_chance > 0 and math.random() < dec_chance then
        if targetpop < maxpop then
            targetpop = targetpop - 1
        end
    end

    --Start spawner if target population has changed
    if params.targetpop ~= targetpop then
        params.targetpop = targetpop
        StartSpawn(player, params)
    end

    --Reschedule population update
    params.poptask = player:DoTaskInTime(10+5*math.random(), UpdatePopulation, params)
end

local function Start(player, params)
    if params.poptask == nil then
        params.poptask = player:DoTaskInTime(0, UpdatePopulation, params)
    end
end

local function Stop(player, params)
    StopSpawn(player, params)
    if params.poptask ~= nil then
        params.poptask:Cancel()
        params.poptask = nil
    end
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnInducedInsanity(player)
    local params = _players[player]
    if params ~= nil then
        --Reset the update timers to 0 for this player
        Stop(player, params)
        Start(player, params)
    end
end

local function OnPlayerJoined(inst, player)
    if _players[player] ~= nil then
        return
    end
    _players[player] = { ents = {}, targetpop = 0 }
    Start(player, _players[player])
    inst:ListenForEvent("inducedinsanity", OnInducedInsanity, player)
    inst:ListenForEvent("sanitymodechanged", OnInducedInsanity, player)
end

local function OnPlayerLeft(inst, player)
    if _players[player] == nil then
        return
    end
    inst:RemoveEventCallback("inducedinsanity", OnInducedInsanity, player)
    inst:RemoveEventCallback("sanitymodechanged", OnInducedInsanity, player)
    Stop(player, _players[player])
    _players[player] = nil
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Initialize variables
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
        return count == 1 and "1 shadowcreature" or (tostring(count).." shadowcreatures")
    end
end

--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
