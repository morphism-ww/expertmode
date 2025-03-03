
local function IsPointInRange(player, x, z)
    local px, py, pz = player.Transform:GetWorldPosition()
    return Metric2(x, z, px, pz) <= 4096
end

local function ConvertPlatformRelativePositionToAbsolutePosition(relative_x, relative_z, platform, platform_relative)
    if platform_relative then
		if platform == nil then
			return
		end
		local y
		relative_x, y, relative_z = platform.entity:LocalToWorldSpace(relative_x, 0, relative_z)
	end
    return relative_x, relative_z
end

newcs_env.AddModRPCHandler("The_NewConstant", "KeyHandle", function(player,x,z,platform, platform_relative)
    if not ( checknumber(x) and checknumber(z)) then
        return
    end
    local playercontroller = player.components.playercontroller
    if playercontroller ~= nil then

        x, z = ConvertPlatformRelativePositionToAbsolutePosition(x, z, platform, platform_relative)
        if x ~= nil then
            if IsPointInRange(player, x, z) then
                playercontroller:NeWCS_Remote_keyhandle(Vector3(x, 0, z))
            else
                print("Remote point action out of range")
            end
        end
    end
end)