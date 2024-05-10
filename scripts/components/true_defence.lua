local True_Defence = Class(function(self, inst)
    self.inst = inst
    

end)

function True_Defence:GetAbsorption(damage)
    return self.resistfn~=nil and self.resistfn(damage) or damage
end

function True_Defence:SetResistFn(fn)
	self.resistfn = fn
end


return True_Defence