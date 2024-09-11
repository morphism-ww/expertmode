local function SpawnQueen()
    local self = TheWorld.components.lunarthrall_queen_spawner
    --print("self.waves_to_release",self.waves_to_release)

    self.currentrift.SoundEmitter:PlaySound("monkeyisland/portal/buildup_burst")
    self.inst:DoTaskInTime(4,function()
        

        -- find herd to infest
        local plants = {}


        local patch = self:FindWildPatch()
        if patch and #patch > 0 then
            for i,member in ipairs(patch)do
                table.insert(plants,member)
            end
        else
            return
        end


        local target = plants[math.random(1,#plants)]
        self:InvadeTarget(target)
    end)
end

local function OnLunarRiftReachedMaxSize(source, rift)
    --print("MAX SIZE REACHED")
    if not TUNING.ALLOW_LUNAR_QUEEN then return end

    local self = TheWorld.components.lunarthrall_queen_spawner
    if not self.currentrift then
        self.currentrift = rift
    end

    if not self.attack then
        self.attack = true
        if not self:HasQueen() then
            
            SpawnQueen()
        end
    end    
end

local function OnQueenDeath(inst, data)
	local manager = TheWorld.components.lunarthrall_queen_spawner
	manager.queen.persists = false

end

local function OnQueenRemoval(inst, data)
	local self = TheWorld.components.lunarthrall_queen_spawner

	self.inst:RemoveEventCallback("onremove", OnQueenRemoval, self.queen)
	self.inst:RemoveEventCallback("death", OnQueenDeath, self.queen)


	self.king = nil

end


local function OnLunarPortalRemoved(source,portal)
    local self = TheWorld.components.lunarthrall_queen_spawner
    if portal == self.currentrift then
        self.currentrift = nil
        self.attack=nil
    end
end


local Queen_spawner = Class(function(self, inst)
    self.inst = inst
    self.queen=nil
    self.attack=nil
    self.currentrift = nil
    self.inst:ListenForEvent("ms_lunarrift_maxsize", OnLunarRiftReachedMaxSize)
    self.inst:ListenForEvent("ms_lunarportal_removed", OnLunarPortalRemoved)
end)




function Queen_spawner:InvadeTarget(target)
    local moonplant = SpawnPrefab("lunarthrall_plant_queen")
    moonplant:infest(target)
    moonplant:playSpawnAnimation()
    self.queen = moonplant
    self.inst:ListenForEvent("onremove", OnQueenRemoval, self.queen)
	self.inst:ListenForEvent("death", OnQueenDeath, self.queen)
end




local PLANTS_MUST = {"plant","tree"}
local BLOCKERS_MUST_TAGS = {"no_queen"}
function Queen_spawner:FindWildPatch()
    local tries = {}
    local candidtate_nodes={}
    for i,v in ipairs(TheWorld.topology.ids) do
		if string.find(v,"Forest") then
			table.insert(candidtate_nodes, TheWorld.topology.nodes[i])
		end
	end

    if #candidtate_nodes == 0 then
		print("Failed to find any Forest nodes!")
		return false
	end

    while #tries < 20 do
		local area = candidtate_nodes[math.random(#candidtate_nodes)]
		local points_x, points_y = TheWorld.Map:GetRandomPointsForSite(area.x, area.y, area.poly, 1)
		if #points_x >= 1 and #points_y >= 1 then
            
			local x = points_x[1]
			local z = points_y[1]
            local noqueen = TheSim:FindEntities(x, 0, z, 30, BLOCKERS_MUST_TAGS)
            local ents = TheSim:FindEntities(x, 0, z, 14, PLANTS_MUST)
            if #ents >6 and next(noqueen)==nil then
                table.insert(tries,ents)
            end
        end   
    end

    local top = 0
    local choice = nil
    for i,try in ipairs(tries)do
        if #try > top then
            choice = i
            top = #try
        end
    end
    if choice then
        return tries[choice]
    end
end


function Queen_spawner:HasQueen()
    return self.queen~=nil
end

function Queen_spawner:OnSave()

    local ents = {}
    if self.currentrift then
        table.insert(ents, self.currentrift.GUID)
    end
    if self.queen then
        table.insert(ents,self.queen.GUID)
    end

    return {
        currentrift = self.currentrift and self.currentrift.GUID or nil,
        queen=self.queen and self.queen.GUID or nil ,
        attack=self.attack
    }, ents
end


function Queen_spawner:LoadPostPass(newents, data)
    if data and data.currentrift then
        self.currentrift = newents[data.currentrift] and newents[data.currentrift].entity or nil
    end    
    if data and data.queen then
        self.queen=newents[data.queen] and newents[data.queen].entity or nil
        self.inst:ListenForEvent("onremove", OnQueenRemoval, self.queen)
		self.inst:ListenForEvent("death", OnQueenDeath, self.queen)
    end
end

function Queen_spawner:OnLoad(data)
    if data and data.attack then
        self.attack = data.attack
    end
end

function Queen_spawner:GetDebugString()
    return self.queen~=nil and self.queen.prefab or "<nil>"
end


return Queen_spawner