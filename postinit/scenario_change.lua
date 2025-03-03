local chest_scenario = require("scenarios/chest_labyrinth")
chest_scenario.OnCreate = function (inst, scenariorunner)

	local items =
	{
		{
			--Body Items
			item = {"armorruins", "ruinshat"},
			chance = 0.15,
			initfn = function(item) item.components.armor:SetCondition(math.random(item.components.armor.maxcondition * 0.7, item.components.armor.maxcondition * 1)) end,
		},
		{
			--Weapon Items
			item = {"ruins_bat","multitool_axe_pickaxe"},
			chance = 0.2,
			initfn = function(item) item.components.finiteuses:SetUses(math.random(item.components.finiteuses.total * 0.7, item.components.finiteuses.total * 0.9)) end,
		},
		{
			item = {"nightmarefuel","thulecite"},
			count = math.random(8, 14),
			chance = 0.2,
		},
		{
			item = {"redgem", "bluegem", "purplegem"},
			count = math.random(3,5),
			chance = 0.2,
		},
		{         
			item = {"orangestaff","greenstaff","yellowstaff"},
			chance = 0.1,
			initfn = function(item)
				local finiteuses = item.components.finiteuses
				if finiteuses~=nil then
					finiteuses:SetUses(math.random(0.3 * finiteuses.total, 0.5 * finiteuses.total))
				end
			end,
		},
		{
			item = {"yellowgem", "orangegem", "greengem"},
			count = math.random(2,3),
			chance = 0.2,
		},
		{
			item = {"greenamulet","orangeamulet","yellowamulet"},
			chance = 0.08,
		},
		{
			--Staff Items
			item = {"firestaff", "icestaff","telestaff"},
			chance = 0.1,
		},
		{
			item = {"maze_key"},
			count = math.random(1,2),
			chance = 0.02,
		},
	}

	chestfunctions.AddChestItems(inst, items)
end


require("scenarios/chest_labyrinth_mimic").OnCreate = function(inst, scenariorunner)
local MIMIC_CHANCE = 0.33
local items =
{
	{
		--Body Items
		item = {"armorruins", "ruinshat"},
		chance = 0.15,
		initfn = function(item)
			local armor = item.components.armor
			armor:SetCondition(math.random(0.33 * armor.maxcondition, 0.80 * armor.maxcondition))

			if math.random() < MIMIC_CHANCE then
				item:AddComponent("itemmimic")
			end
		end,
	},
	{
		--Weapon Items
		item = {"ruins_bat","multitool_axe_pickaxe"},
		chance = 0.2,
		initfn = function(item)
			local finiteuses = item.components.finiteuses
			finiteuses:SetUses(math.random(0.33 * finiteuses.total, 0.80 * finiteuses.total))

			if math.random() < MIMIC_CHANCE then
				item:AddComponent("itemmimic")
			end
		end,
	},
	{
		item = "nightmarefuel",
		count = math.random(1, 3),
		chance = 0.2,
	},
	{
		item = {"redgem", "bluegem", "purplegem"},
		count = math.random(1,2),
		chance = 0.15,
	},
	{
		item = "thulecite_pieces",
		count = math.random(2, 4),
		chance = 0.2,
	},
	{
		item = "thulecite",
		count = math.random(1, 3),
		chance = 0.1,
	},
	{
		item = {"yellowgem", "orangegem", "greengem"},
		count = 1,
		chance = 0.07,
	},
	{
		--Weapon Items
		item =  {"greenstaff","yellowstaff","orangestaff"},
		chance = 0.05,
		initfn = function(item)
			local finiteuses = item.components.finiteuses
			if finiteuses~=nil then
				finiteuses:SetUses(math.random(0.3 * finiteuses.total, 0.5 * finiteuses.total))
			end
			

			if math.random() < MIMIC_CHANCE then
				item:AddComponent("itemmimic")
			end
		end,
	},
	{
		--Weapon Items
		item = {"firestaff", "icestaff","telestaff"},
		chance = 0.05,
		initfn = function(item)
			local finiteuses = item.components.finiteuses
			if finiteuses then
				finiteuses:SetUses(math.random(0.3 * finiteuses.total, 0.5 * finiteuses.total))
			end

			if math.random() < MIMIC_CHANCE then
				item:AddComponent("itemmimic")
			end
		end,
	},
	{
		item = {"constant_medal"},
		count = math.random(1,2),
		chance = 0.03,
	},
	}

	chestfunctions.AddChestItems(inst, items)
end


local function AbleToAcceptTest(inst, item, giver)
    if item.prefab ~= "shadow_soul" then
        return false, "TERRARIUM_REFUSE"
    else
        inst.trader = giver
        return true
    end
end

local SPAWN_OFFSET = 10
local function ItemGet(inst, giver, item)
    inst:AddTag("NOCLICK")
    inst:RemoveComponent("trader")
    if inst._summoning_fx == nil then
        inst._summoning_fx = SpawnPrefab("terrarium_fx")
        inst._summoning_fx.entity:SetParent(inst.entity)
        inst._summoning_fx.AnimState:PlayAnimation("activate_fx")
        inst._summoning_fx.AnimState:PushAnimation("activated_idle_fx", true)
    end
    inst.SoundEmitter:PlaySound("terraria1/terrarium/beam_shoot")
    inst:DoTaskInTime(10,function (inst)
        if AllPlayers ~= nil and #AllPlayers > 0 then
            local targeted_player = inst.trader or AllPlayers[math.random(#AllPlayers)]
    
    
            local angle = math.random() * TWOPI
            local player_pt = targeted_player:GetPosition()
            local spawn_offset = FindWalkableOffset(player_pt, angle, SPAWN_OFFSET, nil, false, true, nil, true, true)
                or Vector3(SPAWN_OFFSET * math.cos(angle), 0, SPAWN_OFFSET * math.sin(angle))
            local spawn_position = player_pt + spawn_offset

            local calamita = SpawnPrefab("calamityeye")
            calamita.Transform:SetPosition(spawn_position:Get())    -- Needs to be done so the spawn fx spawn in the right place
            calamita.sg:GoToState("arrive")
            calamita.components.combat:SetTarget(targeted_player)
            
            
        end
        if inst._summoning_fx ~= nil then
            inst._summoning_fx.AnimState:PlayAnimation("deactivate_fx")
            inst._summoning_fx:DoTaskInTime(0.2, inst._summoning_fx.Remove)
            inst._summoning_fx = nil
    
            inst.SoundEmitter:PlaySound("terraria1/terrarium/beam_stop")
        end
        inst:Remove()
    end)
end

newcs_env.AddPrefabPostInit("chesspiece_twinsofterror",function (inst)
    inst:AddTag("trader")
    inst:AddTag("alltrader")
    if not TheWorld.ismastersim then
        return
    end
    inst:AddComponent("trader")
    inst.components.trader:SetAbleToAcceptTest(AbleToAcceptTest)
    inst.components.trader.onaccept = ItemGet
    inst.components.trader.acceptnontradable = true
end)