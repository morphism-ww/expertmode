local PopupDialogScreen		= require "screens/popupdialog"
local PopupDialogScreenRedux= require "screens/redux/popupdialog"
--local BigPopupDialogScreen	= require "screens/bigpopupdialog"

local function CreateChoicePopup(title,body,action_yes,action_no, theme, longness, style)
	
	local choices = { 
		{ 
		  		text = "OK", 
				cb = function()
				TheFrontEnd:PopScreen()
				if action_yes then
					action_yes()
				end
			end
		}
	}
	
	if action_no then
		table.insert(choices,
		{ 
		  		text = "Cancel", 
				cb = function()
				TheFrontEnd:PopScreen()
				action_no()
			end
		}
		)
	end
	
	if theme and theme == "redux" then
		TheFrontEnd:PushScreen(
			PopupDialogScreenRedux( title, body, choices, nil, longness, style)
		)
	elseif not theme or theme == "original" then
		if style and style == "dark_wide" then
			style = "dark" --unsupported
		end
		--if longness and (longness == "big" or longness == "bigger") then
		--	TheFrontEnd:PushScreen(
		--		BigPopupDialogScreen( title, body, choices)
		--	)
		--else
			TheFrontEnd:PushScreen(
				PopupDialogScreen( title, body, choices, nil, nil, style)
			)
		--end
		
		
	else
		print("[Welcome message] Error: unknown theme "..theme..", not creating popup.")
	end
end

local function CreateProcessPopup(title,body,process,postexec_process)
	
	TheFrontEnd:PushScreen(
		PopupDialogScreen( title, body, { 
		  		text = "Please wait", 
				cb = function()
			end
		})
	)

	TheWorld:DoTaskInTime(0.1,
	function()
	
		process()
	
		TheFrontEnd:PopScreen()
		
		postexec_process()
	end)
end

local function CreateErrorPopup(error_string)
	TheSim:SetTimeScale(0)
	local abort = function() TheSim:ForceAbort() end
	CreateChoicePopup("Error",error_string,abort,nil)
end

return {
	["CreateProcessPopup"] = CreateProcessPopup,
	["CreateChoicePopup"] = CreateChoicePopup ,
	["CreateErrorPopup"] = CreateErrorPopup
}