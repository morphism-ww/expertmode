local CHECK_INTERVAL = 5

FindStatue = Class(BehaviourNode, function(self, inst, see_dist)
    BehaviourNode._ctor(self, "FindStatue")
    self.inst = inst
    self.targ = nil
    self.old_targ={}
    self.see_dist = see_dist
    self.lastchecktime = 0
end)


function FindStatue:Visit()
    if self.status == READY then
        self:PickTarget()
        self.status = RUNNING
    end

    if self.status == RUNNING then
        if GetTime() - self.lastchecktime > CHECK_INTERVAL then
            self:PickTarget() 
        end

        if self.targ == nil or not self.targ:IsValid() then
            self.status = FAILED
        else           
            if self.inst:IsNear(self.targ, 3.5) then
                self.status = SUCCESS
                self.old_targ[self.targ.GUID]=true
                self.targ=nil
                self.inst.components.locomotor:Stop()
            else
                self.inst.components.locomotor:GoToPoint(self.inst:GetPositionAdjacentTo(self.targ, 3), nil, true)
            end
        end
    end
end

function FindStatue:PickTarget()
    local x, y, z = self.inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, self.see_dist, nil,nil,{"altar","statue"})
    for k,v in ipairs(ents) do
        if not self.old_targ[v.GUID] and not v.prefab=="ruins_statue_head_nogem" then
            self.targ=v
            --self.old_targ=nil
            break
        end
    end
    if self.targ==nil then
        for k in pairs(self.old_targ) do
            self.old_targ[k]=nil
        end
        --self.targ=ents[1]
    end    

    self.lastchecktime = GetTime()
end
