local shadow_tags = {"nightmarecreature", "shadowcreature", "shadow", "shadowminion", "stalker", "stalkerminion", "nightmare", "shadow_fire"}

local function GetLevelForTarget(target)
	-- L1: 0.5 to 1.0 is ignore
	-- L2: 0.0 to 0.5 is look at behaviour
	-- L3: shadow target, attack it!

	if target ~= nil then
		if target:HasTag("gestalt_possessable") then
			return 3, 0
		end

		local inventory = target.replica.inventory
		if inventory ~= nil and inventory:EquipHasTag("shadow_item") then
			return 3, 0
		end

		local sanity_rep = target.replica.sanity
		if sanity_rep ~= nil then
			local sanity = sanity_rep:GetPercentWithPenalty() or 0
			local level = (sanity>0.9 and 3) or (sanity > 0.33 and 1)
					or 2
			return level, sanity
		end

		for i = 1, #shadow_tags do
			if target:HasTag(shadow_tags[i]) then
				return 3, 0
			end
		end
	end

	return 1, 1
end


local attack_any_tags = {"player","gestalt_possessable","nightmarecreature", "shadowcreature", "shadow", "shadowminion", "stalker", "stalkerminion", "nightmare", "shadow_fire"}
local watch_must_tags = {"player"}
local function Retarget(inst)
	local targets_level = 1
	local function attacktargetcheck(target)
        if target.components.inventory ~= nil and target.components.inventory:EquipHasTag("gestaltprotection") then
            return false
        end
		targets_level = GetLevelForTarget(target)
		return targets_level == 3
	end
	local function watchtargetcheck(target)
        if target.components.inventory ~= nil and target.components.inventory:EquipHasTag("gestaltprotection") then
            return false
        end
		targets_level = GetLevelForTarget(target)
		return targets_level == 2
	end

	local target = FindEntity(inst, TUNING.GESTALTGUARD_AGGRESSIVE_RANGE, attacktargetcheck, nil, nil, attack_any_tags)
					or FindEntity(inst, TUNING.GESTALTGUARD_WATCHING_RANGE, watchtargetcheck, watch_must_tags)

	if target == nil and inst.components.combat.target ~= nil then
		inst.components.combat:DropTarget()
	elseif target == inst.components.combat.target then
		inst.behaviour_level = target ~= nil and targets_level or 1
	end

	return target, target ~= inst.components.combat.target
end
AddPrefabPostInit("gestalt_guard",function(inst)
    if not TheWorld.ismastersim then
        return inst
    end
	inst.components.combat:SetRetargetFunction(1, Retarget)
end)


