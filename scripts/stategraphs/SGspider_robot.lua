require("stategraphs/commonstates")
local function SetLightValue(inst, val)
    if inst.Light ~= nil then
        inst.Light:SetIntensity(.6 * val * val)
        inst.Light:SetRadius(5 * val)
        inst.Light:SetFalloff(3 * val)
    end
end

local function SetLightValueAndOverride(inst, val, override)
    if inst.Light ~= nil then
        inst.Light:SetIntensity(.6 * val * val)
        inst.Light:SetRadius(5 * val)
        inst.Light:SetFalloff(3 * val)
        inst.AnimState:SetLightOverride(override)
    end
end

local function SetLightColour(inst, val)
    if inst.Light ~= nil then
        inst.Light:SetColour(val, 0, 0)
    end
end

local events=
{
    CommonHandlers.OnStep(),
    CommonHandlers.OnLocomote(true,true), 
    EventHandler("doattack", function(inst,data)
		if not (inst.components.health:IsDead() or inst.sg:HasStateTag("busy")) then
                local target = data.target
                if target~=nil and target:IsValid() and inst:IsNear(target,8) then
                    inst.sg:GoToState("laserbeam",data.target)
                end     
        end            
	end),
    EventHandler("death", function(inst,data) 
        inst.sg:GoToState("death")
    end),
}

local function SpawnLaserHitOnly(inst, dist, scale, targets)
	local x, y, z = inst.Transform:GetWorldPosition()
	local rot = inst.Transform:GetRotation() * DEGREES
	local fx = SpawnPrefab("deerclops_laserempty")
	fx.caster = inst
	fx.Transform:SetPosition(x + dist * math.cos(rot), 0, z - dist * math.sin(rot))

	local hitscale = math.max(1, scale)
	local heavymult, mult, forcelanded = scale, scale * 1.3, true

	fx:Trigger(0, targets, nil, true, nil, nil, hitscale, heavymult, mult, forcelanded)
end
local function SpawnLaser(inst, dist, angle_offset, scale, scorchscale, targets)
	local x, y, z = inst.Transform:GetWorldPosition()
	local rot = (inst.Transform:GetRotation() + angle_offset) * DEGREES
	local fx = SpawnPrefab("deerclops_laser")
	fx.caster = inst
	fx.Transform:SetPosition(x + dist * math.cos(rot), 0, z - dist * math.sin(rot))

	local animscale = scale * (0.9 + math.random() * 0.2) * (inst.sg.mem.fliplaser and -1 or 1)
	inst.sg.mem.fliplaser = not inst.sg.mem.fliplaser

	local hitscale = math.max(1, scale)
	local heavymult, mult =  scale, scale * 1.3

	fx:Trigger(0, targets, nil, scorchscale < 0.2, animscale, scorchscale, hitscale, heavymult, mult, true)
	return dist + 0.6
end

local states=
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("idle", true)
            inst.sg:SetTimeout(2 + 2*math.random())
        end,
        
        ontimeout=function(inst)
            inst.sg:GoToState("taunt")
        end,
    },

    State{
        name = "activate",
        tags = {"busy","activating"},
        
        onenter = function(inst)
           
            
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("activate")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/gears_LP","gears")
            inst.SoundEmitter:SetParameter("gears", "intensity", .5)

        end,
        timeline =
        {
            FrameEvent(2, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/active")
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/start")
            end),
            
            FrameEvent(4, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/active")
            end),
            FrameEvent(6, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/active")
            end),
            FrameEvent(8, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/active")
            end),
            FrameEvent(10, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/active")
            end),
            FrameEvent(12, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/active")
            end),

            FrameEvent(14, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/active")
            end),
            FrameEvent(16, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/active")
            end),
            FrameEvent(18, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
            end),
            FrameEvent(21, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
            end),
            FrameEvent(30, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
            end),
            FrameEvent(33, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
            end),
            FrameEvent(39, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
            end),
        },
        events=
        {
            EventHandler("animover", function(inst)
                inst:RestartBrain()
                inst.sg:GoToState("taunt") 
            end),
        },    
    },

    State{
        name = "taunt",
        tags = {"busy","canrotate"},
        
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("taunt")
            inst.SoundEmitter:PlaySound("grotto/creatures/centipede/rolling_atk_LP","roll")
        end,
        timeline=
        {
            FrameEvent(4,function (inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo")
            end),
            FrameEvent(17,function (inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo")
            end),
            FrameEvent(21,function (inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/taunt")
            end),
            FrameEvent(45,function (inst)
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo")
            end)
        },
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        }, 
        onexit = function(inst)
            inst.SoundEmitter:KillSound("roll")
        end,       
    },

    State{
        name = "laserbeam",
        tags = { "busy","attack" },

        onenter = function(inst, target)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("atk")
            inst.Transform:SetEightFaced()
            if target ~= nil and target:IsValid() then
                inst.components.combat:StartAttack()
                inst:ForceFacePoint(target.Transform:GetWorldPosition())
                inst.sg.statemem.target = target
                inst.sg.statemem.targetpos =target:GetPosition()
            end
            --inst.components.timer:StopTimer("laserbeam_cd")
            --inst.components.timer:StartTimer("laserbeam_cd", 5)
        end,
        onupdate = function(inst)
            
            if inst.sg.statemem.target then
				if inst.sg.statemem.target:IsValid() then
					local rot = inst.Transform:GetRotation()
					local rot1 = inst:GetAngleToPoint(inst.sg.statemem.target.Transform:GetWorldPosition())
					if DiffAngle(rot, rot1) < 30 then
						inst.Transform:SetRotation(rot1)
					end
				else
					inst.sg.statemem.target = nil
				end
			end
        end,
        timeline =
        {

            FrameEvent(4, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo")
            end),

            FrameEvent(2, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser_pre")
            end),

            FrameEvent(19, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo")
            end),

            FrameEvent(22, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser","laserfilter")
                inst.SoundEmitter:SetParameter("laserfilter", "intensity", .12)
                inst.sg.statemem.target = nil
            end),
            FrameEvent(24, function(inst) 
                
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser","laserfilter")
                inst.SoundEmitter:SetParameter("laserfilter", "intensity", .24)
            end),
            FrameEvent(26, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser","laserfilter")
                inst.SoundEmitter:SetParameter("laserfilter", "intensity", .48)
            end),
            FrameEvent(28, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser","laserfilter")
                inst.SoundEmitter:SetParameter("laserfilter", "intensity", .60)
            end),
            FrameEvent(30, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser","laserfilter")
                inst.SoundEmitter:SetParameter("laserfilter", "intensity", .72)
            end),
            FrameEvent(32, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser","laserfilter")
                inst.SoundEmitter:SetParameter("laserfilter", "intensity", .84)
            end),
            FrameEvent(34, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser","laserfilter")
                inst.SoundEmitter:SetParameter("laserfilter", "intensity", .96)
            end),
            FrameEvent(36, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/laser","laserfilter")
                inst.SoundEmitter:SetParameter("laserfilter", "intensity", 1)
            end),


            FrameEvent(8 , function(inst) inst.Light:Enable(true) 
                                                 SetLightValueAndOverride(inst, 0.05, .2) end),
            FrameEvent(9 , function(inst) SetLightValueAndOverride(inst, 0.1, .15) end),
            FrameEvent(10 , function(inst) SetLightValueAndOverride(inst, 0.15, .05) end),
            FrameEvent(11 , function(inst) SetLightValueAndOverride(inst, 0.20, 0) end),
            FrameEvent(12 , function(inst) SetLightValueAndOverride(inst, 0.25, .35) end),
            FrameEvent(13 , function(inst) SetLightValueAndOverride(inst, 0.30, .3) end),
            FrameEvent(14 , function(inst) SetLightValueAndOverride(inst, 0.35, .05) end),
            FrameEvent(15 , function(inst) SetLightValueAndOverride(inst, 0.40, 0) end),
            FrameEvent(16 , function(inst) SetLightValueAndOverride(inst, 0.45, .3) end),
            FrameEvent(17 , function(inst) SetLightValueAndOverride(inst, 0.50, .15) end),
            FrameEvent(18 , function(inst) SetLightValueAndOverride(inst, 0.55, .05) end),
            FrameEvent(19 , function(inst) SetLightValueAndOverride(inst, 0.60, 0) end),
            FrameEvent(20 , function(inst) SetLightValueAndOverride(inst, 0.65, .35) end),
            FrameEvent(21 , function(inst) SetLightValueAndOverride(inst, 0.70, .3) end),
            FrameEvent(22 , function(inst) SetLightValueAndOverride(inst, 0.75, .05) end),
            FrameEvent(23 , function(inst) SetLightValueAndOverride(inst, 0.80, 0) end),
            FrameEvent(24 , function(inst) SetLightValueAndOverride(inst, 0.85, .3) end),
            FrameEvent(25 , function(inst) SetLightValueAndOverride(inst, 0.90, .15) end),
            FrameEvent(26 , function(inst) SetLightValueAndOverride(inst, 0.95, .05) end),
            FrameEvent(27 , function(inst) SetLightValueAndOverride(inst, 1, 0) end),
            FrameEvent(28 , function(inst) SetLightValueAndOverride(inst, 1.01, .35) end),

            FrameEvent(29 , function(inst)
                SetLightValueAndOverride(inst, .9, 0)                
            end),
            FrameEvent(30 , function(inst)
                inst.sg.statemem.targets = { [inst] = true }
                
                SpawnPrefab("deerclops_laserhit"):SetTarget(inst)
				inst.sg.statemem.hit = true

				SpawnLaserHitOnly(inst, 1.5, 2.5, inst.sg.statemem.targets)
                local dist = 2
				SpawnLaser(inst, dist, -30, 2, 0, inst.sg.statemem.targets)
				SpawnLaser(inst, dist, 30, 2, 0, inst.sg.statemem.targets)
				dist = SpawnLaser(inst, dist, 0, 2, 5, inst.sg.statemem.targets)

				SpawnLaser(inst, dist, -25, 1.5, 0, inst.sg.statemem.targets)
				SpawnLaser(inst, dist, 25, 1.5, 0, inst.sg.statemem.targets)
				dist = SpawnLaser(inst, dist, 0, 1.5, 3, inst.sg.statemem.targets)
				inst.sg.statemem.dist = dist
                inst.sg.statemem.target = nil
            end),
            FrameEvent(31 , function(inst) 
                local dist = inst.sg.statemem.dist
				local scorchscale = 2.5
				for i = 1, 4 do
					scorchscale = scorchscale * 0.8
					dist = SpawnLaser(inst, dist, 0, 1, scorchscale, inst.sg.statemem.targets)
				end
				inst.sg.statemem.dist = dist
				inst.sg.statemem.scorchscale = scorchscale
                SetLightValueAndOverride(inst, 1.12, 1) 
            end),
            FrameEvent(32 , function(inst) 
                local dist = inst.sg.statemem.dist
				local scorchscale = inst.sg.statemem.scorchscale
				for i = 1, 6 do
					--scorchscale = scorchscale * 0.8
					dist = SpawnLaser(inst, dist, 0, Lerp(1, 0.5, i / 10), scorchscale, inst.sg.statemem.targets)
				end
				--inst.sg.statemem.dist = dist
				--inst.sg.statemem.scorchscale = scorchscale
            end),
            FrameEvent(34 , function(inst) SetLightValueAndOverride(inst, 1.1, .6) end),
            FrameEvent(35 , function(inst) inst.sg.statemem.lightval = 1.1 end),
            FrameEvent(36 , function(inst) 
                inst.sg.statemem.lightval = 1.035
                SetLightColour(inst, .9)
            end),

            FrameEvent(37 , function(inst)
                inst.sg.statemem.lightval = nil
                SetLightValueAndOverride(inst, .9, 0)
                SetLightColour(inst, .9)
            end),
            FrameEvent(38 , function(inst)
                inst.sg:RemoveStateTag("busy")
                SetLightValue(inst, 1)
                SetLightColour(inst, 1)
                inst.Light:Enable(false)
            end),
        },
        
        events =
        {
            EventHandler("animover", function(inst)
                inst.sg.statemem.keepfacing = true
                inst.sg:GoToState("idle")
            end),
        },

        onexit = function(inst)
            inst.Transform:SetFourFaced()
            
            SetLightValueAndOverride(inst, 1, 0)
            SetLightColour(inst, 1)

            inst.Light:Enable(false)
        end,
        
    },
    State{
        name = "attack",
        tags = {"attack", "busy"},
        
        onenter = function(inst, target)    
			inst.sg.statemem.target = target
            inst.components.combat:StartAttack()
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("atk", false)
        end,        
        
        
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },    
    State{
        name = "death",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("death")
            inst.Physics:Stop()
            --RemovePhysicsColliders(inst)
            inst.components.lootdropper:DropLoot(inst:GetPosition())
            ReplacePrefab(inst,"spider_robot_debris")
        end,
    },    
    
}
CommonStates.AddWalkStates(states)
CommonStates.AddRunStates(states,
{
    starttimeline={
        FrameEvent(1,function (inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step","steps")
            inst.SoundEmitter:SetParameter("steps", "intensity", 1)
        end)
    },

    runtimeline=
    {
        FrameEvent(0,function (inst)
            inst.Physics:Stop() 
            inst.components.locomotor:WalkForward()
        end),
        FrameEvent(3, function(inst)   
            inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/boss/hulk_metal_robot/ribs/servo", {intensity=math.random()})                                                      
        end),
        FrameEvent(12,function (inst)
            inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/enemy/metal_robot/leg/step", {intensity=math.random()})
            inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/pangolden/walk", {timeoffset=math.random()})
        end),
        FrameEvent(16,function (inst)
            inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/enemy/metal_robot/leg/step", {intensity=math.random()})
            inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/pangolden/walk", {timeoffset=math.random()})
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step_wires","steps")
            inst.SoundEmitter:SetParameter("steps", "intensity", 0.5)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo","servo")
            inst.SoundEmitter:SetParameter("servo", "intensity", 0.5)
        end),
        FrameEvent(25,function (inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step","steps")
            inst.SoundEmitter:SetParameter("steps", "intensity", 1)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo","servo")
            inst.SoundEmitter:SetParameter("servo", "intensity", 1)
        end),
        FrameEvent(38,function (inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step","steps")
            inst.SoundEmitter:SetParameter("steps", "intensity", 0.8)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo","servo")
            inst.SoundEmitter:SetParameter("servo", "intensity", 0.8)
        end),
        FrameEvent(48,function (inst)
            inst.Physics:Stop() 
        end)
    },
    endtimeline=
    {
        FrameEvent(3,function (inst)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/step","steps")
            inst.SoundEmitter:SetParameter("steps", "intensity", 0.5)
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/ribs/servo","servo")
            inst.SoundEmitter:SetParameter("servo", "intensity", 0.5)
        end),
        FrameEvent(48,function (inst)
            inst.Physics:Stop() 
        end)
    }
},
    {startrun="walk_pre",run="walk_loop",stoprun="walk_pst"},
    true,
    {
        startexit = function(inst)
            if not inst.cleantransition then
                inst.SoundEmitter:KillSound("robo_walk_LP")
            end            
        end,
        loopexit = function(inst)
            if not inst.cleantransition then
                inst.SoundEmitter:KillSound("robo_walk_LP")
            end 
        end,        
        endexit = function(inst)
           inst.SoundEmitter:KillSound("robo_walk_LP")
        end,
    }
)


return StateGraph("SGspider_robot", states, events, "idle")