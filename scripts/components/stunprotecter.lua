local SourceModifierList = require("util/sourcemodifierlist")

local function giveprotect(inst)
    inst.sg:AddStateTag("nointerrupt")
end


local StunProtecter = Class(function(self, inst)
    self.inst = inst
    self._sources = SourceModifierList(inst, false, SourceModifierList.boolean)

    if inst.sg~=nil then
        inst.sg:AddStateTag("nointerrupt")
    end
    
    self.inst:ListenForEvent("newstate",giveprotect)
end)

function StunProtecter:AddSource(source)
    self._sources:SetModifier(source, true)
end

function StunProtecter:OnRemoveFromEntity()
    self.inst:RemoveEventCallback("newstate",giveprotect)
end

function StunProtecter:RemoveSource(source)
    self._sources:RemoveModifier(source)
    if not self._sources:Get() then
        self.inst:RemoveComponent("stunprotecter")
    end
end

return StunProtecter