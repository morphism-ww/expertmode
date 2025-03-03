local function onenable(self,val)
	self.inst:AddOrRemoveTag("mythical_repairer",val)
end
local AurumiteRepair = Class(function(self, inst)
	self.inst = inst
	self.enable = true
	--self.onrepaired = nil
end,nil,{
	enable = onenable
})

function AurumiteRepair:Enable(val)
	self.enable = val
end


function AurumiteRepair:SetOnRepaired(fn)
	self.onrepaired = fn
end

function AurumiteRepair:FindValidSlot(target)
	local container = self.inst.components.container
	for i = 1, container.numslots do
        local item = container.slots[i]
        if item ~= nil then
            local valid_repairable = MYTHICAL_REPAIR_MAP[item.prefab]
			if valid_repairable~=nil and table.contains(valid_repairable,target.prefab) then
				return item
			end
        end
    end
end

function AurumiteRepair:Repair(target, doer)
	if not self.enable then
		return false,"WRONG_STATE"
	end
	local success
	local item = self:FindValidSlot(target)
	if item== nil then
		return false,"INVALID_TARGET"
	end
	if target.components.armor ~= nil then
		if target.components.armor:IsDamaged() then
			target.components.armor:Repair(1500)
			success = true
		end
	elseif target.components.finiteuses ~= nil then
		if target.components.finiteuses:GetPercent() < 1 then
			target.components.finiteuses:Repair(150)
			success = true
		end
	end
	if success then
		if target.components.forgerepairable~=nil then
			target.components.forgerepairable.onrepaired(target,doer)
		end
		target:PushEvent("u_repaired")
		self.onrepaired(self.inst,target,doer,item)
		return true
	end
end

return AurumiteRepair
