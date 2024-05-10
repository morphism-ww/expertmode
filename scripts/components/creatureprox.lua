local function DoTest(inst)   
    local component = inst.components.creatureprox
    if component and component.enabled and not inst:HasTag("INTERIOR_LIMBO") then

        local x,y,z = inst.Transform:GetWorldPosition()

        local range

        if component.isclose then
            range = component.far
        else
            range = component.near
        end

        --local oneofhave = { "animal","character","epic","monster" }
        local must_have = {"locomotor"}
        local nothave = {"INLIMBO", "playerghost","shadow","chess","spore"}
        local ents=TheSim:FindEntities(x,y,z, range, must_have, nothave)
        local close

        for i=#ents,1,-1 do
            if ents[i] == inst or ( component.testfn and not component.testfn(ents[i]) ) then
                table.remove(ents,i)
            end
        end

        if #ents > 0 and inst then
            close = true
            if component.inproxfn then
                for i, ent in ipairs(ents)do
                    component.inproxfn(inst,ent)
                end
            end
        end
        if component.isclose ~= close then
            component.isclose = close
            if component.isclose and component.onnear then
                component.onnear(inst, ents)
            end

            if not component.isclose and component.onfar then
                component.onfar(inst)
            end        
        end
    end
end

local CreatureProx = Class(function(self, inst)
    self.inst = inst
    self.near = 2
    self.far = 3
    self.period = .333
    self.onnear = nil
    self.onfar = nil
    self.isclose = nil
    self.enabled = true    
    self.all = nil
    self.task = nil
    
    self:Schedule()
end)

function CreatureProx:GetDebugString()
    return self.isclose and "NEAR" or "FAR"
end

function CreatureProx:SetOnPlayerNear(fn)
    self.onnear = fn
end


function CreatureProx:OnSave()
   local data = {
        enabled = self.enabled
    }
end
function CreatureProx:OnLoad(data)
    if data.enabled then
        self.enabled = data.enabled
    end
end

function CreatureProx:SetEnabled(enabled)
    self.enabled = enabled
    if enabled == false then
        self.isclose = nil
    end
end

function CreatureProx:SetOnPlayerFar(fn)
    self.onfar = fn
end

function CreatureProx:IsPlayerClose()
	return self.isclose
end

function CreatureProx:SetDist(near, far)
    self.near = near
    self.far = far
end

function CreatureProx:SetTestfn(testfn)
    self.testfn = testfn    
end

function CreatureProx:forcetest()
    DoTest(self.inst)
end


function CreatureProx:Schedule()
    if self.task then
        self.task:Cancel()
        self.task = nil
    end
    self.task = self.inst:DoPeriodicTask(self.period, DoTest)
end

function CreatureProx:OnEntitySleep()
    if self.task then
        self.task:Cancel()
        self.task = nil
    end
end

function CreatureProx:OnEntityWake()
    self:Schedule()
end

function CreatureProx:OnRemoveEntity()
    if self.task then
        self.task:Cancel()
        self.task = nil
    end
end

return CreatureProx
