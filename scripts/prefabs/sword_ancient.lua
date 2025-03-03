local assets =
{
	Asset("ANIM", "anim/sword_ancient.zip"),
    Asset("ANIM", "anim/swap_sword_ancient.zip"),
}

local function Projectile_Create()
    local inst = CreateEntity()

    inst.entity:AddNetwork()
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    --[[Non-networked entity]]
    inst.entity:SetCanSleep(false)
    inst.persists = false

    

    MakeProjectilePhysics(inst)
    inst.Physics:ClearCollidesWith(COLLISION.LIMITS)

    inst.AnimState:SetBank("sword_ancient")
    inst.AnimState:SetBuild("sword_ancient")
    inst.AnimState:PlayAnimation("shoot")
    inst.AnimState:SetScale(2,2,2)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)

    inst.AnimState:SetLightOverride(0.3)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst.AnimState:SetAddColour(1, 1, 1, 0)

    inst:DoTaskInTime(3,inst.Remove)

    return inst
end

local function summon_star(inst,owner,target)
    local x,y,z = owner.Transform:GetWorldPosition()
    local angle = owner:GetAngleToPoint(target.Transform:GetWorldPosition())
    for i = 1, 3 do
        local star_type = math.random()<0.5 and "constant_fire" or "constant_light"
        local star = SpawnPrefab(star_type)

        local angle_offset = (math.random()<0.5 and 1 or -1)*math.random(30,110)
        local final_angle = angle + angle_offset
        star.Transform:SetPosition(x+2*math.cos(final_angle*DEGREES),0.8,z-2*math.sin(final_angle*DEGREES))
        star.Transform:SetRotation(final_angle)
        star.components.circleprojectile:Shoot(target,owner)
    end
end

local function reset_stacks(inst)
    if inst.decaystacktask ~= nil then
        inst.decaystacktask:Cancel()
        inst.decaystacktask = nil
    end

    inst.buff_stacks = 0
end


local function onattack(inst,owner,target)

    
    if inst.decaystacktask ~= nil then
        inst.decaystacktask:Cancel()
    end
    inst.decaystacktask = inst:DoTaskInTime(4, reset_stacks)

    
    inst.buff_stacks = inst.buff_stacks + 1

    if target~=nil and target:IsValid() then
        local angle = owner:GetAngleToPoint(target.Transform:GetWorldPosition())
        local theta = angle*DEGREES
        local x,y,z = owner.Transform:GetWorldPosition()
        
        local cos_rot = math.cos(theta)
        local sin_rot = math.sin(theta)

        local proj = SpawnPrefab("sword_ancient_proj")
        proj.Transform:SetPosition(x+2*cos_rot,0.75,z-2*sin_rot)
        proj.Transform:SetRotation(angle)
        proj.Physics:SetMotorVel(30, 0, 0)

        local doer_combat = owner.components.combat
        local ents = TheSim:FindEntities(x,0,z,30,P_AOE_TARGETS_MUST, P_AOE_TARGETS_CANT)
        for _, v in ipairs(ents) do
            if v~=target and doer_combat:CanTarget(v) and not doer_combat:IsAlly(v)
                and not (v.components.health and v.components.health:IsDead()) then
                local tx,ty,tz = v.Transform:GetWorldPosition()        
                local drot = math.abs(angle - owner:GetAngleToPoint(tx,0,tz))
                while drot > 180 do
                    drot = drot - 360
                end
                
                if math.abs(drot) <= 70 and math.abs(sin_rot*(x-tx)+cos_rot*(z-tz))<=2 then
                    local dmg, spdmg = doer_combat:CalcDamage(v, inst)
                    v.components.combat:GetAttacked(owner, dmg, inst, nil, spdmg)
                end    
            end
        end
        
        if  inst.buff_stacks== 2 or inst.buff_stacks==4 then
            summon_star(inst,owner,target)
        elseif inst.buff_stacks== 6 then
            summon_star(inst,owner,target)
            --inst:DoChop(owner,target:GetPosition())
            reset_stacks(inst)
            --inst:AddTag("allow_chop")
        end            
    end
end

local function onequip(inst, owner)
    owner.AnimState:OverrideSymbol("swap_object", "swap_sword_ancient", "swap_sword_ancient")
    owner.AnimState:Show("ARM_carry")
    owner.AnimState:Hide("ARM_normal")
    inst.buff_stacks = 0
end

local function onunequip(inst, owner)
    owner.AnimState:Hide("ARM_carry")
    owner.AnimState:Show("ARM_normal")
    inst.buff_stacks = 0
end




local function DoChop(inst,owner,pos)
    local fx = SpawnPrefab("sword_ancient_fx")

    fx.Transform:SetPosition(owner.Transform:GetWorldPosition())
    local rot = owner:GetAngleToPoint(pos)
    fx.Transform:SetRotation(rot)
    fx._owner=owner
    fx:Shoot(pos)
end

local function fn()
	local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("sword_ancient")
    inst.AnimState:SetBuild("sword_ancient")
    inst.AnimState:PlayAnimation("idle")
    
    inst:AddTag("mythical")
    inst:AddTag("sharp")
    inst:AddTag("nosteal")

    inst.itemtile_colour = RGB(218,165,32)

    MakeInventoryPhysics(inst)
	MakeInventoryFloatable(inst, "med", 0.05, {1.1, 0.5, 1.1}, true, -9)
    inst.triggerfx = net_bool(inst.GUID, "sword_ancient.shoot","sword_ancient_shoot")
    
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    
    inst:AddComponent("inventoryitem")

    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(150)
    inst.components.weapon:SetRange(14)
    inst.components.weapon:SetOnAttack(onattack)

    local planardamage = inst:AddComponent("planardamage")
	planardamage:SetBaseDamage(100)
    --inst:AddComponent("finiteuses")

    inst:AddComponent("equippable")
    inst.components.equippable:SetOnEquip(onequip)
    inst.components.equippable:SetOnUnequip(onunequip)
    inst.components.equippable.walkspeedmult = 1.2

    --inst:AddComponent("move_attack")
    MakeHauntableLaunch(inst)

    inst.DoChop = DoChop

    return inst

end

local HARVEST_MUSTTAGS  = {"_combat"}
local HARVEST_CANTTAGS  = {"INLIMBO", "FX","player"}


local function CheckForHit(inst)
    local x, y, z = inst.Transform:GetWorldPosition()

    if inst._owner==nil then
        inst:Remove()
    end
    local doer_combat=inst._owner.components.combat
    local ents = TheSim:FindEntities(x, y, z, 6, HARVEST_MUSTTAGS, HARVEST_CANTTAGS, nil)
    for _, ent in pairs(ents) do
        if ent:IsValid() 
            and doer_combat:CanTarget(ent) and not doer_combat:IsAlly(ent)
            and not (ent.components.health and ent.components.health:IsDead()) then
            ent.components.combat:GetAttacked(inst._owner, 200, nil, nil, {["planar"]=200})   
        end
    end
end

local function OnHit(inst)
    inst.HasHit=true
    inst.Physics:Stop()
    inst:DoTaskInTime(4,inst.Remove)
end

local function Shoot(inst,pos)
    local dist_sq = inst:GetDistanceSqToPoint(pos.x,0,pos.z)
    if dist_sq< 4 then
        CheckForHit(inst)
        OnHit(inst)
    else
        local speed = math.max(4, 2*math.sqrt(dist_sq))
        inst.pos = pos
        inst.Physics:SetMotorVel(speed,0,0)
        inst:DoTaskInTime(0.5, function ()
            inst.Physics:Stop()
            OnHit(inst)
        end)
    end
    inst:DoPeriodicTask(0.2, CheckForHit)    
end



local function fxfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeProjectilePhysics(inst)
    inst.Physics:ClearCollidesWith(COLLISION.LIMITS)

    inst.AnimState:SetBank("sword_ancient")
    inst.AnimState:SetBuild("sword_ancient")
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")
    --inst.AnimState:SetLightOverride(.3)
    inst.AnimState:PlayAnimation("spin",true)

    inst.AnimState:SetAddColour(1,215/255,0,0.5)
    inst.AnimState:SetOrientation(1)
    inst.AnimState:SetScale(2,2,2)
    
    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false
    inst.Shoot = Shoot
    


    return inst
end

local function onhit(inst, attacker)

    local x,y,z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 2, {"_combat"}, { "INLIMBO", "brightmare","flight", "invisible", "notarget", "noattack"})
    for i, v in ipairs(ents) do
        if v:IsValid() and v.components.health ~= nil and not v.components.health:IsDead() then
            v:AddDebuff("buff_mooncurse","buff_mooncurse")
            v.components.combat:GetAttacked(attacker,200,nil,nil,{["planar"] = 40})
        end
    end

    inst:Remove()
end

local function projfn()
    local inst = CreateEntity()
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeProjectilePhysics(inst)
    inst.Physics:ClearCollidesWith(COLLISION.LIMITS)

    inst.AnimState:SetBank("sword_ancient")
    inst.AnimState:SetBuild("sword_ancient")
    inst.AnimState:PlayAnimation("shoot")
    inst.AnimState:SetScale(1.5,1.5,1.5)
    inst.AnimState:SetOrientation(ANIM_ORIENTATION.OnGround)

    inst.AnimState:SetLightOverride(0.3)
    inst.AnimState:SetBloomEffectHandle("shaders/anim.ksh")

    inst.AnimState:SetAddColour(1, 1, 1, 0)
    
    inst:AddTag("FX")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst.persists = false

    inst:AddComponent("linearprojectile")
    inst.components.linearprojectile:SetHorizontalSpeed(25)
    inst.components.linearprojectile:SetRange(30)
    inst.components.linearprojectile:SetOnHit(onhit)
    inst.components.linearprojectile:SetOnMiss(inst.Remove)
    inst.components.linearprojectile.hitdist = 1 
    inst.components.linearprojectile:AddNoHitTag("deity")

    inst:DoTaskInTime(1,inst.Remove)


    return inst
end


return Prefab( "sword_ancient", fn,assets),
    Prefab("sword_ancient_fx",fxfn,assets),
    Prefab("sword_ancient_proj",projfn,assets)
    