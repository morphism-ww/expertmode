local function MakeReplacePrefab(name,replace)
    local function fn()
       local inst =  Prefabs[replace].fn()
       inst:SetPrefabName(replace)
       return inst
    end
    return Prefab(name,fn)
end

return MakeReplacePrefab("cs_dreadsword","dreadsword")