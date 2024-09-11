return Class(function(self, inst)

assert(TheWorld.ismastersim, "VoidLand_Manager should not exist on client")

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst
self.has_land = false
self.bossrush_on = false


local _players = {}
local _activeplayers = {}


--Private
local _map = TheWorld.Map

local function AddWorldTopolopy(left, top)
	local index = #TheWorld.topology.ids + 1
	TheWorld.topology.ids[index] = "BOSSRUSH:0:Void_Land"
	TheWorld.topology.story_depths[index] = 0

	local size = 64

	local node = {}
	node.area = size * size
	node.c = 1 -- colour index
	node.cent = {left + (size / 2), top + (size / 2)}
	node.neighbours = {}
	node.poly = { {left, top},
				  {left + size, top},
				  {left + size, top + size},
				  {left, top + size}
				}
	node.tags  = {"nocavein","Abyss"}
	node.type = NODE_TYPE.Default
	node.x = node.cent[1]
	node.y = node.cent[2]

	node.validedges = {}

	TheWorld.topology.nodes[index] = node
    return index
end

local function AddTileNodeIdsForArea( node_index, left, top)
	for x = left, left + 64 do
		for y = top, top + 64 do
			_map:SetTileNodeId(x, y, node_index)
		end
	end
end
--------------------------------------------------------------------------
--[[ Public member functions ]]
--------------------------------------------------------------------------

function self:GenerateLand(gate)
    self.has_land = true
    local obj_layout = require("map/object_layout")
	local map_width, map_height = _map:GetSize()
    --local scaled_mapdim = map_width* 0.85
    local add_fn = 
    {
        fn=function(prefab, points_x, points_y, current_pos_idx, entitiesOut, width, height, prefab_list, prefab_data, rand_offset)
            local x = (points_x[current_pos_idx] - width/2.0)*TILE_SCALE
            local y = (points_y[current_pos_idx] - height/2.0)*TILE_SCALE
            x = math.floor(x*100)/100.0
            y = math.floor(y*100)/100.0
            if prefab == "bossrush_manager" then
                local p1 = SpawnPrefab(prefab)
				p1.Transform:SetPosition(x, 0, y)
                gate.components.teleporter:Target(p1)
                p1.components.teleporter:Target(gate)
                p1.components.entitytracker:TrackEntity("gate", gate)
            else
                SpawnPrefab(prefab).Transform:SetPosition(x, 0, y)
            end       
        end,
        args={entitiesOut={}, width=map_width, height=map_height, rand_offset = false, debug_prefab_list=nil}
    }
    obj_layout.Place({0, 0}, "Void_Land", add_fn, nil, _map)
    local left, top = -map_width * 2,-map_width * 2
    local index = AddWorldTopolopy(left, top)
    AddTileNodeIdsForArea(index,    0,  0)
end

function self:AddTopolopy()
    local map_width, map_height = _map:GetSize()
    local left, top = -map_width * 2,-map_width * 2
    local index = AddWorldTopolopy(left, top)
    AddTileNodeIdsForArea(index,    0,  0)
end


function self:GetBattleMode()
    local mult = 1
    local index = 1
    for k,_ in pairs(_activeplayers) do
        if k:HasTag("strongman") or MODCHARACTERMODES[k] then
            mult = mult + 0.7
        elseif index~=1 then
            mult = mult + (index>4 and 0.3 or 0.2)
        end
        index = index + 1
    end
    return mult
end

function self:HasPlayer()
    return next(_activeplayers)~=nil
end


local function OnRegisterManager(inst,manager)
    self.manager = manager
end


local function OnLocalPlayersChanged(player)
    if player.player_classified~=nil then
        player.player_classified.MapExplorer:EnableUpdate(false)
    end
    if self.manager then
        self.manager:CheckForPlayerAlive()
    end
end


function self:RegisterListener(player)
    if _activeplayers[player]==nil then
        _activeplayers[player] = true
        inst:ListenForEvent("ms_becameghost", OnLocalPlayersChanged, player)
        inst:ListenForEvent("ms_respawnedfromghost", OnLocalPlayersChanged, player)
        if player.player_classified~=nil then
            player.player_classified.MapExplorer:EnableUpdate(false)
        end
        if player.components.playercontroller ~= nil then
            player.components.playercontroller:EnableMapControls(false)
        end
    end
    
end

function self:UnregisterListener(player)
    if _activeplayers[player]~=nil then
        _activeplayers[player] = nil
        inst:RemoveEventCallback("ms_becameghost", OnLocalPlayersChanged, player)
        inst:RemoveEventCallback("ms_respawnedfromghost", OnLocalPlayersChanged, player)
    end
end

function self:RegisterPlayer(player)
    if _players[player.userid] ~= nil then
        return
    end
    _players[player.userid] = true
    self:RegisterListener(player)
end

function self:UnregisterPlayer(player)
    if _players[player.userid]~=nil then
        self:UnregisterListener(player)
        _players[player.userid] = nil
    end
end

function self:ForceLunacy(enable)
    for k,v in pairs(_activeplayers) do
        k.components.sanity:EnableLunacy(enable, "bossrush")
    end
end


local function ClearBossrush()
    for k,v in pairs(_activeplayers) do
        self:UnregisterPlayer(k)
        _activeplayers[k] = nil
    end

    for k,v in pairs(_players) do
        _players[k] = nil
    end

    self.bossrush_on = false
end

local first_check = false
local function OnPlayerJoined(src, player)
    
    if self.bossrush_on then
        if _players[player.userid] then
            _activeplayers[player] = true
        end
        if not first_check then
            first_check = true
            TheWorld:PushEvent("bossrush_start",true)
        end 
    end
end

local function OnPlayerLeft(src,player)
    self:UnregisterListener(player)
end


inst:ListenForEvent("ms_registerBossRushManager", OnRegisterManager)
inst:ListenForEvent("ms_playerjoined",OnPlayerJoined)
inst:ListenForEvent("ms_playerleft", OnPlayerLeft)
inst:ListenForEvent("bossrush_end",ClearBossrush)
--------------------------------------------------------------------------
--[[ Save / Load ]]
--------------------------------------------------------------------------

function self:OnSave()

    local ents = {}
    if self.gate then
        table.insert(ents, self.gate.GUID)
    end


    return 
    {   
        has_land=self.has_land,
        gate = self.gate,
        game_start = self.bossrush_on,
        userids = _players
    },
    ents
end

function self:OnLoad(data)
	if data ~= nil then
		self.has_land = data.has_land
        self.bossrush_on = data.game_start
        if data.userids then
            _players = data.userids
        end
	end
end

function self:LoadPostPass(newents, data)
    if data and data.gate then
        self.gate = newents[data.gate] and newents[data.gate].entity or nil
    end    
end
end)