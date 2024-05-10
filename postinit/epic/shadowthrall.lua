AddStategraphPostInit("shadowthrall_hands",function(sg)
    sg.events["attacked"].fn=function(inst,data)
        return false
    end
end)

AddStategraphPostInit("shadowthrall_wings",function(sg)
    sg.events["attacked"].fn=function(inst,data)
        return false
    end
end)

AddStategraphPostInit("shadowthrall_horns",function(sg)
    sg.events["attacked"].fn=function(inst,data)
        return false
    end
end)