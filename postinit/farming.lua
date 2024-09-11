
local function farm_expert(inst,data)
    if data.owner:HasTag("player") then
        data.owner:AddTag("quagmire_fasthands")
    end
end
local function not_farm_expert(inst,data)
    if data.owner~=nil then
        data.owner:RemoveTag("quagmire_fasthands")
    end
end

AddPrefabPostInit("plantregistryhat",function(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("equipped",farm_expert)
    inst:ListenForEvent("unequipped",not_farm_expert)

end)


local function farm_master(inst,data)
    if data.owner:HasTag("player") then
        data.owner:AddTag("farmplantfastpicker")
        data.owner:AddTag("quagmire_farmhand")
    end
end
local function not_farm_master(inst,data)
    if data.owner~=nil then
        data.owner:RemoveTag("farmplantfastpicker")
        data.owner:RemoveTag("quagmire_farmhand")
    end
end

AddPrefabPostInit("nutrientsgoggleshat",function(inst)
    if not TheWorld.ismastersim then
        return inst
    end

    inst:ListenForEvent("equipped",farm_master)
    inst:ListenForEvent("unequipped",not_farm_master)

end)




AddComponentPostInit("farmtiller",function (self)
    function self:Till(pt, doer)
        if TheWorld.Map:CanTillSoilAtPoint(pt.x, 0, pt.z, false) then
            if doer~=nil and  doer:HasTag("quagmire_farmhand") then
                local cx, cy, cz = TheWorld.Map:GetTileCenterPoint(pt.x, 0, pt.z)
                -- 清除这块地皮上多余的土堆
                local ents = TheWorld.Map:GetEntitiesOnTileAtPoint(cx, 0, cz)
                for _, ent in ipairs(ents) do
                    if ent:HasTag("soil") then -- 是土堆，则清除
                        ent:PushEvent("collapsesoil")
                    end
                end
                -- 生成整齐的土堆
                for i = -1, 1 do
                    for j = -1, 1 do
                        local nx = cx + 1.3 * i
                        local nz = cz + 1.3 * j
                        if TheWorld.Map:CanTillSoilAtPoint(nx, 0, nz, false) then
                            SpawnPrefab("farm_soil").Transform:SetPosition(nx,0,nz)
                        end   
                    end
                end
            else
                TheWorld.Map:CollapseSoilAtPoint(pt.x, 0, pt.z)
                SpawnPrefab("farm_soil").Transform:SetPosition(pt:Get())
            end    
            if doer ~= nil then
                doer:PushEvent("tilling")
            end
            return true
        end
        return false
    end
end)