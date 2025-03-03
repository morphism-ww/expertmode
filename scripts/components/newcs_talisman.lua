local function try_rescue(inst)
    local medal = next(inst.components.newcs_talisman.sources)
    if medal ~= nil then
        SpawnPrefab("shadow_shield1").Transform:SetPosition(inst.Transform:GetWorldPosition())
        inst.components.health:DoDelta(30)
        inst:AddDebuff("buff_constant_protect","buff_constant_protect")
        medal:Remove()
    end
end

local function try_resist_debuff(inst)
    if inst.components.newcs_talisman:TryResist() then
        if inst.components.freezable~=nil and inst.components.freezable:IsFrozen() then
            inst.components.freezable:Unfreeze()
        end
    end
end

local function do_kill(inst,attacker)
    --inst.components.health:SetInvincible(false)
    inst.SoundEmitter:PlaySound("dontstarve/common/rebirth_amulet_poof")

    if attacker~=nil and attacker:IsValid() and not attacker.components.health:IsDead() then
        attacker.components.health:Kill()
    end
end

local function try_kill(inst,attacker)
    if inst.components.newcs_talisman:TryResist() then
        local stafflight = SpawnPrefab("staff_castinglight")
        stafflight.entity:SetParent(inst.entity)
        stafflight:SetUp({218/255,165/255,32/255 }, 1.2)
        inst.SoundEmitter:PlaySound("dontstarve/common/rebirth_amulet_raise")
        
        inst:DoTaskInTime(1.2,do_kill,attacker)
        return true
    end
    return false
end

local function AddListener(inst)
    inst:ListenForEvent("minhealth",try_rescue)
    inst:ListenForEvent("freeze",try_resist_debuff)
    inst:ListenForEvent("suspended",try_kill)
end

local function RemoveListener(inst)
    inst:RemoveEventCallback("minhealth",try_rescue)
    inst:RemoveEventCallback("freeze",try_resist_debuff)
    inst:RemoveEventCallback("suspended",try_kill)
end

local Talisman = Class(function(self, inst)
    self.inst = inst

    self.sources = {}
end)


function Talisman:AddSource(medal)
    if next(self.sources) == nil then
        AddListener(self.inst)    
    end
    self.sources[medal] = true
end

function Talisman:RemoveSource(medal)
    self.sources[medal] = nil
    if next(self.sources) == nil then
        RemoveListener(self.inst)
    end
end


function Talisman:TryResist()
    local medal = next(self.sources)
    if medal ~= nil then
        medal.components.finiteuses:Use(1)
        return true
    end
    return false
end

function Talisman:TryKillThreat(attacker)
    if self:TryResist() then
        do_kill(self.inst,attacker)
        return true
    end
    return false
end

return  Talisman