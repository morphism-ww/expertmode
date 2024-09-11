local CircleCenter = Class(function(self, inst)
    self.inst = inst

    self.prefab = "soul_seeker"
    self.team = {}

    self.radius = 6
    self.theta = 0
    self.num = 5
    self.thetaincrement = 1
    self.teamsize = 0
    self.start = false

    self.timebetweenattacks = 3
	self.attackinterval = 3
	
	self.reverse = false
end)

function CircleCenter:Start()
    self.theta = self.inst.Transform:GetWorldPosition()
    self.start = true
    for i = 1, self.num do
        local member = SpawnPrefab(self.prefab)
        self:AddMember(member)
    end
    self:SetFormation()
    self.inst:StartUpdatingComponent(self)
end


function CircleCenter:SetFormation(target,canattack)
    local theta = self.theta
    local pt = self.inst:GetPosition()
    local steps = self.teamsize
	local step_decrement = (TWOPI / steps)

    local x,y,z,shouldfocus
    if target and target:IsValid() then
        shouldfocus = true
        x,y,z = target.Transform:GetWorldPosition()
    end
    
    for member in pairs(self.team) do
        if shouldfocus and not member.components.health:IsDead() then
            member:ForceFacePoint(x,y,z)
            if canattack then
                member:DoCast(target)
            end
            
        end
        member.Transform:SetPosition(pt.x +self.radius * math.cos(theta),0,pt.z-self.radius * math.sin(theta) )
        theta = theta - step_decrement
    end
end

function CircleCenter:OnLostTeammate(member)
	if member then
		self.inst:RemoveEventCallback("death", member.deathfn, member)
		self.inst:RemoveEventCallback("onremove", member.deathfn, member)
        self.team[member] = nil
        self.teamsize = self.teamsize - 1
	end
    if self.teamsize==0 then
        self.start = false
        if self.OnLostTeam~=nil then
            self.OnLostTeam(self.inst)
        end
        self.inst:StopUpdatingComponent(self)
    end
end
function CircleCenter:Kill()
    self.start = false
    self.inst:StopUpdatingComponent(self)
    for member in pairs(self.team) do
        member:Remove()
    end    
end


function CircleCenter:AddMember(member)
    self.team[member] = true
    self.teamsize = self.teamsize + 1
    member.deathfn = function() self:OnLostTeammate(member) end
    self.inst:ListenForEvent("death", member.deathfn, member)
    self.inst:ListenForEvent("onremove", member.deathfn, member)
end


function CircleCenter:OnUpdate(dt)
    local direction = (self.reverse and -1) or 1
    self.theta = self.theta + direction * dt * self.thetaincrement
    self.timebetweenattacks = self.timebetweenattacks - dt

    
    
    self:SetFormation(self.inst.components.combat.target,self.timebetweenattacks <= 0)
    if self.timebetweenattacks <= 0 then
        self.timebetweenattacks = self.attackinterval
        
    end
end


function CircleCenter:OnSave()
    local team = {}
    local references = {}
    for k, v in pairs(self.team) do
        table.insert(team, k.GUID)
        table.insert(references, k.GUID)
    end
    if #team > 0 then
        return { team = team, theta = self.theta ,start = self.start}, references
    end
end

function CircleCenter:LoadPostPass(newents, data)
    self.theta = data.theta or 0
    if data.team ~= nil then
        for i, v in ipairs(data.team) do
            local member = newents[v]
            if member ~= nil then
                self:AddMember(member.entity)
            end
        end
    end
    if data.start then
        self.start = true    
        self.inst:StartUpdatingComponent(self)
    end
end
--bs.components.circlecenter.team

return CircleCenter