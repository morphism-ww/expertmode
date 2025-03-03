
local PLANT_MUST = {"lunarthrall_plant"}
local TARGET_MUST_TAGS = { "_combat", "character" }
local TARGET_CANT_TAGS = { "INLIMBO","lunarthrall_plant", "lunarthrall_plant_end" }
local function vine_addcoldness(vine, ...)
	local inst = vine.parentplant
	if inst ~= nil and inst:IsValid() then
		inst.components.freezable:AddColdness(...)
		return true
	end
	return false
end
local function Retarget(inst)
    --print("RETARGET")
    if not inst.no_targeting then
        local target = FindEntity(
            inst,
            TUNING.LUNARTHRALL_PLANT_RANGE,
            function(guy)
                local total = 0
                local x,y,z = inst.Transform:GetWorldPosition()

                if inst.tired then
                    return nil
                end

                local plants = TheSim:FindEntities(x,y,z, 15, PLANT_MUST)
                for i, plant in ipairs(plants)do
                    if plant ~= inst then
                        if plant.components.combat.target and plant.components.combat.target == guy then
                            total = total +1
                        end
                    end
                end
                if total < 8 then  ---- CS_CHANGE:3-->8
                    return inst.components.combat:CanTarget(guy)
                end
            end,
            TARGET_MUST_TAGS,
            TARGET_CANT_TAGS
        )

        if inst.vinelimit > 0 then
            if target and ( not inst.components.freezable or not inst.components.freezable:IsFrozen()) then

                local pos = inst:GetPosition()

                local theta = math.random()*TWOPI
                local radius = TUNING.LUNARTHRALL_PLANT_MOVEDIST
                local offset = Vector3(radius * math.cos( theta ), 0, -radius * math.sin( theta ))
                pos = pos + offset

                if TheWorld.Map:IsVisualGroundAtPoint(pos.x,pos.y,pos.z) then

                    local vine = SpawnPrefab("lunarthrall_plant_vine_end")
                    vine.Transform:SetPosition(pos.x,pos.y,pos.z)
                    vine.Transform:SetRotation(inst:GetAngleToPoint(pos.x, pos.y, pos.z))
    				vine.components.freezable:SetRedirectFn(vine_addcoldness)
                    vine.sg:RemoveStateTag("nub")
                    if inst.tintcolor then
                        vine.AnimState:SetMultColour(inst.tintcolor, inst.tintcolor, inst.tintcolor, 1)
                        vine.tintcolor = inst.tintcolor
                    end

    				inst.components.colouradder:AttachChild(vine)

                    vine.parentplant = inst
                    table.insert(inst.vines,vine)
                    inst.vinelimit = inst.vinelimit -1
                    inst:DoTaskInTime(0,function() vine:ChooseAction() end)

                    return target
                end
            end
        end
    end
end


newcs_env.AddPrefabPostInit("lunarthrall_plant", function(inst)
    inst:AddTag("noauradamage")
	if not TheWorld.ismastersim then
		return
    end
    inst.components.health.fire_damage_scale = 0
    inst.components.combat.targetfn = Retarget   --- 增加密集情况下的索敌能力
end)

newcs_env.AddPrefabPostInit("lunarthrall_plant_vine_end", function(inst)
    inst:AddTag("noauradamage")
	if not TheWorld.ismastersim then
		return
    end
    inst.components.health.fire_damage_scale = 0
end)
newcs_env.AddPrefabPostInit("lunarthrall_plant_vine", function(inst)
    inst:AddTag("noauradamage")
end)


local BLOCKER_MUST_TAGS = {"lunarthall_plant_blocker"}
local HUSK_MUST = {"lunarthrall_plant"}
local SCREEN_DIST_SQ = PLAYER_CAMERA_SEE_DISTANCE_SQ
local EXISTING_PLANT_SPACE = 30

newcs_env.AddComponentPostInit('lunarthrall_plantspawner',function (self)

    local function CheckForNoBlocker(ent)
        local x,y,z = ent.Transform:GetWorldPosition()
        return TheSim:CountEntities(x,y,z, 35, BLOCKER_MUST_TAGS)==0
    end

    function self:PushInvade()
        local plants = {}

        local herd
        if math.random()<0.5 then
            herd = self:FindHerd()
        end
        
        if not herd then
            -- MAYBE FIND SOME WILD PLANTS?
            local patch = self:FindWildPatch()
            if patch and #patch > 0 then
                for i,member in ipairs(patch)do
                    table.insert(plants,member)
                end
            else
                --"NOTHING FOUND THIS TIME"
                return
            end
        else
            --"ALL PLANTS IN HERD"
            for member, bool in pairs(herd.components.herd.members)do
                table.insert(plants,member)
            end
        end


        
        while #plants>0 do
            local random = math.random(1,#plants)
            local plant = plants[random]
            if plant then
                local eligable = CheckForNoBlocker(plant)

                    -- NO EXISTING PLANTS TOO CLOSE.
                local x,y,z = plant.Transform:GetWorldPosition()
                
                local ents = TheSim:FindEntities(x,y,z, 4, HUSK_MUST)
                if #ents > 0 then
                    eligable = false
                end
                table.remove(plants,random)
                if eligable then
                    self:InvadeTarget(plant)
                    return
                end
            end
        end    
    end
    

    function self:InvadeTarget(target)

        if target and target:IsValid() then
            if not CheckForNoBlocker(target) then
                return false
            end
            local x, y, z = target.Transform:GetWorldPosition()
            local visible = IsAnyPlayerInRangeSq(x, y, z, SCREEN_DIST_SQ)
           
            if visible then
                self:SpawnGestalt(target) -- spawn gestalt to invate on screen
            else
                self:SpawnPlant(target)--Invade Plant offscreen
            end
        end
    
    end

    function self:FindHerd()
        local choices = {}
        for i, herd in ipairs(self.plantherds)do
            if CheckForNoBlocker(herd) then
                table.insert(choices,herd)
            end
        end
        local num = 0
        local choice = {}
        for i, herd in ipairs(choices)do
            local count = 0
            for member, i in pairs(herd.components.herd.members) do
                local pt = Vector3(member.Transform:GetWorldPosition())
                local ents = TheSim:FindEntities(pt.x,pt.y,pt.z, EXISTING_PLANT_SPACE, HUSK_MUST)
                if #ents <= 0 then
                    if not member.lunarthrall_plant and
                        (not member.components.witherable or not member.components.witherable:IsWithered()) then
                        count = count +1
                    end
                end
            end

            if count > 0 then
                table.insert(choice,{herd=herd, count=count}) 
            end
        end

        table.sort(choice, function(a,b) return a.count > b.count end)

        if #choice > 0 then
            return choice[math.random(1,math.min(5, #choice))].herd
        end
    end
end)

