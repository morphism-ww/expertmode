TUNING.KLAUS_HIT_RANGE = 5
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

AddPrefabPostInit("deer_red", function(inst)
	if not TheWorld.ismastersim then
		return
	end
    inst.DoCast = DoCast
end)
AddPrefabPostInit("deer_blue", function(inst)
	if not TheWorld.ismastersim then
		return
	end
    inst.DoCast = DoCast
end)



local function SoulHunter(inst,data)
    if data.redirected then
        return
    end
    local target=data.target
	if target ~= nil then
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
end

local function spawnsoul(inst)
    local x,y,z=inst.Transform:GetWorldPosition()
    for i=1,15 do
        local radius=4*math.random()
        local angle=2*PI*math.random()
        SpawnPrefab("demon_soul").Transform:SetPosition(x+radius*math.cos(angle),2,z-radius*math.sin(angle))
    end
    if inst.enraged then
        SpawnPrefab("krampus_sack").Transform:SetPosition(x,0,z)
    end
end


local function summonsacrifice(inst)
    local x, _, z = inst.Transform:GetWorldPosition()
    for i=1,5 do
        local angle=math.random()
        local radius=8+6*math.random()
        SpawnPrefab("krampus").Transform:SetPosition(x+radius*math.cos(angle),0,z-radius*math.sin((angle)))
    end
end

local function Sacrifice(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    for i, v in ipairs(TheSim:FindEntities(x, y, z, 12,{"_health"})) do
        if (v.prefab=="krampus" or v.prefab=="lureplant" or v:HasTag("smallcreature") or v:HasTag("spiderden"))
                and not v.components.health:IsDead() then
            SpawnPrefab("klaus_soul_spawn").Transform:SetPosition(v.Transform:GetWorldPosition())
            v.components.health:Kill()
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
    inst.Sacrifice=Sacrifice
    inst.SummonSacrifice=summonsacrifice

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
        local speed = 6 + math.random() * 3
        item.Physics:SetVel(math.cos(angle) * speed, 10, math.sin(angle) * speed)
    end
end

local function dropeverthing(inst)
    local x,y,z=inst.Transform:GetWorldPosition()
    local players=FindPlayersInRange(x,y,z,15)
    for i,v in ipairs(players) do
        if not v:HasTag("playerghost") and v.components.inventory~=nil then
            v.components.inventory:DropEquipped(false)
        end
    end
end

local function dropweapon(inst)
    local x,y,z=inst.Transform:GetWorldPosition()
    local players=FindPlayersInRange(x,y,z,7)
    for i,v in ipairs(players) do
        if not v:HasTag("playerghost") and v.components.inventory~=nil then
            local item = v.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
            if item ~= nil then
                v.components.inventory:DropItem(item)
                LaunchItem(inst, v, item)
            end
        end
    end
end



AddStategraphEvent("SGklaus",
EventHandler("soulhip", function(inst)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
            local target=inst.components.combat.target
            if target ~= nil then
                inst.sg:GoToState("hip_in", target)
                return true
            end
        end
    end))

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

        onenter = function(inst, target)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("taunt1")
            local x, y, z = inst.Transform:GetWorldPosition()
            SpawnPrefab("wortox_portal_jumpin_fx").Transform:SetPosition(x, y, z)
            inst.sg:SetTimeout(11 * FRAMES)
            local dest = target:GetPosition()
            if dest ~= nil then
                inst.sg.statemem.dest = dest
                inst:ForceFacePoint(dest:Get())
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

local function DoBodyfall(inst)
    inst.SoundEmitter:PlaySound("dontstarve/creatures/together/klaus/bodyfall")
end
AddStategraphState("SGklaus",
State{
        name = "sacrifice_pre",
        tags = { "transition", "busy"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("transform_pre")
        end,

        timeline =
        {
            TimeEvent(6 * FRAMES, DoFoleySounds),
            TimeEvent(9 * FRAMES, function(inst)
                DoBodyfall(inst)
                inst:SummonSacrifice()
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    inst.sg:GoToState("sacrifice", inst.sg.statemem.transition)
                end
            end),
        },
    }
)

AddStategraphState("SGklaus",
State{
        name = "sacrifice",
        tags = { "transition", "busy"},

        onenter = function(inst, transition)
            if not inst.AnimState:IsCurrentAnimation("transform_loop") then
                inst.AnimState:PlayAnimation("transform_loop", true)
            end
            inst.sg:SetTimeout(3)
        end,

        timeline =
        {
            TimeEvent(16 * FRAMES, DoFoleySounds),
            TimeEvent(29 * FRAMES, function(inst)
                DoFoleySounds(inst, .6)
            end),
            TimeEvent(80*FRAMES,    Sacrifice)
        },

        ontimeout=function(inst)
            inst.sg:GoToState("idle")
        end,

        onexit = function(inst)
            inst.components.timer:StartTimer("sacrifice_cd", 90)

        end,
    })



AddStategraphPostInit("SGklaus",function(sg)
    sg.states.taunt_roar.onenter =function(inst)
        inst.components.locomotor:StopMoving()
        inst.AnimState:PlayAnimation("taunt2")
        dropeverthing(inst)
        Sacrifice(inst)
    end
    table.insert(sg.states.attack_chomp.timeline,
            TimeEvent(8 * FRAMES, dropweapon))
end)

local function ShouldEnrage(inst)
    return not inst.enraged
        and (inst.components.commander:GetNumSoldiers() < 2 or inst.soulcount>=20)
end

local function ShouldHip(inst)
    return inst.components.combat:HasTarget()
        and inst.soulcount>=5
end


local function ShouldSacrifice(inst)
    return not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy"))
            and (inst.components.health:GetPercent()<0.3 or inst:IsUnchained())
            and not inst.components.timer:TimerExists("sacrifice_cd")
end

AddBrainPostInit("klausbrain", function(self)
    self.bt.root.children[1]=
    WhileNode(function() return ShouldEnrage(self.inst) end, "Enrage",
            ActionNode(function() self.inst:PushEvent("enrage") end))
    table.insert(self.bt.root.children, 2,
            WhileNode(function() return ShouldHip(self.inst) end, "Hip",
            ActionNode(function() self.inst:PushEvent("soulhip") end)))
    table.insert(self.bt.root.children, 3,
            WhileNode(function() return ShouldSacrifice(self.inst) end, "Sacrifice",
            ActionNode(function() self.inst.sg:GoToState("sacrifice_pre") end)))
end)