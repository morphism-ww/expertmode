local Projectile = require("components/projectile")

local function StopTrackingDelayOwner(self)
    if self.delayowner ~= nil then
        self.inst:RemoveEventCallback("onremove", self._ondelaycancel, self.delayowner)
        self.inst:RemoveEventCallback("newstate", self._ondelaycancel, self.delayowner)
        self.delayowner = nil
    end
end

local old_FN = Projectile.Hit

function Projectile:Hit(target)
    if self.custom_onhit~=nil then
        local attacker = self.owner
        StopTrackingDelayOwner(self)
        self:Stop()
        self.inst.Physics:Stop()

        if attacker.components.combat == nil and attacker.components.weapon ~= nil and attacker.components.inventoryitem ~= nil then
            attacker = attacker.components.inventoryitem.owner
        end
        
        self.custom_onhit(self.inst,attacker,target)
        
        if self.onhit ~= nil then
            self.onhit(self.inst, attacker, target)
        end
    else
        old_FN(self,target)
    end
end