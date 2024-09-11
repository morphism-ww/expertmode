local function onopen(inst)
    inst.AnimState:PlayAnimation("open")
    inst.SoundEmitter:PlaySound("dontstarve/common/wardrobe_open")
end

local function onclose(inst)
    inst.AnimState:PlayAnimation("closed")
    inst.SoundEmitter:PlaySound("dontstarve/common/wardrobe_close")
end


local function onhammered(inst)
    if inst.components.burnable ~= nil and inst.components.burnable:IsBurning() then
        inst.components.burnable:Extinguish()
    end
    inst.components.lootdropper:DropLoot()
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
    end
    --close it
    local fx = SpawnPrefab("collapse_big")
    fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
    fx:SetMaterial("wood")
    inst:Remove()
end

local function onhit(inst)
    if not inst:HasTag("burnt") then
        inst.AnimState:PlayAnimation("hit")
        inst.AnimState:PushAnimation("closed", false)
        inst.SoundEmitter:PlaySound("dontstarve/common/wardrobe_hit")
    end
    if inst.components.container ~= nil then
        inst.components.container:DropEverything()
        inst.components.container:Close()
    end
    if inst.components.wardrobe ~= nil then
        inst.components.wardrobe:EndAllChanging()
    end
end

local containerdata = {
    widget =
    {
        slotpos = {},
        animbank = "ui_fish_box_5x4",
        animbuild = "ui_fish_box_5x4",
        pos = Vector3(0, 220, 0),
        side_align_tip = 160,
    },
    type = "chest",
    itemtestfn = CheckWardrobeItem,
}



AddPrefabPostInit("wardrobe",function(inst)
    inst:AddTag("dressable")
    
    
    if not TheWorld.ismastersim then
		return inst
	end

	inst:AddComponent("container")
    inst.components.container:WidgetSetup("wardrobe")
    inst.components.container.skipclosesnd = true
    inst.components.container.skipopensnd = true
    inst.components.container.onopenfn = onopen
    inst.components.container.onclosefn = onclose


    inst.components.workable:SetOnFinishCallback(onhammered)
    inst.components.workable:SetOnWorkCallback(onhit)
    

end)

local function CheckWardrobeItem(container, item, slot)
    return item:HasTag("_equippable")
end


local params = require("containers").params
params["wardrobe"] =
{
    widget =
    {
        slotpos = {},
        animbank = "ui_fish_box_5x4",
        animbuild = "ui_fish_box_5x4",
        pos = Vector3(0, 220, 0),
        side_align_tip = 160,
    },
    type = "chest",
    itemtestfn = CheckWardrobeItem,
}

for y = 2.5, -0.5, -1 do
    for x = -1, 3 do
        table.insert(params.wardrobe.widget.slotpos, Vector3(75 * x - 75 * 2 + 75, 75 * y - 75 * 2 + 75, 0))
    end
end
