local function onspell(inst,data)
    if inst.wormlight == data.spell then
        inst.components.statemeter:AddState("medal_wormlight",data.duration)
    end
end
local function endspell(inst,spell)
    if inst.wormlight==spell then
        inst.components.statemeter:ClearState("medal_wormlight")
    end
end


-----------维护一个列表，当且仅当表内容改变时，发起网络同步
local StateMeter = Class(function(self, inst)
    self.inst = inst

    self.state_list = {}

    self.inst:ListenForEvent("onspell",onspell)
    self.inst:ListenForEvent("endspell",endspell)

    inst:StartUpdatingComponent(self)
end)


function StateMeter:HasState(name)
    return self.state_list[name]~=nil
end


------------time=nil or >65535 be regarded as infinite
function StateMeter:AddState(name,time)
    if time==nil or time>65534 then
        time = -1 
    end
    time = math.ceil(time)
    self.state_list[name] = time
    self.should_sync = true
end
function StateMeter:ClearState(name)
    if self:HasState(name) then
        self.should_sync = true
        self.state_list[name] = nil
    end
end

local function GetBuffTime(inst)
    local timer = inst.components.timer
    if timer ~= nil then
        return math.ceil(timer:GetTimeLeft(next(timer.timers)) or 0)
    elseif inst.task~=nil then
        return math.ceil(GetTaskRemaining(inst.task))
    end
    return 65534 ---infinite
end

local function IsValidName(name)

    return type(STRINGS.NAMES[string.upper(name)])=="string"
end

---------name must be unique
function StateMeter:SetDebuffInfo(buff,name)
    print(name)
    if not IsValidName(name) then
        print("invalid name!!!")
        return 
    end
    
    local time = GetBuffTime(buff)
    
    self:AddState(name,time)
end

local tick = 0

function StateMeter:OnUpdate(dt)
    tick = tick + dt
    if tick>1 then
        tick = 0
        for k,v in pairs(self.state_list) do
            if v>0 then
                self.state_list[k] = v - 1
            end
        end
    end
    if self.should_sync then   
        self.inst.replica.statemeter:SetStateInfo(self.state_list)
        self.should_sync = false
    end
end

return StateMeter