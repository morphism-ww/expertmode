return Class(function(self, inst)

assert(TheWorld.ismastersim, "VoidLand_Manager should not exist on client")

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst
self.has_land = false
self.bossrush_on = false

self.level_list = {}
self.room_list = {}
self.acid_list = {}

local _players = {}
local _activeplayers = {}

local Abyss_Depth = {
    BOSSRUSH = 1,
    RUINS_TO_SHADOW = 1,
    Night_Land = 1,
    MeTal_Labyrinth_Task = 1,
    Iron_Miner = 1,
    Hades = 2,
    DarkGarden = 3
}

--Private
local _map = TheWorld.Map

local size = 32
local function isvalidarea( _left, _top, x_hat,y_hat)
    for x = 0, 50 do
        for y = 0, 50 do
            if not TileGroupManager:IsImpassableTile((_map:GetTile(_left +x_hat* x, _top + y*y_hat))) then
                return false
            end
        end
    end
    return true
end

local function FindOpenArea(map_width)
    if isvalidarea(0,0,1,1) then
        return 0,0
    elseif isvalidarea(map_width-size,0,1,1) then
        return  map_width-size,0
    elseif isvalidarea(0,map_width-size,1,-1) then
        return 0,map_width-size
    elseif isvalidarea(map_width-size,map_width-size,-1,-1) then
        return  map_width-size,map_width-size
    end
    return 0,0
end
local function AddWorldTopolopy(left, top)
    local _topology = TheWorld.topology
	local index = #_topology.ids + 1
	_topology.ids[index] = "BOSSRUSH:0:Void_Land"
	_topology.story_depths[index] = 0



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
	node.tags  = {"notele","nocavein"}
	node.type = NODE_TYPE.Default
	node.x = node.cent[1]
	node.y = node.cent[2]

	node.validedges = {}

	_topology.nodes[index] = node
    return index
end

local function AddTileNodeIdsForArea( node_index, left, top)
	for x = left, left + size do
		for y = top, top + size do
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
        args = {entitiesOut={}, width=map_width, height=map_height, rand_offset = false, debug_prefab_list=nil}
    }
    local left, top = FindOpenArea(map_width)
    obj_layout.Place({left,top}, "Void_Land", add_fn, nil, _map)
    
    local index = AddWorldTopolopy(left-map_width * 2, top-map_width * 2)
    AddTileNodeIdsForArea(index,  left,  top)
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
        if inst.components.playercontroller ~= nil then
            inst.components.playercontroller:SetCanUseMap(false)
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
    if _players[player.userid] then
        return
    end
    _players[player.userid] = true
    self:RegisterListener(player)
end

function self:UnregisterPlayer(player)
    if _players[player.userid] then
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

function self:OnPostInit()
    local _topology = TheWorld.topology
    for i, node in ipairs(_topology.nodes) do
        if node.tags and table.contains(node.tags, "Abyss") then
            local room_id = string.match(_topology.ids[i],"([^:]*)") 
            local level = Abyss_Depth[room_id]
            if level then
                self.level_list[i] = level
            end
            if room_id=="Night_Land" then
                self.acid_list[i] = true
            end
        end
	end
end


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
        has_land = self.has_land,
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