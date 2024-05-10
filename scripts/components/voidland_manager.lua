

return Class(function(self, inst)

assert(TheWorld.ismastersim, "VoidLand_Manager should not exist on client")

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst
self.has_land = false
self.gate = nil 
self.bossrush_on = false
self.players = {}

--Private
local _map = TheWorld.Map



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
end

function self:HasLand()
    return self.has_land
end

function self:RegisterPlayer(player)
    if self.players[player] ~= nil then
        return
    end

    self.players[player] = true
end

function self:CountPlayer()
    return GetTableSize(self.players)
end

function self:HasPlayer()
    return self:CountPlayer()>0
end

function self:StartBossRush()
    self.bossrush_on = true
end

function self:UnregisterPlayer(player)
    if self.players[player]~=nil then
        self.players[player]=nil
    end
end

self.OnPlayerLeft = function(inst, player)
    if self.players[player] == nil then
        return
    end

    self.players[player] = nil
end

inst:ListenForEvent("ms_playerleft", self.OnPlayerLeft)
--------------------------------------------------------------------------
--[[ Save / Load ]]
--------------------------------------------------------------------------

function self:OnSave()

    local gate = {}
    if self.gate then
        table.insert(gate, self.gate.GUID)
    end

    return {has_land=self.has_land,gate=self.gate,game_start = self.bossrush_on},gate
end

function self:OnLoad(data)
	if data ~= nil then
		self.has_land = data.has_land
        self.bossrush_on = data.bossrush_on
	end
end

function self:LoadPostPass(newents, data)
    if data and data.gate then
        self.gate = newents[data.gate] and newents[data.gate].entity or nil
    end    
end

end)



-----TheWorld.components.bossrush_manager:GenerateLand()