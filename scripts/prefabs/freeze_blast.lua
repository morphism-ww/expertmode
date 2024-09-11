local assets =
{
	Asset("ANIM", "anim/winter_ornaments2021.zip"),
}

local function onfreeze(inst, target)
    if not target:IsValid() then
        --target killed or removed in combat damage phase
        return
    end

    if target.components.burnable ~= nil then
        if target.components.burnable:IsBurning() then
            target.components.burnable:Extinguish()
        elseif target.components.burnable:IsSmoldering() then
            target.components.burnable:SmotherSmolder()
        end
    end

    if target.components.combat ~= nil and inst.owner and inst.owner:IsValid() then
        target.components.combat:SuggestTarget(inst.owner)
    end

    if target.sg ~= nil and not target.sg:HasStateTag("frozen") and inst.owner and inst.owner:IsValid() then
        target:PushEvent("attacked", { attacker = inst.owner, damage = 0, weapon = inst })
    end

    if target.components.freezable ~= nil then
        target.components.freezable:AddColdness(30,25)
        target.components.freezable:SpawnShatterFX()
    end
end

local function dofreezefz(inst)
    if inst.freezetask then
        inst.freezetask:Cancel()
        inst.freezetask = nil
    end
    local time = 0.1
    inst.freezetask = inst:DoTaskInTime(time,function() inst.freezefx(inst) end)
end

local function freezefx(inst)
    local function spawnfx()
        local MAXRADIUS = 12
        local x,y,z = inst.Transform:GetWorldPosition()
        local theta = math.random()*PI2
        local radius = 4+ math.pow(math.random(),0.8)* MAXRADIUS
        local offset = Vector3(radius * math.cos( theta ), 0, -radius * math.sin( theta ))

        local prefab = "crab_king_icefx"
        local fx = SpawnPrefab(prefab)
        fx.Transform:SetPosition(x+offset.x,y+offset.y,z+offset.z)
    end

    local MAXFX = 15


    local fx = Remap(inst.components.age:GetAge(),0,10,2,MAXFX)

    for i=1,fx do
        if math.random()<0.2 then
            spawnfx()
        end
    end

    dofreezefz(inst)
end

local FREEZE_CANT_TAGS = {"shadow", "ghost", "playerghost", "FX", "NOCLICK", "DECOR", "INLIMBO"}

local function dofreeze(inst)
    local pos = Vector3(inst.Transform:GetWorldPosition())
    local range = 20
    local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, range, nil, FREEZE_CANT_TAGS)
    for i,v in ipairs(ents)do
        if v.components.temperature then
            local rate = 15
            if v.components.moisture then
                rate = rate * Remap(v.components.moisture:GetMoisture(),0,v.components.moisture.maxmoisture,1,3)
            end

            local mintemp = v.components.temperature.mintemp
            local curtemp = v.components.temperature:GetCurrent()
            if mintemp < curtemp then
                v.components.temperature:DoDelta(math.max(-rate, mintemp - curtemp))
            end
        end
    end

    local time = 0.2
    inst.lowertemptask = inst:DoTaskInTime(time,function() inst.dofreeze(inst) end)
end

local function endfreeze(inst)
    if inst.freezetask then
        inst.freezetask:Cancel()
        inst.freezetask = nil
    end

    if inst.lowertemptask then
        inst.lowertemptask:Cancel()
        inst.lowertemptask = nil
    end

    local pos = Vector3(inst.Transform:GetWorldPosition())
    local range = 20
    local ents = TheSim:FindEntities(pos.x, pos.y, pos.z, range, nil, FREEZE_CANT_TAGS)
    for i,v in pairs(ents)do
        onfreeze(inst, v)
    end
    SpawnPrefab("crabking_ring_fx").Transform:SetPosition(pos.x,pos.y,pos.z)
    inst:DoTaskInTime(1,function() inst:Remove() end)
end

local function fn()
	local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()

    inst:AddTag("NOCLICK")
    inst:AddTag("fx")
    inst:AddTag("freeze_blast")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("age")

    inst.persists = false

    inst.freezefx = freezefx
    inst.dofreeze = dofreeze
    inst:DoTaskInTime(0,function()
        dofreezefz(inst)
        dofreeze(inst)
    end)

    inst.SoundEmitter:PlaySound("hookline_2/creatures/boss/ownerking/ice_attack")

    inst:ListenForEvent("onremove", function()
        if inst.burbletask then
            inst.burbletask:Cancel()
            inst.burbletask = nil
        end
    end)

    inst:ListenForEvent("endspell", function()
        endfreeze(inst)
    end)

    inst:DoTaskInTime(40,function()
        endfreeze(inst)
    end)

    return inst
end


return Prefab("freeze_blast", fn)
