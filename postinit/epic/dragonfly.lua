local function OnTimerDone(inst, data)
    if data.name == "selfdestruct" and inst.components.explosive~=nil then
        inst.components.explosive:OnBurnt()
    end
end
newcs_env.AddPrefabPostInit("lavae", function(inst)
	if not TheWorld.ismastersim then
		return
	end
    inst:AddComponent("explosive")
    inst.components.explosive.explosiverange = 8
    inst.components.explosive.explosivedamage = 20
    inst.components.explosive.buildingdamage=600
    inst:ListenForEvent("timerdone", OnTimerDone)
end)

newcs_env.AddStategraphPostInit("lavae",function(sg)
    sg.states.thaw_break.onenter=function(inst)
        if inst.components.locomotor then
            inst.components.locomotor:StopMoving()
        end
        inst.AnimState:PlayAnimation("shatter")
        if inst.components.lootdropper then
            inst.components.lootdropper:SetChanceLootTable(inst.FrozenLootTable or 'lavae_frozen')
            inst.components.lootdropper:DropLoot(Vector3(inst.Transform:GetWorldPosition()))
            inst.SoundEmitter:PlaySound("dontstarve/creatures/together/lavae/shatter")
        end
        if inst.components.explosive~=nil then
            inst.components.explosive.explosiverange = 6
            inst.components.explosive.explosivedamage = 0
            inst.components.explosive:OnBurnt()
        end

    end
end)

local function Dofire(inst)
    if not inst.enraged and inst.components.health and inst.components.health:GetPercent() <= TUNING.DRAGONFLY_TRANSFORM
            and not inst.components.health:IsDead() then
        inst.sg:GoToState("transform_fire")
    end
end

local function StartFireEra(inst)
    TheWorld:PushEvent("FireEra")
end

newcs_env.AddPrefabPostInit("dragonfly", function(inst)
    if not TheWorld.ismastersim then return end

    inst:AddComponent("resistance")
	inst.components.resistance:AddResistance("lavae")


    inst.components.freezable:SetResistance(8)

    inst:DoPeriodicTask(8,Dofire)
    inst:ListenForEvent("death", StartFireEra)

    table.insert(inst.components.groundpounder.noTags, "lavae")
end)