local AddClassPostConstruct = AddClassPostConstruct
GLOBAL.setfenv(1, GLOBAL)
AddClassPostConstruct("map/storygen", function(self)
    
    ----Abyss:深渊，noteleport:禁止传送
    self.map_tags.Tag["Abyss"] = function(tagdata) return "TAG", "Abyss" end
    self.map_tags.Tag["notele"] = function(tagdata) return "TAG", "notele" end


    function self:AddRegionsToMainland(on_region_added_fn)
        for region_id, region_taskset in pairs(self.region_tasksets) do
            if region_id=="abyss" then
                local c1, c2 = self:FindMainlandNodesForAbyss()
                local new_region = self:GenerateNodesForAbyss(region_taskset, "RestrictNodesByKey")

                local new_task_nodes = {}
                for k, v in pairs(region_taskset) do
                    new_task_nodes[k] = self.TERRAIN[k]
                end
                self:AddCoveNodes(new_task_nodes)
                self:InsertAdditionalSetPieces(new_task_nodes)

                self:LinkRegions_InCave(c1, new_region.entranceNode)
                self:LinkRegions_InCave(c2, new_region.finalNode)

                if on_region_added_fn ~= nil then
                    on_region_added_fn()
                end
            elseif region_id~="mainland" then
                local c1, c2 = self:FindMainlandNodesForNewRegion()
                local new_region = self:GenerateNodesForRegion(region_taskset, "RestrictNodesByKey")

                local new_task_nodes = {}
                for k, v in pairs(region_taskset) do
                    new_task_nodes[k] = self.TERRAIN[k]
                end
                self:AddCoveNodes(new_task_nodes)
                self:InsertAdditionalSetPieces(new_task_nodes)

                self:LinkRegions(c1, new_region.entranceNode)
                self:LinkRegions(c2, new_region.finalNode)

                if on_region_added_fn ~= nil then
                    on_region_added_fn()
                end
            end
        end
    end

    function self:GenerateNodesForAbyss(taskset, layout_mode)
        assert(layout_mode ~= nil, "Must specify a layout mode for your level.")
    
        if taskset == nil then return end
    
        -- Generate all the TERRAIN
        local task_nodes = {}
        for k, task in pairs(taskset) do
            assert(self.TERRAIN[task.id] == nil, "Cannot add the same task twice!")
    
            local task_node = self:GenerateNodesFromTask(task, task.crosslink_factor or 1, nil)
            self.TERRAIN[task.id] = task_node
            task_nodes[task.id] = task_node
        end
    
        local startingTask = self:_FindStartingTask(task_nodes)
        task_nodes[startingTask.id] = nil
    
        print("[Story Gen] Generate nodes. Starting at: '" .. startingTask.id .. "'")
        --dumptable(task_nodes, 1, 1)
    
        local finalNode = nil
        if string.upper(layout_mode) == string.upper("RestrictNodesByKey") then
            finalNode = self:RestrictNodesByKey(startingTask, task_nodes)
        else
            finalNode = self:LinkNodesByKeys(startingTask, task_nodes)
        end
    
        local entranceNode
        for k, v in pairs(startingTask.nodes) do
            if v.data.entrance then
                entranceNode = v
            end
        end

        assert(entranceNode~=nil, "Fail To Get EntranceNode!!!")
    
    
        -- TODO: SeperateStoryByBlanks has bad names in the lock edge ID, might have bad rooms too!
        --       This might be one of the sources of bad debug rendering!!!!
    
        -- form the map into a loop!
        --[[if entranceNode.data.task ~= finalNode.data.task then
            if self.gen_params.loop_percent ~= nil then
                if math.random() < self.gen_params.loop_percent then
                    --print("Adding map loop")
                    self:SeperateStoryByBlanks(entranceNode, finalNode )
                end
            else
                if math.random() < 0.5 then
                    --print("Adding map loop")
                    self:SeperateStoryByBlanks(entranceNode, finalNode )
                end
            end
        end]]
    
        return {startingTask = startingTask, entranceNode = entranceNode, finalNode = finalNode}
    end

    function self:FindMainlandNodesForAbyss()
        print("[Story Gen] Finding nodes on mainland to connect a region to.")
    
        local next_bucket = {	{{{x=2, y=1}, {x=1, y=2}}, {{x=1, y=1}, {x=3, y=1}}, {{x=2, y=1}, {x=3, y=2}}},
                                {{{x=1, y=1}, {x=1, y=3}}, {{x=2, y=2}, {x=2, y=2}}, {{x=3, y=1}, {x=3, y=3}}},
                                {{{x=1, y=2}, {x=2, y=3}}, {{x=1, y=3}, {x=3, y=3}}, {{x=2, y=3}, {x=3, y=2}}} }
        local bucket_counts = {}
        for x = 1, 3 do
            for y = 1, 3 do
                
                table.insert(bucket_counts, {x = x, y = y, count = 0})
                
            end
        end
    
        local function _GetOffsetPositionsAndSize(task_nodes)
            local pos = {}
            local min_x, max_x = math.huge, -math.huge
            local min_y, max_y = math.huge, -math.huge
            for t_id, t in pairs(task_nodes) do
                for n_id, n in pairs(t.nodes) do
                    if n.data.task ~= nil then
                        local _x, _y = WorldSim:GetSite(n_id)
                        pos[n_id] = {x = _x, y = _y, node = n}
                        min_x, max_x = math.min(_x, min_x), math.max(_x, max_x)
                        min_y, max_y = math.min(_y, min_y), math.max(_y, max_y)
                    end
                end
            end
            local padding = 5
            min_x, max_x = math.floor(min_x - padding), math.ceil(max_x + padding)
            min_y, max_y = math.floor(min_y - padding), math.ceil(max_y + padding)
    
            local offset_x, offset_y = -min_x, -min_y
    
            max_x = max_x - min_x
            max_y = max_y - min_y
            if max_y < max_x then
                offset_y = offset_y + (max_x - max_y)/2
            else
                offset_x = offset_x + (max_y - max_x)/2
            end
    
            for _, v in pairs(pos) do
                v.x = v.x + offset_x
                v.y = v.y + offset_y
            end
    
            return pos, math.max(max_x, max_y)
        end
    
        local function _FindBestNodes(node_pos, target_bucket, w)
            local function GetClosestNode(point, exclude_task)
                local closest_node = {node = nil, dist = math.huge}
                for n_id, n in pairs(node_pos) do
                    if n.node.data.type ~= NODE_TYPE.Blank 
                        and not (string.find(n.node.id , "Military"))
                        and (exclude_task == nil or node_pos[n_id].node.data.task ~= exclude_task)then
                        local dist = DistXYSq(point, n)
                        if dist < closest_node.dist then
                            closest_node.dist = dist
                            closest_node.node = node_pos[n_id]
                        end
                    end
                end
                return closest_node.node,closest_node.dist
            end
    
            local bucket_outer_pt = {x = (target_bucket.x - 1) * w/2, y = (target_bucket.y - 1) * w/2}
            local bucket_edge_pts = {	{{{x=0, y=w/3},   {x=w/3, y=0}},	{{x=w/3, y=0}, {x=2*w/3, y=0}}, {{x=2*w/3, y=0}, {x=w, y=w/3}}},
                                        {{{x=0, y=w/3},   {x=0, y=2*w/3}},	{},								{{x=w, y=w/3},   {x=w, y=2*w/3}}},
                                        {{{x=0, y=2*w/3}, {x=w/3, y=w}},	{{x=w/3, y=w}, {x=2*w/3, y=w}}, {{x=2*w/3, y=w}, {x=w, y=2*w/3}}}
                                    }
    
            local bucket_p1, bucket_p2 = bucket_edge_pts[target_bucket.y][target_bucket.x][1],bucket_edge_pts[target_bucket.y][target_bucket.x][2]
            
            local closest_node1, dist1= GetClosestNode(target_bucket.count == 0 and bucket_outer_pt or bucket_p1)
    
            if target_bucket.count == 0 then
                bucket_p2 = (DistXYSq(closest_node1, bucket_p1) < DistXYSq(closest_node1, bucket_p2)) and bucket_p2 or bucket_p1
            end
            
            local closest_node2,dist2 = GetClosestNode(bucket_p2, closest_node1.node.data.task)
    
            return math.min(dist1,dist2),closest_node1, closest_node2
        end
    
        local node_pos, w = _GetOffsetPositionsAndSize(self.TERRAIN)
    
        for n_id, n in pairs(node_pos) do
            local x = 1 + math.max(0, math.floor(((n.x) / w) * 3))
            local y = 1 + math.max(0, math.floor(((n.y) / w) * 3))
            bucket_counts[(x-1) * 3 + y].count = bucket_counts[(x-1) * 3 + y].count + 1
        end
        --GLOBAL.shuffleArray(bucket_counts)
        --table.sort(bucket_counts, function(a, b) return a.count < b.count end)
    
    --	local str = "\n"
    --	for y = 1, 3 do for x = 1, 3 do str = str .. tostring(bucket_counts[(x-1) * 3 + y].count) .. "\t" end str = str .. "\n" end
    --	print(str)
        
        local min_dist = 0
        local best_node1, best_node2
        for i, bucket in ipairs(bucket_counts) do
            if bucket.x~=2 or bucket.y~=2 then
                local dist,node1,node2 = _FindBestNodes(node_pos, bucket, w)
                if dist>=min_dist then
                    min_dist = dist
                    best_node1, best_node2 = node1,node2
                end
            end
        end
        --local bucket = (bucket_counts[1].x == 2 and bucket_counts[1].y == 2) and bucket_counts[2] or bucket_counts[1] -- never pick the center bucket, even if it is the best
        return best_node1, best_node2
    end
    function self:LinkRegions_InCave(n1, n2)
        local task_id = "REGION_LINK_"..tostring(self.region_link_tasks)
        local node_task = Graph(task_id, {parent=self.rootNode, default_bg=WORLD_TILES.IMPASSABLE, colour = {r=0,g=0,b=0,a=1}, background="BGImpassable" })
        WorldSim:AddChild(self.rootNode.id, task_id, WORLD_TILES.IMPASSABLE, 0, 0, 0, 1, "blank")
    
        local nodes = {}
        local prev_node = nil
        for i = 1, 2 do
            --local id = task_id..":REGION_LINK_SUB_"..tostring(i)
            WorldSim:AddChild(self.rootNode.id, task_id, WORLD_TILES.IMPASSABLE, 0, 0, 0, 1, "blank")
            table.insert(nodes, node_task:AddNode({
                                                    id=task_id..":REGION_LINK_SUB_"..tostring(i),
                                                    data={
                                                            type = NODE_TYPE.Blocker,
                                                            name="REGION_LINK_SUB",
                                                            tags = {"RoadPoison","ForceConnected"},
                                                            colour={r=0,g=0,b=0,a=1},
                                                            value = WORLD_TILES.IMPASSABLE
                                                        }
                                                }))
            if i > 1 then
                node_task:AddEdge({node1id=nodes[#nodes-1].id, node2id=nodes[#nodes].id})
            end
        end
        --node_task:AddEdge({node1id=nodes[1].id, node2id=nodes[#nodes].id})
    
        self.rootNode:LockGraph(n1.node.data.task..'->'..nodes[1].id, 	n1.node, nodes[1], {type="none", key=KEYS.NONE, node=nil})
        self.rootNode:LockGraph(task_id..'->'..n2.id, 	                nodes[2], n2, {type="none", key=KEYS.NONE, node=nil})
    
        self.region_link_tasks = self.region_link_tasks + 1
    end
end)
