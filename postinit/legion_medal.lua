if GetModConfigData("legion_medal") then
    AddRecipePostInit("siving_feather_real",function (self)
        table.insert(self.ingredients,Ingredient("cs_infused_iron",1))
    end)

    AddRecipePostInit("siving_soil_item",function (self)
        table.insert(self.ingredients,Ingredient("cs_waterdrop",1))
    end)
    AddRecipePostInit("siving_mask_gold",function (self)
        table.insert(self.ingredients,Ingredient("cs_iron",2))
    end)
end

AddComponentPostInit("projectilelegion",function (self)
    self.inst:AddTag("projectile")
    self.inst:AddTag("s_l_throw")
end)