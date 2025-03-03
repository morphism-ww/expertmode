require("stategraphs/commonstates")

local SHAKE_DIST = 40
local BEAMRAD = 9


local ARC = 90 * DEGREES --degrees to each side
local AOE_RANGE_PADDING = 3
local AOE_TARGET_MUSTHAVE_TAGS = { "_combat" }
local AOE_TARGET_CANT_TAGS = { "INLIMBO", "flight", "invisible", "notarget", "noattack", "laser" }
local MAX_SIDE_TOSS_STR = 0.8

local function DoArcAttack(inst, dist, radius, targets)
	inst.components.combat.ignorehitrange = true
	local x, y, z = inst.Transform:GetWorldPosition()
	local rot = inst.Transform:GetRotation() * DEGREES
	local x0, z0
	if dist ~= 0 then
		x = x + dist * math.cos(rot)
		z = z - dist * math.sin(rot)
	end
	for i, v in ipairs(TheSim:FindEntities(x, y, z, radius + AOE_RANGE_PADDING, AOE_TARGET_MUSTHAVE_TAGS, AOE_TARGET_CANT_TAGS)) do
		if v ~= inst and
			not (targets ~= nil and targets[v]) and
			v:IsValid() and not v:IsInLimbo()
			and not (v.components.health ~= nil and v.components.health:IsDead())
		then
			local range = radius + v:GetPhysicsRadius(0)
			local x1, y1, z1 = v.Transform:GetWorldPosition()
			local dx = x1 - x
			local dz = z1 - z
			local distsq = dx * dx + dz * dz
			if distsq > 0 and distsq < range * range and
				DiffAngleRad(rot, math.atan2(-dz, dx)) < ARC and
				inst.components.combat:CanTarget(v)
			then
				inst.components.combat:DoAttack(v)
				if targets ~= nil then
					targets[v] = true
				end
			end
		end
	end
	inst.components.combat.ignorehitrange = false
end

---如果无法发射激光，就逼近，否则保持距离
local function FindTelePos(inst,target,type)
    local pt 
    local x,y,z = inst.Transform:GetWorldPosition()
    if target and target:IsValid() then
        pt = target:GetPosition()
        if type ==1 then
            return pt
        elseif type ==2 then
            local offset = FindWalkableOffset(pt, PI2*math.random(), 12 + math.random()*4, 10)
            if offset~=nil then
                return pt + offset
            end
        end
    end
    return Vector3(x,0,z)
end

local function teleportcharge(inst)

    local pt = inst:GetPosition()
    local theta = inst.Transform:GetRotation() * DEGREES

    local offset = FindWalkableOffset(pt, theta, 7 , 8)


    if offset~=nil then
        pt.x = pt.x + offset.x
        pt.z = pt.z + offset.z
    end

    inst.Physics:Teleport(pt.x,0,pt.z)
end


local function spawnburns(inst,rad,startangle,endangle,num)
    local pt = inst:GetPosition() 
    --local down = TheCamera:GetDownVec()
    local angle = 0

    angle = angle + startangle
    local angdiff = (endangle-startangle)/num
    for i=1,num do
        local offset = Vector3(rad * math.cos( angle*DEGREES ), 0, rad * math.sin( angle*DEGREES ))
        local newpt = pt + offset      
        local burn =  SpawnPrefab("deerclops_laserscorch")
        burn.Transform:SetPosition(newpt.x,newpt.y,newpt.z)
        angle = angle + angdiff           
    end    
end



local events=
{
    CommonHandlers.OnLocomote(false,true),
    CommonHandlers.OnDeath(),
    EventHandler("doattack", function (inst,data)
        if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy"))
            and (data.target ~= nil and data.target:IsValid()) then
            local dsq_to_target = inst:GetDistanceSqToInst(data.target)
            if inst.canbarrier and not inst.components.timer:TimerExists("barrier_cd")
                    and dsq_to_target < 36 then
                inst.sg:GoToState("barrier",data.target)
            elseif inst.angry and not inst.components.timer:TimerExists("spin_cd") and dsq_to_target < 49 then
                inst.sg:GoToState("spin", data.target)
            elseif inst.cancharge and not inst.components.timer:TimerExists("teleportcharge_cd") then
                inst.sg:GoToState("teleportout_pre", {charge = true,data.target})
            elseif dsq_to_target > 36 and inst.lob_count>0 then
                inst.sg:GoToState("lob",data.target)
            else
                inst.sg:GoToState("attack", data.target)
            end
        end
    end),
    EventHandler("attacked",function (inst)
        if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy") or inst._is_shielding) then
            inst.sg:GoToState("hit")
        end
    end),
    EventHandler("lay_mines", function (inst)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
            inst.sg:GoToState("bomb_pre")
        end
    end),
    EventHandler("teleportout", function (inst,data)
        if not (inst.sg:HasStateTag("busy") or inst.components.health:IsDead()) then
            inst.sg:GoToState("teleportout_pre",{target = data.target,type = data.type})
        end
    end),
    --EventHandler("activate", function(inst) inst.sg:GoToState("activate") end),
}


local function DoFootstep(inst)
    inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/enemy/metal_robot/leg/step", {intensity=math.random()})
    inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/pangolden/walk", {timeoffset=math.random()})
end
local states=
{

    State{
        name = "idle",
        tags = {"idle"},

        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("idle")
        end,

        timeline=
        {
            TimeEvent(19*FRAMES, function(inst)
                inst.SoundEmitter:SetParameter( "gears", "intensity", .2 )
            end),
            TimeEvent(46*FRAMES, function(inst)
                inst.SoundEmitter:SetParameter( "gears", "intensity", .5 )
            end),

        },

        events =
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },

    },

-------------------ACTIVATE--------------

    State{
        name = "activate",
        tags = {"busy"},

        onenter = function(inst, cb)
            if inst.components.locomotor then
                inst.components.locomotor:StopMoving()
            end
            inst.AnimState:PlayAnimation("activate")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/gears_LP","gears")
        end,

        timeline=
        {
            ----start---
            TimeEvent(46*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/start") end),
            -----------gears loop--------------------
            TimeEvent(0*FRAMES, function(inst)
                inst.SoundEmitter:SetParameter( "gears", "intensity", 0.2 )
            end),
            TimeEvent(25*FRAMES, function(inst)
                inst.SoundEmitter:SetParameter( "gears", "intensity", 0.3 )
            end),
            TimeEvent(50*FRAMES, function(inst)
                inst.SoundEmitter:SetParameter( "gears", "intensity", 0.4 )
            end),
            TimeEvent(75*FRAMES, function(inst)
                inst.SoundEmitter:SetParameter( "gears", "intensity", 1 )
            end),

            TimeEvent(100*FRAMES, function(inst)
                inst.SoundEmitter:SetParameter( "gears", "intensity", .7 )
            end),

            ---------------electric--------------------
            TimeEvent(1*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro") end),
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro",nil,.5) end),
            TimeEvent(24*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro") end),
            TimeEvent(27*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro",nil,.5) end),
            TimeEvent(36*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro") end),
            TimeEvent(39*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro",nil,.5) end),
            TimeEvent(42*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro") end),
            TimeEvent(65*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro",nil,.5) end),
            TimeEvent(83*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro") end),
            TimeEvent(86*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro",nil,.5) end),
            TimeEvent(103*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro") end),
            TimeEvent(106*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro",nil,.25) end),
            TimeEvent(113*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro",nil,.25) end),
        ---------------green lights--------------------
            TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/arm/active") end),
            TimeEvent(10*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/arm/active") end),
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/arm/active",nil,.5) end),
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/arm/active") end),
            TimeEvent(40*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/head/active") end),
            TimeEvent(44*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/head/active") end),
            TimeEvent(54*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/active") end),
            TimeEvent(56*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/active") end),
            TimeEvent(58*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/active") end),
            TimeEvent(60*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/active") end),
        -------------step---------------
            TimeEvent(37*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/step") end),
            TimeEvent(101*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step") end),
        -------------servo---------------
            TimeEvent(28*FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity=math.random()})
            end),
            TimeEvent(46*FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity=math.random()})
            end),
            TimeEvent(64*FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity=math.random()})
            end),
            TimeEvent(84*FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity=math.random()})
            end),
            TimeEvent(128*FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity=math.random()})
            end),
    -------------tanut---------------
            TimeEvent(106*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/taunt") end),

        },

        events =
        {
            EventHandler("animqueueover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

----------------------COMBAT------------------------


    State{
        name = "hit",
        tags = {"hit"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/hit")
            inst.AnimState:PlayAnimation("hit")
        end,

        events =
        {
            EventHandler("animqueueover", function(inst)
                inst.sg:GoToState("idle")
            end),
        },
    },

    State{
        name = "attack",
        tags = {"attack", "busy", "canrotate"},

        onenter = function(inst)
            
            inst.components.locomotor:StopMoving()
            inst.components.combat:StartAttack()
            inst.AnimState:PlayAnimation("atk_chomp")
        end,

        timeline=
        {
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/dig") end),
            TimeEvent(22*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/drag") end),
            TimeEvent(14*FRAMES, function(inst)
				inst.sg.statemem.targets = {}
				DoArcAttack(inst, 0.5, 6, inst.sg.statemem.targets) 
			end),
            TimeEvent(15*FRAMES, function(inst) 
                DoArcAttack(inst, 0.5, 6, inst.sg.statemem.targets) 
            end),
        },

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

    State{
        name = "death",
        tags = {"busy"},

        onenter = function(inst)
            
            inst.components.locomotor:StopMoving()
            
            inst.AnimState:PlayAnimation("death_explode")
            
            RemovePhysicsColliders(inst)

            inst:ExitShield()
        end,

        timeline=
        {
            TimeEvent(2  * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity = 0.2}) end),
            TimeEvent(6  * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity = 0.3}) end),
            TimeEvent(23 * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity = 0.4}) end),
            TimeEvent(26 * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity = 0.6}) end),
            TimeEvent(33 * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity = 0.8}) end),
            TimeEvent(36 * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity = 1.0}) end),

            TimeEvent(17 * FRAMES, function (inst) inst.SoundEmitter:KillSound("gears") end),

            TimeEvent(17 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/death") end),
            TimeEvent(20 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/death_taunt") end),

            TimeEvent(61 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/explode_small", nil, 0.5) end),
            TimeEvent(67 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/explode_small", nil, 0.6) end),
            TimeEvent(77 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/explode_small", nil, 0.7) end),
            TimeEvent(79 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/explode_small", nil, 0.6) end),
            TimeEvent(82 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("porkland_soundpackage/creatures/boss/hulk_metal_robot/explode") end),

            TimeEvent(81*FRAMES, function(inst)
                   
                ShakeAllCameras(CAMERASHAKE.FULL, 0.7, 0.02, 2, inst, 40)
                local x,y,z = inst.Transform:GetWorldPosition()

                for i = -1, 1 do
                    for j = -1, 1 do
                        SpawnPrefab("deerclops_laserscorch").Transform:SetPosition(x+i, 0, z+j)
                    end
                end

                inst:DoDamage(7)
                inst.components.lootdropper:DropLoot()
                    
            end),
        },
    },

    ------------- TELEPORT ----------------------------

    State{
        name = "teleportout_pre",
        tags = {"busy"},

        onenter = function(inst,data)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("teleport_out_pre")

            
            if data.target~=nil and data.target:IsValid() then
                inst:ForceFacePoint(data.target.Transform:GetWorldPosition())
            end
            inst.sg.statemem.teledata = data
        end,

        timeline=
        {
                        ---teleport---
            TimeEvent(18*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/teleport_out") end),
                    -------------step---------------
            TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step",nil,.25) end),
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step",nil,.25) end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                --[[if inst.cancharge and not inst.sg.mem.teleporthome then
                    inst.sg:GoToState("teleport_attack")
                else
                    inst.sg.mem.teleporthome=nil
                    inst.sg:GoToState("teleportout")
                end]]
                if inst.sg.statemem.teledata.charge then
                    inst.sg:GoToState("teleport_attack")
                else
                    inst.sg:GoToState("teleportout",inst.sg.statemem.teledata)
                end
                
            end),
        },
    },

    State{
        name = "teleportout",
        tags = {"busy"},

        onenter = function(inst,data)
            
            inst.components.locomotor:StopMoving()
            
            inst.AnimState:PlayAnimation("teleport_out")
            inst.sg.statemem.telepos = FindTelePos(inst,data.target,data.type)
            inst.components.timer:StartTimer("teleport_cd",15)
        end,

        timeline=
        {
                        -----------servo---------------
            TimeEvent(11*FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity=math.random()})
            end),
            ----steps---
            TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step",nil,.15) end),
            TimeEvent(16*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step",nil,.25) end),
            TimeEvent(18*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/head/step",nil,.25) end),
            TimeEvent(39*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step") end),
            ----------gears loop--------------
            TimeEvent(19*FRAMES, function(inst)
                inst.SoundEmitter:SetParameter( "gears", "intensity", .2 )
            end),
            TimeEvent(5*FRAMES, function(inst)
                inst:DoDamage(5)
            end),
            TimeEvent(10*FRAMES, function(inst)
                inst.DynamicShadow:Enable(false)
                --inst.Physics:ClearCollisionMask()        
                inst:DoDamage(6)
            end),
            TimeEvent(15*FRAMES, function(inst)
                inst:DoDamage(8)
            end),
            TimeEvent(20*FRAMES, function(inst)
                inst:DoDamage(8)
            end),
        },
        events =
        {
            EventHandler("animover", function(inst)
                inst:Hide()
                inst.Physics:Teleport(inst.sg.statemem.telepos:Get())
                inst.sg:GoToState("teleportin")
            end ),
        },
    },
    State{
        name = "teleport_attack",
        tags = {"busy"},

        onenter = function(inst)
            
            inst.components.locomotor:Stop()

            inst.AnimState:PlayAnimation("teleport_out")
            inst.components.timer:StartTimer("teleportcharge_cd",15)
            inst.sg:SetTimeout(1.2)
        end,


        timeline=
        {
                        -----------servo---------------
            TimeEvent(11*FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity=math.random()})
            end),
            ----steps---
            TimeEvent(15*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step",nil,.15)
                teleportcharge(inst)
                inst:DoDamage(6)
            end),
            TimeEvent(16*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step",nil,.25) end),
            TimeEvent(20*FRAMES, function(inst)
                
                inst.DynamicShadow:Enable(false)
                --inst.Physics:ClearCollisionMask()
                teleportcharge(inst)
                inst:DoDamage(6)
            end),
            TimeEvent(30*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step")
                teleportcharge(inst)
                inst:DoDamage(6)
            end),
            TimeEvent(40*FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step")
                teleportcharge(inst)
                inst:DoDamage(6)
            end),
        },
        ontimeout=function(inst)
            
            inst.sg:GoToState("teleportin")
        end,
        onexit = function (inst)
            inst:Hide()


            inst.components.locomotor:Stop()
        end
    },
    
    State{
        name = "teleportin",
        tags = {"busy"},

        onenter = function(inst)
            inst:Show()
            inst.DynamicShadow:Enable(true)
            
            inst.components.locomotor:StopMoving()
            
            inst.AnimState:PlayAnimation("teleport_in")
            
        end,

        timeline=
        {
            TimeEvent(FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/teleport_in") end),
            -----------step---------------
            TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step",nil,.5) end),

            TimeEvent(16*FRAMES, function(inst) TheMixer:PushMix("boom")
            end),
            TimeEvent(17*FRAMES, function(inst)
                --GetPlayer().components.playercontroller:ShakeCamera(inst, "FULL", 0.7, 0.02, 2, 40)
                --ShakeAllCameras(CAMERASHAKE.FULL, .7, .02, 1, inst, 40)
                inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/groundpound")
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step",nil,.5)
                inst.components.groundpounder:GroundPound()
            end),
            TimeEvent(19*FRAMES, function(inst) TheMixer:PopMix("boom")
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                

                inst.sg:GoToState("idle")
            end ),
        },
    },
    --------------------- BOMBS -------------------------------

    State{
        name = "bomb_pre",
        tags = {"busy"},

        onenter = function(inst)

            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("atk_bomb_pre")
        end,

        
        timeline=
        {
            -----rust----
            TimeEvent(16*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust",nil,.5) end),
            TimeEvent(18*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust",nil,.5) end),
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust",nil,.5) end),
            TimeEvent(22*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust",nil,.5) end),
            -----bomb ting----
            TimeEvent(18*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ting") end),
            TimeEvent(20*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ting") end),
            TimeEvent(22*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ting") end),
            TimeEvent(24*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ting") end),
            ----electro-----
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro",nil,.5) end),
            TimeEvent(15*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro",nil,.5) end),
            TimeEvent(19*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro",nil,.5) end),
            TimeEvent(23*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro",nil,.5) end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("bomb")
            end ),
        },
    },

    State{
        name = "bomb",
        tags = {"busy"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("atk_bomb_loop")
            inst.components.timer:StartTimer("bomb_cd",16)
        end,

        timeline=
        {   ---mine shoot---
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/mine_shot") end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/mine_shot") end),
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/mine_shot") end),
            TimeEvent(18*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/mine_shot") end),


            TimeEvent(5*FRAMES, function(inst)
                inst:LaunchMine(0)
                inst:LaunchMine(45)
            end),
            TimeEvent(9*FRAMES, function(inst)
                inst:LaunchMine(90)
            end),
            TimeEvent(13*FRAMES, function(inst)
                inst:LaunchMine(180)
            end),
            TimeEvent(19*FRAMES, function(inst)
                inst:LaunchMine(270)
                inst:LaunchMine(220)
            end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("bomb_pst")
            end ),
        },
    },

    State{
        name = "bomb_pst",
        tags = {"busy"},

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("atk_bomb_pst")
        end,

       

        timeline=
        {
            -----rust----
            TimeEvent(6*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust",nil,.5) end),
            TimeEvent(9*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust",nil,.5) end),
            TimeEvent(11*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust",nil,.5) end),
            TimeEvent(17*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/rust",nil,.5) end),
            -----bomb ting----
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ting") end),
            TimeEvent(11*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ting") end),
            TimeEvent(13*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ting") end),
            TimeEvent(19*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ting") end),
             -----------servo---------------
            TimeEvent(11*FRAMES, function(inst)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity=math.random()}) end),
        },

        events =
        {
            EventHandler("animover", function(inst)
                
                inst.sg:GoToState("idle")
            end ),
        },
    },

---------------------------LOB---------------

    State{
        name = "lob",
        tags = {"busy","canrotate"},

        onenter = function(inst,target)

            inst.AnimState:PlayAnimation("atk_lob")
            inst.sg.statemem.target = target
            --inst.components.combat:StartAttack()
            inst.components.locomotor:Stop()
        end,

        onupdate = function(inst)
            if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then
                inst:ForceFacePoint(inst.sg.statemem.target.Transform:GetWorldPosition())
            end
        end,

        timeline =
        {
            TimeEvent(25*FRAMES, function(inst)
                local angle = inst.Transform:GetRotation() * DEGREES
                if inst.sg.statemem.target~=nil and inst.sg.statemem.target:IsValid() then
                    inst.sg.statemem.targetpos = inst.sg.statemem.target:GetPosition()
                    angle = inst:GetAngleToPoint(inst.sg.statemem.targetpos)
                else
                    
                    local offset = Vector3(15 * math.cos( angle ), 0, -15 * math.sin( angle ))
                    local x, y, z = inst.Transform:GetWorldPosition()
                    inst.sg.statemem.targetpos = Vector3(x + offset.x,y + offset.y,z + offset.z)
                end
                
                inst:ShootProjectile(inst.sg.statemem.targetpos)
                if inst.angry then
                    local offset1 = Vector3(6 * math.cos( angle ), 0, -6 * math.sin( angle ))
                    local offset2 = Vector3(6 * math.cos( angle+PI/2 ), 0, -6 * math.sin( angle+PI/2 ))
                    local offset3 = Vector3(6 * math.cos( angle+PI ), 0, -6 * math.sin( angle+PI ))
                    local offset4 = Vector3(6 * math.cos( angle-PI/2 ), 0, -6 * math.sin( angle-PI/2 ))
                    inst:ShootProjectile(inst.sg.statemem.targetpos+offset1)
                    inst:ShootProjectile(inst.sg.statemem.targetpos+offset2)
                    inst:ShootProjectile(inst.sg.statemem.targetpos+offset3)
                    inst:ShootProjectile(inst.sg.statemem.targetpos+offset4)
                end
                inst.lob_count = inst.lob_count - 1
                if inst.lob_count<=0 then
                    inst.components.combat.attackrange = 5
                    inst:DoTaskInTime(inst.cancharge and 12 or 18, function() 
                        inst.lob_count = 5 
                        inst.components.combat.attackrange = 18
                    end)
                end
            end),

            TimeEvent(0*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser_pre") end),
            TimeEvent(30*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity=math.random()})end),
        },


        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end ),
        },
    },


----------------------SPIN--------------------

    State{
        name = "spin",
        tags = {"busy"},

        onenter = function(inst)

            inst.Transform:SetNoFaced()
            inst.components.locomotor:StopMoving()

            inst.AnimState:PlayAnimation("atk_circle")
            inst.components.timer:StartTimer("spin_cd", 20)

            inst.components.planardamage:AddBonus(inst, 25, "full_charged")
        end,

        timeline=
        {
            TimeEvent(10 * FRAMES, function(inst)inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/step", nil, 0.5) end),
            TimeEvent(68 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step", nil, 0.5) end),
            TimeEvent(70 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step", nil, 0.5) end),
            TimeEvent(82 * FRAMES, function(inst)inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/step", nil, 0.5) end),
            TimeEvent(90 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/leg/step", nil, 0.5) end),

            TimeEvent(11 * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity = math.random()}) end),
            TimeEvent(62 * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity = math.random()}) end),

            TimeEvent(14 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro") end),
            TimeEvent(21 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro") end),
            TimeEvent(26 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/electro") end),

            TimeEvent(30 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/spin") end),
            TimeEvent(30 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/burn_LP", "laserburn") end),
            TimeEvent(49 * FRAMES, function(inst) inst.SoundEmitter:KillSound("laserburn") end),

             ---------spin laser ground--------
            TimeEvent(37*FRAMES, function(inst)
                inst:DoDamage(BEAMRAD,0,45)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity= 0})
                spawnburns(inst,BEAMRAD,0,45,5)
            end),
            TimeEvent(39*FRAMES, function(inst)
                inst:DoDamage(BEAMRAD,45,90)
                spawnburns(inst,BEAMRAD,45,90,5)
            end),
            TimeEvent(40*FRAMES, function(inst)
                inst:DoDamage(BEAMRAD,90,135)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity= .3})
                spawnburns(inst,BEAMRAD,90,135,5)
            end),
            TimeEvent(41*FRAMES, function(inst)
                inst:DoDamage(BEAMRAD,135,180)

                spawnburns(inst,BEAMRAD,135,180,5)
            end),
            TimeEvent(42*FRAMES, function(inst)
                inst:DoDamage(BEAMRAD,180,225)

                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity= 0.5})
                spawnburns(inst,BEAMRAD,180,225,5)
            end),
            TimeEvent(45*FRAMES, function(inst)
                inst:DoDamage(BEAMRAD,225,270)

                spawnburns(inst,BEAMRAD,225,270,5)
            end),
            TimeEvent(47*FRAMES, function(inst)
                inst:DoDamage(BEAMRAD,270,315)
                inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/laser", {intensity= 0.7})
                spawnburns(inst,BEAMRAD,270,315,5)
            end),
            TimeEvent(48*FRAMES, function(inst)
                inst:DoDamage(BEAMRAD,315,360)
                spawnburns(inst,BEAMRAD,315,360,5)
            end),
        },


        onexit = function(inst)
            inst.Transform:SetSixFaced()
            inst.components.planardamage:RemoveBonus(inst,"full_charged")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                inst.sg:GoToState("idle")
            end ),
        },
    },


----------------------  BARRIER--------------------

    State{
        name = "barrier",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.Transform:SetNoFaced()
            
            inst.components.locomotor:StopMoving()
            
            inst.AnimState:PlayAnimation("atk_barrier")
        end,            
        
        timeline=
        {        
            --step---
            TimeEvent(12 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/step") end),
            TimeEvent(19 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/barrier") end),
            TimeEvent(67 * FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC001/creatures/bearger/groundpound")end),


            TimeEvent(64*FRAMES, function(inst)
                inst.components.groundpounder.damageRings = 4
                inst.components.groundpounder.destructionRings = 4
                inst.components.groundpounder.numRings = 4
                ShakeAllCameras(CAMERASHAKE.FULL, 0.7, 0.02, 2, inst, SHAKE_DIST)
                inst.components.groundpounder:GroundPound()
                
                inst:DoTaskInTime(0.6,inst.spawnbarrier)
                --local fx = SpawnPrefab("metal_hulk_ring_fx")
                --fx.Transform:SetPosition(pt.x,pt.y,pt.z)
                --fx.AnimState:SetOrientation( ANIM_ORIENTATION.OnGround )
                --fx.AnimState:SetLayer( LAYER_BACKGROUND )
                --fx.AnimState:SetSortOrder( 2 )
            end),
        },

        onexit = function(inst)
            inst.Transform:SetSixFaced()
            inst.components.timer:StartTimer("barrier_cd",40)
            inst.components.groundpounder.damageRings = 2
            inst.components.groundpounder.destructionRings = 3
            inst.components.groundpounder.numRings = 3
        end, 

        events =
        {   
            EventHandler("animover", function(inst)  
                inst.sg:GoToState("idle")
            end ),        
        },
    },
}

CommonStates.AddWalkStates(states,
{
    walktimeline =
    {
        TimeEvent(12 * FRAMES, function(inst) DoFootstep(inst) end),
        TimeEvent(16 * FRAMES, function(inst) DoFootstep(inst) end),
        TimeEvent(20 * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/arm/step", {intensity = math.random()}) end),
        TimeEvent(3  * FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity = math.random()}) end),
    },
}, nil, nil, true, {endonenter = DoFootstep})


return StateGraph("ancient_hulk", states, events, "idle")


