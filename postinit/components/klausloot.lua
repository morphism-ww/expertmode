AddComponentPostInit("klaussackloot", function(KlausSackLoot)
    local giant_loot1 =
    {
    "deerclops_eyeball",
    "dragon_scales",
    "hivehat",
    "shroom_skin",
    }

    local giant_loot2 =
    {
    "dragonflyfurnace_blueprint",
    "red_mushroomhat_blueprint",
    "green_mushroomhat_blueprint",
    "blue_mushroomhat_blueprint",
    "mushroom_light2_blueprint",
    "mushroom_light_blueprint",
    "townportal_blueprint",
    "bundlewrap_blueprint",
    "trident_blueprint",
    }

    local giant_loot3 =
    {
    "bearger_fur",
    "lavae_egg",
    "greengem",
    "malbatross_beak",
    }
    local giant_loot4 =
    {
    "lightninggoathorn",
    "staff_tornado",
    "mandrake",
    "tallbirdegg",
    }
    local boss_ornaments =
    {
    "winter_ornament_boss_klaus",
    "winter_ornament_boss_noeyeblue",
    "winter_ornament_boss_noeyered",
    "winter_ornament_boss_krampus",
    }

    local function FillItems(items, prefab)
    for i = 1 + #items, math.random(3, 4) do
        table.insert(items, prefab)
    end
    end
    function KlausSackLoot:RollKlausLoot()
        --WINTERS FEAST--
        self.wintersfeast_loot = {}

        local rnd = math.random(3)
        local items = {
            boss_ornaments[math.random(#boss_ornaments)],
            GetRandomFancyWinterOrnament(),
            GetRandomLightWinterOrnament(),
            ((rnd == 1 and GetRandomLightWinterOrnament()) or (rnd == 2 and GetRandomFancyWinterOrnament()) or GetRandomBasicWinterOrnament()),
        }
        table.insert(self.wintersfeast_loot, items)

        items = {
            "goatmilk",
            "goatmilk",
            {"winter_food"..tostring(math.random(2)), 4},
        }
        table.insert(self.wintersfeast_loot, items)

        --WINTERS FEAST--
        self.loot = {}

        items = {}
        table.insert(items, "amulet")
        table.insert(items, "goldnugget")
        FillItems(items, "charcoal")
        table.insert(self.loot, items)

        items = {}
        if math.random() < .5 then
            table.insert(items, "yellowamulet")
        end
        if math.random()< .75 then
            FillItems(items, "bluegem")
        else
            FillItems(items, "yellowgem")
        end

        table.insert(self.loot, items)

        items = {}
        if math.random() < .5 then
            table.insert(items, "krampus_sack")
        end
        table.insert(items, "goldnugget")
        FillItems(items, "charcoal")
        table.insert(self.loot, items)

        items = {}

        table.insert(items, giant_loot1[math.random(#giant_loot1)])
        table.insert(items, giant_loot2[math.random(#giant_loot2)])
        table.insert(items, giant_loot3[math.random(#giant_loot3)])
        table.insert(items, giant_loot4[math.random(#giant_loot4)])
        table.insert(self.loot, items)
    end
    KlausSackLoot:RollKlausLoot()
end)



--[[AddComponentPostInit("stewer",function (self)
    local cooking = require("cooking")
    local function dospoil(inst, self)
        self.task = nil
        self.targettime = nil
        self.spoiltime = nil
    
        if self.onspoil ~= nil then
            self.onspoil(inst)
        end
    end
    
    local function dostew(inst, self)
        self.task = nil
        self.targettime = nil
        self.spoiltime = nil
    
        if self.ondonecooking ~= nil then
            self.ondonecooking(inst)
        end
    
        if self.product == self.spoiledproduct then
            if self.onspoil ~= nil then
                self.onspoil(inst)
            end
        elseif self.product ~= nil then
            local recipe = cooking.GetRecipe(inst.prefab, self.product)
            local prep_perishtime = (recipe ~= nil and (recipe.cookpot_perishtime or recipe.perishtime)) or 0
            if prep_perishtime > 0 then
                local prod_spoil = self.product_spoilage or 1
                self.spoiltime = prep_perishtime * prod_spoil
                self.targettime =  GetTime() + self.spoiltime
                self.task = self.inst:DoTaskInTime(self.spoiltime, dospoil, self)
            end
        end
    
        self.done = true
    end

    local function tryconsume(self, v, amount)
        if v.components.stackable == nil then
            self:RemoveItem(v):Remove()
            return 1
        elseif v.components.stackable.stacksize > amount then
            v.components.stackable:SetStackSize(v.components.stackable.stacksize - amount)
            return amount
        else
            amount = v.components.stackable.stacksize
            self:RemoveItem(v, true):Remove()
            return amount
        end
    end

    local OldStartCooking = self.StartCooking
    function self:StartCooking(doer)

        if self.upgraded then
            if self.targettime == nil and self.inst.components.container ~= nil then
                self.chef_id = (doer ~= nil and doer.player_classified ~= nil) and doer.userid
                self.ingredient_prefabs = {}

                self.done = nil
                self.spoiltime = nil

                if self.onstartcooking ~= nil then
                    self.onstartcooking(self.inst)
                end
                
                local container = self.inst.components.container
                local num_to_give = container.slots[1].components.stackable and container.slots[1].components.stackable:StackSize() or 1
                for k, v in pairs (container.slots) do
                    
                    num_to_give = math.min(num_to_give , v.components.stackable and v.components.stackable:StackSize() or 1)

                    table.insert(self.ingredient_prefabs, v.prefab)
                end
                

                local cooktime = 1
                self.product, cooktime = cooking.CalculateRecipe(self.inst.prefab, self.ingredient_prefabs)
                local productperishtime = cooking.GetRecipe(self.inst.prefab, self.product).perishtime or 0
                
                local loot = SpawnPrefab(self.product)
                self.num_to_give = loot.components.stackable and num_to_give or 1
                loot:Remove()

                if productperishtime > 0 then
                    local spoilage_total = 0
                    local spoilage_n = 0
                    for k, v in pairs (container.slots) do
                        if v.components.perishable ~= nil then
                            spoilage_n = spoilage_n + 1
                            spoilage_total = spoilage_total + v.components.perishable:GetPercent()
                        end
                    end
                    self.product_spoilage =
                        (spoilage_n <= 0 and 1) or
                        (self.keepspoilage and spoilage_total / spoilage_n) or
                        1 - (1 - spoilage_total / spoilage_n) * .5
                else
                    self.product_spoilage = nil
                end

                cooktime = TUNING.BASE_COOK_TIME * cooktime * self.cooktimemult
                self.targettime = GetTime() + cooktime
                if self.task ~= nil then
                    self.task:Cancel()
                end
                self.task = self.inst:DoTaskInTime(cooktime, dostew, self)

                container:Close()
                for k, v in pairs(container.slots) do
                    tryconsume(container, v, num_to_give)
                end
                container.canbeopened = false
            end
        else
            OldStartCooking(self,doer)
        end    
    end

    
    function self:Harvest(harvester)
        if self.done then
            if self.onharvest ~= nil then
                self.onharvest(self.inst)
            end
    
            if self.product ~= nil then
                local loot = SpawnPrefab(self.product)
                if loot ~= nil then
                    local recipe = cooking.GetRecipe(self.inst.prefab, self.product)
    
                    if harvester ~= nil and
                        self.chef_id == harvester.userid and
                        recipe ~= nil and
                        recipe.cookbook_category ~= nil and
                        cooking.cookbook_recipes[recipe.cookbook_category] ~= nil and
                        cooking.cookbook_recipes[recipe.cookbook_category][self.product] ~= nil then
                        harvester:PushEvent("learncookbookrecipe", {product = self.product, ingredients = self.ingredient_prefabs})
                    end
                    
                    local actual_consume = 1

                    if loot.components.stackable then
                        actual_consume = (recipe and recipe.stacksize or 1)* (self.num_to_give or 1)
                        loot.components.stackable:SetStackSize(actual_consume)
                    end    

                    self.num_to_give = 1
    
                    if self.spoiltime ~= nil and loot.components.perishable ~= nil then
                        local spoilpercent = self:GetTimeToSpoil() / self.spoiltime
                        loot.components.perishable:SetPercent(self.product_spoilage * spoilpercent)
                        loot.components.perishable:StartPerishing()
                    end
                    if harvester ~= nil and harvester.components.inventory ~= nil then
                        harvester.components.inventory:GiveItem(loot, nil, self.inst:GetPosition())
                    else
                        LaunchAt(loot, self.inst, nil, 1, 1)
                    end
                end
                self.product = nil
            end
    
            if self.task ~= nil then
                self.task:Cancel()
                self.task = nil
            end
            self.targettime = nil
            self.done = nil
            self.spoiltime = nil
            self.product_spoilage = nil
    
            if self.inst.components.container ~= nil then
                self.inst.components.container.canbeopened = true
            end
    
            return true
        end
    end
end)]]


