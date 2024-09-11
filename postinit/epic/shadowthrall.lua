require("stategraphs/commonstates")
--[[AddStategraphPostInit("shadowthrall_hands",function(sg)
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
end)]]


local function slurphunger(inst, owner)
    
    if owner.components.hunger ~= nil then
        if owner.components.hunger.current > 0 then
            owner.components.hunger:DoDelta(-2)
        end
    end    
    if owner.components.mightiness~=nil then
        owner.components.mightiness:DoDelta(-3)
    end
    if owner.components.health ~= nil then
        owner.components.health:DoDelta(-2, nil, "shadow_leech")
    end
    
end


local function AttachPlayer(inst,player)
    if player.components.health:IsDead() or not player:IsValid() then
        inst.components.entitytracker:ForgetEntity("daywalker")
        return 
    end

    if inst.task ~= nil then
        inst.task:Cancel()
    end
    inst.components.entitytracker:TrackEntity("daywalker", player)
	inst.Follower:FollowSymbol(player.GUID, "swap_body", nil, nil, nil, true)
	inst.sg:GoToState("attached_player")
    inst._attached = true
    inst.task = inst:DoPeriodicTask(1, slurphunger, nil, player)
end

local function DettachPlayer(inst)
    if inst.task ~= nil then
        inst.task:Cancel()
        inst.task = nil
    end
    inst._attached = false
end

local function OnDrop(inst,player)
    inst:RemoveEventCallback("death",inst.DropFn,player)
    inst.components.entitytracker:ForgetEntity("daywalker")
    --TheNet:Announce("fuck")
    if inst._attached then
        inst:OnFlungFrom(player)
    end
    DettachPlayer(inst)
    
end

local function OnAttacked(inst,data)
    local owner = inst.components.entitytracker:GetEntity("daywalker")
    if inst._attached and owner and inst._abyss then
        inst:OnFlungFrom(owner)
        DettachPlayer(inst)
    end
end

local function FindPlayer(inst)
    if not (inst._abyss and inst.components.entitytracker:GetEntity("daywalker")==nil) then
        return
    end
    local x,y,z = inst.Transform:GetWorldPosition()
    local target = FindClosestPlayerInRangeSq(x,y,z,12*12,true)
    if target then
        inst.components.entitytracker:TrackEntity("daywalker", target)
        inst:ListenForEvent("death",inst.DropFn, target)
        inst:ListenForEvent("onremove",inst.DropFn, target)
    end
end

local function OnDeath(inst)
    if inst.task~=nil then
        inst.task:Cancel()
        inst.task = nil
    end
end

local function OnSpawnedBy(inst)
    inst._abyss = true
end

local function OnSave(inst,data)
    data._abyss = inst._abyss
end

local function OnLoad(inst,data)
    inst._abyss = data~=nil and data._abyss
end

local function IgnoreTrueDamage(inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
	return afflicter==nil and cause==nil
end


AddPrefabPostInit("shadow_leech",function (inst)
    if not TheWorld.ismastersim then
        return inst
    end
    inst.components.health.redirect = IgnoreTrueDamage
    --inst.components.health.canmurder = false
    --inst.components.health.redirect = OnlyPlayer
    inst.components.combat:SetRetargetFunction(2,FindPlayer)

    inst.AttachPlayer = AttachPlayer
    inst.OnSpawnedBy = OnSpawnedBy
    inst.DropFn = function(player) OnDrop(inst,player) end
    inst:ListenForEvent("attacked",OnAttacked)
    inst:ListenForEvent("death",OnDeath)

    inst.OnSave = OnSave
    inst.OnLoad = OnLoad
end)


AddStategraphState("shadow_leech",State{
    name = "attached_player",
    tags = { "busy"},

    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("attach_loop", true)
        inst.Physics:SetActive(false)
        inst:ToggleBrain(false)
        inst.SoundEmitter:PlaySound("daywalker/leech/suck", "suckloop")
        inst.components.health:SetAbsorptionAmount(0.9)
    end,

    onexit = function(inst)
        inst.Follower:StopFollowing()
        inst.Physics:SetActive(true)
        inst:ToggleBrain(true)
        inst.SoundEmitter:KillSound("suckloop")
        inst.components.health:SetAbsorptionAmount(0)
    end,
})


local function BurntOther(inst,data)
    if data.target and data.target:IsValid() and data.target:HasTag("character") then
		data.target:AddDebuff("curse_fire", "curse_fire")
	end
end

AddPrefabPostInit("fused_shadeling_bomb",function (inst)
    if not TheWorld.ismastersim then
        return inst
    end
    inst:ListenForEvent("onhitother",BurntOther)
end)

AddPrefabPostInit("fused_shadeling_quickfuse_bomb",function (inst)
    if not TheWorld.ismastersim then
        return inst
    end
    inst:ListenForEvent("onhitother",BurntOther)
end)