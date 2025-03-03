local UpvalueTracker = require("util/upvaluetracker")



newcs_env.AddSimPostInit(function ()
	local shadow_tags = {"nightmarecreature", "shadowcreature", "shadow", "shadowminion", "stalker", "stalkerminion", "nightmare", "shadow_fire"}
	local function GetLevelForTarget(target)
		-- L1: 0.5 to 1.0 is ignore
		-- L2: 0.0 to 0.5 is look at behaviour
		-- L3: shadow target or >0.9, attack it!
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
	local ctor = Prefabs["gestalt_guard"].fn

	--print("TESTING!!!!",ctor)
	--dumptable(debug.getinfo(ctor))

	UpvalueTracker.SetUpvalue(ctor,GetLevelForTarget,"Client_CalcTransparencyRating","GetLevelForTarget")
end)