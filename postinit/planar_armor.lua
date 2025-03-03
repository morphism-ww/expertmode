local function DoRegen(inst, owner)

	local fx = SpawnPrefab("ghostlyelixir_shield_fx")
	fx.entity:SetParent(owner.entity)
	fx.Transform:SetPosition(0, 0, 0)
	
	if not owner.components.health:IsDead() then
		owner.components.health:DoDelta(1)
	end
	if not owner.components.health:IsHurt() then
		inst.regentask:Cancel()
		inst.regentask = nil
	end
end


local function StartRegen(inst, owner)
	if not owner.components.health:IsHurt() then
		return
	end
	if inst.regentask == nil then
		inst.regentask = inst:DoPeriodicTask(4, DoRegen,nil,owner)
	end
end

local function StopRegen(inst)
	if inst.regentask ~= nil then
		inst.regentask:Cancel()
		inst.regentask = nil
	end
end


local function OnBlocked(inst,owner)
    if not owner:HasDebuff("lunar_protect") and inst.components.setbonus:IsEnabled(EQUIPMENTSETNAMES.LUNARPLANT) then
        owner:AddDebuff("lunar_protect","lunar_shield")
	end
	StartRegen(inst, owner)
end

local function onequip_2(inst,data)
	local owner=data.owner
	if owner~=nil and owner.components.health~=nil then
		inst:ListenForEvent("blocked", inst.procfn,owner)
		inst:ListenForEvent("attacked", inst.procfn,owner)
		StartRegen(inst, owner)
	end
end

local function onunequip_2(inst,data)
	local owner=data.owner
	if owner~=nil and owner.components.health~=nil then
		inst:RemoveEventCallback("blocked", inst.procfn,owner)
		inst:RemoveEventCallback("attacked", inst.procfn,owner)
		StopRegen(inst)
	end		
end


newcs_env.AddPrefabPostInit("armor_lunarplant",function(inst)
    if not TheWorld.ismastersim then return end

	inst:ListenForEvent("equipped",onequip_2)
    inst:ListenForEvent("unequipped",onunequip_2)

	inst.procfn = function(owner) OnBlocked(inst, owner) end

end)

newcs_env.AddPrefabPostInit("armor_lunarplant_husk",function(inst)
    if not TheWorld.ismastersim then return end

	inst:ListenForEvent("equipped",onequip_2)
    inst:ListenForEvent("unequipped",onunequip_2)

	inst.procfn = function(owner) OnBlocked(inst, owner) end

end)


----------------------------------------------------------------------




local function OnEnabledSetBonus2(inst)
	
	inst.components.damagetyperesist:AddResist("shadow_aligned", inst, TUNING.ARMOR_VOIDCLOTH_SETBONUS_SHADOW_RESIST, "setbonus")
	inst.components.equippable.walkspeedmult = 1.3
	inst.components.armor:SetAbsorption(0.85)
end

local function OnDisabledSetBonus2(inst)
	
	inst.components.damagetyperesist:RemoveResist("shadow_aligned", inst, "setbonus")
	inst.components.equippable.walkspeedmult = 1.2
	inst.components.armor:SetAbsorption(0.8)
end



newcs_env.AddPrefabPostInit("armor_voidcloth",function(inst)
	
    if not TheWorld.ismastersim then return end

	
	inst.components.setbonus:SetOnEnabledFn(OnEnabledSetBonus2)
	inst.components.setbonus:SetOnDisabledFn(OnDisabledSetBonus2)

	inst.components.equippable.walkspeedmult = 1.2
end)

local function OnEnabledSetBonus3(inst)
	inst:AddTag("shadowdodge")
	inst.components.damagetyperesist:AddResist("shadow_aligned", inst, TUNING.ARMOR_VOIDCLOTH_SETBONUS_SHADOW_RESIST, "setbonus")

end

local function OnDisabledSetBonus3(inst)
	inst:RemoveTag("shadowdodge")
	inst.components.damagetyperesist:RemoveResist("shadow_aligned", inst, "setbonus")
end

newcs_env.AddPrefabPostInit("voidclothhat",function(inst)
	
    if not TheWorld.ismastersim then return end

	
	inst.components.setbonus:SetOnEnabledFn(OnEnabledSetBonus3)
	inst.components.setbonus:SetOnDisabledFn(OnDisabledSetBonus3)

	
end)

local function OnColourDirty(inst)
	
	if inst.OnSyncMultColour ~= nil then
		local a = inst.colour:value()
		local r = math.floor(a / 16777216)
		a = a - r * 16777216
		local g = math.floor(a / 65536)
		a = a - g * 65536
		local b = math.floor(a / 256)
		a = a - b * 256
		for i, v in ipairs(inst.fx) do
			v.AnimState:OverrideMultColour(r,g,b,a)
		end
	end
end

local function SynColour(inst,r,g,b,a)
	for i, v in ipairs(inst.fx) do
		v.AnimState:OverrideMultColour(r,g,b,a)
	end
end

local function SynColour_server(inst,r,g,b,a)
	inst.colour:set(
		math.floor(r * 255 + .5) * 0x1000000 +
		math.floor(g * 255 + .5) * 0x10000 +
		math.floor(b * 255 + .5) * 0x100 +
		math.floor(a * 255 + .5)
	)
end

--虚空套装的特效
newcs_env.AddPrefabPostInit("armor_voidcloth_fx",function (inst)
	inst.colour = net_uint(inst.GUID, "armor_voidcloth_fx.colour", "multcolourdirty")
	if not TheNet:IsDedicated() then
		inst.OnSyncMultColour = SynColour
	else
		inst.OnSyncMultColour = SynColour_server
	end
	if not TheWorld.ismastersim then
		inst:ListenForEvent("multcolourdirty", OnColourDirty)
	end
end)

newcs_env.AddPrefabPostInit("voidclothhat_fx",function (inst)
	inst.colour = net_uint(inst.GUID, "voidclothhat_fx.colour", "multcolourdirty")
	if not TheNet:IsDedicated() then
		inst.OnSyncMultColour = SynColour
	else
		inst.OnSyncMultColour = SynColour_server
	end
	if not TheWorld.ismastersim then
		inst:ListenForEvent("multcolourdirty", OnColourDirty)
	end
	
end)
