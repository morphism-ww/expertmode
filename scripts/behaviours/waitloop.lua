WaitLoopNode = Class(BehaviourNode, function(self, time, children)
    BehaviourNode._ctor(self, "WaitLoop",children)
    self.wait_time = time
end)

function WaitLoopNode:DBString()
    local w = self.wake_time - GetTime()
    return string.format("%2.2f", w)
end

function WaitLoopNode:Visit()
    local current_time = GetTime()

    if self.status ~= RUNNING then
        self.wake_time = current_time + FunctionOrValue(self.wait_time)
        self.status = RUNNING
    end

    if self.status == RUNNING then
        for idx, child in ipairs(self.children) do
            child:Visit()
        end    
        if current_time >= self.wake_time then
            self.status = SUCCESS
        else
            self:Sleep(current_time - self.wake_time)
        end
    end

end