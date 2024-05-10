
local function onequip(inst,data)
    if data.owner~=nil and data.owner:HasTag("player") then
        data.owner.components.locomotor:StartStrafing()
    end 
end
local function unequip(inst,data)
    if data.owner~=nil and data.owner:HasTag("player") then
        data.owner.components.locomotor:StopStrafing()
    end
end


AddPrefabPostInit("houndstooth_blowpipe",function (inst)
    inst:AddTag("move_shoot")
    if not TheWorld.ismastersim then return end


    --inst:AddComponent("move_attack")

    inst.components.container:EnableInfiniteStackSize(true)

    inst:ListenForEvent("equipped",onequip)
    inst:ListenForEvent("unequipped",unequip)
end)





