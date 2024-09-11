require "behaviours/approach"
require "behaviours/leash"



local MAX_FOLLOW_DSQ = 24*24


local SporeBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local TOFOLLOW_ONEOF_TAGS = {"player"}

local function IsValidTarget(inst,target)
	return target~=nil and target:IsValid() and 
	target.components.health and not target.components.health:IsDead() 
end

local function FindObjectToFollow(inst)
	local x,y,z = inst.Transform:GetWorldPosition()
	if IsValidTarget(inst.followobj) then
		
		local tx,ty,tz = inst.followobj.Transform:GetWorldPosition()

		if (x-tx)*(x-tx)+(z-tz)*(z-tz)<=900 then
			return inst.followobj
		end
	end
	inst.followobj = FindClosestPlayerInRangeSq(x,y,z,MAX_FOLLOW_DSQ,true)
	return inst.followobj
end

function SporeBrain:OnStart()

	local root =
	PriorityNode(
	{
        Approach(self.inst, FindObjectToFollow, 0.1,false),
		Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("spawnpoint") end, 12,
            {minwalktime=50,  randwalktime=3, minwaittime=0, randwaittime=0})
	}, 1)

	self.bt = BT(self.inst, root)
end

function SporeBrain:OnInitializationComplete()
    self.inst.components.knownlocations:RememberLocation("spawnpoint", self.inst:GetPosition())
end

return SporeBrain
