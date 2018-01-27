-- Local variables
--
local LOG_ACTIVE = false
local _logger = nil

POC_UltMenu = {}
POC_UltMenu.__index = POC_UltMenu

-- Select ultimate group menu
--
function POC_UltMenu.SetUlt(group, arg)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_UltMenu.Setult")
        _logger:logDebug("group.Name, arg", group.Name, arg)
    end

    CALLBACK_MANAGER:FireCallbacks(POC_SET_ULTIMATE_GROUP, group, arg)
end

-- Show ultimate group menu
--
function POC_UltMenu.ShowUltMenu(control, arg)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_UltMenu.ShowUltMenu")
        _logger:logDebug("arg", arg)
    end

    if (control ~= nil) then
        ClearMenu()

        local ults = POC_Ult.GetUlts()

        for i, group in ipairs(ults) do
            AddMenuItem(group.Desc, function() POC_UltMenu.SetUlt(group, arg) end)
        end

        ShowMenu(control)
    else
        _logger:logError("POC_UltMenu.ShowUltMenu, control nil")
    end
end

-- Initialize POC_UltMenu
--
function POC_UltMenu.Initialize(logger)
    if (LOG_ACTIVE) then 
        logger:logTrace("POC_UltMenu.Initialize")
    end

    _logger = logger

    CALLBACK_MANAGER:RegisterCallback(POC_SHOW_ULTIMATE_GROUP_MENU, POC_UltMenu.ShowUltMenu)
end
