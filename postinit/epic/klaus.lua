local function SpawnSpell(inst, x, z)
    local spell = SpawnPrefab(inst.castfx)
    spell.Transform:SetPosition(x, 0, z)
    spell:DoTaskInTime(inst.castduration, spell.KillFX)
    return spell
end

local function SpawnSpells(inst, targets)
    local spells = {}
    for i, v in ipairs(targets) do
        if v:IsValid() and v:IsNear(inst, TUNING.DEER_GEMMED_CAST_MAX_RANGE) then
            local x, y, z = v.Transform:GetWorldPosition()
            table.insert(spells, SpawnSpell(inst, x, z))
            local angle=2*PI*math.random()
            table.insert(spells, SpawnSpell(inst, x+6*math.cos(angle), z-6*math.sin(angle)))
        end
    end
    return #spells > 0 and spells or nil
end

local function DoCast(inst, targets)
    local spells = targets ~= nil and SpawnSpells(inst, targets) or nil
    inst.components.timer:StopTimer("deercast_cd")
    inst.components.timer:StartTimer("deercast_cd", spells ~= nil and inst.castcd or TUNING.DEER_GEMMED_FIRST_CAST_CD)
    return spells
end


local function  DoSacrifice(inst,targets)
    local spells = {}
    if targets==nil then return end
    for i, v in ipairs(targets) do
        if v:IsValid() and v:IsNear(inst, 16) then
            local x, y, z = v.Transform:GetWorldPosition()
            local spell = SpawnPrefab("deer_soul_circle")
            spell.Transform:SetPosition(x, 0, z)
            spell:DoTaskInTime(5, spell.KillFX)
            table.insert(spells, spell)
            if #spells >= 3 then
                return spells
            end
        end
    end
    return spells
end
AddPrefabPostInit("deer_red", function(inst)
	if not TheWorld.ismastersim then
		return
	end
    inst.DoCast = DoCast
    inst.DoSacrifice=DoSacrifice
end)
AddPrefabPostInit("deer_blue", function(inst)
	if not TheWorld.ismastersim then
		return
	end
    inst.DoCast = DoCast
    inst.DoSacrifice=DoSacrifice
end)


local function DoChainSound(inst, volume)
    inst:DoChainSound(volume)
end

local function DoChainIdleSound(inst, volume)
    inst:DoChainIdleSound(volume)
end

local function DoBellSound(inst, volume)
    inst:DoBellSound(volume)
end

local function DoBellIdleSound(inst, volume)
    inst:DoBellIdleSound(volume)
end

local function DoFootstep(inst, volume)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/footstep", nil, volume)
    PlayFootstep(inst, volume)
end

local function DoFootstepRun(inst, volume)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/footstep_run", nil, volume)
    PlayFootstep(inst, volume)
end

AddStategraphState("deer",
State{
    name = "sacrifice_pre",
    tags = { "attack", "busy", "casting" },

    onenter = function(inst, targets)
        inst.components.combat:StartAttack()
        inst.components.locomotor:StopMoving()
        inst.AnimState:PlayAnimation("atk_magic_pre")

        inst.sg.statemem.targets = targets
        inst.sg.mem.wantstocast = nil

        inst.sg.statemem.fx = SpawnPrefab(inst.gem == "red" and "deer_fire_charge" or "deer_ice_charge")
        inst.sg.statemem.fx.entity:SetParent(inst.entity)
        inst.sg.statemem.fx.entity:AddFollower()
        inst.sg.statemem.fx.Follower:FollowSymbol(inst.GUID, "swap_antler_red", 0, 0, 0)
    end,

    timeline =
    {
        TimeEvent(0, DoChainIdleSound),
        TimeEvent(FRAMES, DoBellIdleSound),
        TimeEvent(3 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/huff")
        end),
        TimeEvent(14 * FRAMES, function(inst)
            DoChainSound(inst)
            DoBellSound(inst)
        end),
        TimeEvent(19.5 * FRAMES, function(inst)
            inst.sg.statemem.spells = inst:DoSacrifice(inst.sg.statemem.targets)
            inst.sg.statemem.targets = nil
        end),
        TimeEvent(22 * FRAMES, DoBellSound),
        TimeEvent(23 * FRAMES, DoChainSound),
    },

    events =
    {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg.statemem.magic = true
                if inst.sg.statemem.spells == nil and inst.sg.statemem.targets == nil then
                    inst.sg:GoToState("magic_pst", { fx = inst.sg.statemem.fx })
                else
                    inst.sg:GoToState("magic_loop", { fx = inst.sg.statemem.fx, spells = inst.sg.statemem.spells, targets = inst.sg.statemem.targets })
                end
            end
        end),
    },

    onexit = function(inst)
        if not inst.sg.statemem.magic then
            inst.sg.statemem.fx:KillFX()
        end
    end,
})


AddStategraphState("deer",
State{
    name = "sacrifice_loop",
    tags = { "attack", "busy", "casting" },

    onenter = function(inst, data)
        data.looped = (data.looped or 0) + 1
        inst.sg.statemem.data = data
        if not inst.AnimState:IsCurrentAnimation("atk_magic_loop") then
            inst.AnimState:PlayAnimation("atk_magic_loop", true)
        end
        inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
    end,

    timeline =
    {
        TimeEvent(0, DoChainIdleSound),
        TimeEvent(9 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/scratch")
        end),
        TimeEvent(14 * FRAMES, DoBellIdleSound),
    },
    ontimeout = function(inst)
        inst.sg.statemem.magic = true
        inst.sg:GoToState(inst.sg.statemem.data.looped < 2 and "sacrifice_loop" or "sacrifice_pst", inst.sg.statemem.data)
    end,

    onexit = function(inst)
        if not inst.sg.statemem.magic and inst.sg.statemem.data ~= nil and inst.sg.statemem.data.fx ~= nil then
            inst.sg.statemem.data.fx:KillFX()
        end
    end,
})

AddStategraphState("deer",
State{
    name = "sacrifice_pst",
    tags = { "attack", "busy", "casting" },

    onenter = function(inst, data)
        if data ~= nil then
            inst.sg.statemem.fx = data.fx
            inst.sg.statemem.spells = data.spells
            inst.sg.statemem.targets = data.targets
        end
        inst.AnimState:PlayAnimation("atk_magic_pst")
    end,

    timeline =
    {
        TimeEvent(2 * FRAMES, function(inst)
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/deer/grrr")
        end),
        TimeEvent(5 * FRAMES, DoBellSound),
        TimeEvent(11 * FRAMES, DoChainSound),
        TimeEvent(20 * FRAMES, DoBellSound),
        TimeEvent(21 * FRAMES, DoFootstepRun),
        TimeEvent(22 * FRAMES, DoChainSound),
        TimeEvent(25 * FRAMES, function(inst)
            local success = false
            if inst.sg.statemem.spells ~= nil then
                for i, v in ipairs(inst.sg.statemem.spells) do
                    if v:IsValid() then
                        success = true
                        v:TriggerFX()
                    end
                end
            end
            if inst.sg.statemem.fx ~= nil then
                inst.sg.statemem.fx:KillFX(success and "blast" or nil)
                inst.sg.statemem.fx = nil
            end
            inst.sg:RemoveStateTag("casting")
        end),
        TimeEvent(26 * FRAMES, function (inst)
            DoChainSound(inst)
            DoBellIdleSound(inst)
        end),
        TimeEvent(35 * FRAMES, DoBellSound),
        TimeEvent(36 * FRAMES, DoFootstep),
        TimeEvent(39 * FRAMES, DoChainSound),
        TimeEvent(41 * FRAMES, DoBellSound),
        TimeEvent(45 * FRAMES, DoFootstep),
        TimeEvent(46 * FRAMES, DoBellIdleSound),
        TimeEvent(47 * FRAMES, function(inst)
            inst.sg:RemoveStateTag("busy")
        end),
    },

    events =
    {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("idle")
            end
        end),
    },

    onexit = function(inst)
        if inst.sg.statemem.fx ~= nil then
            inst.sg.statemem.fx:KillFX()
        end
    end,
})

AddStategraphEvent("deer",
EventHandler("sacrifice", function(inst)
    if inst.gem ~= nil and not inst.components.health:IsDead() then
        if not inst.sg:HasStateTag("busy") then
            local targets = inst:FindCastTargets()
            if targets ~= nil then
                inst.sg:GoToState("sacrifice_pre", targets)
            end
        end
    end    
end))










-----------------------------------------------------------------------
local function HasSoul(victim)
    return not (victim:HasTag("veggie") or
                victim:HasTag("structure") or
                victim:HasTag("wall") or
                victim:HasTag("balloon") or
                victim:HasTag("soulless") or
                victim:HasTag("chess") or
                victim:HasTag("shadow") or
                victim:HasTag("shadowcreature") or
                victim:HasTag("shadowminion") or
                victim:HasTag("shadowchesspiece") or
                victim:HasTag("groundspike") or
                victim:HasTag("smashable"))
        and (  (victim.components.combat ~= nil and victim.components.health ~= nil)
            or victim.components.murderable ~= nil )
end

local function SoulHunter(inst,data)
    if data.redirected then
        return
    end
    local target=data.target
	if target ~= nil then
        if HasSoul(target) then
            local soul=SpawnPrefab("klaus_soul_spawn")
            soul.Transform:SetPosition(target.Transform:GetWorldPosition())
            if target.components.mightiness~=nil then
                target.components.mightiness:DoDelta(-8)
            end
            if target.components.sanity~=nil then
                target.components.sanity:DoDelta(-10)
            end
            if inst.enraged and target.components.grogginess~=nil then
                target.components.grogginess:AddGrogginess(0.5, 1)
            end
        end
        if target.components.upgrademoduleowner~=nil then
            target.components.upgrademoduleowner:AddCharge(-1)
        end
    end
end

local function spawnsoul(inst)
    if not TheWorld:HasTag("cave") then
        local x,y,z=inst.Transform:GetWorldPosition()
        for i=1,10 do
            local radius=4*math.random()
            local angle=2*PI*math.random()
            SpawnPrefab("demon_soul").Transform:SetPosition(x+radius*math.cos(angle),2,z-radius*math.sin(angle))
        end
        if inst.enraged then
            SpawnPrefab("krampus_sack").Transform:SetPosition(x,0,z)
        end
    end    
end




AddPrefabPostInit("klaus", function(inst)
    inst:AddTag("noteleport")
	if not TheWorld.ismastersim then
		return
	end
    inst:AddComponent("damagetypebonus")
    inst.components.damagetypebonus:AddBonus("ghost",inst,2)
    inst:AddComponent("colouradder")
    inst.soulcount=0

    inst:ListenForEvent("dropkey",spawnsoul)
    inst:ListenForEvent("onhitother",SoulHunter)
end)

local function LaunchItem(inst, target, item)
    if item.Physics ~= nil and item.Physics:IsActive() then
        local x, y, z = item.Transform:GetWorldPosition()
        item.Physics:Teleport(x, .1, z)

        x, y, z = inst.Transform:GetWorldPosition()
        local x1, y1, z1 = target.Transform:GetWorldPosition()
        local angle = math.atan2(z1 - z, x1 - x) + (math.random() * 20 - 10) * DEGREES
        local speed = 5 + math.random() * 2
        item.Physics:SetVel(math.cos(angle) * speed, 10, math.sin(angle) * speed)
    end
end
local function dropeverthing(inst)
    local x,y,z=inst.Transform:GetWorldPosition()
    local players=FindPlayersInRange(x,y,z,12,true)
    for i,v in ipairs(players) do
        local item = v.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
        if item ~= nil then
            v.components.inventory:DropItem(item)
            LaunchItem(inst, v, item)
        end
        v:AddDebuff("vulnerable","vulnerable",{duration=20})
    end
end



local function DeerCanCast(deer)
    return not (deer.shouldavoidmagic or
                deer.components.health.takingfiredamage or
                deer.components.hauntable.panic or
                deer.components.health:IsDead() or
                deer.components.sleeper:IsAsleep() or
                (deer.components.freezable ~= nil and deer.components.freezable:IsFrozen()) or
                (deer.components.burnable ~= nil and deer.components.burnable:IsBurning()))
end

local function PickCommandDeer(inst, highprio, lowprio)
    local deer, lowpriodeer
    for i, v in ipairs(inst.components.commander:GetAllSoldiers()) do
        if DeerCanCast(v) and v:FindCastTargets() ~= nil then
            if v == highprio then
                return v
            elseif v == lowprio then
                lowpriodeer = v
            elseif highprio == nil then
                return v
            elseif deer == nil then
                deer = v
            end
        end
    end
    return deer or lowpriodeer
end

local function DoWortoxPortalTint(inst, val)
    if val > 0 then
        inst.components.colouradder:PushColour("portaltint", 154 / 255 * val, 23 / 255 * val, 19 / 255 * val, 0)
        val = 1 - val
        inst.AnimState:SetMultColour(val, val, val, 1)
    else
        inst.components.colouradder:PopColour("portaltint")
        inst.AnimState:SetMultColour(1, 1, 1, 1)
    end
end

AddStategraphState("SGklaus",
State{
        name = "hip_in",
        tags = { "busy", "attack","nosleep","nofreeze" },

        onenter = function(inst,targetpos)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("taunt1")
            inst.components.timer:StartTimer("hip_cd", 10)
            local x, y, z = inst.Transform:GetWorldPosition()
            SpawnPrefab("wortox_portal_jumpin_fx").Transform:SetPosition(x, y, z)
            inst.sg:SetTimeout(11 * FRAMES)

            if targetpos ~= nil then
                inst.sg.statemem.dest = targetpos
                inst:ForceFacePoint(targetpos:Get())
            else
                inst.sg.statemem.dest = Vector3(x, y, z)
            end
        end,

        onupdate = function(inst)
            if inst.sg.statemem.tints ~= nil then
                DoWortoxPortalTint(inst, table.remove(inst.sg.statemem.tints))
                if #inst.sg.statemem.tints <= 0 then
                    inst.sg.statemem.tints = nil
                end
            end
        end,

        timeline =
        {
            TimeEvent(FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/creatures/together/toad_stool/infection_post", nil, .7)
                inst.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/spawn", nil, .5)
            end),
            TimeEvent(2 * FRAMES, function(inst)
                inst.sg.statemem.tints = { 1, .6, .3, .1 }
            end),
            TimeEvent(4 * FRAMES, function(inst)
                inst.components.health:SetInvincible(true)
                inst.DynamicShadow:Enable(false)
            end),
        },

        ontimeout = function(inst)
            inst.sg.statemem.portaljumping = true
            inst.sg:GoToState("attack_hip", inst.sg.statemem.dest)
        end,

        onexit = function(inst)
            if not inst.sg.statemem.portaljumping then
                inst.components.health:SetInvincible(false)
                inst.DynamicShadow:Enable(true)
                DoWortoxPortalTint(inst, 0)
            end
        end,
    })

AddStategraphState("SGklaus",
State{
        name = "attack_hip",
        tags = { "busy", "attack","nosleep","nofreeze" },

        onenter = function(inst, dest)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("idle_loop")
            if dest ~= nil then
                inst.Physics:Teleport(dest:Get())
            else
                dest = inst:GetPosition()
            end
            SpawnPrefab("wortox_portal_jumpout_fx").Transform:SetPosition(dest:Get())
            inst.DynamicShadow:Enable(false)
            inst.sg:SetTimeout(14 * FRAMES)
            DoWortoxPortalTint(inst, 1)
            inst.components.health:SetInvincible(true)
            inst.soulcount=inst.soulcount-1
        end,

        onupdate = function(inst)
            if inst.sg.statemem.tints ~= nil then
                DoWortoxPortalTint(inst, table.remove(inst.sg.statemem.tints))
                if #inst.sg.statemem.tints <= 0 then
                    inst.sg.statemem.tints = nil
                end
            end
        end,

        timeline =
        {
            TimeEvent(FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/characters/wortox/soul/hop_out") end),
            TimeEvent(5 * FRAMES, function(inst)
                inst.sg.statemem.tints = { 0, .4, .7, .9 }
            end),
            TimeEvent(7 * FRAMES, function(inst)
                inst.components.health:SetInvincible(false)
                inst.SoundEmitter:PlaySound("dontstarve/movement/bodyfall_dirt")
            end),
            TimeEvent(8 * FRAMES, function(inst)
                inst.DynamicShadow:Enable(true)
            end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("quickattack")
        end,

        onexit = function(inst)
            inst.components.health:SetInvincible(false)
            inst.DynamicShadow:Enable(true)
            DoWortoxPortalTint(inst, 0)
        end}
)
local function DoFoleySounds(inst, volume)
    inst:DoFoleySounds(volume)
end


AddStategraphState("SGklaus",
State{
        name = "sacrifice_pre",
        tags = { "transition", "busy"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("command_pre")
            inst.sg.mem.wantstosacrifice=nil
            DoFoleySounds(inst, .5)
        end,

        timeline =
        {
            TimeEvent(8 * FRAMES, DoFoleySounds),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    for i, v in ipairs(inst.components.commander:GetAllSoldiers()) do
                        if DeerCanCast(v) and v:FindCastTargets() ~= nil then
                            v:PushEvent("sacrifice")
                        end
                    end    
                end
                inst.sg:GoToState("sacrifice_loop")
            end),
        },
    }
)


AddStategraphState("SGklaus",
State{
    name = "sacrifice_loop",
    tags = { "busy" },

    onenter = function(inst, deer)
        inst.sg.statemem.deer = deer
        inst.components.locomotor:StopMoving()
        if not inst.AnimState:IsCurrentAnimation("command_loop") then
            inst.AnimState:PlayAnimation("command_loop", true)
        end
        inst.sg:SetTimeout(inst.AnimState:GetCurrentAnimationLength())
    end,

    timeline =
    {
        TimeEvent(7 * FRAMES, function(inst)
            DoFoleySounds(inst, .3)
        end),
    },

    ontimeout = function(inst)
        inst.sg:GoToState("command_pst")
    end,

    onexit = function(inst)
        if not inst.sg.statemem.commanding then
            inst.components.timer:StopTimer("sacrifice_cd")
            inst.components.timer:StartTimer("sacrifice_cd", 90)
        end
    end,
}
)    


AddStategraphEvent("SGklaus",
EventHandler("sacrifice", function(inst)
    if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
        inst.sg:GoToState("sacrifice_pre")
    else
        inst.sg.mem.wantstosacrifice=true
    end        
end))

AddStategraphEvent("SGklaus",
EventHandler("soul_hip", function(inst,target)
    if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) 
        and target~=nil and target:IsValid() then
        inst.sg:GoToState("hip_in",target:GetPosition())
    end    
end))

local function TryChomp(inst)
    local target = inst:FindChompTarget()
    if target ~= nil then
        if not inst.components.combat:TargetIs(target) then
            inst.components.combat:SetTarget(target)
        end
        inst.sg:GoToState("attack_chomp", target)
        return true
    end
end

AddStategraphPostInit("SGklaus",function(sg)
    sg.states.taunt_roar.onenter =function(inst)
        inst.components.locomotor:StopMoving()
        inst.AnimState:PlayAnimation("taunt2")
        dropeverthing(inst)
    end
    sg.states.idle.onenter=function (inst)
        if inst.sg.mem.sleeping then
            inst.sg:GoToState("sleep")
        elseif inst.sg.mem.wantstotransition ~= nil then
            inst.sg:GoToState("transition", inst.sg.mem.wantstotransition)
        elseif inst.sg.mem.laughsremaining ~= nil then
            inst.sg:GoToState("laugh_pre")
        elseif inst.sg.mem.wantstosacrifice then
            inst.sg:GoToState("sacrifice_pre")    
        elseif not (inst.sg.mem.wantstochomp and TryChomp(inst)) then
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle_loop")
        end
        
    end
    --debug.setupvalue(sg.events["doattack"].fn,1,ChooseAttack)
end)

local function ShouldEnrage(inst)
    return not inst.enraged
        and (inst.components.commander:GetNumSoldiers() < 2 or inst.soulcount>=20)
end

local function ShouldHip(inst)
    return inst.soulcount>=5 and inst.components.combat:HasTarget()
    and not inst.components.timer:TimerExists("hip_cd")
end

local function ShouldSacrifice(inst)
    return  (inst.components.health:GetPercent()<0.3 or inst:IsUnchained())
            and not inst.components.timer:TimerExists("sacrifice_cd")
end

AddBrainPostInit("klausbrain", function(self)
    self.bt.root.children[1]=
    WhileNode(function() return ShouldEnrage(self.inst) end, "Enrage",
            ActionNode(function() self.inst:PushEvent("enrage") end))
    table.insert(self.bt.root.children, 3,
            WhileNode(function() return ShouldSacrifice(self.inst) end, "Sacrifice",
            ActionNode(function() self.inst:PushEvent("sacrifice") end)))
    table.insert(self.bt.root.children, 4,
            WhileNode(function() return ShouldHip(self.inst) end, "Sacrifice",
            ActionNode(function() self.inst:PushEvent("soul_hip",self.inst.components.combat.target) end)))        

end)


