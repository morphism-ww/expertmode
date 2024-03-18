local assets =
    {
        Asset("ANIM", "anim/fx_book_light.zip")
    }

local function DoDamage(inst)
    local x, y, z = inst.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, 0, z, 3, nil, {"FX","playerghost","brightmareboss"},{"structure","character","epic","shadow_aligned","monster"})
    for i, v in ipairs(ents) do
        if v:IsValid() and v.components.health ~= nil then
            if v:HasTag("shadow_aligned") then
                v.components.health:Kill()
            elseif v:HasTag("player") then
                v.components.health:DoDelta(-20,false,"alterguardian_phase3",true,nil,true)
                inst.components.combat:DoAttack(v)
                v.components.sanity:DoDelta(30)
            else
                v.components.health:DoDelta(-1000,false,"alterguardian_phase3",true,nil,true)
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
    local ents = TheSim:FindEntities(x, 0, z, 3, { "_combat"}, { "INLIMBO", "player", "wall" })
    for _, target in ipairs(ents) do
		if (target.components.health ~= nil and not target.components.health:IsDead()) and
        target.components.combat~=nil and inst.CASTER~=nil then
			if target:HasTag("shadow_aligned") then
                target.components.health:DoDelta(-500,false,inst.CASTER)
            else
                target.components.health:DoDelta(-400,false,inst.CASTER)
            end
            target.components.combat:SuggestTarget(inst.CASTER)
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

    inst.entity:SetPristine()
    if not TheWorld.ismastersim then
        return inst
    end
    inst:AddComponent("combat")
    inst.components.combat:SetDefaultDamage(50)
    inst.components.combat:SetRange(2)

    inst:DoTaskInTime(0.7, DoDamage)
    inst:DoTaskInTime(1.2, DoDamage)
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
    inst.AnimState:SetScale(2.5,2.5,2.5)

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
    inst:DoTaskInTime(1.2, DoDamag2)
    inst:DoTaskInTime(1.5, DoDamag2)
    inst.persists = false

    inst:ListenForEvent("animover", function()
        inst:Remove()
    end)

    return inst
end

return Prefab("alter_light", terrarium_fx, assets),
    Prefab("small_alter_light",fn,assets)
