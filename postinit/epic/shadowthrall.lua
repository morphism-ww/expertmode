local function BurntOther(inst,data)
    if data.target:IsValid() and data.target.components.burnable~=nil then
		data.target:AddDebuff("buff_cursefire", "buff_cursefire")
	end
end

newcs_env.AddPrefabPostInit("fused_shadeling_bomb",function (inst)
    if not TheWorld.ismastersim then
        return inst
    end
    inst:ListenForEvent("onhitother",BurntOther)
end)

newcs_env.AddPrefabPostInit("fused_shadeling_quickfuse_bomb",function (inst)
    if not TheWorld.ismastersim then
        return inst
    end
    inst:ListenForEvent("onhitother",BurntOther)
end)

local function TryLurk(inst,data)
    if data.statename == "walk" then
        inst.sg:AddStateTag("hiding")
    end
end

newcs_env.AddPrefabPostInit("ruinsnightmare",function (inst)
    if not TheWorld.ismastersim then
        return inst
    end
    inst:SetStateGraph("SGruinsnightmare2")
    inst:ListenForEvent("newstate", TryLurk)

end)


newcs_env.AddPrefabPostInit("shadowthrall_mouth",function (inst)
    inst:AddTag("notaunt")
end)


newcs_env.AddComponentPostInit("shadowparasitemanager",function (self)
    local oldSpawn = self.SpawnParasiteWaveForPlayer
    local function IsValidSpawnPoint(pt)
        return not TheWorld.Map:IsPointNearHole(pt) or not IsAnyPlayerInRange(pt.x, 0, pt.z, PLAYER_CAMERA_SEE_DISTANCE)
    end
    function self:SpawnParasiteWaveForPlayer(player, joining)
        if self:GetShadowRift() == nil then
            return
        end

        oldSpawn(self,player,joining)
        if player.components.abysscurse~=nil and player.components.abysscurse.enter_abyss and math.random()<0.5 then
            local pt = player:GetPosition()
            local offset = FindWalkableOffset(pt, math.random()*TWOPI, PLAYER_CAMERA_SEE_DISTANCE+(math.random()*12), 16, nil, nil, IsValidSpawnPoint)

            if offset ~= nil then
                local host = SpawnPrefab("void_peghook")
                host.persists = false
                host.OnEntitySleep = host.Remove
                if host ~= nil then
                    local np = pt + offset
                    host.Transform:SetPosition(np:Get())
                    host.SoundEmitter:PlaySound("hallowednights2024/thrall_parasite/appear_taunt_offscreen")
                end
            end
        end
    end
end)