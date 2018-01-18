--[[
	Local variables
]]--
local LOG_ACTIVE = false
local _logger = nil

--[[
	Table POC_UltimateGroupMenu
]]--
POC_UltimateGroupMenu = {}
POC_UltimateGroupMenu.__index = POC_UltimateGroupMenu

--[[
	Table Members
]]--

--[[
	SetUltimateGroup shows ultimate group menu
]]--
function POC_UltimateGroupMenu.SetUltimateGroup(group, arg)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_UltimateGroupMenu.SetultimateGroup")
        _logger:logDebug("group.GroupName, arg", group.GroupName, arg)
    end

    CALLBACK_MANAGER:FireCallbacks(POC_SET_ULTIMATE_GROUP, group, arg)
end

--[[
	ShowUltimateGroupMenu shows ultimate group menu
]]--
function POC_UltimateGroupMenu.ShowUltimateGroupMenu(control, arg)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_UltimateGroupMenu.ShowUltimateGroupMenu")
        _logger:logDebug("arg", arg)
    end

    if (control ~= nil) then
        ClearMenu()

        local ultimateGroups = POC_UltimateGroupHandler.GetUltimateGroups()

        for i, group in pairs(ultimateGroups) do
            AddMenuItem(group.GroupName .. " - " .. group.GroupDescription, function() POC_UltimateGroupMenu.SetUltimateGroup(group, arg) end)
        end

        ShowMenu(control)
    else
        _logger:logError("POC_UltimateGroupMenu.ShowUltimateGroupMenu, control nil")
    end
end

--[[
	Initialize initializes POC_UltimateGroupMenu
]]--
function POC_UltimateGroupMenu.Initialize(logger)
    if (LOG_ACTIVE) then 
        logger:logTrace("POC_UltimateGroupMenu.Initialize")
    end

    _logger = logger

    CALLBACK_MANAGER:RegisterCallback(POC_SHOW_ULTIMATE_GROUP_MENU, POC_UltimateGroupMenu.ShowUltimateGroupMenu)
end
