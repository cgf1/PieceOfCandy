--[[
	Local variables
]]--
local LOG_ACTIVE = false
local _logger = nil

local SETTINGS_VERSION = 5

--[[
	Table TGU_SettingsHandler
]]--
TGU_SettingsHandler = {}
TGU_SettingsHandler.__index = TGU_SettingsHandler

--[[
	Table Members
]]--
TGU_SettingsHandler.Name = "TGU-SettingsHandler"
TGU_SettingsHandler.SettingsName = "POCSettings"
TGU_SettingsHandler.SavedVariables = nil
TGU_SettingsHandler.Default = 
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
    ["Style"] = 1,
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
	Sets SetStyleSettings and fires TGU-StyleChanged callbacks
]]--
function TGU_SettingsHandler.SetStyleSettings(style)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_SettingsHandler.SetStyleSettings")
        _logger:logDebug("style", style)
    end

    local numberStyle = tonumber(style)

    if (numberStyle == 1 or numberStyle == 2 or numberStyle == 3) then
        TGU_SettingsHandler.SavedVariables.Style = numberStyle

        CALLBACK_MANAGER:FireCallbacks(TGU_STYLE_CHANGED)
    else
        _logger:logError("TGU_SettingsHandler.SetStyleSettings, invalid style " .. tostring(style))
    end
end

--[[
	Sets MovableSettings and fires TGU-MovableChanged callbacks
]]--
function TGU_SettingsHandler.SetStaticUltimateIDSettings(staticUltimateID)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_SettingsHandler.StaticUltimateIDSettings")
        _logger:logDebug("staticUltimateID", staticUltimateID)
    end

    TGU_SettingsHandler.SavedVariables.StaticUltimateID = staticUltimateID

    CALLBACK_MANAGER:FireCallbacks(TGU_STATIC_ULTIMATE_ID_CHANGED, staticUltimateID)
end

--[[
	Sets MovableSettings and fires TGU-MovableChanged callbacks
]]--
function TGU_SettingsHandler.SetSwimlaneUltimateGroupIdSettings(swimlane, ultimateGroup)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_SettingsHandler.StaticUltimateIDSettings")
        _logger:logDebug("swimlane", swimlane)
        _logger:logDebug("ultimateGroup", ultimateGroup)
    end

    TGU_SettingsHandler.SavedVariables.SwimlaneUltimateGroupIds[swimlane] = ultimateGroup.GroupAbilityId

    CALLBACK_MANAGER:FireCallbacks(TGU_SWIMLANE_ULTIMATE_GROUP_ID_CHANGED, swimlane, ultimateGroup)
end

--[[
	Sets MovableSettings and fires TGU-MovableChanged callbacks
]]--
function TGU_SettingsHandler.SetMovableSettings(movable)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_SettingsHandler.SetMovableSettings")
        _logger:logDebug("movable", movable)
    end

    TGU_SettingsHandler.SavedVariables.Movable = movable

    CALLBACK_MANAGER:FireCallbacks(TGU_MOVABLE_CHANGED, movable)
end

--[[
	Sets MovableSettings and fires TGU-MovableChanged callbacks
]]--
function TGU_SettingsHandler.SetOnlyAvaSettings(onlyAva)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_SettingsHandler.SetOnlyAvaSettings")
        _logger:logDebug("onlyAva", onlyAva)
    end

    TGU_SettingsHandler.SavedVariables.OnlyAva = onlyAva

    CALLBACK_MANAGER:FireCallbacks(TGU_IS_ZONE_CHANGED)
end

--[[
	Sets IsLgsActive settings
]]--
function TGU_SettingsHandler.SetIsLgsActiveSettings(isLgsActive)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_SettingsHandler.SetIsLgsActiveSettings")
        _logger:logDebug("isLgsActive", isLgsActive)
    end

    TGU_SettingsHandler.SavedVariables.IsLgsActive = isLgsActive
end

--[[
        Sets Swimlane max value
]]--
function TGU_SettingsHandler.TGU_SetSwimlaneMax(max)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_SettingsHandler.TGU_SetSwimlaneMax")
        _logger:logDebug("SwimlaneMax", max)
    end
    TGU_SettingsHandler.SavedVariables.SwimlaneMax = max
end

--[[
        Set whether to show ultimate number on screen
]]--
function TGU_SettingsHandler.TGU_SetUltNumberShow(val)
    TGU_SettingsHandler.SavedVariables.UltNumberShow = val
    TGU_UltNumber:SetHidden(not value)
end

--[[
        Set whether to play a sound when you hit #1 in ultimate order
]]--
function TGU_SettingsHandler.TGU_SetWereNumberOne(val)
    TGU_SettingsHandler.SavedVariables.WereNumberOne = val
end

--[[
	Sets IsSortingActive settings
]]--
function TGU_SettingsHandler.SetIsSortingActiveSettings(isSortingActive)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_SettingsHandler.SetIsLgsActiveSettings")
        _logger:logDebug("isSortingActive", isSortingActive)
    end

    TGU_SettingsHandler.SavedVariables.IsSortingActive = isSortingActive
end

--[[
	Gets SimpleList visible in connection with selected style
]]--
function TGU_SettingsHandler.IsSimpleListVisible()
    if (LOG_ACTIVE) then _logger:logTrace("TGU_SettingsHandler.IsSimpleListVisible") end
    if (TGU_SettingsHandler.SavedVariables ~= nil) then
        if (LOG_ACTIVE) then _logger:logDebug("style", TGU_SettingsHandler.SavedVariables.Style) end
        return tonumber(TGU_SettingsHandler.SavedVariables.Style) == 2 and TGU_SettingsHandler.IsControlsVisible()
    else
        _logger:logError("TGU_SettingsHandler.SavedVariables is nil")
        return false
    end
end

--[[
	Gets SwimlaneList visible in connection with selected style
]]--
function TGU_SettingsHandler.IsSwimlaneListVisible()
    if (LOG_ACTIVE) then _logger:logTrace("TGU_SettingsHandler.IsSwimlaneListVisible") end
    if (TGU_SettingsHandler.SavedVariables ~= nil) then
        if (LOG_ACTIVE) then _logger:logDebug("style", TGU_SettingsHandler.SavedVariables.Style) end
        return tonumber(TGU_SettingsHandler.SavedVariables.Style) == 1 and TGU_SettingsHandler.IsControlsVisible()
    else
        _logger:logError("TGU_SettingsHandler.SavedVariables is nil")
        return false
    end
end

--[[
	Gets CompactSwimlaneList visible in connection with selected style
]]--
function TGU_SettingsHandler.IsCompactSwimlaneListVisible()
    if (LOG_ACTIVE) then _logger:logTrace("TGU_SettingsHandler.IsCompactSwimlaneListVisible") end
    if (TGU_SettingsHandler.SavedVariables ~= nil) then
        if (LOG_ACTIVE) then _logger:logDebug("style", TGU_SettingsHandler.SavedVariables.Style) end
        return tonumber(TGU_SettingsHandler.SavedVariables.Style) == 3 and TGU_SettingsHandler.IsControlsVisible()
    else
        _logger:logError("TGU_SettingsHandler.SavedVariables is nil")
        return false
    end
end

--[[
	Gets CompactSwimlaneList visible in connection with selected style
]]--
function TGU_SettingsHandler.IsControlsVisible()
    if (LOG_ACTIVE) then _logger:logTrace("TGU_SettingsHandler.IsControlsVisible") end
    if (TGU_SettingsHandler.SavedVariables ~= nil) then
        if (LOG_ACTIVE) then _logger:logDebug("onlyAvA", TGU_SettingsHandler.SavedVariables.OnlyAva) end
        if (TGU_SettingsHandler.SavedVariables.OnlyAva) then
            _logger:logDebug("isPlayerInAvAWorld", IsPlayerInAvAWorld())
            return IsPlayerInAvAWorld()
        else
            return true
        end
    else
        _logger:logError("TGU_SettingsHandler.SavedVariables is nil")
        return false
    end
end

--[[
	OnPlayerActivated sends IsZoneChanged event
]]--
function TGU_SettingsHandler.OnPlayerActivated(eventCode)
    if (LOG_ACTIVE) then 
        _logger:logTrace("TGU_SettingsHandler.OnPlayerActivated")
    end

    CALLBACK_MANAGER:FireCallbacks(TGU_IS_ZONE_CHANGED)
end

--[[
	Initialize loads SavedVariables
]]--
function TGU_SettingsHandler.Initialize(logger)
    if (LOG_ACTIVE) then logger:logTrace("TGU_SettingsHandler.Initialize") end

    _logger = logger

    TGU_SettingsHandler.SavedVariables = ZO_SavedVars:NewAccountWide(TGU_SettingsHandler.SettingsName, SETTINGS_VERSION, nil, TGU_SettingsHandler.Default)

    -- Register
    EVENT_MANAGER:RegisterForEvent(TGU_SettingsHandler.Name, EVENT_PLAYER_ACTIVATED, TGU_SettingsHandler.OnPlayerActivated)
end
