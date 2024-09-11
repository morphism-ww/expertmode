local assets =
    {
        Asset("ANIM", "anim/fx_book_light.zip")
    }


local DAMAGE_CANT_TAGS = { "brightmareboss", "brightmare", "playerghost", "INLIMBO", "DECOR", "FX","deity" ,"moonglass"}
local DAMAGE_ONEOF_TAGS = { "_combat", "pickable", "NPC_workable", "CHOP_workable", "HAMMER_workable", "MINE_workable", "DIG_workable" }

local function DoEraser(inst, target)
    if target.components.inventory~=nil then
        for k, v in pairs(target.components.inventory.equipslots) do
            if v.components.finiteuses ~= nil then
                v.components.finiteuses:SetUses(0)
            end
            if v.components.fueled~=nil then
                v.components.fueled:MakeEmpty()
            end
            if v.components.perishable~=nil then
                v.components.perishable:Perish()
            end
        end
    end
    if target.components.burnable~=nil then
        target.components.burnable:Ignite()
    end
    inst.components.truedamage:SetBaseDamage(10000)
    inst.components.combat:DoAttack(target)

    --target.components.health:DoDelta(-100000,false,inst.prefab,true,nil,true)
    --target.components.health:SetVal(0,inst.prefab,inst)
    target.components.health:DeltaPenalty(0.4)
end

local function DoDamage(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, 0, z, 3, nil, DAMAGE_CANT_TAGS,DAMAGE_ONEOF_TAGS)
    for i, v in ipairs(ents) do
        if v:IsValid() and v.components.health ~= nil and not v.components.health:IsDead() then
            if v:HasTag("shadow_aligned") then
                v.components.health:Kill()
            elseif v:HasTag("player") then
                v.components.sanity:DoDelta(20)
                v:AddDebuff("moon_curse","moon_curse")
                v.components.inventory:ApplyDamage(200,inst)
                inst.components.combat:DoAttack(v)
            else
                v.components.health:DoDelta(-1000,false,inst.prefab,nil,inst,true)
            end
        end
        if v.components.workable ~= nil and
            v.components.workable:CanBeWorked() and
            v.components.workable.action ~= ACTIONS.NET then
            v.components.workable:Destroy(inst)
        end
    end
end

local function DoDamag2(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, 0, z, 5+2, { "_combat","_health"}, { "INLIMBO", "player", "wall" })
    for _, target in ipairs(ents) do
		if (target.components.health ~= nil and not target.components.health:IsDead()) and
        target.components.combat~=nil and inst.CASTER~=nil then
            local targetrange = 5 + target:GetPhysicsRadius(0.5)
            if target:GetDistanceSqToPoint(x,0,z) < targetrange*targetrange then
                target.components.health:DoDelta(-500,false,nil,nil,inst.CASTER)
            end    
		end
	end
end

local function terrarium_fx()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("fx_book_light")
    inst.AnimState:SetBuild("fx_book_light")
    inst.AnimState:PlayAnimation("play_fx")
    inst.AnimState:SetDeltaTimeMultiplier(0.5)
    --inst.AnimState:SetFinalOffset(-1)
    inst.AnimState:SetScale(4,4,4)

    inst:AddTag("FX")
    inst:AddTag("toughworker")


    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end
    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(50)
    inst.components.combat:SetRange(2)

    inst:AddComponent("truedamage")
    inst.components.truedamage:SetBaseDamage(15)

    inst:DoTaskInTime(0.7, DoDamage)
    inst:DoTaskInTime(0.9, DoDamage)
    inst.killer=false

    inst.DoEraser=DoEraser
    inst.persists = false

    inst:ListenForEvent("animover", function()
        inst:Remove()
    end)

    return inst
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    inst.AnimState:SetBank("fx_book_light")
    inst.AnimState:SetBuild("fx_book_light")
    inst.AnimState:PlayAnimation("play_fx")
    inst.AnimState:SetDeltaTimeMultiplier(0.5)
    --inst.AnimState:SetFinalOffset(-1)
    inst.AnimState:SetScale(4,4,4)

    inst.entity:AddLight()
    inst.Light:SetRadius(3)
    inst.Light:SetFalloff(0.3)
    inst.Light:SetIntensity(0.85)
    inst.Light:EnableClientModulation(true)
    inst.Light:SetColour(180/255, 195/255, 150/255)

    inst:AddTag("FX")

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end

    inst.CASTER=nil

    inst:DoTaskInTime(0.8, DoDamag2)
    inst:DoTaskInTime(0.9, DoDamag2)

    inst.persists = false

    inst:ListenForEvent("animover", function()
        inst:Remove()
    end)

    return inst
end

return Prefab("alter_light", terrarium_fx, assets),
    Prefab("small_alter_light",fn,assets)
