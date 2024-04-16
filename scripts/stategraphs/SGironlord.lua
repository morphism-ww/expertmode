require("stategraphs/commonstates")

local actionhandlers =
{
    ActionHandler(ACTIONS.HAMMER, "combat_leap_start"),
}

--[[local function shoot_orb(inst,target)
    if target~=nil and target:IsValid() then
         
        local x,y,z = inst.Transform:GetWorldPosition()

        local projectile = SpawnPrefab("ancient_hulk_orb")
        projectile.Transform:SetPosition(x,1,z)
        projectile.AnimState:SetMultColour(0,0,0,0.5)
        projectile.primed = false
        projectile.AnimState:PlayAnimation("spin_loop",true)
        projectile.components.linearprojectile:SetLaunchOffset(Vector3(0.4,1.2,0))
        projectile.components.linearprojectile:SetHorizontalSpeed(40)
        projectile.components.linearprojectile:Launch(target:GetPosition(), inst)
        projectile.owner = inst
    end
    if target~=nil and target:IsValid() then
        local rotation = inst:GetAngleToPoint(target:GetPosition())
        local beam = SpawnPrefab("ancient_hulk_orb_small")
        local pt = inst:GetPosition()
        local angle = rotation * DEGREES
        local radius = 2.5
        local offset = Vector3(radius * math.cos( angle ), 0, -radius * math.sin( angle ))
        local newpt = pt+offset
        
        beam.Transform:SetPosition(newpt.x,1,newpt.z)
        beam.Transform:SetRotation(rotation)
        beam.AnimState:PlayAnimation("spin_loop",true) 
    end
end]]
    

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

local function shoot_laser(inst,target)
    if target~=nil and target:IsValid() then 
        local laser=SpawnPrefab("ancient_hulk_orb_small")
        --laser.components.projectile.owner=inst

        local x, y, z = inst.Transform:GetWorldPosition()
        laser.Transform:SetPosition(x,y,z)
        laser.components.projectile:Throw(inst, target, inst)
    end
end

local events=
{
    CommonHandlers.OnLocomote(true,true),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
    EventHandler("doattack", function(inst,data)
        if not ( inst.components.health:IsDead() or inst.sg:HasStateTag("busy"))
            and (data.target ~= nil and data.target:IsValid())  then
            local target=data.target
            inst.sg:GoToState("atk_shoot",target)
        end
    end), 
    EventHandler("leap_pre", function(inst, data)
        if not inst.sg:HasStateTag("killer") then
            inst.components.timer:StartTimer("leapattack_cd", 20)
            inst:EquipLeap()
            inst.sg.mem.leapcount=math.random(4,5)
            inst.sg:GoToState("item_out")
        end
    end),
    EventHandler("killer_laser", function(inst, data)
        inst.components.timer:StartTimer("killer_cd", 40)
        inst.sg:GoToState("charge")
    end),
    EventHandler("stunned", function(inst)
        if inst.components.health ~= nil and not inst.components.health:IsDead() then
            inst:EnterShield()
        end
    end),
    EventHandler("stun_finished", function(inst)
        if inst.components.health ~= nil and not inst.components.health:IsDead() then
            inst:ExitShield()
        end
    end),
}

local states=
{
    State {
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
               
            inst.AnimState:PlayAnimation("idle_loop")

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
        tags = {"busy","killer"},
        
        onenter = function(inst)		
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("charge_pre")
            inst.AnimState:PushAnimation("charge_grow")
            inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/iron_lord/charge_up_LP", "chargedup")
            inst.sg.statemem.target=inst.components.combat.target  
            inst.sg:SetTimeout(0.5)  
            inst.components.talker:Chatter("WHY_YOU_HERE",nil, nil, CHATPRIORITIES.HIGH)
        end,
        onupdate = function(inst)
            if inst.sg.statemem.target and inst.sg.statemem.target:IsValid() then             
                inst:ForceFacePoint(inst.sg.statemem.target:GetPosition())  
            end          
        end,    
        ontimeout=function (inst)
            inst.sg:GoToState("chagefull",inst.sg.statemem.target)
        end          
    },

    State{
        name = "chagefull",
        tags = {"busy","killer"},
        
        onenter = function(inst,target)           
            inst.components.locomotor:Stop()
            
            inst.AnimState:PlayAnimation("charge_super_pre")
            inst.AnimState:PushAnimation("charge_super_loop",true)

            inst.SoundEmitter:PlaySound("dontstarve_DLC003/creatures/enemy/metal_robot/electro")
            
            if target and target:IsValid() and target.components.grogginess~=nil then
                target.components.grogginess:AddGrogginess(1,20)
                inst.sg.mem.targetpos=target:GetPosition()
            end
            
            inst.sg:SetTimeout(0.5)

        end,        

        onexit = function(inst)
            inst.SoundEmitter:KillSound("chargedup")
        end,

        ontimeout = function(inst)
            inst.sg:GoToState("charge_pst")
        end,
    },    
    State{
        name = "charge_pst",
        tags = {"busy","killer"},
        
        onenter = function(inst)

            inst.AnimState:PlayAnimation("charge_pst")
            --inst.components.combat:StartAttack()       
            inst.Physics:Stop()
        end,
        
        timeline=
        {
            TimeEvent(1*FRAMES, function(inst) 

                
                local ix, iy, iz = inst.Transform:GetWorldPosition()
            
                -- This is the "step" of fx spawning that should align with the position the beam is targeting.
                local angle
                if inst.sg.mem.targetpos~=nil then
                    angle = math.atan2(iz - inst.sg.mem.targetpos.z, ix - inst.sg.mem.targetpos.x)
                     inst.sg.mem.targetpos=nil
                else
                    angle = inst.Transform:GetRotation()*DEGREES
                end    
               
                
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
                        fx:Trigger(0, targets, skiptoss)
                        if num%5==0 and num>0 then
                            local spell = SpawnPrefab("alter_light")
                            spell.killer=true
                            spell.Transform:SetPosition(x1, 0, z1)
                            spell.caster=inst
                        end
                    end,i)
                    
                end
            end),   
            
        }, 
        

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
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
            
        }, 
        

        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end ),
        },             
    },
    State{
        name = "item_out",
		tags = { "idle", "nodangle", "busy" },

        onenter = function(inst)
            inst.components.locomotor:Stop()
            inst.AnimState:PlayAnimation("item_out")
            --TheNet:Announce("会赢的")
            inst.components.talker:Chatter("I_WILL_WIN",math.random(2),nil, nil, CHATPRIORITIES.HIGH)
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
            if target and target:IsValid() then
                inst.sg.statemem.target=target
            end   
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
                inst.sg:GoToState("combat_leap",inst.sg.statemem.target )
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
            inst.sg.statemem.target=target
            
            inst.sg.statemem.startingpos = inst:GetPosition()
            if inst.sg.statemem.target ~= nil then
                inst.sg.statemem.targetpos = inst.sg.statemem.target:GetPosition()
            else
                inst.sg.statemem.targetpos=inst:GetPosition()
            end
            if inst.sg.statemem.startingpos.x ~= inst.sg.statemem.targetpos.x or inst.sg.statemem.startingpos.z ~= inst.sg.statemem.targetpos.z then
                inst.leap_velocity = math.sqrt(distsq(inst.sg.statemem.startingpos.x, inst.sg.statemem.startingpos.z,
                                                        inst.sg.statemem.targetpos.x, inst.sg.statemem.targetpos.z)) / (12 * FRAMES)
                inst:ForceFacePoint(inst.sg.statemem.targetpos:Get())
                inst.Physics:SetMotorVel(inst.leap_velocity,0,0)
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
                inst.components.locomotor:Stop()
                inst.Physics:Stop()
                inst.Physics:SetMotorVel(0, 0, 0)
                inst.Physics:Teleport(inst.sg.statemem.targetpos.x, 0, inst.sg.statemem.targetpos.z)
                ToggleOnPhysics(inst)
            end),
            TimeEvent(13 * FRAMES, function(inst)
                if inst.sg.statemem.flash then
                    inst.components.bloomer:PushBloom("leap", "shaders/anim.ksh", -2)
                    inst.components.colouradder:PushColour("leap", 1, 1, 0, 0)
                    inst.sg.statemem.flash = 1.3
                    
                end
                local weapon = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                weapon.components.aoeweapon_leap:DoLeap(inst, inst.sg.statemem.startingpos, inst.sg.statemem.targetpos)
                inst.components.locomotor:EnableGroundSpeedMultiplier(true)
            end),
            TimeEvent(19 * FRAMES, function(inst)
                local pos=inst:GetPosition()
                if inst:IsOnValidGround() then
                    inst.components.groundpounder:GroundPound()
                elseif not TheWorld.Map:IsPassableAtPoint(pos:Get()) then
                    SpawnAttackWaves(pos, 0, 2, 12,360,18)
                else
                    local platform = inst:GetCurrentPlatform()
                    if platform~=nil and platform:IsValid() then
                        platform.components.health:Kill()
                    end
                end
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
                if inst.sg.mem.leapcount and inst.sg.mem.leapcount>0 
                    and inst.sg.statemem.target then
                    inst.sg.mem.leapcount=inst.sg.mem.leapcount-1
                    inst.sg:GoToState("combat_leap",inst.sg.statemem.target)
                else
                    inst.components.inventory:DropEquipped(true)
                    inst.sg:GoToState("idle") 
                end           
            end)
        }
    },
    State {
        name = "morph",
        tags = {"busy"},
        onenter = function(inst)
            inst.components.locomotor:StopMoving()
            inst.AnimState:PlayAnimation("morph_idle")
            inst.AnimState:PushAnimation("morph_complete",false)
			
        end,
        
        timeline=
        {
--            TimeEvent(0*FRAMES, function(inst) 
--                inst.SoundEmitter:PlaySound("dontstarve_DLC003/music/iron_lord")
--            end),
            TimeEvent(15*FRAMES, function(inst) 
                inst.SoundEmitter:PlaySound("dontstarve_DLC003/common/crafted/iron_lord/morph")
            end),
            TimeEvent(105*FRAMES, function(inst) 
				ShakeAllCameras(CAMERASHAKE.FULL, .7, .02, 1, inst, 40)
            end),


--            TimeEvent(152*FRAMES, function(inst) 
--                inst.SoundEmitter:PlaySound("dontstarve_DLC003/music/iron_lord_suit", "ironlord_music")
--            end),
        },

        
        onexit = function(inst)
            inst.components.health:SetInvincible(false)
            inst.is_boss=true
            inst:LevelUp()
        end,

        events=
        {
            EventHandler("animqueueover", function(inst) 
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
            inst.components.talker:Chatter("MFZ_KNOW_YOU",1,nil, nil, CHATPRIORITIES.HIGH)		
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
                local explosive = SpawnPrefab("laser_explosion")
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
})


CommonStates.AddRunStates(states,
{
	runtimeline = {
		TimeEvent(0*FRAMES, PlayFootstep ),
		TimeEvent(10*FRAMES, PlayFootstep ),
	},
})


return StateGraph("SGironlord", states, events, "idle",actionhandlers)