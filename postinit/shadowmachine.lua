local NIGHTMARE_LOOT = { "nightmarefuel","nightmarefuel"}
local function IsWorldNightmare(inst, phase)
	return phase == "wild" or phase == "dawn"
end
local function DoFx(inst)
    inst.SoundEmitter:PlaySound("dontstarve/common/ghost_spawn")

    local x, y, z = inst.Transform:GetWorldPosition()
    local fx = SpawnPrefab("statue_transition_2")
    if fx ~= nil then
        fx.Transform:SetPosition(x, y, z)
        fx.Transform:SetScale(.8, .8, .8)
    end
    fx = SpawnPrefab("statue_transition")
    if fx ~= nil then
        fx.Transform:SetPosition(x, y, z)
        fx.Transform:SetScale(.8, .8, .8)
    end
end
local function SetNightmare(inst)
    inst:AddTag("nightmare")
    if inst.leech==nil then
        inst.leech = SpawnPrefab("small_leechterror")
        inst.leech:SetHost(inst,inst:HasTag("rook") and "innerds" or "hips")
    end
    
    inst.components.lootdropper:SetLoot(NIGHTMARE_LOOT)
end
local function SetNormal(inst)
    inst:RemoveTag("nightmare")
    if inst.leech~=nil then
        inst.leech:Remove()
        inst.leech = nil
    end
    inst.components.lootdropper:SetLoot(nil)
end
local function TestNightmarePhase(inst, phase)
	
    if IsWorldNightmare(inst, phase) then
        if not inst:HasTag("nightmare") then
            DoFx(inst)
            SetNightmare(inst)
        end
    elseif inst:HasTag("nightmare") then
        DoFx(inst)
        SetNormal(inst)
    end
end

local function OnSave(inst, data)
    data.nightmare = inst:HasTag("nightmare") or nil
end

local function OnLoad(inst, data)
	if data ~= nil and data.nightmare then
        SetNightmare(inst)
    end
end

newcs_env.AddPrefabPostInit("bishop_nightmare",function(inst)
    if not TheWorld.ismastersim then return end

    inst:WatchWorldState("nightmarephase", TestNightmarePhase)
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
end)

newcs_env.AddPrefabPostInit("knight_nightmare",function(inst)
    if not TheWorld.ismastersim then return end
    inst:WatchWorldState("nightmarephase", TestNightmarePhase)
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
end)
----------------------------------------------------------

local function KnockbackOther(inst, data)
	if data.target ~= nil and inst.sg:HasStateTag("runningattack") then
        data.target:PushEvent("knockback", { knocker = inst, radius = 5, strengthmult = 1.2})
    end
end

newcs_env.AddPrefabPostInit("rook_nightmare",function(inst)
    if not TheWorld.ismastersim then return end

    inst.components.combat:SetAreaDamage(3, 0.8)

    inst:ListenForEvent("onattackother", KnockbackOther)
    inst:WatchWorldState("nightmarephase", TestNightmarePhase)
    
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
end)



local function spawnshadow(inst)
    SpawnPrefab("shadowdragon").Transform:SetPosition(inst.Transform:GetWorldPosition())
end


newcs_env.AddPrefabPostInit("ancient_altar_broken",function(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("onprefabswaped",spawnshadow)
end)