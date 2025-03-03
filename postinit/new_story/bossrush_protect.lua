local function DelayedMarkTalker(player)
	-- if the player starts moving right away then we can skip this
	if player.sg == nil or player.sg:HasStateTag("idle") then 
		player.components.talker:Say(GetString(player, "ANNOUNCE_POCKETWATCH_MARK"))
	end 
end
local function Recall_DoCastSpell(inst, doer, target, pos)
	local recallmark = inst.components.recallmark
	local x, y, z = doer.Transform:GetWorldPosition()
	if TheWorld.Map:NodeAtPointHasTag(x,y,z,"Abyss") then
		return false, "SHARD_UNAVAILABLE"
	end

	if recallmark:IsMarked() then
		if Shard_IsWorldAvailable(recallmark.recall_worldid) then
			inst.components.rechargeable:Discharge(TUNING.POCKETWATCH_RECALL_COOLDOWN)

			doer.sg.statemem.warpback = {dest_worldid = recallmark.recall_worldid, dest_x = recallmark.recall_x, dest_y = 0, dest_z = recallmark.recall_z, reset_warp = true}
			return true
		else
			return false, "SHARD_UNAVAILABLE"
		end
	else
		
		inst.components.recallmark:MarkPosition(x, y, z)
		inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/MarkPosition")

		doer:DoTaskInTime(12 * FRAMES, DelayedMarkTalker) 

		return true
	end
end
newcs_env.AddPrefabPostInit("pocketwatch_recall",function (inst)
    if not TheWorld.ismastersim then return end
    inst.components.pocketwatch.DoCastSpell = Recall_DoCastSpell
end)


