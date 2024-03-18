local function DoHurtSound(inst)
    if inst.hurtsoundoverride ~= nil then
        inst.SoundEmitter:PlaySound(inst.hurtsoundoverride, nil, inst.hurtsoundvolume)
    elseif not inst:HasTag("mime") then
        inst.SoundEmitter:PlaySound((inst.talker_path_override or "dontstarve/characters/")..(inst.soundsname or inst.prefab).."/hurt", nil, inst.hurtsoundvolume)
    end
end
AddStategraphPostInit("wilson", function(sg)
    local old_attackedfn=sg.events["attacked"].fn
    sg.events["attacked"].fn=function(inst,data)
        if not inst.components.health:IsDead() and not inst.sg:HasStateTag("drowning") then
            if inst:HasTag("stun_immune") then
                inst.SoundEmitter:PlaySound("dontstarve/wilson/hit")
                DoHurtSound(inst)
            else
               old_attackedfn(inst,data)
            end
        end
    end
end)