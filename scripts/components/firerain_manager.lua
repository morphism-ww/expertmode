--------------------------------------------------------------------------
--[[ FrogRain class definition ]]
--------------------------------------------------------------------------

return Class(function(self, inst)

assert(TheWorld.ismastersim, "FireRain should not exist on client")

--------------------------------------------------------------------------
--[[ Member variables ]]
--------------------------------------------------------------------------

--Public
self.inst = inst
self.firerain_enabled = false


--Private
local _activeplayers = {}

local _worldstate = TheWorld.state
local _worldsettingstimer = TheWorld.components.worldsettingstimer

local _spawntime = 5
local _fireduration = 90
local _timetofire = 0
local _attackdelay = 0
local _warning= false
local _warnduration = 60
local _timetonextwarningsound=0
local _announcewarningsoundinterval = 4
local _scheduleddrops=nil
--------------------------------------------------------------------------
--[[ Private member functions ]]
--------------------------------------------------------------------------
local function CanFire()
    return self.firerain_enabled and TheWorld.state.cycles > TUNING.NO_BOSS_TIME
            and (_worldstate.season == "summer") and #_activeplayers>0
end
local function PauseAttacks()
    _warning = false
    self.inst:StopUpdatingComponent(self)
    _worldsettingstimer:PauseTimer("FireRain", true)
end
local function ResetAttacks()
    _worldsettingstimer:StopTimer("FireRain")
    PauseAttacks()
end
local function TryStartAttacks()
    if CanFire() then
        if  _worldsettingstimer:GetTimeLeft("FireRain") == nil then
            _worldsettingstimer:StartTimer("FireRain", _attackdelay)
        end

        _worldsettingstimer:ResumeTimer("FireRain")
        self.inst:StartUpdatingComponent(self)
        self:StopWatchingWorldState("cycles", TryStartAttacks)
        self.inst.watchingcycles = nil
    else
        PauseAttacks()
        if not self.inst.watchingcycles then
            self:WatchWorldState("cycles", TryStartAttacks)  -- keep checking every day until NO_BOSS_TIME is up
            self.inst.watchingcycles = true
        end
    end
end

local function TargetLost()
    local timetoattack = _worldsettingstimer:GetTimeLeft("FireRain")
    if timetoattack == nil then
        _warning = false
        _worldsettingstimer:StartTimer("FireRain", _warnduration + 1)
    elseif (timetoattack < _warnduration and _warning) then
        _warning = false
        _worldsettingstimer:SetTimeLeft("FireRain", _warnduration + 1)
    end

    PauseAttacks()
end

local function OnSeasonChange()
    TryStartAttacks()
end

local function hasprotecter(pos)
    local ents = TheSim:FindEntities(pos.x,0,pos.z,TUNING.DEERCLOPSEYEBALL_SENTRYWARD_RADIUS)
    for i,v in ipairs(ents) do
        if v.prefab=="deerclopseyeball_sentryward_fx" then
            return true
        end
    end
    return false
end


local function SpawnFireForPlayer(player)
    local pos = player:GetPosition()
    if hasprotecter(pos) then return end
    local firerain
    if math.random() <= 0.4 then
        firerain = SpawnPrefab("dragoonegg_falling")
    else
        firerain = SpawnPrefab("firerain")
    end
    local theta = math.random() * 2 * PI
    local radius = 4+math.random() * 4
    firerain.Transform:SetPosition(pos.x+radius*math.cos(theta),0,pos.z-radius*math.sin(theta))
    firerain:StartStep()
end

local function SpawnFireForPlayers()
    for i, v in ipairs(_activeplayers) do
        v:DoTaskInTime(5*math.random(),SpawnFireForPlayer,v)
    end
end

local function CancelSpawn()
    if _scheduleddrops~=nil then
        _scheduleddrops:Cancel()
        _scheduleddrops=nil
    end
end

local function ScheduleSpawn()
    if _scheduleddrops~=nil then
        _scheduleddrops:Cancel()
        _scheduleddrops=nil
    end
    _scheduleddrops=self.inst:DoPeriodicTask(_spawntime,SpawnFireForPlayers)
    self.inst:DoTaskInTime(_fireduration,CancelSpawn)
end

--------------------------------------------------------------------------
--[[ Private event handlers ]]
--------------------------------------------------------------------------

local function OnPlayerJoined(src, player)
    for i, v in ipairs(_activeplayers) do
        if v == player then
            return
        end
    end
    table.insert(_activeplayers, player)
    TryStartAttacks()
end

local function OnPlayerLeft(src, player)
    for i, v in ipairs(_activeplayers) do
        if v == player then
            table.remove(_activeplayers, i)
            return
        end
    end
end

local function OnFireRainTimerDone()
    _warning = false
    if #_activeplayers==0 then
        TargetLost()
    else
        ScheduleSpawn()
        ResetAttacks()
        TryStartAttacks()
    end
end

--------------------------------------------------------------------------
--[[ Initialization ]]
--------------------------------------------------------------------------

--Initialize variables
for i, v in ipairs(AllPlayers) do
    table.insert(_activeplayers, v)
end

--Register events
self:WatchWorldState("season", OnSeasonChange)
self.inst:ListenForEvent("ms_playerjoined", OnPlayerJoined, TheWorld)
self.inst:ListenForEvent("ms_playerleft", OnPlayerLeft, TheWorld)
self.inst:ListenForEvent("FireEra",function() self:FirstAttack() end,TheWorld)


--------------------------------------------------------------------------
--[[ Public member functions ]]
    --------------------------------------------------------------------------
function self:EnableFire()
    self.firerain_enabled = true
end

function self:FirstAttack()
    if not self.firerain_enabled then
        self:EnableFire()
        TheNet:Announce("古老的龙与火已经苏醒")
        self.inst:DoTaskInTime(60, ScheduleSpawn)
        --ResetAttacks()
    end
end

function self:OnPostInit()
    -- Shorten the time used for winter to account for the time deerclops spends stomping around
    -- Then add one to _attacksperseason to shift the attacks so the last attack isn't right when the season changes to spring
    _attackdelay = (TheWorld.state.summerlength - 1) * TUNING.TOTAL_DAY_TIME 
    _worldsettingstimer:AddTimer("FireRain", _attackdelay, true, OnFireRainTimerDone)
    if _timetofire then
        _worldsettingstimer:StartTimer("FireRain", math.min(_timetofire, _attackdelay))
    end
    TryStartAttacks()
end

function self:DoWarningSpeech()
    TheNet:Announce("空气变得燥热")
end

function self:DoWarningSound()
    TheNet:Announce("远处传来巨龙的吼叫")
end

function self:OnUpdate(dt)
    local timetoattack = _worldsettingstimer:GetTimeLeft("FireRain")
    if not timetoattack then
        ResetAttacks()
        return
    end

    if not _warning then
        if timetoattack > 0 and timetoattack < _warnduration then
			-- let's pick a random player here
			if #_activeplayers==0 then
				PauseAttacks()
				return
			end
			_warning = true
			_timetonextwarningsound = 0
        end
    else
        _timetonextwarningsound	= _timetonextwarningsound - dt

		if _timetonextwarningsound <= 0 then
	        if #_activeplayers==0 then
                TargetLost()
                return
	        end
			_announcewarningsoundinterval = _announcewarningsoundinterval - 1
			if _announcewarningsoundinterval <= 0 then
				_announcewarningsoundinterval = 30
				self:DoWarningSpeech()
			end
            _timetonextwarningsound = timetoattack < 30 and 10 + math.random(1) or 15 + math.random(4)
            self:DoWarningSound()
		end
	end
end

function self:LongUpdate(dt)
	self:OnUpdate(dt)
end
--------------------------------------------------------------------------
--[[ Save/Load ]]
--------------------------------------------------------------------------

function self:OnSave()
    return
    {
        warning=_warning,
        _firerain_enabled=self.firerain_enabled
    }
end

function self:OnLoad(data)
    _warning=data.warning
    self.firerain_enabled = data._firerain_enabled or false
    if data.timetofire then
        _timetofire = data.timetofire
    end
end
--------------------------------------------------------------------------
--[[ Debug ]]
--------------------------------------------------------------------------

function self:GetDebugString()
    local timetoattack = _worldsettingstimer:GetTimeLeft("FireRain")
	local s = ""
	if not timetoattack then
	    s = s .. "DORMANT <no time>"
	elseif self.inst.updatecomponents[self] == nil then
		s = s .. "DORMANT "..timetoattack
	elseif timetoattack > 0 then
		s = s .. string.format("%s Deerclops is coming in %2.2f", _warning and "WARNING" or "WAITING", timetoattack)
	else
		s = s .. string.format("ATTACKING!!!")
	end
	s=s..string.format(" firerain_enable=%s",self.firerain_enabled and "true" or "false")
    return s
end

function self:SummonMonster(time)
    if _worldsettingstimer:ActiveTimerExists("FireRain") then
        _worldsettingstimer:SetTimeLeft("FireRain", 10)
        _worldsettingstimer:ResumeTimer("FireRain")
    else
        _worldsettingstimer:StartTimer("FireRain", 10)
    end
	self.inst:StartUpdatingComponent(self)
end



--------------------------------------------------------------------------
--[[ End ]]
--------------------------------------------------------------------------

end)
