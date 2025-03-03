---------From UM
local UpvalueHacker = {}
local function GetUpvalueHelper(fn, name)
	for i = 1, 50 do
		local f_name, value = debug.getupvalue(fn, i)
		if f_name == name then
			return value, i
		end
	end
	error("fail to get upvalue with name: "..name)
end

UpvalueHacker.GetUpvalueHelper = GetUpvalueHelper

function UpvalueHacker.GetUpvalue(fn, ...)
	local prv, i, prv_var = nil, nil, "(the starting point)"
	for j, var in ipairs({ ... }) do
		assert(type(fn) == "function", "We were looking for " .. var .. ", but the value before it, "
			.. prv_var .. ", wasn't a function (it was a " .. type(fn)
			.. "). Here's the full chain: " .. table.concat({ "(the starting point)", ... }, ", "))
		prv = fn
		prv_var = var
		fn, i = GetUpvalueHelper(fn, var)
	end
	return fn, i, prv
end

function UpvalueHacker.SetUpvalue(start_fn, new_fn, ...)
	local _fn, _fn_i, scope_fn = UpvalueHacker.GetUpvalue(start_fn, ...)
	debug.setupvalue(scope_fn, _fn_i, new_fn)
end

return UpvalueHacker