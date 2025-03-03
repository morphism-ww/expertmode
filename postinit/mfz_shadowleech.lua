local env = env
GLOBAL.setfenv(1, GLOBAL)

local function OnFlungFrom(inst, daywalker,dir)
	inst.Follower:StopFollowing()

	local x, y, z 
	if daywalker:IsValid() then
		x, y, z = daywalker.Transform:GetWorldPosition()
	else
		x, y, z = inst.Transform:GetWorldPosition()
	end
	if daywalker.components.hunger ~= nil then
		daywalker.components.hunger.burnratemodifiers:RemoveModifier(inst,"leech")
	end

	inst._leechtarget = nil
	local rot = dir or  math.random() * 360 
	inst.Transform:SetRotation(rot + 180) --flung backwards
	rot = rot * DEGREES
	inst.Physics:Teleport(x + math.cos(rot), y, z - math.sin(rot) )
	inst.sg:GoToState("flung", 1)
end

local function ClearLeech(inst,target)
    if target==nil then
        return
    end
    inst:RemoveEventCallback("death",inst.ClearLeech,target)
    inst:RemoveEventCallback("onremove",inst.ClearLeech,target)
    inst:RemoveEventCallback("minhealth",inst.ClearLeech,target)
    if target._p_leechtask~=nil then
        target._p_leechtask:Cancel()
        target._p_leechtask = nil
    end
    if target.components.hunger ~= nil then
        target.components.hunger.burnratemodifiers:RemoveModifier(inst,"leech")
    end
    OnFlungFrom(inst,target)
end

local function NoShadow(inst,target)
    return not inst:HasTag("shadow_aligned")
end

function TransformToShadowLeech(player)
    player.entity:AddFollower()

    player.Transform:SetSixFaced()
    player:AddTag("shadow_leech")
    player:AddTag("shadowcreature")
    --player:AddTag("debugnoattack")
    player.components.sanity:SetInducedInsanity(player, true)
    player.AnimState:SetBank("shadow_leech")
	player.AnimState:SetBuild("shadow_leech")
    player:SetStateGraph("SGplayer_leech")

    player.Physics:ClearCollisionMask()
	player.Physics:SetCollisionGroup(COLLISION.SANITY)
	player.Physics:CollidesWith(COLLISION.SANITY)
	player.Physics:CollidesWith(COLLISION.WORLD)
    
    player.components.combat.shouldavoidaggrofn = NoShadow
    
    player.ClearLeech = function (target) ClearLeech(player,target) end
    player.components.locomotor.runspeed = 14
end


local leech = Action({ priority = 20, rmb = true, distance = 10 })
leech.id = "PLAYER_LEECH"
leech.str = "寄生"
leech.fn = function (act)
    act.doer:PushEvent("leech_jump",{target = act.target})
    return true
end

local leech_jump = Action({ priority = 20, rmb = true, distance = 10 })
leech_jump.id = "PLAYER_LEECH_JUMP"
leech_jump.str = "跳跃"
leech_jump.fn = function (act)
    act.doer:PushEvent("leech_jump",{targetpos = act:GetActionPoint()})
    return true
end

env.AddComponentAction("POINT","weapon", function (inst, doer, pos, actions, right)  
    local x,y,z = pos:Get()
    if right and doer:HasTag("shadow_leech") and not doer:HasTag("leeched") and (TheWorld.Map:IsAboveGroundAtPoint(x,y,z) or TheWorld.Map:GetPlatformAtPoint(x,z) ~= nil) then
        table.insert(actions, ACTIONS.PLAYER_LEECH_JUMP)
    end
end)

env.AddComponentAction("SCENE","combat", function (inst, doer, actions, right)  
    if right and doer:HasTag("shadow_leech") and not doer:HasTag("leeched") and 
        not IsEntityDead(inst,true) and
        not inst:HasTag("shadowcreature") and 
        inst.replica.combat ~= nil and inst.replica.combat:CanBeAttacked(doer) then
        table.insert(actions, ACTIONS.PLAYER_LEECH)
    end
end)

env.AddAction(leech)   
env.AddAction(leech_jump)   
