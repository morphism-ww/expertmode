local function ObsidianToolHitWater(inst)
    inst.components.obsidiantool:SetCharge(0)
end

local function SpawnObsidianLight(inst)
    local owner = inst.components.inventoryitem.owner
    inst._obsidianlight = inst._obsidianlight or SpawnPrefab("obsidiantoollight")
    inst._obsidianlight.entity:SetParent((owner or inst).entity)
end

local function RemoveObsidianLight(inst)
    if inst._obsidianlight ~= nil then
        inst._obsidianlight:Remove()
        inst._obsidianlight = nil
    end
end

local function ChangeObsidianLight(inst, old, new)
    local percentage = new / inst.components.obsidiantool.maxcharge
    local rad = Lerp(1, 2.5, percentage)

    if percentage >= inst.components.obsidiantool.yellow_threshold then
        SpawnObsidianLight(inst)

        if percentage >= inst.components.obsidiantool.red_threshold then
            inst._obsidianlight.Light:SetColour(254/255,98/255,75/255)
            inst._obsidianlight.Light:SetRadius(rad)
            inst._obsidianlight:AddTag("fire")
        elseif percentage >= inst.components.obsidiantool.orange_threshold then
            inst._obsidianlight.Light:SetColour(255/255,159/255,102/255)
            inst._obsidianlight.Light:SetRadius(rad)
            inst._obsidianlight:RemoveTag("fire")
        else
            inst._obsidianlight.Light:SetColour(255/255,223/255,125/255)
            inst._obsidianlight.Light:SetRadius(rad)
            inst._obsidianlight:RemoveTag("fire")
        end
    else
        RemoveObsidianLight(inst)
    end
end

local function ManageObsidianLight(inst)
    local cur, max = inst.components.obsidiantool:GetCharge()
    if cur / max >= inst.components.obsidiantool.yellow_threshold then
        SpawnObsidianLight(inst)
    else
        RemoveObsidianLight(inst)
    end
end

function MakeObsidianTool(inst, tooltype)
    inst:AddTag("obsidian")
    

    if inst.components.floatable then
        inst.components.floatable:SetOnHitWaterFn(function()
            inst.components.obsidiantool:SetCharge(0)
        end)
    end
    inst:AddComponent("temperature")
    inst:AddComponent("obsidiantool")
    inst.components.obsidiantool.tool_type = tooltype

    inst.components.obsidiantool.onchargedelta = ChangeObsidianLight

    inst:ListenForEvent("equipped", ManageObsidianLight)
    inst:ListenForEvent("onputininventory", ManageObsidianLight)
    inst:ListenForEvent("ondropped", ManageObsidianLight)
    inst:ListenForEvent("floater_startfloating", ObsidianToolHitWater)
end

local function giveprotect(inst,data)
	if data.owner.isplayer then
		data.owner._stunprotecter:SetModifier(inst, true)
	end
end

local function removeprotect(inst,data)
	if data.owner.isplayer then
		data.owner._stunprotecter:RemoveModifier(inst)
	end
end

function MakeStunProtectArmor(inst)
    inst:ListenForEvent("equipped",giveprotect)
    inst:ListenForEvent("unequipped",removeprotect)
end


function MakePlayerOnlyTarget(inst)
    inst.components.combat:AddNoAggroTag("epic")
    if inst.components.damagetyperesist==nil then
        inst:AddComponent("damagetyperesist")
    end
    inst.components.damagetyperesist:AddResist("epic", inst, 0)
end

function Metric2(x0,z0,x1,z1)
    local dx = x0-x1
    local dz = z0-z1
    return dx*dx + dz*dz
end


function ExtendInDirAndFindLand(pos,theta,radius)
    local cos_theta = math.cos(theta)
    local sin_theta = math.sin(theta)
    local gap = radius/6
    for i = 0,6 do
        local x = pos.x + (radius-gap*i)*cos_theta
        local z = pos.z - (radius-gap*i)*sin_theta
        if TheWorld.Map:IsAboveGroundAtPoint(x, 0, z) or (TheWorld.Map:GetPlatformAtPoint(x,z) ~= nil) then
            return x,z
        end
    end
    return pos.x,pos.z
end

local function replaceValueInList(t, oldval,val)
    for k, v in ipairs(t) do
        if v == oldval then
            t[k] = val
        end
    end
    return nil  -- 如果未找到，返回 nil
end

function c_resetcavetags()
    local topology = TheWorld.topology
    if topology and topology.nodes then
        print ("Retrofitting for new map tags")
        for k,node in ipairs(topology.nodes) do
            if node.tags~=nil then
                replaceValueInList(node.tags,"DarkLand","notele")
                if topology.ids[k] == "BOSSRUSH:0:Void_Land" then
                    node.tags = {"notele"} 
                end
            end
        end
    end
end

function c_killbossrush()
    if TheWorld.components.voidland_manager~=nil then
        local manager = TheWorld.components.voidland_manager.manager
        if manager~=nil then
            manager:KillProgram()
            manager:DebugResetTime()
            c_announce("bossrush已关闭并清空进程")
            return
        else
            c_announce("出现未知错误，bossrush管理器丢失，请重置洞穴")
        end
    else
        c_announce("当前世界不存在bossrush")
    end
end

---玩家AOE
P_AOE_TARGETS_MUST = { "_combat" }
P_AOE_TARGETS_CANT = { "INLIMBO", "invisible", "noattack", "notarget", "playerghost","flight","player","companion","wall" }


local function IgnoreTrueDamage(inst, amount, overtime, cause, ignore_invincible, afflicter, ignore_absorb)
	return amount<0 and not (afflicter~=nil and afflicter.entity:HasAnyTag("_combat","projectile") or overtime)
end

---绝对无敌帧，受击上限，真伤抵抗
function MakeHitstunAndIgnoreTrueDamageEnt(inst)
    inst.components.health.disable_penalty = true
    inst.legiontag_ban_undefended = true
    inst.components.combat.hit_stuntime = 0.1
    --inst.components.health.redirect = IgnoreTrueDamage
end

local function RegisterAttacker(inst,data)
    if data.attacker~=nil then
        inst._attackertrack[data.attacker] = GetTime()
    end
end

local function CanDodge(inst,attacker)
    local last_hit_time = inst._attackertrack[attacker]
    if last_hit_time then
        return (GetTime() < 0.1 + last_hit_time)
    end
    return false
end

---独立无敌帧
function MakeSmartAbsorbDamageEnt(inst)
    inst.components.health.disable_penalty = true
    inst.legiontag_ban_undefended = true
    inst._attackertrack = {}

    inst:AddComponent("attackdodger")
    inst.components.attackdodger:SetCanDodgeFn(CanDodge)

    inst:ListenForEvent("attacked",RegisterAttacker)
end



function IsEntInAbyss(inst)
    if inst==nil or not inst:IsValid() then
        return false
    end
    local x,y,z = inst.Transform:GetWorldPosition()
    return TheWorld.Map:NodeAtPointHasTag(x, y, z, "Abyss")
end

local function ForceDropEverything(self)
    if self.activeitem ~= nil then
        self:DropItem(self.activeitem, true, true)
        self:SetActiveItem(nil)
    end

    for k = 1, self.maxslots do
        local v = self.itemslots[k]
        if v ~= nil and not v.components.curseditem then
            self:DropItem(v, true, true)
        end
    end

    
    if self.inst.EmptyBeard ~= nil then
        self.inst:EmptyBeard()
    end

    for k, v in pairs(self.equipslots) do
        self:DropItem(v, true, true)
    end
    
end

local function ForceDeath(player)
    if not player.entity:IsValid() then
        return
    end
    if player.components.inventory ~= nil then
        ForceDropEverything(player.components.inventory)
    end
    if not IsEntityDeadOrGhost(player) then
        player.components.health:SetMinHealth(0)
        
        player.components.health:DeltaPenalty(0.7)
        player:PushEvent("death",{cause = "abyss_curse"})
    end
end

--强制死亡
function AbyssForceDeath(player)
    player.__abyssdeathtask = player:DoPeriodicTaskWithLimit(3,ForceDeath,1,30) 
    print(player.components.abysscurse:GetDebugString())
end


function FindRandomPointInNode(polygon, centroid)

    return function ()
        local p1_idx = math.random(1, #polygon)
        local p2_idx = p1_idx + 1
        if p2_idx > #polygon then
            p2_idx = 1
        end

        local v0 = { x = polygon[p1_idx][1] - centroid[1], y = polygon[p1_idx][2] - centroid[2]}
        local v2 = { x = polygon[p2_idx][1] - centroid[1], y = polygon[p2_idx][2] - centroid[2]}

        -- u = random [0-1]
        local u = math.random()

        -- v = random [0-1]
        local v =  math.random()

        -- u+v < 1
        if u + v > 1 then
            u = 1-u
            v = 1-v
        end

        -- P = centroid + u*v0 + v*v2
        --local p = {centroid[1] + v0.x*u + v2.x*v, centroid[2] + v0.y*u + v2.y*v}
        -- The consumer of this is expecting relative positions
        return centroid[1]+ v0.x*u + v2.x*v, centroid[2] + v0.y*u + v2.y*v
    end
end


function MakeForgeRepairable2(inst,  onbroken, onrepaired)
	local function _onbroken(inst)
		if inst.components.equippable ~= nil and inst.components.equippable:IsEquipped() then
			local owner = inst.components.inventoryitem.owner
			if owner ~= nil and owner.components.inventory ~= nil then
				local item = owner.components.inventory:Unequip(inst.components.equippable.equipslot)
				if item ~= nil then
					owner.components.inventory:GiveItem(item, nil, owner:GetPosition())
				end
			end
		end
		if onbroken ~= nil then
			onbroken(inst)
		end		
	end
  
    
	if inst.components.finiteuses ~= nil then
		inst.components.finiteuses:SetOnFinished(_onbroken)
	
    elseif inst.components.armor ~= nil then
		inst.components.armor:SetKeepOnFinished(true)
		inst.components.armor:SetOnFinished(_onbroken)
    end
    inst:ListenForEvent("u_repaired",onrepaired)
end

