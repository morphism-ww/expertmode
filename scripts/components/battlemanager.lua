local bossrush_util = require("bossrush/bossrush_program")
local bossrush_tuning = require("bossrush/bossrush_tuning")
local bossrush_health = require("bossrush/bossrush_health")
local bossrush_program = bossrush_util.program

local LEVEL_COUNT = #bossrush_program

local BattleManager = Class(function(self, inst)
    self.inst = inst
    self.progress = 1
    self.level = 1
	self.mode = 1
	self.currentbattle = nil
	self.is_on = false
end)   

function BattleManager:Init(mode)
	self.progress = 1
	self.level = 1
	self.mode = mode or 1
	self.is_on = true
end

function BattleManager:Start()
	for k, v in pairs(bossrush_tuning) do
		ORIGINAL_TUNING[k] = TUNING[k]
		TUNING[k] = v
	end

	for k, v in pairs(bossrush_health) do
		ORIGINAL_TUNING[k] = TUNING[k]
		TUNING[k] = v*self.mode
	end
	self.inst:OnLevelStart(self.level)
	self:ToggleProgram()
end


function BattleManager:ToggleProgram()
	self.currentbattle = bossrush_program[self.level][self.progress]


	self.inst:ToggleProgram(self.currentbattle)
end


function BattleManager:Next()
	
    if self.currentbattle and self.currentbattle.onexit~=nil then
		self.currentbattle.onexit(self.inst)
	end

	--something bad happends force kill!!!
	if self.level>LEVEL_COUNT then
		TheNet:SystemMessage("Boss Rush Error Occurs!!! Force Reset The Schedule")
		self.inst:KillProgram()
		self.inst:DebugResetTime()
	end
	if self.progress<#bossrush_program[self.level] then
		self.progress = self.progress + 1
		local delay = self.level==5 and 6 or 3
    	self.inst:DoTaskInTime(delay,function() self:ToggleProgram() end)
	else
		self.level = self.level + 1
		if self.level>LEVEL_COUNT then
			--TODO	self:OnLevelStart()
			self.currentbattle = nil
			self.inst:DoTaskInTime(5,function() self.inst:ToggleVictory() end)
		else
			self.progress = 1
			local delay = self.level==5 and 10 or 5
    		self.inst:DoTaskInTime(delay,function() 
				self.inst:OnLevelStart(self.level)
				self:ToggleProgram() 
			end)
		end		
	end
end

function BattleManager:KillProgram()
    
	if self.currentbattle and self.currentbattle.onexit~=nil then
		self.currentbattle.onexit(self.inst)
	end
	
	self.progress = 1
	self.level = 1
	self.mode = 1
	self.is_on = false

	for k, v in pairs(bossrush_tuning) do
		TUNING[k] = ORIGINAL_TUNING[k]
		ORIGINAL_TUNING[k] = nil
	end
	for k, v in pairs(bossrush_health) do
		TUNING[k] = ORIGINAL_TUNING[k]
		ORIGINAL_TUNING[k] = nil
	end
	
end

function BattleManager:OnSave()
	if self.is_on then
		return {
			mode = self.mode,
			is_on = self.is_on,
			level = self.level,
			progress = self.progress,
		}
	end
end


function BattleManager:OnLoad(data)
    if data ~= nil then
        self.level = data.level
		self.is_on = data.is_on
		self.mode = data.mode
        self.progress = data.progress or 1
    end
end 


return BattleManager