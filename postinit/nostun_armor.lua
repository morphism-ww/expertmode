local function FunctionAdder(obj,name,addfn)
	local oldfn = obj[name]
	obj[name] = function (inst,owner)
		oldfn(inst,owner)
		addfn(inst,owner)
	end
end


local function giveprotect(inst)
	local owner = inst.components.inventoryitem:GetGrandOwner()
	if owner and owner.sg~=nil then
        owner.sg:AddStateTag("nointerrupt")
    end
end



AddPrefabPostInit("armordreadstone",function(inst)

	inst:AddTag("heavyarmor")

	if not TheWorld.ismastersim then
		return inst
	end

	inst.components.armor.ontakedamage = giveprotect
	
	--[[local equippable = inst.components.equippable
	FunctionAdder(equippable,"onequipfn",giveprotect)
	FunctionAdder(equippable,"onunequipfn",removeprotect)]]
end)


local function addprotect(inst,owner)
	if owner.components.stunprotecter == nil then
        owner:AddComponent("stunprotecter")
    end
    owner.components.stunprotecter:AddSource(inst)
end

local function removeprotect(inst,owner)
	if owner.components.stunprotecter ~= nil then
        owner.components.stunprotecter:RemoveSource(inst)
    end
end

AddPrefabPostInit("shieldofterror",function(inst)

	inst:AddTag("heavyarmor")

	if not TheWorld.ismastersim then
		return inst
	end

	--inst.components.armor.ontakedamage = giveprotect
	
	local equippable = inst.components.equippable
	FunctionAdder(equippable,"onequipfn",addprotect)
	FunctionAdder(equippable,"onunequipfn",removeprotect)
end)
