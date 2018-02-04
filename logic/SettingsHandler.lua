--[[
	Local variables
]]--
local SETTINGS_VERSION = 5

--[[
	Table POC_Settings
]]--
POC_Settings = {
    Name = "POC-SettingsHandler",
    SettingsName = "POCSettings",
    SavedVariables = nil,
    Default = {
	GroupMembers = {},
	IsLgsActive = false,
	MIA = true,
	Movable = true,
	MyUltId = {},
	OnlyAva = false,
	PosX = 0,
	PosY = 0,
	Style = "Standard",
	SwimlaneMax = 24,
	SwimlaneMaxCols = 6,
	SwimlaneUltIds = {
	    [1] = 29861,
	    [2] = 27413,
	    [3] = 86536,
	    [4] = 86112,
	    [5] = 46537,
	    [6] = 46622,
	    [7] = 'MIA'
	},
	UltNumberPos = nil,
	UltNumberShow = true,
	WereNumberOne = true
    }
}
POC_Settings.__index = POC_Settings

local ultix = GetUnitName("player")

--[[
	Sets SetStyleSettings and fires POC-StyleChanged callbacks
]]--
function POC_Settings.SetStyleSettings(style)
    POC_Settings.SavedVariables.Style = style

    CALLBACK_MANAGER:FireCallbacks(POC_STYLE_CHANGED)
end

-- Set our ultimate
--
function POC_Settings.SetStaticUltimateIDSettings(ultid)
    if POC_Settings.SavedVariables.MyUltId == nil then
	POC_Settings.SavedVariables.MyUltId = {}
    end
    POC_Settings.SavedVariables.MyUltId[ultix] = ultid

    CALLBACK_MANAGER:FireCallbacks(POC_STATIC_ULTIMATE_ID_CHANGED, ultid)
end

-- Set the ultimate to use for a specific swimlane
--
function POC_Settings.SetSwimlaneUltId(swimlane, ult)
    POC_Settings.SavedVariables.SwimlaneUltIds[swimlane] = ult.Gid

    CALLBACK_MANAGER:FireCallbacks(POC_SWIMLANE_ULTIMATE_GROUP_ID_CHANGED, swimlane, ult)
end

-- Control whether or not to show MIA lane
--
function POC_Settings.SetMIA(what)
    POC_Settings.SavedVariables.MIA = what
    CALLBACK_MANAGER:FireCallbacks(POC_SWIMLANE_COLMAX_CHANGED, "Display MIA changed")
end

-- Sets MovableSettings and fires POC-MovableChanged callbacks
--
function POC_Settings.SetMovableSettings(movable)
    POC_Settings.SavedVariables.Movable = movable

    CALLBACK_MANAGER:FireCallbacks(POC_MOVABLE_CHANGED, movable)
end

--[[
	Sets MovableSettings and fires POC-MovableChanged callbacks
]]--
function POC_Settings.SetOnlyAvaSettings(onlyAva)
    POC_Settings.SavedVariables.OnlyAva = onlyAva

    CALLBACK_MANAGER:FireCallbacks(POC_IS_ZONE_CHANGED)
end

--[[
	Sets IsLgsActive settings
]]--
function POC_Settings.SetIsLgsActiveSettings(isLgsActive)
    POC_Settings.SavedVariables.IsLgsActive = isLgsActive
end

-- Sets maximum number of cells in a swimlane
--
function POC_Settings.SetSwimlaneMax(max)
    POC_Settings.SavedVariables.SwimlaneMax = max
end

-- Sets maximum number of swimlanes
--
function POC_Settings.SetSwimlaneMaxCols(max)
    POC_Settings.SavedVariables.SwimlaneMaxCols = max
    CALLBACK_MANAGER:FireCallbacks(POC_SWIMLANE_COLMAX_CHANGED)
end

--[[
	Set whether to show ultimate number on screen
]]--
function POC_Settings.SetUltNumberShow(show)
    POC_Settings.SavedVariables.UltNumberShow = show
end

--[[
	Set whether to play a sound when you hit #1 in ultimate order
]]--
function POC_Settings.SetWereNumberOne(val)
    POC_Settings.SavedVariables.WereNumberOne = val
end

--[[
	Sets IsSortingActive settings
]]--
function POC_Settings.SetIsSortingActiveSettings(isSortingActive)
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
    if (POC_Settings.SavedVariables ~= nil) then
	if (POC_Settings.SavedVariables.OnlyAva) then
	    return IsPlayerInAvAWorld()
	else
	    return true
	end
    else
	POC_Error("POC_Settings.SavedVariables is nil")
	return false
    end
end

--[[
	OnPlayerActivated sends IsZoneChanged event
]]--
function POC_Settings.OnPlayerActivated(eventCode)
    CALLBACK_MANAGER:FireCallbacks(POC_IS_ZONE_CHANGED)
end

--[[
	Initialize loads SavedVariables
]]--
function POC_Settings.Initialize()
    POC_Settings.SavedVariables = ZO_SavedVars:NewAccountWide(POC_Settings.SettingsName, SETTINGS_VERSION, nil, POC_Settings.Default)
    POC_Settings.SavedVariables.SwimlaneUltimateGroupIds = nil
    POC_Settings.SavedVariables.StaticUltimateID = nil
    POC_Settings.SavedVariables.SwimlaneUltGrpIds = nil
    POC_Settings.SavedVariables.SwimlaneUltIds[7] = 'MIA'

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
