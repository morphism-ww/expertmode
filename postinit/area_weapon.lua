local function CanBeUpgraded(inst, item)
    return inst.components.equippable~=nil and not inst.components.equippable:IsEquipped()
end

local function OnUpgraded(inst, upgrader, item)
    local skin_build, skin_id = inst:GetSkinBuild(), inst.skin_id
    if skin_build == nil or skin_build == "" or skin_id == 0 then
        skin_build, skin_id = nil, nil
    end
    local sword = SpawnPrefab("true_sword_lunarplant", skin_build, skin_id)

    sword.components.finiteuses:SetPercent(inst.components.finiteuses:GetPercent())

    local container = inst.components.inventoryitem:GetContainer()
    if container ~= nil then
        local slot = inst.components.inventoryitem:GetSlotNum()
        inst:Remove()
        container:GiveItem(sword, slot)
    else
        local x, y, z = inst.Transform:GetWorldPosition()
        inst:Remove()
        sword.Transform:SetPosition(x, y, z)
    end
end


AddPrefabPostInit("sword_lunarplant",function(inst)


    if not TheWorld.ismastersim then return end

    inst:AddComponent("upgradeable")
    inst.components.upgradeable.upgradetype = UPGRADETYPES.IRON_SOUL
    inst.components.upgradeable:SetOnUpgradeFn(OnUpgraded)
    inst.components.upgradeable:SetCanUpgradeFn(CanBeUpgraded)

end)

--[[local function DefaultRangeCheck(doer, target)
    if target == nil then
        return
    end
    local target_x, target_y, target_z = target.Transform:GetWorldPosition()
    local doer_x, doer_y, doer_z = doer.Transform:GetWorldPosition()
    local dst = distsq(target_x, target_z, doer_x, doer_z)
    return dst <= 36
end
local sweep_attack = Action({ rmb=true, distance=3, rangecheckfn=DefaultRangeCheck })
sweep_attack.id="SWEEP"
sweep_attack.str="横扫"
sweep_attack.fn=function(act)
    local weapon = act.doer.components.combat:GetWeapon()
    if act.doer.sg ~= nil then
        if act.doer.sg:HasStateTag("propattack") then
            --don't do a real attack with prop weapons
            return true
        elseif act.doer.sg:HasStateTag("thrusting") then
            return weapon ~= nil
                and weapon.components.multithruster ~= nil
                and weapon.components.multithruster:StartThrusting(act.doer)
        elseif act.doer.sg:HasStateTag("helmsplitting") then
            return weapon ~= nil
                and weapon.components.helmsplitter ~= nil
                and weapon.components.helmsplitter:StartHelmSplitting(act.doer)
        end
    end
    weapon:DoSweepAttack(act.target,act.doer)
    return true
end
AddAction(sweep_attack)

AddComponentAction("EQUIPPED","weapon", function(inst, doer,target, actions, right)
    if right and doer.replica.combat ~= nil
            and not (doer.replica.rider ~= nil and doer.replica.rider:IsRiding()) -- 动作执行者不在骑乘状态
            and not target:HasTag("wall") -- 目标不是墙
            and doer.replica.combat:CanTarget(target) -- doer可以把target作为目标
            and target.replica.combat:CanBeAttacked(doer) -- target可以被doer攻击
            and not doer.replica.combat:IsAlly(target) -- 目标不是队友
            and inst:HasTag("nc_sweep_weapon") then
        table.insert(actions, ACTIONS.SWEEP)
    end
end,"the new Constant")


AddStategraphActionHandler("wilson",ActionHandler(ACTIONS.SWEEP, "scythe"))
AddStategraphActionHandler("wilson_client",ActionHandler(ACTIONS.SWEEP), "scythe")


local function IsEntityInFront(inst, entity, doer_rotation, doer_pos,angle)
    local facing = Vector3(math.cos(-doer_rotation / RADIANS), 0 , math.sin(-doer_rotation / RADIANS))

    return IsWithinAngle(doer_pos, facing, angle, entity:GetPosition())
end
local HARVEST_MUSTTAGS  = {"_health"}
local HARVEST_CANTTAGS  = {"INLIMBO", "FX","character"}
local HARVEST_ONEOFTAGS = {"", "lichen", "oceanvine", "kelp"}

local function DoScythe(inst, target, doer)
    if target.components.health ~= nil then
        local doer_pos = doer:GetPosition()
        local x, y, z = doer_pos:Get()

        local doer_rotation = doer.Transform:GetRotation()
        local combat0=doer.components.combat
        local ents = TheSim:FindEntities(x, y, z, 6, HARVEST_MUSTTAGS, HARVEST_CANTTAGS, nil)
        for _, ent in pairs(ents) do
            if ent:IsValid() then
                if inst:IsEntityInFront(ent, doer_rotation, doer_pos,165/RADIANS) then
                    local dmg, spdmg = combat0:CalcDamage(ent, inst, 2)
			        ent.components.combat:GetAttacked(doer, dmg, inst, nil, spdmg)
                    --doer.components.combat:DoAttack(ent,inst)
                end
            end
        end
    end
end


AddPrefabPostInit("ruins_bat",function(inst)
    inst:AddTag("nc_sweep_weapon")
    if not TheWorld.ismastersim then return end

    inst.DoSweepAttack = DoScythe
    inst.IsEntityInFront = IsEntityInFront
end)

AddPrefabPostInit("voidcloth_scythe",function(inst)
    inst:AddTag("nc_sweep_weapon")
    if not TheWorld.ismastersim then return end

    inst.DoSweepAttack = DoScythe
    inst.IsEntityInFront = IsEntityInFront
end)]]



