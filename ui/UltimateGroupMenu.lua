--[[
	Local variables
]]--
local LOG_ACTIVE = false
local _logger = nil

--[[
	Table TGU_UltimateGroupMenu
]]--
TGU_UltimateGroupMenu = {}
TGU_UltimateGroupMenu.__index = TGU_UltimateGroupMenu

--[[
	Table Members
]]--

--[[
	SetUltimateGroup shows ultimate group menu
]]--
function TGU_UltimateGroupMenu.SetUltimateGroup(group, arg)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_UltimateGroupMenu.SetultimateGroup")
        _logger:logDebug("group.GroupName, arg", group.GroupName, arg)
    end

    CALLBACK_MANAGER:FireCallbacks(TGU_SET_ULTIMATE_GROUP, group, arg)
end

--[[
	ShowUltimateGroupMenu shows ultimate group menu
]]--
function TGU_UltimateGroupMenu.ShowUltimateGroupMenu(control, arg)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_UltimateGroupMenu.ShowUltimateGroupMenu")
        _logger:logDebug("arg", arg)
    end

    if (control ~= nil) then
        ClearMenu()

        local ultimateGroups = TGU_UltimateGroupHandler.GetUltimateGroups()

        for i, group in pairs(ultimateGroups) do
            AddMenuItem(group.GroupName .. " - " .. group.GroupDescription, function() TGU_UltimateGroupMenu.SetUltimateGroup(group, arg) end)
        end

        ShowMenu(control)
    else
        _logger:logError("TGU_UltimateGroupMenu.ShowUltimateGroupMenu, control nil")
    end
end

--[[
	Initialize initializes TGU_UltimateGroupMenu
]]--
function TGU_UltimateGroupMenu.Initialize(logger)
    if (LOG_ACTIVE) then 
        logger:logTrace("TGU_UltimateGroupMenu.Initialize")
    end

    _logger = logger

    CALLBACK_MANAGER:RegisterCallback(TGU_SHOW_ULTIMATE_GROUP_MENU, TGU_UltimateGroupMenu.ShowUltimateGroupMenu)
end
