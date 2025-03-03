local function SetAbsorptionAmount(self,amount)
    if self.inst.components.combat~=nil then
        self.inst.components.combat.externaldamagetakenmultipliers:SetModifier(self.inst,1-amount,"shield")
    else
        self.absorb = amount
    end    
end

local List_of_Creature = {"klaus","spider_hider","slurtle","toadstool","woodie","rocky"}

for k,v in ipairs(List_of_Creature) do
    newcs_env.AddPrefabPostInit(v,function (inst)
        inst.components.health.SetAbsorptionAmount = SetAbsorptionAmount
    end)
end