require("stategraphs/commonstates")

local events=
{
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    EventHandler("doattack", function(inst,data)
        if not inst.components.health:IsDead() then
            if data.target~=nil and data.target:IsValid() then
                local dsq_to_target = inst:GetDistanceSqToInst(data.target)
                if not inst.components.timer:TimerExists("echo_cd") and dsq_to_target < TUNING.CORRUPT_HEART_RANGESQ then
                    inst.sg:GoToState("echo")
                else
                    inst.sg:GoToState("attack",data.target)
                end		
            end
        end
    end),
}



local function SpawnShadowBall(inst,index)
    local x, y, z = inst.Transform:GetWorldPosition()
    local proj = SpawnPrefab("darkball_projectile")
    proj.AnimState:PlayAnimation("portal_pre")
    proj.AnimState:PushAnimation("portal_loop")
    proj.Transform:SetPosition(x+4*math.cos(PI/3*index),0,z-4*math.sin(PI/3*index))
    --proj.Physics:Teleport(x+4*math.cos(PI/3*index),3,z-4*math.sin(PI/3*index))
    
    inst.sg.statemem.projs[index]=proj
end

local states=
{
    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        onenter = function(inst)
            inst.AnimState:PlayAnimation("idle", true)
        end,
        events=
        {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },

	State{
        name = "death",
        tags = {"busy","dead"},

        onenter = function(inst)
            inst.components.lootdropper:DropLoot(inst:GetPosition())
            RemovePhysicsColliders(inst)
        end,

        timeline =
        {   
            TimeEvent(17*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/eyeballturret/pop") end)
        },
        
    },
    State{
        name = "echo",
        tags={"attack","busy"},
        onenter = function(inst,target)
            inst.AnimState:PlayAnimation("idle")
            inst.components.combat:StartAttack()
            inst.components.timer:StartTimer("echo_cd",30)
            inst.sg:SetTimeout(4)
           
        end,
        timeline=
        {   
            FrameEvent(0,function (inst)
                local x,y,z = inst.Transform:GetWorldPosition()
                local fx = SpawnPrefab("sanity_lower")
                fx.Transform:SetPosition(x+4,0,z+4)  
                local trap = SpawnPrefab("shadow_trap")
                trap.Transform:SetPosition(x,y,z)
                trap.sg:GoToState("trigger")  
            end),
            FrameEvent(10,function (inst)
                local x,y,z = inst.Transform:GetWorldPosition()
                local fx = SpawnPrefab("sanity_lower")
                fx.Transform:SetPosition(x+4,0,z-4)    
            end),
            FrameEvent(20,function (inst)
                local x,y,z = inst.Transform:GetWorldPosition()
                local fx = SpawnPrefab("sanity_lower")
                fx.Transform:SetPosition(x-4,0,z-4)    
            end),
            FrameEvent(30,function (inst)
                local x,y,z = inst.Transform:GetWorldPosition()
                local fx = SpawnPrefab("sanity_lower")
                fx.Transform:SetPosition(x-4,0,z+4)    
            end),
            FrameEvent(30,function (inst)
                SpawnPrefab("shadowecho_fx").Transform:SetPosition(inst.Transform:GetWorldPosition())
            end),
            FrameEvent(40,function (inst)
                inst:DoEcho()
            end),
            FrameEvent(50,function (inst)
                inst:DoEcho()
            end),
            FrameEvent(60,function (inst)
                inst:DoEcho()
            end),
            FrameEvent(70,function (inst)
                inst:DoEcho()
            end),
            FrameEvent(80,function (inst)
                inst:DoEcho()
            end),
            FrameEvent(90,function (inst)
                inst:DoEcho()
            end),
            FrameEvent(100,function (inst)
                inst:DoEcho()
            end),
            FrameEvent(110,function (inst)
                inst:DoEcho()
            end),
        },
        ontimeout= function(inst) inst.sg:GoToState("idle") end
    },
    State{
        name = "attack",
        tags = {"attack", "canrotate"},
        onenter = function(inst,target)
            inst.AnimState:PlayAnimation("idle")
            inst.components.combat:StartAttack()
            inst.sg.statemem.target=target
            inst.sg.statemem.projs={}
            inst.sg:SetTimeout(2)
        end,
        timeline=
        {   
            FrameEvent(1,function (inst)
                SpawnShadowBall(inst,1)
            end),
            FrameEvent(5,function (inst)
                SpawnShadowBall(inst,2)
            end),
            FrameEvent(10,function (inst)
                SpawnShadowBall(inst,3)
            end),
            FrameEvent(15,function (inst)
                SpawnShadowBall(inst,4)
            end),
            FrameEvent(20,function (inst)
                SpawnShadowBall(inst,5)
            end),
            FrameEvent(25,function (inst)
                SpawnShadowBall(inst,6)
            end),
            FrameEvent(50, function(inst)

                
                if inst.sg.statemem.target ~= nil and inst.sg.statemem.target:IsValid() then
					for k,v in ipairs(inst.sg.statemem.projs) do
                        --v.owner = inst
                        --v.components.linearprojectile:Launch(targetpos, inst, inst)
                        v.components.projectile:Throw(inst, inst.sg.statemem.target, inst)
                    end
				else
                    for k,v in ipairs(inst.sg.statemem.projs) do
                        v:Remove()
                    end
                end    
                
            end),
        },
        ontimeout= function(inst) 
            inst.sg:GoToState("idle")     
        end
    },
}


return StateGraph("SGcorrupt_heart", states, events, "idle")
