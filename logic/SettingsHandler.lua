--[[
	Local variables
]]--
local LOG_ACTIVE = false
local _logger = nil

local SETTINGS_VERSION = 5

--[[
	Table POC_Settings
]]--
POC_Settings = {}
POC_Settings.__index = POC_Settings

--[[
	Table Members
]]--
POC_Settings.Name = "POC-SettingsHandler"
POC_Settings.SettingsName = "POCSettings"
POC_Settings.SavedVariables = nil
POC_Settings.Default = 
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
    ["UltNumberPos"] = nil,
    ["WereNumberOne"] = true,
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
function POC_Settings.SetStyleSettings(style)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Settings.SetStyleSettings")
        _logger:logDebug("style", style)
    end

    POC_Settings.SavedVariables.Style = style

    CALLBACK_MANAGER:FireCallbacks(POC_STYLE_CHANGED)
end

--[[
	Sets MovableSettings and fires POC-MovableChanged callbacks
]]--
function POC_Settings.SetStaticUltimateIDSettings(staticUltimateID)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Settings.StaticUltimateIDSettings")
        _logger:logDebug("staticUltimateID", staticUltimateID)
    end

    POC_Settings.SavedVariables.StaticUltimateID = staticUltimateID

    CALLBACK_MANAGER:FireCallbacks(POC_STATIC_ULTIMATE_ID_CHANGED, staticUltimateID)
end

--[[
	Sets MovableSettings and fires POC-MovableChanged callbacks
]]--
function POC_Settings.SetSwimlaneUltimateGroupIdSettings(swimlane, ultimateGroup)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Settings.StaticUltimateIDSettings")
        _logger:logDebug("swimlane", swimlane)
        _logger:logDebug("ultimateGroup", ultimateGroup)
    end

    POC_Settings.SavedVariables.SwimlaneUltimateGroupIds[swimlane] = ultimateGroup.GroupAbilityId

    CALLBACK_MANAGER:FireCallbacks(POC_SWIMLANE_ULTIMATE_GROUP_ID_CHANGED, swimlane, ultimateGroup)
end

--[[
	Sets MovableSettings and fires POC-MovableChanged callbacks
]]--
function POC_Settings.SetMovableSettings(movable)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Settings.SetMovableSettings")
        _logger:logDebug("movable", movable)
    end

    POC_Settings.SavedVariables.Movable = movable

    CALLBACK_MANAGER:FireCallbacks(POC_MOVABLE_CHANGED, movable)
end

--[[
	Sets MovableSettings and fires POC-MovableChanged callbacks
]]--
function POC_Settings.SetOnlyAvaSettings(onlyAva)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Settings.SetOnlyAvaSettings")
        _logger:logDebug("onlyAva", onlyAva)
    end

    POC_Settings.SavedVariables.OnlyAva = onlyAva

    CALLBACK_MANAGER:FireCallbacks(POC_IS_ZONE_CHANGED)
end

--[[
	Sets IsLgsActive settings
]]--
function POC_Settings.SetIsLgsActiveSettings(isLgsActive)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Settings.SetIsLgsActiveSettings")
        _logger:logDebug("isLgsActive", isLgsActive)
    end

    POC_Settings.SavedVariables.IsLgsActive = isLgsActive
end

--[[
        Sets Swimlane max value
]]--
function POC_Settings.POC_SetSwimlaneMax(max)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Settings.POC_SetSwimlaneMax")
        _logger:logDebug("SwimlaneMax", max)
    end
    POC_Settings.SavedVariables.SwimlaneMax = max
end

--[[
        Set whether to show ultimate number on screen
]]--
function POC_Settings.POC_SetUltNumberShow(show)
    POC_Settings.SavedVariables.UltNumberShow = show
    POC_UltNumber.Hide(not show)
end

--[[
        Set whether to play a sound when you hit #1 in ultimate order
]]--
function POC_Settings.POC_SetWereNumberOne(val)
    POC_Settings.SavedVariables.WereNumberOne = val
end

--[[
	Sets IsSortingActive settings
]]--
function POC_Settings.SetIsSortingActiveSettings(isSortingActive)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Settings.SetIsLgsActiveSettings")
        _logger:logDebug("isSortingActive", isSortingActive)
    end

    POC_Settings.SavedVariables.IsSortingActive = isSortingActive
end

--[[
	Gets SwimlaneList visible in connection with selected style
]]--
function POC_Settings.IsSwimlaneListVisible()
    return POC_Settings.IsControlsVisible()
end


--[[
	Gets CompactSwimlaneList visible in connection with selected style
]]--
function POC_Settings.IsControlsVisible()
    if (LOG_ACTIVE) then _logger:logTrace("POC_Settings.IsControlsVisible") end
    if (POC_Settings.SavedVariables ~= nil) then
        if (LOG_ACTIVE) then _logger:logDebug("onlyAvA", POC_Settings.SavedVariables.OnlyAva) end
        if (POC_Settings.SavedVariables.OnlyAva) then
            _logger:logDebug("isPlayerInAvAWorld", IsPlayerInAvAWorld())
            return IsPlayerInAvAWorld()
        else
            return true
        end
    else
        _logger:logError("POC_Settings.SavedVariables is nil")
        return false
    end
end

--[[
	OnPlayerActivated sends IsZoneChanged event
]]--
function POC_Settings.OnPlayerActivated(eventCode)
    if (LOG_ACTIVE) then 
        _logger:logTrace("POC_Settings.OnPlayerActivated")
    end

    CALLBACK_MANAGER:FireCallbacks(POC_IS_ZONE_CHANGED)
end

--[[
	Initialize loads SavedVariables
]]--
function POC_Settings.Initialize(logger)
    if (LOG_ACTIVE) then logger:logTrace("POC_Settings.Initialize") end

    _logger = logger

    POC_Settings.SavedVariables = ZO_SavedVars:NewAccountWide(POC_Settings.SettingsName, SETTINGS_VERSION, nil, POC_Settings.Default)

    -- Register
    EVENT_MANAGER:RegisterForEvent(POC_Settings.Name, EVENT_PLAYER_ACTIVATED, POC_Settings.OnPlayerActivated)

    SLASH_COMMANDS["/pocstyle"] = function(style)
        style = string.lower(style):gsub("^%l", string.upper)
        if (style ~= "Compact" and style ~= "Standard") then
            d("POC: *** unknown style: " .. style)
        else
            POC_Settings.SetStyleSettings(style)
        end
    end
end
