--[[
	Local variables
]]--
local LOG_ACTIVE = false
local _logger = nil

--[[
	Table POC_UltGrpMenu
]]--
POC_UltGrpMenu = {}
POC_UltGrpMenu.__index = POC_UltGrpMenu

--[[
	Table Members
]]--

--[[
	SetUltGrp shows ultimate group menu
]]--
function POC_UltGrpMenu.SetUltGrp(group, arg)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_UltGrpMenu.SetultimateGroup")
        _logger:logDebug("group.GroupName, arg", group.GroupName, arg)
    end

    CALLBACK_MANAGER:FireCallbacks(POC_SET_ULTIMATE_GROUP, group, arg)
end

--[[
	ShowUltGrpMenu shows ultimate group menu
]]--
function POC_UltGrpMenu.ShowUltGrpMenu(control, arg)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_UltGrpMenu.ShowUltGrpMenu")
        _logger:logDebug("arg", arg)
    end

    if (control ~= nil) then
        ClearMenu()

        local ultimateGroups = POC_UltGrpHandler.GetUltGrps()

        for i, group in pairs(ultimateGroups) do
            AddMenuItem(group.GroupName .. " - " .. group.GroupDescription, function() POC_UltGrpMenu.SetUltGrp(group, arg) end)
        end

        ShowMenu(control)
    else
        _logger:logError("POC_UltGrpMenu.ShowUltGrpMenu, control nil")
    end
end

--[[
	Initialize initializes POC_UltGrpMenu
]]--
function POC_UltGrpMenu.Initialize(logger)
    if (LOG_ACTIVE) then 
        logger:logTrace("POC_UltGrpMenu.Initialize")
    end

    _logger = logger

    CALLBACK_MANAGER:RegisterCallback(POC_SHOW_ULTIMATE_GROUP_MENU, POC_UltGrpMenu.ShowUltGrpMenu)
end
