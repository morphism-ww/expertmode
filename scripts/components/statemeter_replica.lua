local StateMeter = Class(function(self, inst)
    self.inst = inst

    self.stateinfo = net_string(inst.GUID,"statemeter._stateinfo","cs_statedirty")
end)

function StateMeter:SetStateInfo(state)
    local state_info = {}
    for name, time in pairs(state) do
        table.insert(state_info,{name,time})
    end
    self.stateinfo:set_local(json.encode(state_info))
    self.stateinfo:set(json.encode(state_info))
end

function StateMeter:GetStateInfo()
    return self.stateinfo:value()
end

return StateMeter