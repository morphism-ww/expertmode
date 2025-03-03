local TwinsBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
    --self._special_move = nil
    self.ai = {0,0,0,0}
end)

local function SoftFaceTarget(inst, target)
    local rot = inst.Transform:GetRotation()
    local rot1 = inst:GetAngleToPoint(inst.sg.statemem.targetpos)
    local drot = ReduceAngle(rot1 - rot)
    if math.abs(drot)>5 then
        if drot<0 then
            rot1  = rot1 + 0.1
        else
            rot1  = rot1 - 0.1
        end
    end
    inst.Transform:SetRotation(rot1)
end

function TwinsBrain:DoUpdate()
    ---get_target
    self.target = self.inst.components.combat.target

    if not (self.target and self.target:IsValid()) then
        return
    end

    SoftFaceTarget(self.inst,self.target)

end

function TwinsBrain:OnStart()
    local root

    --laser
    if self.inst.twin1 then
        root = ParallelNode{

        }
    else

    end
    self.bt = BT(self.inst, root)
end


return TwinsBrain