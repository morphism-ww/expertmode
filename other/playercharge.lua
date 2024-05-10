AddStategraphState("wilson",State{
    name = "playercharge_start",
    tags = { "charge", "doing", "busy", "nointerrupt", "nomorph" },

    onenter = function(inst,data)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("atk_pre")
        inst:ForceFacePoint(data.x,0,data.z)
    end,

    events =
    {

        EventHandler("animover", function(inst)
            if inst.AnimState:AnimDone() then
                if inst.AnimState:IsCurrentAnimation("atk_pre") then
                    inst.AnimState:PlayAnimation("lunge_lag")
                    inst.sg:GoToState("playercharge")
                else
                    
                    inst.sg:GoToState("idle")
                end
            end
        end),
    },
})
local chargestate=State{
        name = "playercharge",
        tags = { "charge", "doing", "busy", "nointerrupt" ,"nopredict"},

        onenter = function(inst)
            inst.components.health:SetInvincible(true)
            local helmet = inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
            if inst.AnimState:IsCurrentAnimation("lunge_lag") 
                and helmet and (helmet:HasTag("shadow_item") or helmet:HasTag("ancient")) then
                inst.AnimState:PlayAnimation("lunge_pst")
                
                
                
                inst.SoundEmitter:PlaySound("dontstarve/common/lava_arena/fireball")
                local pos = inst:GetPosition()
                local theta = inst.Transform:GetRotation() * DEGREES
                local cos_theta = math.cos(theta)
                local sin_theta = math.sin(theta)
                local x= pos.x + 12 *cos_theta
                local z= pos.z - 12 *sin_theta
                
                if helmet:HasTag("ancient") then
                    helmet.components.aoeweapon_lunge:DoLunge(inst, pos, Vector3(x,0,z))
                end
                local fx = SpawnPrefab("spear_wathgrithr_lightning_lunge_fx")
                fx.Transform:SetPosition(x, 0, z)
                fx.Transform:SetRotation(inst:GetRotation())

                local x1, z1
                local map = TheWorld.Map
                if not map:IsPassableAtPoint(x, 0, z) then
                    inst.sg:GoToState("idle")
                end


                local mass = inst.Physics:GetMass()
                if mass > 0 then
                    inst.sg.statemem.restoremass = mass
                    inst.Physics:SetMass(mass + 1)
                end
                inst.Physics:Teleport(x, 0, z)
            else
                inst.sg:GoToState("idle")
            end        
        end,

        onupdate = function(inst)
            if inst.sg.statemem.flash and inst.sg.statemem.flash > 0 then
                inst.sg.statemem.flash = math.max(0, inst.sg.statemem.flash - .1)
                inst.components.colouradder:PushColour("lunge", inst.sg.statemem.flash, inst.sg.statemem.flash, 0, 0)
            end
        end,


        timeline =
        {
			FrameEvent(8, function(inst)
				if inst.sg.statemem.restoremass ~= nil then
					inst.Physics:SetMass(inst.sg.statemem.restoremass)
					inst.sg.statemem.restoremass = nil
				end
			end),
            TimeEvent(12 * FRAMES, function(inst)
                inst.components.bloomer:PopBloom("lunge")
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
			if inst.sg.statemem.restoremass ~= nil then
				inst.Physics:SetMass(inst.sg.statemem.restoremass)
			end
            inst.components.health:SetInvincible(false)
            inst.components.bloomer:PopBloom("lunge")
            inst.components.colouradder:PopColour("lunge")
        end,
    }

AddStategraphState("wilson",chargestate)
AddStategraphState("wilson_client",State{
    name = "playercharge_start",
    tags = { "doing", "busy", "nointerrupt" },
    server_states = { "combat_lunge_start", "combat_lunge" },

    onenter = function(inst)
        inst.components.locomotor:Stop()
        inst.AnimState:PlayAnimation("atk_pre_pre")
        inst.AnimState:PushAnimation("lunge_lag", false)

        
        inst.sg:SetTimeout(2)
    end,


    onupdate = function(inst)
        if inst.sg:ServerStateMatches() then
            inst.sg:GoToState("idle", "noanim")
        elseif inst.bufferedaction == nil then
            inst.sg:GoToState("idle")
        end
    end,

    ontimeout = function(inst)
        inst.sg:GoToState("idle")
    end,
})




AddModRPCHandler("The_NewConstant", "playercharge", function(inst, x,y,z)
    if not inst.sg:HasStateTag("charge") then
        inst.sg:GoToState("playercharge_start",{x=x,z=z})
    end    
end)


AddComponentPostInit("playercontroller", function(self, inst)
    local isdown = false
    local PlayerControllerOnControl = self.OnControl
    self.OnControl = function(self, control, down)
        PlayerControllerOnControl(self,control,down)
        if self.inst:HasTag("playercharge")
            and TheInput:IsKeyDown(KEY_R) then
            if isdown ~= down then
                isdown = down
                
                if isdown and control==0 then
                    local x,y,z =  TheInput:GetWorldPosition():Get()
                    SendModRPCToServer(GetModRPC("The_NewConstant", "playercharge"),x,y,z)
                end
            end
        end 
    end    
end)   