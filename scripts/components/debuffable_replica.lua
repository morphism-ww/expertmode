local debuffable = Class(function(self, inst)
    self.inst = inst
	self.cs_buffinfo = net_string(inst.GUID,"newconstant._buffinfo")
end)

function debuffable:GetBuffInfo()
	return self._buffinfo:value()
end

return debuffable