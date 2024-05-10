local function Recall_DoCastSpell(inst, doer, target, pos)
	local recallmark = inst.components.recallmark

    if TheWorld.components.voidland_manager~=nil and TheWorld.components.voidland_manager.bossrush_on then
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
		local x, y, z = doer.Transform:GetWorldPosition()
		inst.components.recallmark:MarkPosition(x, y, z)
		inst.SoundEmitter:PlaySound("wanda2/characters/wanda/watch/MarkPosition")

		doer:DoTaskInTime(12 * FRAMES, DelayedMarkTalker) 

		return true
	end
end
AddPrefabPostInit("pocketwatch_recall",function (inst)
    if not TheWorld.ismastersim then return end
    inst.components.pocketwatch.DoCastSpell = Recall_DoCastSpell
end)