function EntityScript:ForceDarkness()
    if self.Light~=nil and self.Light:IsEnabled() then
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


--帮克雷优化一下底层的屎
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
    assert(self.entity:IsValid() and otherinst.entity:IsValid())
    local x, y, z = self.Transform:GetWorldPosition()
    local x1, y1, z1 = otherinst.Transform:GetWorldPosition()
    return (x-x1)*(x-x1) + (z-z1)*(z-z1) < dist*dist
end

--带次数限制的，初始延迟的，含终止触发函数的周期性任务
function EntityScript:DoPeriodicTaskWithLimit(time, fn, initialdelay, limit, endfunction, ...)
    local periodic = scheduler:ExecutePeriodic(time, fn, limit, initialdelay, self.GUID, self, ...)

    self.pendingtasks = self.pendingtasks or {}
    self.pendingtasks[periodic] = true
    periodic.onfinish =  function(task, success, inst)
        if inst and inst.pendingtasks and inst.pendingtasks[task] then
            inst.pendingtasks[task] = nil
            if endfunction then
                endfunction(inst)
            end
        end
    end
    return periodic
end

---time>0!!!
function EntityScript:DoPeriodicTaskWithTimeLimit(time, fn, initialdelay, limit, endfunction, ...)
    initialdelay = initialdelay or time
    limit = math.floor((limit-initialdelay)/time)
    local periodic = scheduler:ExecutePeriodic(time, fn, limit, initialdelay, self.GUID, self, ...)

    self.pendingtasks = self.pendingtasks or {}
    self.pendingtasks[periodic] = true
    periodic.onfinish =  function(task, success, inst)
        if inst and inst.pendingtasks and inst.pendingtasks[task] then
            inst.pendingtasks[task] = nil
            if endfunction then
                endfunction(inst)
            end
        end
    end
    return periodic
end