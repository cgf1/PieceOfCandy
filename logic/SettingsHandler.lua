--[[
	Local variables
]]--
local LOG_ACTIVE = false
local _logger = nil

local SETTINGS_VERSION = 5

--[[
	Table POC_SettingsHandler
]]--
POC_SettingsHandler = {}
POC_SettingsHandler.__index = POC_SettingsHandler

--[[
	Table Members
]]--
POC_SettingsHandler.Name = "POC-SettingsHandler"
POC_SettingsHandler.SettingsName = "POCSettings"
POC_SettingsHandler.SavedVariables = nil
POC_SettingsHandler.Default = 
{
    ["PosX"] = 0,
    ["PosY"] = 0,
    ["SelectorPosX"] = 0,
    ["SelectorPosY"] = 0,
    ["OnlyAva"] = false,
    ["IsLgsActive"] = false,
    ["IsSortingActive"] = true,
    ["SwimlaneMax"] = 24,
    ["UltNumberShow"] = true,
    ["UltNumberPos"] = {100,100},
    ["WereNumberOne"] = false,
    ["Movable"] = true,
    ["Style"] = "Standard",
    ["StaticUltimateID"] = 29861,
    ["SwimlaneUltimateGroupIds"] =
    {
        [1] = 29861,
        [2] = 27413,
        [3] = 86536,
        [4] = 86112,
        [5] = 46537,
        [6] = 46622,
    },
}

--[[
	Sets SetStyleSettings and fires POC-StyleChanged callbacks
]]--
function POC_SettingsHandler.SetStyleSettings(style)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SettingsHandler.SetStyleSettings")
        _logger:logDebug("style", style)
    end

    POC_SettingsHandler.SavedVariables.Style = style

    CALLBACK_MANAGER:FireCallbacks(POC_STYLE_CHANGED)
end

--[[
	Sets MovableSettings and fires POC-MovableChanged callbacks
]]--
function POC_SettingsHandler.SetStaticUltimateIDSettings(staticUltimateID)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SettingsHandler.StaticUltimateIDSettings")
        _logger:logDebug("staticUltimateID", staticUltimateID)
    end

    POC_SettingsHandler.SavedVariables.StaticUltimateID = staticUltimateID

    CALLBACK_MANAGER:FireCallbacks(POC_STATIC_ULTIMATE_ID_CHANGED, staticUltimateID)
end

--[[
	Sets MovableSettings and fires POC-MovableChanged callbacks
]]--
function POC_SettingsHandler.SetSwimlaneUltimateGroupIdSettings(swimlane, ultimateGroup)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SettingsHandler.StaticUltimateIDSettings")
        _logger:logDebug("swimlane", swimlane)
        _logger:logDebug("ultimateGroup", ultimateGroup)
    end

    POC_SettingsHandler.SavedVariables.SwimlaneUltimateGroupIds[swimlane] = ultimateGroup.GroupAbilityId

    CALLBACK_MANAGER:FireCallbacks(POC_SWIMLANE_ULTIMATE_GROUP_ID_CHANGED, swimlane, ultimateGroup)
end

--[[
	Sets MovableSettings and fires POC-MovableChanged callbacks
]]--
function POC_SettingsHandler.SetMovableSettings(movable)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SettingsHandler.SetMovableSettings")
        _logger:logDebug("movable", movable)
    end

    POC_SettingsHandler.SavedVariables.Movable = movable

    CALLBACK_MANAGER:FireCallbacks(POC_MOVABLE_CHANGED, movable)
end

--[[
	Sets MovableSettings and fires POC-MovableChanged callbacks
]]--
function POC_SettingsHandler.SetOnlyAvaSettings(onlyAva)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SettingsHandler.SetOnlyAvaSettings")
        _logger:logDebug("onlyAva", onlyAva)
    end

    POC_SettingsHandler.SavedVariables.OnlyAva = onlyAva

    CALLBACK_MANAGER:FireCallbacks(POC_IS_ZONE_CHANGED)
end

--[[
	Sets IsLgsActive settings
]]--
function POC_SettingsHandler.SetIsLgsActiveSettings(isLgsActive)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SettingsHandler.SetIsLgsActiveSettings")
        _logger:logDebug("isLgsActive", isLgsActive)
    end

    POC_SettingsHandler.SavedVariables.IsLgsActive = isLgsActive
end

--[[
        Sets Swimlane max value
]]--
function POC_SettingsHandler.POC_SetSwimlaneMax(max)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SettingsHandler.POC_SetSwimlaneMax")
        _logger:logDebug("SwimlaneMax", max)
    end
    POC_SettingsHandler.SavedVariables.SwimlaneMax = max
end

--[[
        Set whether to show ultimate number on screen
]]--
function POC_SettingsHandler.POC_SetUltNumberShow(show)
    POC_SettingsHandler.SavedVariables.UltNumberShow = show
    POC_UltNumber.SetHidden(not show)
end

--[[
        Set whether to play a sound when you hit #1 in ultimate order
]]--
function POC_SettingsHandler.POC_SetWereNumberOne(val)
    POC_SettingsHandler.SavedVariables.WereNumberOne = val
end

--[[
	Sets IsSortingActive settings
]]--
function POC_SettingsHandler.SetIsSortingActiveSettings(isSortingActive)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SettingsHandler.SetIsLgsActiveSettings")
        _logger:logDebug("isSortingActive", isSortingActive)
    end

    POC_SettingsHandler.SavedVariables.IsSortingActive = isSortingActive
end

--[[
	Gets SwimlaneList visible in connection with selected style
]]--
function POC_SettingsHandler.IsSwimlaneListVisible()
    return POC_SettingsHandler.IsControlsVisible()
end


--[[
	Gets CompactSwimlaneList visible in connection with selected style
]]--
function POC_SettingsHandler.IsControlsVisible()
    if (LOG_ACTIVE) then _logger:logTrace("POC_SettingsHandler.IsControlsVisible") end
    if (POC_SettingsHandler.SavedVariables ~= nil) then
        if (LOG_ACTIVE) then _logger:logDebug("onlyAvA", POC_SettingsHandler.SavedVariables.OnlyAva) end
        if (POC_SettingsHandler.SavedVariables.OnlyAva) then
            _logger:logDebug("isPlayerInAvAWorld", IsPlayerInAvAWorld())
            return IsPlayerInAvAWorld()
        else
            return true
        end
    else
        _logger:logError("POC_SettingsHandler.SavedVariables is nil")
        return false
    end
end

--[[
	OnPlayerActivated sends IsZoneChanged event
]]--
function POC_SettingsHandler.OnPlayerActivated(eventCode)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_SettingsHandler.OnPlayerActivated")
    end

    CALLBACK_MANAGER:FireCallbacks(POC_IS_ZONE_CHANGED)
end

--[[
	Initialize loads SavedVariables
]]--
function POC_SettingsHandler.Initialize(logger)
    if (LOG_ACTIVE) then logger:logTrace("POC_SettingsHandler.Initialize") end

    _logger = logger

    POC_SettingsHandler.SavedVariables = ZO_SavedVars:NewAccountWide(POC_SettingsHandler.SettingsName, SETTINGS_VERSION, nil, POC_SettingsHandler.Default)

    -- Register
    EVENT_MANAGER:RegisterForEvent(POC_SettingsHandler.Name, EVENT_PLAYER_ACTIVATED, POC_SettingsHandler.OnPlayerActivated)
end

SLASH_COMMANDS["/pocstyle"] = function(style)
    style = string.lower(style):gsub("^%l", string.upper)
    if (style ~= "Compact" and style ~= "Standard") then
        d("POC: *** unknown style: " .. style)
    else
        POC_SettingsHandler.SetStyleSettings(style)
    end
end
