local TransformLimit = Class(function(self, inst)
    self.inst = inst
    self.state = false

    inst:ListenForEvent("changearea",function (player,area)
        self:UpdatePosition(area) 
    end) 
end)


function TransformLimit:UpdatePosition(area)
    local in_notele = area and area.tags~=nil and table.contains(area.tags,"notele")
    
    if (self.state == not in_notele) and not 
    (self.inst.components.health:IsInvincible() and self.inst.components.builder.freebuildmode) then
        self.inst.components.locomotor:Stop()
        if self.inst.sg~=nil then
            self.inst.sg:GoToState("idle")
        end
        local pt = self.inst:GetPosition()
        local tp = self.inst.components.areaaware.lastpt
        local offset = tp - pt
        local dir,len = offset:GetNormalizedAndLength()
        if len<1.5 then
            tp.x = tp.x + 2 * dir.x 
            tp.z = tp.z + 2 * dir.z 
        end
        self.inst.Physics:Teleport(tp.x,0,tp.z)            
    end
end


function TransformLimit:SetState(val)
    self.state = val
end


function TransformLimit:OnSave()
    if self.state then
        return {
            state = self.state
        }
    end
end

function TransformLimit:OnLoad(data)
    if data~=nil then
        self.state = data.state
    end
end

return TransformLimit