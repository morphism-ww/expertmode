return Class(function(self, inst)

    assert(TheWorld.ismastersim, "Retrofitmap_temp should not exist on client")

    local function replaceValueInList(t, oldval,val)
        for k, v in ipairs(t) do
            if v == oldval then
                t[k] = val
            end
        end
        return nil  -- 如果未找到，返回 nil
    end

    self.retrofit_cavetag = true
    function self:OnPostInit()
        if self.retrofit_cavetag then
            local topology = TheWorld.topology
            if topology and topology.nodes then
                self.retrofit_cavetag = false
                print ("Retrofitting for new map tags")
                for k,node in ipairs(topology.nodes) do
                    if node.tags~=nil then
                        replaceValueInList(node.tags,"DarkLand","notele")
                        if topology.ids[k] == "BOSSRUSH:0:Void_Land" then
                            table.insert(node.tags,"notele")    
                        end
                    end
                end
            end
        end
    end


    function self:OnSave()
        return {retrofit_cavetag = self.retrofit_cavetag}
    end
    
    function self:OnLoad(data)
        if data ~= nil then
            -- flags for OnPostLoad
            self.retrofit_cavetag = data.retrofit_cavetag or false
        end
    end
end)