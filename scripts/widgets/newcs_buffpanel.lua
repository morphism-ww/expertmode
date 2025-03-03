local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/redux/templates"
local NineSlice = require "widgets/nineslice"
local Text = require "widgets/text"
local PopupDialogScreen = require "screens/popupdialog"
local ImageButton = require "widgets/imagebutton"

local newcs_buffpanel = Class(Widget, function(self, owner)
    Widget._ctor(self, "newcs_buffpanel")
    self.owner = owner

	--顶栏

	self.bar = self:AddChild(NineSlice("images/dialogrect_9slice.xml"))
    self.bar:SetHAnchor(0) -- 设置原点x坐标位置，0、1、2分别对应屏幕中、左、右
    self.bar:SetVAnchor(1)
	self.bar:SetSize(60,100)
	self.bar:SetPosition(-500,-100,0)
    self.bar:SetTooltip(STRINGS.UI.BUFFPANEL_TIP)
    local oldOnControl = self.bar.OnControl
    self.bar.OnControl = function (self,control, down)
        if self.focus and control == CONTROL_SECONDARY then
            if down then
                self:StartDrag()
            else
                self:EndDrag()
            end
        end    
        if oldOnControl then
            return oldOnControl(self,control,down)
        end
    end 
    
    

    self.bar.SetDragPosition = function(self,pos)
        --[[local pos
        if type(x) == "number" then
            pos = Vector3(x, y, z)
        else
            pos = x
        end]]
        
        local self_scale=self:GetScale()

        local newpos=self.p_startpos+(pos-self.m_startpos)/(self_scale.x)
        self:SetPosition(newpos)
    end

    self.bar.StartDrag = function(self)
        if not self.followhandler then
            local mousepos = TheInput:GetScreenPosition()
            self.m_startpos = mousepos--鼠标初始坐标
            self.p_startpos = self:GetPosition()--面板初始坐标
            self.followhandler = TheInput:AddMoveHandler(function(x,y)
                self:SetDragPosition(Vector3(x,y,0))
                if not Input:IsMouseDown(MOUSEBUTTON_RIGHT) then
                    self:EndDrag()
                end
            end)
            self:SetDragPosition(mousepos)
        end
    end

    self.bar.EndDrag = function(self)
        if self.followhandler then
            self.followhandler:Remove()
        end
        self.followhandler = nil
        self.m_startpos = nil
        self.p_startpos = nil
    end

    self.bar.SetBackgroundTint = function(self, r,g,b,a)
        for i=4,5 do
            self.elements[i]:SetTint(r,g,b,a)
        end
        self.mid_center:SetTint(r,g,b,a)
    end

    local r,g,b = unpack(UICOLOURS.BROWN_DARK)
    self.bar:SetBackgroundTint(r,g,b,0.3)

    local function DestItemCtor(content, index)
        local widget = Widget()

        widget.buff_time = widget:AddChild(Text(BODYTEXTFONT, 32))
        --widget.buff_time:SetString("60s")
        widget.buff_time:SetPosition(30, 0)
        widget.buff_name = widget:AddChild(Text(BODYTEXTFONT, 32))
        --widget.buff_name:SetString("buff名")
        widget.buff_name:SetPosition(-30, 0)

        return widget
    end 

    local function DestApply(context, widget, data, index)
        widget.buff_name:Hide()
        widget.buff_time:Hide()
        if data then
            local time_to_show = data[2]==-1 and "" or data[2]
            widget.buff_name:SetString(STRINGS.NAMES[string.upper(data[1])])
            widget.buff_time:SetString(time_to_show)        
            widget.buff_name:Show()
            widget.buff_time:Show()
        end
    end

    self.buff_info = {}

    self.scrollpanel = self.bar:AddChild(TEMPLATES.ScrollingGrid(self.buff_info, {
        num_columns = 1,             -- 有几个滚动条
        num_visible_rows = 4,        -- 滚动条内最多显示多少行
        item_ctor_fn = DestItemCtor, -- 每一项的构造方法
        apply_fn = DestApply,        -- 给每一项赋值，添加事件等
        widget_width = 180,          -- 每一项的宽
        widget_height = 20,          -- 每一项的高
        scrollbar_offset = -30,
        end_offset = 1
    }))
    
    self.default_focus = self.scrollpanel


    --[[self.apply_button = self.bar:AddChild(ImageButton())
    
    self.apply_button:SetPosition(0,50, 0)
    self.apply_button:SetText("键位设置")
    self.apply_button.text:SetColour(0,0,0,1)
    self.apply_button:SetOnClick( function() self:ShowKeySetting() end )
    self.apply_button:SetFont(BUTTONFONT)
    self.apply_button:SetTextSize(30)]]
    
    --[[TheSim:GetPersistentString("newconstant_key", function(load_success, data)
		if load_success and data ~= nil then
            PLAYERCHARGE_KEY = data
		end
	end)]]
    
    self.inst:ListenForEvent("cs_statedirty",function (owner)
        if owner.replica.statemeter then
            local statestring = owner.replica.statemeter:GetStateInfo()
            if #statestring>0 then
                self.buff_info = json.decode(statestring)
                self.scrollpanel:SetItemsData(self.buff_info)
            end
        end
    end,owner)

    self:UpdateWhilePaused(false)
    self.inst:DoPeriodicTask(1,function ()
        self:OnUpdate()
    end)

end)


--[[function cs_buffpanel:ShowKeySetting()
    
    -- Written with reference to OptionsScreen:MapControl
    
    local body_text = "冲刺辅助键:"..string.char(PLAYERCHARGE_KEY-32)
	

    local popup = PopupDialogScreen("按键设置", body_text, {
		{text="确认", cb=function() TheFrontEnd:PopScreen() end},
		{text="恢复默认", cb = function ()
            PLAYERCHARGE_KEY = KEY_Z
            TheSim:SetPersistentString("newconstant_key", KEY_Z, false)
            TheFrontEnd:PopScreen()
            return true
        end},
	})
    	
    popup.OnRawKey = function(self, key, down)
		if down then return end
		-- It fails when key is invalid, so we reject it
		if key<97 or key>122 then return false end
		local key_char = string.char(key-32)
        PLAYERCHARGE_KEY = key
        self.text:SetString("冲刺辅助键:"..key_char)
		--TheFrontEnd:PopScreen()
        TheSim:SetPersistentString("newconstant_key", key, false)
	    TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
		return true
	end	
	TheFrontEnd:PushScreen(popup)
end]]

function newcs_buffpanel:OnUpdate()
    if IsEntityDead(self.owner) then
        return
    end
    local should_update = false
    for i,data in ipairs(self.buff_info) do
        if data[2]>-1 then
            data[2] = data[2]-1
            if data[2]<=0 then
                should_update = true
            end
        end
    end
    if should_update then
        local state_list = {}
        for i, data in ipairs(self.buff_info) do
            if data[2]>0 then
                table.insert(state_list,data)
            end
        end
        self.buff_info = state_list
        self.scrollpanel:SetItemsData(self.buff_info)
    else
        self.scrollpanel:RefreshView()
    end
end



return newcs_buffpanel
