local function PoisonOther(inst, data)
    if data.target~=nil and data.target:IsPoisonable() and not data.redirected then
        data.target:AddDebuff("beequeen_poison","buff_deadpoison")
    end
end
newcs_env.AddPrefabPostInit("beequeen",function(inst)
    if not TheWorld.ismastersim then return end
    
    inst:ListenForEvent("onhitother", PoisonOther)
end)
