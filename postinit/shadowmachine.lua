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
    inst:AddTag("shadowchesspiece")
    if inst.shadow==nil then
        inst.shadow = SpawnPrefab("small_leechterror")
        inst.shadow:SetHost(inst,inst:HasTag("rook") and "innerds" or "hips")
    end
    
    inst.components.lootdropper:SetLoot(NIGHTMARE_LOOT)
end
local function SetNormal(inst)
    inst:RemoveTag("shadowchesspiece")
    if inst.shadow~=nil then
        inst.shadow:Remove()
        inst.shadow = nil
    end
    inst.components.lootdropper:SetLoot(nil)
end
local function TestNightmarePhase(inst, phase)
	
    if IsWorldNightmare(inst, phase) then
        if not inst:HasTag("shadowchesspiece") then
            DoFx(inst)
            SetNightmare(inst)
        end
    elseif inst:HasTag("shadowchesspiece") then
        DoFx(inst)
        SetNormal(inst)
    end
end

local function OnSave(inst, data)
    data.nightmare = inst:HasTag("shadowchesspiece") or nil
end

local function OnLoad(inst, data)
	if data ~= nil and data.nightmare then
        SetNightmare(inst)
    end
end

AddPrefabPostInit("bishop_nightmare",function(inst)
    if not TheWorld.ismastersim then return end
    

    inst:WatchWorldState("nightmarephase", TestNightmarePhase)
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
end)

AddPrefabPostInit("knight_nightmare",function(inst)
    if not TheWorld.ismastersim then return end
    inst:WatchWorldState("nightmarephase", TestNightmarePhase)
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
end)
----------------------------------------------------------

local function OnHitOther2(inst, data)
	if data.target ~= nil then
        data.target:PushEvent("knockback", { knocker = inst, radius = 5, strengthmult = 1.2})
        if data.target.components.sanity~=nil then
            data.target.components.sanity:DoDelta(-5)
        end
    end

end

AddPrefabPostInit("rook_nightmare",function(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("onhitother", OnHitOther2)
    inst:WatchWorldState("nightmarephase", TestNightmarePhase)
    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
end)

local function spawnshadow(inst)
    SpawnPrefab("shadowdragon").Transform:SetPosition(inst.Transform:GetWorldPosition())
end


AddPrefabPostInit("ancient_altar_broken",function(inst)
    if not TheWorld.ismastersim then return end
    inst:ListenForEvent("onprefabswaped",spawnshadow)
end)