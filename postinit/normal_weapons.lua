local BOUNCE_MUST_TAGS = { "_combat" }
local BOUNCE_NO_TAGS = { "INLIMBO", "wall", "notarget", "player", "companion", "flight", "invisible", "noattack", "electricdamageimmune" }

local function TryElectricChain(inst,attacker,target,targets,count)
    if count<1 then
        targets = nil
        return
    end
    local x,y,z = target.Transform:GetWorldPosition()
    for i, v in ipairs(TheSim:FindEntities(x, 0, z, 5, BOUNCE_MUST_TAGS, BOUNCE_NO_TAGS)) do
        if v ~= target and v.entity:IsVisible() and not targets[v] and 
			not (v.components.health ~= nil and v.components.health:IsDead()) and
			attacker.components.combat:CanTarget(v) and not attacker.components.combat:IsAlly(v) then
            local fx = SpawnPrefab("electricchargedfx")
            fx:SetTarget(target)
            targets[v] = true
            fx:DoTaskInTime(0.3,function ()
                if v.entity:IsValid() and not (v.components.health ~= nil and v.components.health:IsDead()) then
                    
                    local mult = 1
                    if not (v:HasTag("electricdamageimmune") 
                    or (v.components.inventory ~= nil and v.components.inventory:IsInsulated())) then
                        mult = 1.5 + (v:GetIsWet() and 1 or 0)
                    end
                    v.components.combat:GetAttacked(attacker,(10+2*count)*mult,inst,"electric")
                    TryElectricChain(inst,attacker,v,targets,count-1)
                end
            end)
            break
        end
    end    
end

local function onattack(inst, attacker, target)
    if target ~= nil and target:IsValid() and attacker ~= nil and attacker:IsValid() then
        SpawnPrefab("electrichitsparks"):AlignToTarget(target, attacker, true)
        TryElectricChain(inst,attacker,target,{},5)
    end
end


newcs_env.AddPrefabPostInit("nightstick",function (inst)
    if not TheWorld.ismastersim then
        return inst
    end
    
    inst.components.weapon:SetOnAttack(onattack)
end)