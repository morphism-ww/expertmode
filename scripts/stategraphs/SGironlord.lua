require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.HAMMER, "combat_leap_start"),
}
    

local function ToggleOffPhysics(inst)
    inst.sg.statemem.isphysicstoggle = true
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.GROUND)
end

local function ToggleOnPhysics(inst)
    inst.sg.statemem.isphysicstoggle = nil
    inst.Physics:ClearCollisionMask()
    inst.Physics:CollidesWith(COLLISION.OBSTACLES)
    inst.Physics:CollidesWith(COLLISION.CHARACTERS)
    inst.Physics:CollidesWith(COLLISION.GIANTS)
    inst.Physics:CollidesWith(COLLISION.GROUND)
end

local function SummonHolyLight(inst,target,num,radius)
    if target and target:IsValid() then
        local x, _, z = target.Transform:GetWorldPosition()
        local angle=360*math.random()
        local angle_delta=360/num
        for i=1,num do
            local projectile = SpawnPrefab("alter_light")
            projectile.Transform:SetPosition(x + radius*math.cos(angle*DEGREES), 0, z - radius* math.sin(angle*DEGREES))
            angle = angle + angle_delta
        end
        SpawnPrefab("alter_light").Transform:SetPosition(x, 0, z)
    end
end

local function TryLineAttack(inst,angle_delta)
    
    local x,y,z = inst.Transform:GetWorldPosition()
    local angle = inst.Transform:GetRotation() + angle_delta


    local proj = SpawnPrefab("sword_ancient_proj")
    proj.Transform:SetPosition(x,y,z)
    --proj.Transform:SetRotation(angle)
    --proj.Physics:SetMotorVel(30, 0, 0)
    proj.components.linearprojectile:LineShoot(Vector3(x+4*math.cos(angle*DEGREES),0,z-4*math.sin(angle*DEGREES)),inst)
    --[[local doer_combat = inst.components.combat
    local ents = TheSim:FindEntities(x,0,z,20,{"_combat","_health"}, {"FX",  "INLIMBO","invisible","noattack"})
    for _, v in ipairs(ents) do
        if doer_combat:CanTarget(v) and not (v.components.health and v.components.health:IsDead()) then
            local tx,ty,tz = v.Transform:GetWorldPosition()        
            local drot = math.abs(angle - inst:GetAngleToPoint(tx,0,tz))
            while drot > 180 do
                drot = drot - 360
            end
            
            if math.abs(drot) <= 80 and math.abs(sin_rot*(x-tx)+cos_rot*(z-tz))<=2 then
                
                v.components.combat:GetAttacked(inst, 150, nil, nil, {planar = 30})
            end    
        end
    end]]
    if inst.shootcount<1 then
        inst:DoTaskInTime(10,function ()
            inst.shootcount = math.random(7,9)
        end)
    end
end
local function shoot_laser(inst,target)
    if target~=nil and target:IsValid() then 
        local laser = SpawnPrefab("twin_laser")
        --laser.components.projectile.owner=inst

        local x, y, z = inst.Transform:GetWorldPosition()
        laser.Transform:SetPosition(x,y,z)
        laser.components.projectile:Throw(inst, target, inst)
    end
end

local SWIPE_ARC = 240
local SWIPE_OFFSET = 2
local SWIPE_RADIUS = 6


local function IsTargetInFront(inst, target, arc)
	if not (target and target:IsValid()) then
		return false
	end
	local rot = inst.Transform:GetRotation()
	local rot1 = inst:GetAngleToPoint(target.Transform:GetWorldPosition())
	return DiffAngle(rot, rot1) < (arc or 180) / 2
end

local COLLAPSIBLE_WORK_ACTIONS =
{
	CHOP = true,
	HAMMER = true,
	MINE = true,
	-- no digging
}
local COLLAPSIBLE_TAGS = { "NPC_workable" }
for k, v in pairs(COLLAPSIBLE_WORK_ACTIONS) do
	table.insert(COLLAPSIBLE_TAGS, k.."_workable")
end
local NON_COLLAPSIBLE_TAGS = { "FX", --[["NOCLICK",]] "DECOR", "INLIMBO" }

local function DoAOEWork(inst, radius)
	local x, y, z = inst.Transform:GetWorldPosition()
	
	for i, v in ipairs(TheSim:FindEntities(x, y, z, radius, nil, NON_COLLAPSIBLE_TAGS, COLLAPSIBLE_TAGS)) do
		if v:IsValid() and not v:IsInLimbo() and v.components.workable ~= nil then
			local work_action = v.components.workable:GetWorkAction()
			--V2C: nil action for NPC_workable (e.g. campfires)
			if (work_action == nil and v:HasTag("NPC_workable")) or
				(v.components.workable:CanBeWorked() and work_action ~= nil and COLLAPSIBLE_WORK_ACTIONS[work_action.id])
				then
				
				v.components.workable:Destroy(inst)
					--[[if v:IsValid() and v:HasTag("stump") then
						v:Remove()
					end]]
				
			end
		end
	end
end

local AOE_RANGE_PADDING = 3
local AOE_TARGET_MUSTHAVE_TAGS = { "_combat" }
local AOE_TARGET_CANT_TAGS = { "INLIMBO", "flight", "invisible", "notarget", "noattack" }

local function DoArcAttack(inst, dist, radius, arc, heavymult, mult, forcelanded, targets)
	inst.components.combat.ignorehitrange = true
	local x, y, z = inst.Transform:GetWorldPosition()
	local arcx, cos_theta, sin_theta
	if dist ~= 0 or arc then
		local theta = inst.Transform:GetRotation() * DEGREES
		cos_theta = math.cos(theta)
		sin_theta = math.sin(theta)
		if dist ~= 0 then
			x = x + dist * cos_theta
			z = z - dist * sin_theta
		end
		if arc then
			--min-x for testing points converted to local space
			arcx = x + math.cos(arc / 2 * DEGREES) * radius
		end
	end
	for i, v in ipairs(TheSim:FindEntities(x, y, z, radius + AOE_RANGE_PADDING, AOE_TARGET_MUSTHAVE_TAGS, AOE_TARGET_CANT_TAGS)) do
		if v ~= inst and
			not (targets and targets[v]) and
			v:IsValid() and not v:IsInLimbo() and
			not (v.components.health and v.components.health:IsDead())
		then
			local range = radius + v:GetPhysicsRadius(0)
			local x1, y1, z1 = v.Transform:GetWorldPosition()
			local dx = x1 - x
			local dz = z1 - z
			if dx * dx + dz * dz < range * range and
				--convert to local space x, and test against arcx
				(arcx == nil or x + cos_theta * dx - sin_theta * dz > arcx) and
				inst.components.combat:CanTarget(v)
			then
				
                inst.components.combat:DoAttack(v)
                if mult then
                    local strengthmult = (v.components.inventory and v.components.inventory:ArmorHasTag("heavyarmor") or v:HasTag("heavybody")) and heavymult or mult
                    v:PushEvent("knockback", { knocker = inst, radius = radius + dist, strengthmult = strengthmult, forcelanded = forcelanded })
                end
				
				if targets then
					targets[v] = true
				end
			end
		end
	end
	inst.components.combat.ignorehitrange = false
end

local function ChooseAttack0(inst,target)
    if not inst.components.timer:TimerExists("killer_cd") then
        inst.sg:GoToState("charge",target)
    elseif inst:IsNear(target, 14 + target:GetPhysicsRadius(0)) and inst.shootcount>0 then
		inst.sg:GoToState("attack1", target)
    else
        inst.sg:GoToState("attack3_pre", target)
    end
end

local function ChooseAttack(inst,target)
    if inst:IsNear(target, 6 + target:GetPhysicsRadius(0)) then
		inst.sg:GoToState(math.random()<0.5 and "attack1" or "attack2", target)
    elseif inst:IsNear(target, 14 + target:GetPhysicsRadius(0)) then
        inst.sg:GoToState("attack3", target)
    elseif inst:IsNear(target, 18) then
        inst.sg:GoToState("combat_leap_atk", {target = target})
    end    
end

local events=
{
    CommonHandlers.OnLocomote(false,true),
    CommonHandlers.OnDeath(),
    EventHandler("doattack", function(inst,data)
        if not ( inst.components.health:IsDead() or inst.sg:HasStateTag("busy"))
            and (data.target ~= nil and data.target:IsValid())  then
            if inst.awake then
                ChooseAttack0(inst,data.target)
            else
                ChooseAttack(inst,data.target)
            end        
        end
    end), 
    EventHandler("leap_pre", function(inst)
        if not inst.components.health:IsDead() then
            
            inst.sg:GoToState("combat_leap_start",inst.components.combat.target)
        end
    end),
    EventHandler("awake", function(inst)
        if not inst.components.health:IsDead() then
            if not inst.sg:HasStateTag("busy") then
                inst.sg:GoToState("awake")
            else
                inst.sg.mem.wantstoawake = true
            end    
        end
    end),
    EventHandler("erode",function (inst)
        if not inst.components.health:IsDead() then
            inst.sg:GoToState("erode_pre")
        end    
    end)
}

local function DoAOEAttack(inst,radius)
    local x,y,z = inst.Transform:GetWorldPosition()
    local leap_targets = TheSim:FindEntities(x, 0, z, radius, {"_combat"}, {"FX", "DECOR", "INLIMBO","deity","noattack","invisible"})
    for _, leap_target in ipairs(leap_targets) do
        if leap_target ~= inst and leap_target:IsValid() and not leap_target:IsInLimbo()
                and not (leap_target.components.health and leap_target.components.health:IsDead()) then
            local targetrange = 4 + leap_target:GetPhysicsRadius(0.5)
            if leap_target:GetDistanceSqToPoint(x,y,z) < targetrange * targetrange 
                and inst.components.combat:CanTarget(leap_target) then
                inst.components.combat:DoAttack(leap_target)
            end
        end
    end
end

local states=
{
    State {
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("idle_loop")
            if inst.sg.mem.wantstoawake  then
                inst.sg:GoToState("awake")
            end
        end,
        
       events=
        {
            EventHandler("animover", function(inst) 
                inst.sg:GoToState("idle")                                    
            end),
        }, 
    },
    State{
        name = "awake",
        tags = {"busy", "nointerrupt"},
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("idle_lunacy_pre")
            inst.AnimState:PushAnimation("idle_lunacy_loop")
            inst.sg.mem.wantstoawake = nil
            inst.components.health:SetInvincible(true)
            inst:EquipGodWeapon()
            inst.sg:SetTimeout(3)
        end,
        timeline = {
            TimeEvent(FRAMES,function (inst)
                SummonHolyLight(inst,inst,3,6)
            end),
            TimeEvent(30*FRAMES,function (inst)
                SummonHolyLight(inst,inst,3,6)
                SummonHolyLight(inst,inst,6,8)
            end)
        },
        ontimeout  =function (inst)
            inst.components.health:SetInvincible(false)
            inst.sg:GoToState("idle")   
        end,
    },
    State{
        name = "erode_pre",
        tags = {"busy", "nointerrupt","noattack"},
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("multithrust_yell")
            inst.components.timer:StartTimer("erode_cd",35)
            inst:erode(3,false)
        end,
        events=
        {
            EventHandler("animover", function(inst) 
                inst.sg:GoToState("idle")                                    
            end),
        }, 
    },
    State{
        name = "charge",
        tags = {"busy","charge"},
        
        onenter = function(inst,target)		
            inst:UnEquipWeapon()
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("charge_pre")
            inst.AnimState:PushAnimation("charge_grow")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/iron_lord/charge_up_LP", "chargedup")
            inst.sg.statemem.target = target  
            inst.sg:SetTimeout(0.3)  
            --inst.components.talker:Chatter("WHY_YOU_HERE",nil, nil, CHATPRIORITIES.HIGH)
        end,
          
        ontimeout=function (inst)
            inst.sg:GoToState("chagefull",inst.sg.statemem.target)
        end          
    },

    State{
        name = "chagefull",
        tags = {"busy","charge"},
        
        onenter = function(inst,target)           
            inst.components.locomotor:Stop()
            
            inst.AnimState:PlayAnimation("charge_super_pre")
            inst.AnimState:PushAnimation("charge_super_loop",true)

            inst.sg.statemem.target = target
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
            inst.components.timer:StartTimer("killer_cd", 20)
            inst.sg:SetTimeout(0.5)
        end,
        timeline=
        {
            TimeEvent(6*FRAMES,function (inst)
                if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then             
                    inst.sg.statemem.targetpos = inst.sg.statemem.target:GetPosition()
                end
            end)
        },
        onupdate = function(inst)
            if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then             
                inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())  
            end          
        end,  

        onexit = function(inst)
            inst.SoundEmitter:KillSound("chargedup")
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("charge_pst",inst.sg.statemem.targetpos)
        end,
    },    
    State{
        name = "charge_pst",
        tags = {"busy","charge"},
        
        onenter = function(inst,pos)

            inst.AnimState:PlayAnimation("charge_pst")
            
            --inst.components.combat:StartAttack()    
            inst.sg.statemem.targetpos = pos
            inst.Physics:Stop()
        end,
        
        timeline=
        {
            TimeEvent(1*FRAMES, function(inst) 

                
                local ix, iy, iz = inst.Transform:GetWorldPosition()
            
                -- This is the "step" of fx spawning that should align with the position the beam is targeting.
                local angle
                if inst.sg.statemem.targetpos~=nil then
                    angle = math.atan2(iz - inst.sg.statemem.targetpos.z, ix - inst.sg.statemem.targetpos.x)
                     inst.sg.statemem.targetpos=nil
                else
                    angle = -inst.Transform:GetRotation()*DEGREES
                end    
               
                
                inst.components.truedamage:SetBaseDamage(1000)
                
                
                -- gx, gy, gz is the point of the actual first beam fx
                local gx, gy, gz = nil, 0, nil
            
                
            
                gx, gy, gz = inst.Transform:GetWorldPosition()
                gx = gx + (3 * math.cos(angle))
                gz = gz + (3 * math.sin(angle))
            
                local targets, skiptoss = {}, {}
                local x, z = nil, nil
                local trigger_time = nil
            
                for i=2,40 do
                    
                    x = gx - i  * math.cos(angle)
                    z = gz - i  * math.sin(angle)
            

                    local prefab = "alterguardian_laser"
                    local x1, z1 = x, z
            
                    trigger_time = (math.max(0, i - 1) * FRAMES)*0.2
                    inst:DoTaskInTime(trigger_time, function(inst,num)
                        local fx = SpawnPrefab(prefab)
                        fx.caster = inst
                        fx.Transform:SetPosition(x1, 0, z1)
                        fx:Trigger(0, targets, skiptoss,false,2,2,2)
                        if num%5==0 and num>0 then
                            local spell = SpawnPrefab("alter_light")
                            spell.Transform:SetPosition(x1, 0, z1)
                            spell.caster=inst
                        end
                    end,i)
                    
                end
            end),   
            
        }, 

        events=
        {
            EventHandler("animover", function(inst) 
                inst.components.truedamage:SetBaseDamage(5)
                inst:EquipWeapon()
                inst.sg:GoToState("idle") 

            end ),
        },             
    },
    State{
        name = "atk_shoot",
        tags = {"busy","canrotate","longattack"},
        
        onenter = function(inst,target)
            
            inst.AnimState:PlayAnimation("charge_pst")
            inst.components.combat:StartAttack()       
            --inst.Physics:Stop()
            inst.components.locomotor:StopMoving()
            inst.sg.statemem.target=target
            
        end,
        
        timeline=
        {
            TimeEvent(1*FRAMES, function(inst) 
                shoot_laser(inst,inst.sg.statemem.target)
            end),   
            TimeEvent(3*FRAMES, function(inst) 
                shoot_laser(inst,inst.sg.statemem.target)
                
            end), 
            TimeEvent(5*FRAMES, function(inst) 
                shoot_laser(inst,inst.sg.statemem.target)
                
            end), 
            
        }, 
        

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },             
    },
    State{
        name = "attack1",
        tags = {"busy","attack"},
        onenter = function(inst, target)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("atk_pre")
            inst.AnimState:PushAnimation("atk", false)
			if target and target:IsValid() then
				inst:ForceFacePoint(target.Transform:GetWorldPosition())
				inst.sg.statemem.target = target
			end
		end,
        timeline=
        {
            TimeEvent(5*FRAMES, function(inst)
                if inst.awake then
                    TryLineAttack(inst,0)
                    TryLineAttack(inst,40)
                    TryLineAttack(inst,-40)
                end
                inst.shootcount = inst.shootcount - 1
                inst.components.combat:DoAttack(inst.sg.statemem.target)
            end)
        },
        events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
					if IsTargetInFront(inst, inst.sg.statemem.target, SWIPE_ARC) then
						inst.sg:GoToState("attack2", inst.sg.statemem.target)
					elseif inst.components.combat.target ~= inst.sg.statemem.target and IsTargetInFront(inst, inst.components.combat.target, SWIPE_ARC) then
						inst.sg:GoToState("attack2", inst.components.combat.target)
					else
						inst.sg:GoToState("idle")
					end
				end
			end),
		},
    },

    State{
		name = "attack2",
		tags = { "attack", "busy" },

		onenter = function(inst, target)
			inst.components.locomotor:Stop()
			inst.AnimState:PlayAnimation("scythe_pre")
			inst.AnimState:PushAnimation("scythe_loop", false)
			if target and target:IsValid() then
				inst.sg.statemem.target = target
			end
			
			
		end,

		timeline =
		{
			FrameEvent(14, function(inst) inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh") end),
			FrameEvent(15, function(inst)
				inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_whoosh")
                if inst.awake then
                    TryLineAttack(inst,40)
                    TryLineAttack(inst,-40)
                    TryLineAttack(inst,0)
                    TryLineAttack(inst,80)
                    TryLineAttack(inst,-80)
                end
                inst.shootcount = inst.shootcount - 1
				DoArcAttack(inst, SWIPE_OFFSET, SWIPE_RADIUS, SWIPE_ARC, nil, 1)
			end),
		},

		events =
		{
			EventHandler("animover", function(inst)
				if inst.AnimState:AnimDone() then
                    if inst.sg.statemem.target and inst.sg.statemem.target:IsValid()
                        and inst:IsNear(inst.sg.statemem.target, 15) then
                        inst.sg:GoToState("attack3_pre", inst.sg.statemem.target)    
					else
						inst.sg:GoToState("idle")
					end
				end
			end),
		},
	},
    State{
        name = "attack3_pre",
        tags = { "thrusting", "doing", "busy", "nointerrupt", "nomorph", "pausepredict" },

        onenter = function(inst,target)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("idle")

            if target and target:IsValid() then
                inst:ForceFacePoint(target.Transform:GetWorldPosition())
            end
            inst.components.combat:StartAttack()
            --inst.sg.statemem.target = target
        end,

        events =
        {
            EventHandler("animover", function(inst)
                if inst.AnimState:AnimDone() then
                    
                    inst.sg:GoToState("attack3", inst.sg.statemem.target)
                end
            end),
        },
        
    },

    State{
        name = "attack3",
        tags = { "attack","busy", "nointerrupt", "nomorph" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("multithrust")
            inst.Transform:SetEightFaced()

            
            inst.Physics:SetMotorVelOverride(inst.awake and 24 or 16, 0, 0)
            inst.sg:SetTimeout(inst.awake and 0.8 or 1)

        end,

        timeline =
        {
            TimeEvent(7 * FRAMES, function(inst)
                inst.components.colouradder:PushColour("charge", 0.3, 0.3, 0, 1)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
            end),
            TimeEvent(9 * FRAMES, function(inst)
                inst.components.colouradder:PushColour("charge", 0.4, 0.4, 0, 1)
                inst.SoundEmitter:PlaySound("dontstarve/wilson/attack_weapon")
            end),
            TimeEvent(11 * FRAMES, function(inst)  
                inst.components.colouradder:PushColour("charge", 0.6, 0.6, 0, 1)         
                DoAOEAttack(inst,4)
            end),
            TimeEvent(17 * FRAMES, function(inst)
                inst.components.colouradder:PushColour("charge", 0.9, 0.9, 0, 1)  
                DoAOEAttack(inst,4)
            end),
            TimeEvent(19 * FRAMES, function(inst)
                
                DoAOEAttack(inst,4)
            end),
        },

        ontimeout = function(inst)
            inst.sg:GoToState("idle", true)
            
        end,
        onexit = function(inst)
            inst.components.colouradder:PopColour("charge")
            --inst.components.combat:SetTarget(nil)
            inst.Transform:SetFourFaced()
            inst.Physics:ClearMotorVelOverride()
			inst.Physics:Stop()
        end,
    },


    State{
        name = "item_out",
		tags = { "idle","busy","leap" },

        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst:EquipWeapon()
            inst.AnimState:PlayAnimation("item_out")
        end,

        events =
        {
            EventHandler("animover", function(inst)
                
                inst.sg:GoToState("combat_leap_start",inst.components.combat.target)
            end),
        },
    },
    State{
        name = "combat_leap_start",
        tags = { "leap",  "busy", "nointerrupt", "nomorph" },

        onenter = function(inst,target)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("atk_leap_pre")
            inst.components.timer:StartTimer("leapattack_cd", 20)
            inst.sg.mem.leapcount = math.random(4,5)
            
            inst.sg.statemem.target = target
               
        end,
        onupdate = function(inst)
            if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then             
                inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())  
            end          
        end, 
        events =
        {
            EventHandler("animover", function(inst)
                inst.AnimState:PlayAnimation("atk_leap_lag")
                inst.sg:GoToState("combat_leap", inst.sg.statemem.target )
            end),
        },
    },

    State {
        name = "combat_leap",
        tags = {"attack", "backstab", "busy", "leap", "nointerrupt"},
        onenter = function(inst, target)
            
            inst.AnimState:PlayAnimation("atk_leap", false)
            inst.Transform:SetEightFaced()
            ToggleOffPhysics(inst)

            inst.sg.statemem.target = target
            inst.sg.statemem.startingpos = inst:GetPosition()

            if inst.sg.statemem.target ~= nil then
                inst.sg.statemem.targetpos = inst.sg.statemem.target:GetPosition()
            else
                inst.sg.statemem.targetpos = inst:GetPosition()
            end
            if inst.sg.statemem.startingpos.x ~= inst.sg.statemem.targetpos.x or inst.sg.statemem.startingpos.z ~= inst.sg.statemem.targetpos.z then
                inst.leap_velocity = math.sqrt(distsq(inst.sg.statemem.startingpos.x, inst.sg.statemem.startingpos.z,
                                                        inst.sg.statemem.targetpos.x, inst.sg.statemem.targetpos.z)) / (12 * FRAMES)
                inst:ForceFacePoint(inst.sg.statemem.targetpos:Get())
                inst.Physics:SetMotorVel(math.min(inst.leap_velocity,36),0,0)
            end
            inst.sg.statemem.flash = 0
        end,
        onupdate = function(inst)
            if inst.sg.statemem.flash and inst.sg.statemem.flash > 0 then
                inst.sg.statemem.flash = math.max(0, inst.sg.statemem.flash - .1)
                local c = math.min(1, inst.sg.statemem.flash)
                inst.components.colouradder:PushColour("leap", c, c, 0, 0)
            end
        end,
        timeline = {
            TimeEvent( FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/common/deathpoof")
                
                inst.SoundEmitter:PlaySound("turnoftides/common/together/boat/jump")
            end),
            TimeEvent(10 * FRAMES, function(inst) 
                if inst.sg.statemem.flash then 
                    inst.components.colouradder:PushColour("leap", .1, .1, 0, 0) 
                end 
            end),
            TimeEvent(11 * FRAMES, function(inst) 
                if inst.sg.statemem.flash then 
                    inst.components.colouradder:PushColour("leap", .2, .2, 0, 0) 
                end
             end),
            TimeEvent(12 * FRAMES, function(inst)
                if inst.sg.statemem.flash then
                     inst.components.colouradder:PushColour("leap", .4, .4, 0, 0) 
                end
                
                inst.Physics:Stop()
                inst.Physics:SetMotorVel(0, 0, 0)
                --inst.Physics:Teleport(inst.sg.statemem.targetpos.x, 0, inst.sg.statemem.targetpos.z)
                ToggleOnPhysics(inst)
            end),
            TimeEvent(13 * FRAMES, function(inst)
                if inst.sg.statemem.flash then
                    inst.components.bloomer:PushBloom("leap", "shaders/anim.ksh", -2)
                    inst.components.colouradder:PushColour("leap", 1, 1, 0, 0)
                    inst.sg.statemem.flash = 1.3
                end
                
                DoAOEAttack(inst,7)
                
            end),
            TimeEvent(17 * FRAMES, function(inst)
                local pos = inst:GetPosition()
                if inst:IsOnValidGround() then
                    SpawnPrefab("firering_fx").Transform:SetPosition(pos.x,0,pos.z)
                elseif not TheWorld.Map:IsPassableAtPoint(pos.x,0,pos.z) then
                    SpawnAttackWaves(pos, 0, 2, 12,360,18)
                else
                    local platform = inst:GetCurrentPlatform()
                    if platform~=nil and platform:IsValid() then
                        platform.components.health:Kill()
                    end
                end
                DoAOEWork(inst,5)
            end),
            TimeEvent(25 * FRAMES, function(inst)
                if inst.awake then
                    TryLineAttack(inst,0)
                    TryLineAttack(inst,120)
                    TryLineAttack(inst,-120)
                end
                if inst.sg.statemem.flash then
                    inst.components.bloomer:PopBloom("leap")
                end
            end),
        },
        
        onexit = function(inst)
            if inst.sg.statemem.isphysicstoggle then
                ToggleOnPhysics(inst)
                inst.Physics:Stop()
                inst.Physics:SetMotorVel(0, 0, 0)
                local x, y, z = inst.Transform:GetWorldPosition()
                if TheWorld.Map:IsPassableAtPoint(x, 0, z) and not TheWorld.Map:IsGroundTargetBlocked(Vector3(x, 0, z)) then
                    inst.Physics:Teleport(x, 0, z)
                else
                    inst.Physics:Teleport(inst.sg.statemem.targetpos.x, 0, inst.sg.statemem.targetpos.z)
                end
            end
            inst.Transform:SetFourFaced()
            if inst.sg.statemem.flash then
                inst.components.bloomer:PopBloom("leap")
                inst.components.colouradder:PopColour("leap")
            end
        end,
        events = {
            EventHandler("animover", function(inst) 
                if inst.sg.mem.leapcount and inst.sg.mem.leapcount>0 
                    and inst.sg.statemem.target then
                    inst.sg.mem.leapcount=inst.sg.mem.leapcount-1
                    inst.sg:GoToState("combat_leap",inst.sg.statemem.target)
                else
                    inst.sg.mem.leapcount = nil
                    --inst:UnEquipWeapon()
                    inst.sg:GoToState("idle") 
                end           
            end)
        }
    },
    State {
        name = "combat_leap_atk",
        tags = {"attack", "busy", "leap", "nointerrupt"},
        onenter = function(inst, data)
            
            inst.AnimState:PlayAnimation("atk_leap", false)
            inst.Transform:SetEightFaced()
            ToggleOffPhysics(inst)

            inst.sg.statemem.target = data.target
            inst.sg.statemem.nextstate = data.nextstate
            inst.sg.statemem.startingpos = inst:GetPosition()

            if inst.sg.statemem.target ~= nil then
                inst:ForceFacePoint(inst.sg.statemem.target:GetPosition()) 
                inst.sg.statemem.targetpos = inst.sg.statemem.target:GetPosition()
            else
                inst.sg.statemem.targetpos = inst:GetPosition()
            end
            if inst.sg.statemem.startingpos.x ~= inst.sg.statemem.targetpos.x or inst.sg.statemem.startingpos.z ~= inst.sg.statemem.targetpos.z then
                inst.leap_velocity = math.sqrt(distsq(inst.sg.statemem.startingpos.x, inst.sg.statemem.startingpos.z,
                                                        inst.sg.statemem.targetpos.x, inst.sg.statemem.targetpos.z)) / (12 * FRAMES)
                inst:ForceFacePoint(inst.sg.statemem.targetpos:Get())
                inst.Physics:SetMotorVel(math.min(inst.leap_velocity,36),0,0)
            end
            inst.sg.statemem.flash = 0
        end,
        onupdate = function(inst)
            if inst.sg.statemem.flash and inst.sg.statemem.flash > 0 then
                inst.sg.statemem.flash = math.max(0, inst.sg.statemem.flash - .1)
                local c = math.min(1, inst.sg.statemem.flash)
                inst.components.colouradder:PushColour("leap", c, c, 0, 0)
            end
        end,
        timeline = {
            TimeEvent( FRAMES, function(inst)
                inst.SoundEmitter:PlaySound("dontstarve/common/deathpoof")
                
                inst.SoundEmitter:PlaySound("turnoftides/common/together/boat/jump")
            end),
            TimeEvent(10 * FRAMES, function(inst) 
                if inst.sg.statemem.flash then 
                    inst.components.colouradder:PushColour("leap", .1, .1, 0, 0) 
                end 
            end),
            TimeEvent(11 * FRAMES, function(inst) 
                if inst.sg.statemem.flash then 
                    inst.components.colouradder:PushColour("leap", .2, .2, 0, 0) 
                end
             end),
            TimeEvent(12 * FRAMES, function(inst)
                if inst.sg.statemem.flash then
                     inst.components.colouradder:PushColour("leap", .4, .4, 0, 0) 
                end
                
                inst.Physics:Stop()
                inst.Physics:SetMotorVel(0, 0, 0)
                --inst.Physics:Teleport(inst.sg.statemem.targetpos.x, 0, inst.sg.statemem.targetpos.z)
                ToggleOnPhysics(inst)
            end),
            TimeEvent(13 * FRAMES, function(inst)
                if inst.sg.statemem.flash then
                    inst.components.bloomer:PushBloom("leap", "shaders/anim.ksh", -2)
                    inst.components.colouradder:PushColour("leap", 1, 1, 0, 0)
                    inst.sg.statemem.flash = 1.3
                end
                
                DoAOEAttack(inst,7)
                
            end),
            TimeEvent(17 * FRAMES, function(inst)
                local pos = inst:GetPosition()
                
                SpawnPrefab("firering_fx").Transform:SetPosition(pos.x,0,pos.z)
               
            end),
            TimeEvent(25 * FRAMES, function(inst)
                if inst.sg.statemem.flash then
                    inst.components.bloomer:PopBloom("leap")
                end
            end),
        },
        
        onexit = function(inst)
            if inst.sg.statemem.isphysicstoggle then
                ToggleOnPhysics(inst)
                inst.Physics:Stop()
                inst.Physics:SetMotorVel(0, 0, 0)
                local x, y, z = inst.Transform:GetWorldPosition()
                if TheWorld.Map:IsPassableAtPoint(x, 0, z) and not TheWorld.Map:IsGroundTargetBlocked(Vector3(x, 0, z)) then
                    inst.Physics:Teleport(x, 0, z)
                else
                    inst.Physics:Teleport(inst.sg.statemem.targetpos.x, 0, inst.sg.statemem.targetpos.z)
                end
            end
            inst.Transform:SetFourFaced()
            if inst.sg.statemem.flash then
                inst.components.bloomer:PopBloom("leap")
                inst.components.colouradder:PopColour("leap")
            end
        end,
        events = {
            EventHandler("animover", function(inst) 
                
               
                --inst:UnEquipWeapon()
                inst.sg:GoToState(inst.sg.statemem.nextstate or "idle",inst.sg.statemem.target) 
                       
            end)
        }
    },
    State {
        name = "morph",
        tags = {"busy","morph"},
        onenter = function(inst)

            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("morph_idle")
            inst.AnimState:PushAnimation("morph_complete",false)

			inst.components.health:SetInvincible(true)
            inst.components.colouradder:PushColour("morph", 1, 1, 0, 1)
            inst:UnEquipWeapon()
        end,
        
        timeline=
        {
            TimeEvent(0*FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/music/iron_lord")
            end),
            TimeEvent(15*FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/iron_lord/morph")
            end),
            TimeEvent(105*FRAMES, function(inst) 

				ShakeAllCameras(CAMERASHAKE.FULL, .7, .02, 1, inst, 40)
            end),

            TimeEvent(152*FRAMES, function(inst) 
                inst:LevelUp()
                inst.components.colouradder:PopColour("morph")
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/music/iron_lord_suit", "ironlord_music")
            end),
        },

        events=
        {
            EventHandler("animqueueover", function(inst) 
                inst.components.health:SetInvincible(false)   
                inst:EquipWeapon()
                inst.sg:GoToState("idle")                                    
            end),
        },         
    },
    	
	
    State{
        name = "death",
        tags = {"busy"},
        
        onenter = function(inst)     
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("suit_destruct")
            inst.AnimState:ClearSymbolBloom("swap_object")
            inst:UnEquipWeapon()
            TheWorld:PushEvent("ms_setmoonphasestyle", {style = "glassed_default"})
        end,
        
        timeline=
        {   ---- death explosion
            TimeEvent(4*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/enemy/metal_robot/electro", {intensity= .2}) end),
            TimeEvent(8*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/enemy/metal_robot/electro", {intensity= .4}) end),
            TimeEvent(12*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/enemy/metal_robot/electro", {intensity= .6}) end),
            TimeEvent(19*FRAMES, function(inst) inst.SoundEmitter:PlaySoundWithParams("dontstarve_DLC003/creatures/enemy/metal_robot/electro", {intensity= 1}) end),
            TimeEvent(26*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro",nil,.5) end),
            TimeEvent(35*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro",nil,.5) end),
            TimeEvent(54*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro") end),
            TimeEvent(55*FRAMES, function(inst) 
                local x,y,z=inst.Transform:GetWorldPosition()
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/boss/hulk_metal_robot/explode_small",nil,.7)
                inst.components.lootdropper:DropLoot(inst:GetPosition())
                local explosive = SpawnPrefab("newcs_laser_explosion")
                explosive.Transform:SetScale(1.5,1.5,1.5)
                explosive.Transform:SetPosition(x,2,z) 
            end),
        }            
    },    
    State{
        name = "transform_pst",
        tags = {"busy"},
        onenter = function(inst)
			inst.components.health:SetInvincible(false)
            inst.Physics:Stop()            
            inst.AnimState:PlayAnimation("transform_pst")
			inst.sg:SetTimeout(4)
        end,
           
        ontimeout = function(inst) 
            inst:DoTaskInTime(2, function()
                inst.sg:GoToState("idle")
            end)
        end        
    },
	
}

CommonStates.AddWalkStates(states,
{
    walktimeline =
    {
        TimeEvent(0, PlayFootstep),
        TimeEvent(12 * FRAMES, PlayFootstep),
    },
},{
    startwalk = "idle_walk",
    walk = "idle_walk",
    stopwalk = "idle_walk_pst"
})





return StateGraph("SGironlord", states, events, "idle",actionhandlers)