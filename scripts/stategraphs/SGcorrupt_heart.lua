require("stategraphs/commonstates")

local events=
{
    EventHandler("death", function(inst) inst.sg:GoToState("death") end),
    EventHandler("doattack", function(inst,data)
        if not inst.components.health:IsDead() then
            if data.target~=nil and data.target:IsValid() then
                if not inst.components.timer:TimerExists("echo_cd") then
                    inst.sg:GoToState("echo")
                else
                    inst.sg:GoToState("attack",data.target)
                end		
            end
        end
    end),
    CommonHandlers.OnDeath(),
}

local function DoEcho(inst)
    local x,y,z=inst.Transform:GetWorldPosition()
    inst:DoEcho()
    local players = FindPlayersInRange(x, y, z, 16, true)
	for i, v in ipairs(players) do
		inst.components.combat:DoAttack(v,nil,nil,"shadow")
	end
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
        tags = {"busy"},

        onenter = function(inst)
            local pos=inst:GetPosition()
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
            local x,y,z=inst.Transform:GetWorldPosition()
            local ents = TheSim:FindEntities(x, y, z, 40, {"shadowchesspiece"}) -- or we could include a flag to the search?
            for i, v in ipairs(ents) do
                v.components.lootdropper:DropLoot(v:GetPosition())
                v:Remove()
            end
            inst.components.lootdropper:DropLoot(pos)
            
        end,

        timeline =
        {   
            TimeEvent(17*FRAMES, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/eyeballturret/pop") end)
        },
        
    },
    State{
        name="echo",
        tags={"attack","busy"},
        onenter = function(inst,target)
            inst.AnimState:PlayAnimation("idle")
            inst.components.combat:StartAttack()
            inst.components.timer:StartTimer("echo_cd",30)
            inst.sg:SetTimeout(3.2)
        end,
        timeline=
        {   
            FrameEvent(1,function (inst)
                inst:DoEcho()
            end),
            FrameEvent(40,DoEcho),
            FrameEvent(60,DoEcho),
            FrameEvent(90,DoEcho),
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
                local x, y, z = inst.Transform:GetWorldPosition()
                local proj=SpawnPrefab("eye_charge")
                proj.Transform:SetPosition(x-4,2.2,z)
                inst.sg.statemem.projs[1]=proj
            end),
            FrameEvent(5,function (inst)
                local x, y, z = inst.Transform:GetWorldPosition()
                local proj=SpawnPrefab("eye_charge")
                proj.Transform:SetPosition(x-2,2.2,y-3.464)
                inst.sg.statemem.projs[2]=proj
            end),
            FrameEvent(10,function (inst)
                local x, y, z = inst.Transform:GetWorldPosition()
                local proj=SpawnPrefab("eye_charge")
                proj.Transform:SetPosition(x+2,2.2,y-3.464)
                inst.sg.statemem.projs[3]=proj
            end),
            FrameEvent(15,function (inst)
                local x, y, z = inst.Transform:GetWorldPosition()
                local proj=SpawnPrefab("eye_charge")
                proj.Transform:SetPosition(x+4,2.2,z)
                inst.sg.statemem.projs[4]=proj
            end),
            FrameEvent(20,function (inst)
                local x, y, z = inst.Transform:GetWorldPosition()
                local proj=SpawnPrefab("eye_charge")
                proj.Transform:SetPosition(x+2,2.2,z+3.464)
                inst.sg.statemem.projs[5]=proj
            end),
            FrameEvent(25,function (inst)
                local x, y, z = inst.Transform:GetWorldPosition()
                local proj=SpawnPrefab("eye_charge")
                proj.Transform:SetPosition(x-2,2.2,z+3.464)
                inst.sg.statemem.projs[6]=proj
            end),
            FrameEvent(60, function(inst)

                
                if inst.sg.statemem.target ~= nil and inst.sg.statemem.target:IsValid() then
					for k,v in ipairs(inst.sg.statemem.projs) do
                        v.components.projectile:Throw(inst, inst.sg.statemem.target, inst)
                    end
				else
                    for k,v in ipairs(inst.sg.statemem.projs) do
                        v:Remove()
                    end
                end    
                
            end),
        },
        ontimeout= function(inst) inst.sg:GoToState("idle") end
    },
}


return StateGraph("SGcorrupt_heart", states, events, "idle")
