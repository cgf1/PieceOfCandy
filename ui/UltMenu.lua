-- Local variables
--
POC_UltMenu = {}
POC_UltMenu.__index = POC_UltMenu

local xxx

-- Select ultimate group menu
--
function POC_UltMenu.SetUlt(group, arg)
    CALLBACK_MANAGER:FireCallbacks(POC_SET_ULTIMATE_GROUP, group, arg)
end

-- Show ultimate group menu
--
function POC_UltMenu.ShowUltMenu(control, arg)
    if (control ~= nil) then
	ClearMenu()

	local ults = POC_Ult.GetUlts()

	for i, group in ipairs(ults) do
	    AddMenuItem(group.Desc, function() POC_UltMenu.SetUlt(group, arg) end)
	end

	ShowMenu(control)
    else
	POC_Error("POC_UltMenu.ShowUltMenu, control nil")
    end
end

-- Initialize POC_UltMenu
--
function POC_UltMenu.Initialize()
    xxx = POC.xxx
    CALLBACK_MANAGER:RegisterCallback(POC_SHOW_ULTIMATE_GROUP_MENU, POC_UltMenu.ShowUltMenu)
end
