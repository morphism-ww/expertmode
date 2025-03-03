newcs_env.AddPrefabPostInit("shadowheart",function(inst)
    if not TheWorld.ismastersim then return end
    inst:AddComponent("fueled")
    inst.components.fueled.fueltype = FUELTYPE.NIGHTMARE
    inst.components.fueled:InitializeFuelLevel(10 * TUNING.LARGE_FUEL)
    inst.components.fueled.accepting = true
end)


local ATRIUM_RANGE = 8.5

local function ActiveStargate(gate)
    return gate:IsWaitingForStalker()
end

local STARGET_TAGS = { "stargate" }
local STALKER_TAGS = { "stalker" }
local function ItemTradeTest(inst, item, giver)
    if item == nil or item.prefab ~= "shadowheart" or
        giver == nil or giver.components.areaaware == nil then
        return false
    elseif inst.form ~= 1 then
        return false, "WRONGSHADOWFORM"
    elseif not TheWorld.state.isnight then
        return false, "CANTSHADOWREVIVE"
    elseif giver.components.areaaware:CurrentlyInTag("Atrium")
        and (   FindEntity(inst, ATRIUM_RANGE, ActiveStargate, STARGET_TAGS) == nil or
                GetClosestInstWithTag(STALKER_TAGS, inst, 40) ~= nil  and item.components.fueled:GetPercent()<1 ) then
        return false, "CANTSHADOWREVIVE"
    end

    return true
end



newcs_env.AddPrefabPostInit("fossil_stalker",function (inst)
    if not TheWorld.ismastersim then return end
    inst.components.trader:SetAbleToAcceptTest(ItemTradeTest)
end)

---------------------------------------------------------------------
local function spawnvortex(inst)
    local vortex = SpawnPrefab("darkvortex")
    vortex.Transform:SetPosition(inst.Transform:GetWorldPosition())
    --vortex.sg:GoToState("spawn")
    inst._vortexes[vortex] = true
    inst:ListenForEvent("onremove",function (inst2)
        inst._vortexes[inst2] = nil
    end,vortex)
end

local brain = require("brains/stalker2brain")

local function Killvortexes(inst)
    for k,v in pairs(inst._vortexes) do
        k:Disappear()
    end
end

newcs_env.AddPrefabPostInit("stalker_atrium",function (inst)
    inst:AddTag("toughworker")
    inst:AddTag("electricdamageimmune")
    inst:AddTag("no_rooted")


    if not TheWorld.ismastersim then return end
    
    inst._vortexes = {}

    inst.SpawnVortex = spawnvortex
    inst:SetBrain(brain)

    inst:ListenForEvent("death",Killvortexes)

    MakeHitstunAndIgnoreTrueDamageEnt(inst)
end)



newcs_env.AddStategraphPostInit("SGstalker",function (sg)
    table.insert(sg.states.death3_pst.timeline,
        TimeEvent(305 * FRAMES, function(inst)
            local heart = SpawnPrefab("shadowheart")
            heart.components.fueled:MakeEmpty()
            heart.Transform:SetPosition(inst.Transform:GetWorldPosition())
        end))  
end)

newcs_env.AddStategraphEvent("SGstalker",
EventHandler("vortex", function(inst)
    if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
        inst.sg:GoToState("summon_vortex")
    end        
end))
newcs_env.AddStategraphEvent("SGstalker",
EventHandler("shadowball", function(inst,data)
    if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
        inst.sg:GoToState("shadowball_loop",data.crazy)
    end        
end))

newcs_env.AddStategraphState("SGstalker",State{
    name = "shadowball_loop",
    tags = { "busy", "mindcontrol" },

    onenter = function(inst,crazy)
        inst.components.locomotor:StopMoving()
        inst.AnimState:PlayAnimation("control_loop")
        inst.components.epicscare:Scare(5)
        inst.components.combat:StartAttack()
        inst.sg.statemem.target = inst.components.combat.target
        inst.components.timer:StartTimer("shadowball_cd", 12)
        inst.sg.statemem.projs = {}
        inst.sg.statemem.crazy = true
    end,

    timeline = {
        FrameEvent(10,function (inst)
            
            if inst.sg.statemem.target ~= nil and inst.sg.statemem.target:IsValid() then
                local x, y, z = inst.Transform:GetWorldPosition()
                local facing_angle = inst:GetAngleToPoint(inst.sg.statemem.target.Transform:GetWorldPosition())*DEGREES
                inst.sg.statemem.target_angle = facing_angle
                local tx ,tz = x + 2*math.cos(facing_angle), z - 2*math.sin(facing_angle)
                inst.sg.statemem.shootpos = Vector3(tx,0,tz)
                for i = 1,6 do
                    local proj = SpawnPrefab("shadowball_linear")
                    proj.AnimState:PlayAnimation("portal_pre")
                    proj.AnimState:PushAnimation("portal_loop")
                    
                    proj.Transform:SetPosition(tx, 0, tz)
                    inst.sg.statemem.projs[i]=proj
                end
            end
            
        end),
        FrameEvent(30,function (inst)
            if inst.sg.statemem.target_angle then
                inst.SoundEmitter:PlaySound("dontstarve/creatures/eyeballturret/shoot")
                for i,v in ipairs(inst.sg.statemem.projs) do
                    local offset = Vector3(math.cos(inst.sg.statemem.target_angle+i*PI/3),0,-math.sin(inst.sg.statemem.target_angle+i*PI/3))
                    v.components.linearprojectile:LineShoot(inst.sg.statemem.shootpos+offset,inst)
                end
            else
                for i,v in ipairs(inst.sg.statemem.projs) do
                    v:Remove()
                end
            end    
        end)
    },

    events =
    {
        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                inst.sg:GoToState("mindcontrol_pst")
            end
        end),
    },
})

newcs_env.AddStategraphState("SGstalker",State{
    name = "summon_vortex",
    tags = { "attack", "busy" },

    onenter = function(inst, targets)
        inst.components.locomotor:StopMoving()
        inst.AnimState:PlayAnimation("spike")
        --V2C: don't trigger attack cooldown
        --inst.components.combat:StartAttack()
        --inst:StartAbility("snare")
        inst.sg.statemem.targets = targets
    end,

    timeline =
    {
        TimeEvent(24 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/attack1_pbaoe") end),
        TimeEvent(25.5 * FRAMES, function(inst)
            inst:SpawnVortex()

        end),
        TimeEvent(39 * FRAMES, function(inst)
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
})