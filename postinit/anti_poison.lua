
local function HealSpider(inst,target)
	if target.components.debuffable then
		target.components.debuffable:RemoveDebuff("spider_poison")
		target.components.debuffable:RemoveDebuff("spider_dead_poison")
	end
end

AddPrefabPostInit("healingsalve", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst.components.healer.onhealfn=HealSpider
end)


local function HealBee(inst,target)
	if target.components.debuffable then
		target.components.debuffable:RemoveDebuff("bee_poison")
		target.components.debuffable:RemoveDebuff("beequeen_poison")
	end
end

AddPrefabPostInit("bandage", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst.components.healer.onhealfn=HealBee
end)

local function oneatenfn(inst,eater)
	eater:RemoveDebuff("bee_poison")
	eater:RemoveDebuff("spider_poison")
	eater:RemoveDebuff("toad_poison")
end


AddPrefabPostInit("durian", function(inst)
	if not TheWorld.ismastersim then
		return inst
	end
	inst.components.edible:SetOnEatenFn(oneatenfn)
end)
