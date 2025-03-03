-----------------------poison----------------------------------------
local function HealSpider(inst,target)
	target:RemoveDebuff("spider_poison")
	target:RemoveDebuff("spider_dead_poison")
end

newcs_env.AddPrefabPostInit("healingsalve", function(inst)
	inst:AddTag("healerbuffs")
	if not TheWorld.ismastersim then
		return inst
	end
	inst.components.healer.onhealfn = HealSpider
end)


local function HealBee(inst,target)
	target:RemoveDebuff("bee_poison")
	target:RemoveDebuff("beequeen_poison")
end

newcs_env.AddPrefabPostInit("bandage", function(inst)
	inst:AddTag("healerbuffs")
	if not TheWorld.ismastersim then
		return inst
	end
	inst.components.healer.onhealfn = HealBee
end)

newcs_env.AddPrefabPostInit("durian", function(inst)
	local function oneatenfn(inst,eater)
		eater:RemoveDebuff("bee_poison")
		eater:RemoveDebuff("spider_poison")
		eater:RemoveDebuff("toad_poison")
	end
	if not TheWorld.ismastersim then
		return inst
	end
	inst.components.edible:SetOnEatenFn(oneatenfn)
end)


---------------------------freeze----------------------------
local function onequip(inst,data)
	if data.owner.components.freezable then
		data.owner.components.freezable:AddResistance(inst, inst.freeze_resist)
	end
end

local function onunequip(inst,data)
	if data.owner and data.owner.components.freezable then
		data.owner.components.freezable:RemoveResistance(inst)
	end
end


newcs_env.AddPrefabPostInit("trunkvest_summer",function (inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.freeze_resist = 2

	inst:ListenForEvent("equipped",onequip)
    inst:ListenForEvent("unequipped",onunequip)
end)

newcs_env.AddPrefabPostInit("trunkvest_winter",function (inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.freeze_resist = 4

	inst:ListenForEvent("equipped",onequip)
    inst:ListenForEvent("unequipped",onunequip)
end)

newcs_env.AddPrefabPostInit("beargervest",function (inst)
	if not TheWorld.ismastersim then
		return inst
	end

	inst.freeze_resist = 8

	inst:ListenForEvent("equipped",onequip)
    inst:ListenForEvent("unequipped",onunequip)

end)

local DebuffList = {"bee_poison","spider_poison","buff_vulnerable","buff_weak"}
local function SleepRemoveDebuffs(inst,doer)
    for _,k in ipairs(DebuffList) do
        doer:RemoveDebuff(k)
    end
end

for k,v in ipairs({"tent","siestahut","portabletent","bedroll_furry"}) do
	newcs_env.AddPrefabPostInit(v,function (inst)
		if not TheWorld.ismastersim then
			return inst
		end
	
		inst.components.sleepingbag.onsleep = SleepRemoveDebuffs
	
	end)
end

-----------------------------------------------------------

newcs_env.AddComponentPostInit("cursable", function(self)
	local old_fn = self.ForceOntoOwner
	function self:ForceOntoOwner(item)
		if self.inst and self.inst.components.newcs_talisman and self.inst.components.newcs_talisman:TryResist() then
			item:Remove()
			return
		end
		old_fn(self,item)
	end
end)