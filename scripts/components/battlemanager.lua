local bossrush_util = require("bossrush/bossrush_program")
local bossrush_tuning = require("bossrush/bossrush_tuning")
local bossrush_health = require("bossrush/bossrush_health")
local commonfn = bossrush_util.commonfn
local bossrush_program = bossrush_util.program


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
	self:ToggleProgram()
end

local function MakeSpawnProtect(inst)
	inst.components.health.externalabsorbmodifiers:SetModifier(inst, 0.99, "br_protect")
	inst:DoTaskInTime(3,function ()
		inst.components.health.externalabsorbmodifiers:RemoveModifier(inst, "br_protect")
	end)
end

function BattleManager:ToggleProgram()
	self.currentbattle = bossrush_program[self.level][self.progress]
    commonfn.clearland(self.inst)
    local program = self.currentbattle

	if program.type_special then
		program.initfn(self.inst)
	else
		if program.scenery_postinit~=nil then
			program.scenery_postinit(self.inst)
		end

		local boss = SpawnPrefab(program.boss)	

		local x,y,z = self.inst.Transform:GetWorldPosition()
		boss.Transform:SetPosition(x,0,z)

		boss.entity:SetCanSleep(false)

		if boss.components.lootdropper~=nil then
			boss.components.lootdropper.DropLoot = function ()end
		end

		if program.postinitfn~=nil then
			program.postinitfn(boss)
		end

		if boss.components.grouptargeter==nil then
			boss:AddComponent("grouptargeter")
		end


		if boss.components.planardamage==nil then
			boss:AddComponent("planardamage")
		end
		boss.components.planardamage:SetBaseDamage(40)

		if boss.components.planarentity==nil then
			boss:AddComponent("planarentity")
		end
		boss.components.combat.playerdamagepercent = 1.5
		boss.components.combat:SetRetargetFunction(1, commonfn.retarget)
		boss.components.combat:SetKeepTargetFunction(commonfn.keeptarget)
		--boss.components.combat:SetAreaDamage(5, 1)

		boss.persists = false
		
		MakeSpawnProtect(boss)

		self.inst:ListenForEvent("death",function ()
			self:Next()
		end,boss)
	end
end


function BattleManager:Next()
    if self.currentbattle and self.currentbattle.onexit~=nil then
		self.currentbattle.onexit(self.inst)
	end
    if bossrush_program[self.level][self.progress+1]~=nil then
		self.progress = self.progress + 1
		
		
		local delay = self.level==5 and 6 or 3
    	self.inst:DoTaskInTime(delay,function(_) self:ToggleProgram() end)
	else
		self.level = self.level + 1
		if bossrush_program[self.level]~=nil then
			--TODO	self:OnLevelStart()
			self.progress = 1
			
			local delay = self.level==5 and 7 or 3
    		self.inst:DoTaskInTime(delay,function(_) self:ToggleProgram() end)
		else
			self.currentbattle = nil
			self.inst:DoTaskInTime(5,function(_) self.inst:ToggleVictory() end)
			
		end		
	end
end

function BattleManager:KillProgram()
    
	if self.currentbattle and self.currentbattle.onexit~=nil then
		self.currentbattle.onexit(self.inst)
	end
	commonfn.clearland(self.inst)
	self:Init()

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
    return {
        mode = self.mode,
        is_on = self.is_on,
        level = self.level
    }
end

local function ProgressReset(level1)
    for k,v in ipairs(bossrush_program) do
        if v.level==level1 then
            return k
        end
    end
end


function BattleManager:OnLoad(data)
    if data ~= nil then
        self.level = data.level
		self.is_on = data.is_on
		self.mode = data.mode
        self.progress = 1
    end
end 

function BattleManager:OnPostInit()
    if self.is_on then
        for k, v in pairs(bossrush_tuning) do
            ORIGINAL_TUNING[k] = TUNING[k]
            TUNING[k] = v
        end
    
        for k, v in pairs(bossrush_health) do
            ORIGINAL_TUNING[k] = TUNING[k]
            TUNING[k] = v*self.mode
        end
    end
end


return BattleManager