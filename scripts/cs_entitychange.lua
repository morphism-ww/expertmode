--local AddLightProxy = Entity.AddLight

--[[function Entity:AddLight()
    local Light = AddLightProxy(self)
    local guid = self:GetGUID()
    local inst = Ents[guid]

    local Light_meta = getmetatable(Light).__index
    local old_enablelight = Light_meta.Enable
    Light_meta.Enable = function (self,bool)
        old_enablelight(self,not inst.Light_ForceDarkness and bool)
    end   
end]]

function EntityScript:ForceDarkness()
    if self.Light~=nil and self.Light:IsEnabled() then
        --rawset(self.Light,"Light_ForceDarkness",true)
       if self.ForceDarkTask==nil then
            self.Light:Enable(false)
            self.ForceDarkTaskCount = 0
            self.ForceDarkTask = self:DoPeriodicTask(1,
            function (self)
                if self.ForceDarkTaskCount>20 then
                    self.ForceDarkTaskCount = 0
                    self.ForceDarkTask:Cancel()
                    self.ForceDarkTask = nil
                    self.Light:Enable(true)
                end
                self.ForceDarkTaskCount = self.ForceDarkTaskCount+1
            end)
        else
            self.Light:Enable(false)
            self.ForceDarkTaskCount = 0
        end    
    end
end

function EntityScript:IsPoisonable()
    return self.entity:IsValid()
        and self.components.health and not self.components.health:IsDead()
        and not self.entity:HasAnyTag("soulless","mech","ghost")
        and self.entity:HasAnyTag("character","monster","animal")
        and not (self.components.inventory and self.components.inventory:EquipHasTag("poison_immune"))
end

function EntityScript:GetDistanceSqToPoint(x, y, z)
    -- If x is the only input, assume it's a Vector3 or Point
    if x and not y and not z then
        x, y, z = x:Get()
    end
    local x1, y1, z1 = self.Transform:GetWorldPosition()
    return (x-x1)*(x-x1)+(z-z1)*(z-z1)
end

function EntityScript:IsNear(otherinst, dist)
    if otherinst==nil then
        return false
    end
    assert(self:IsValid() and otherinst:IsValid())
    local p1x, p1y, p1z = self.Transform:GetWorldPosition()
    local p2x, p2y, p2z = otherinst.Transform:GetWorldPosition()
    return (p1x-p2x)*(p1x-p2x)+(p1z-p2z)*(p1z-p2z)< dist*dist
end