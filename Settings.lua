--[[
	Local variables
]]--
local SETTINGS_VERSION = 5

--[[
	Table POC_Settings
]]--
POC_Settings = {
    Name = "POC_Settings",
    SettingsName = "POCSettings",
    SavedVariables = nil,
    Default = {
	AtNames = false,
	GroupMembers = {},
	MIA = true,
	MapIndex = 14,
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
local saved

-- Sets SetStyleSettings and fires POC-StyleChanged callbacks
--
function POC_Settings.SetStyleSettings(style)
    saved.Style = style

    CALLBACK_MANAGER:FireCallbacks(POC_STYLE_CHANGED)
end

-- Set our ultimate
--
function POC_Settings.SetStaticUltimateIDSettings(ultid)
    if saved.MyUltId == nil then
	saved.MyUltId = {}
    end
    saved.MyUltId[ultix] = ultid

    CALLBACK_MANAGER:FireCallbacks(POC_STATIC_ULTIMATE_ID_CHANGED, ultid)
end

-- Set the ultimate to use for a specific swimlane
--
function POC_Settings.SetSwimlaneUltId(swimlane, aid)
    saved.SwimlaneUltIds[swimlane] = aid

    CALLBACK_MANAGER:FireCallbacks(POC_SWIMLANE_ULTIMATE_GROUP_ID_CHANGED, swimlane, aid)
end

-- Control whether or not to show MIA lane
--
function POC_Settings.SetMIA(what)
    saved.MIA = what
    CALLBACK_MANAGER:FireCallbacks(POC_SWIMLANE_COLMAX_CHANGED, "Display MIA changed")
end

-- Sets MovableSettings and fires POC-MovableChanged callbacks
--
function POC_Settings.SetMovableSettings(movable)
    saved.Movable = movable

    CALLBACK_MANAGER:FireCallbacks(POC_MOVABLE_CHANGED, movable)
end

-- Control whether to only display in PVP setting
--
function POC_Settings.SetOnlyAvaSettings(onlyAva)
    saved.OnlyAva = onlyAva

    CALLBACK_MANAGER:FireCallbacks(POC_ZONE_CHANGED)
end

-- Sets maximum number of cells in a swimlane
--
function POC_Settings.SetSwimlaneMax(max)
    saved.SwimlaneMax = max
end

-- Sets maximum number of swimlanes
--
function POC_Settings.SetSwimlaneMaxCols(max)
    saved.SwimlaneMaxCols = max
    CALLBACK_MANAGER:FireCallbacks(POC_SWIMLANE_COLMAX_CHANGED)
end

-- Set whether to show ultimate number on screen
--
function POC_Settings.SetUltNumberShow(show)
    saved.UltNumberShow = show
end

-- Set whether to play a sound when you hit #1 in ultimate order
--
function POC_Settings.SetWereNumberOne(val)
    saved.WereNumberOne = val
end

-- Return Swimlane visibility
--
function POC_Settings.IsSwimlaneListVisible()
    return POC_Settings.IsControlsVisible()
end


-- Return control visibility
--
function POC_Settings.IsControlsVisible()
    if not POC_Comm.IsActive() then
	return false
    elseif saved.OnlyAva then
	return IsPlayerInAvAWorld()
    else
	return true
    end
end

-- OnPlayerActivated sends ZoneChanged event
--
function POC_Settings.OnPlayerActivated(eventCode)
    CALLBACK_MANAGER:FireCallbacks(POC_ZONE_CHANGED)
end

-- Initialize/create settings window
--
function POC_Settings.InitializeWindow(major, minor, patch)
    local default = POC_Settings.Default
    local styleChoices = {
	[1] = GetString(POC_OPTIONS_STYLE_SWIM),
	[2] = GetString(POC_OPTIONS_STYLE_SHORT_SWIM)
    }
    local paneldata = {
	    type = "panel",
	    name = "Piece Of Candy",
	    author = "TProg Taonnor & Valandil",
	    version = major .. "." .. minor .. "." .. patch,
	    slashCommand = "/poc",
	    registerForDefaults = true
    }

    local o = {}
    o[#o + 1] = {
	type = "header",
	name = GetString(POC_OPTIONS_HEADER),
     }
    o[#o + 1] = {
	type = "checkbox",
	name = GetString(POC_OPTIONS_DRAG_LABEL),
	tooltip = GetString(POC_OPTIONS_DRAG_TOOLTIP),
	getFunc = function()
	    return saved.Movable
	end,
	setFunc = function(value)
	    POC_Settings.SetMovableSettings(value)
	end,
	default = default.Movable
    }
    o[#o + 1] = {
	type = "checkbox",
	name = GetString(POC_OPTIONS_ONLY_AVA_LABEL),
	tooltip = GetString(POC_OPTIONS_ONLY_AVA_TOOLTIP),
	getFunc = function()
	    return saved.OnlyAva
	end,
	setFunc = function(value)
	    POC_Settings.SetOnlyAvaSettings(value)
	end,
	default = default.OnlyAva
    }
    o[#o + 1] = {
	type = "iconpicker",
	name = "Choose your ultimate",
	choices = POC_Ult.Icons(),
	choicesTooltips = POC_Ult.Descriptions(),
	getFunc = POC_Ult.GetSaved,
	setFunc = POC_Ult.SetSaved,
	maxColumns = 7,
	visibleRows = 6,
	iconSize = 64
    }
    o[#o + 1] = {
	type = "divider",
	name = "DividerWeStand"
    }
    o[#o + 1] = {
	type = "dropdown",
	name = GetString(POC_OPTIONS_STYLE_LABEL),
	tooltip = GetString(POC_OPTIONS_STYLE_TOOLTIP),
	choices = styleChoices,
	getFunc = function()
	    return saved.Style
	end,
	setFunc = function(value)
	    POC_Settings.SetStyleSettings(value)
	end,
	default = default.Style
    }
    o[#o + 1] = {
	type = "slider",
	name = GetString(POC_OPTIONS_SWIMLANE_MAX_LABEL),
	min = 1, max = 24, step = 1,
	getFunc = function() return saved.SwimlaneMax end,
	width = "full",
	setFunc = function(value) POC_Settings.SetSwimlaneMax(value) end,
	default = 24,
    }
    o[#o + 1] = {
	type = "slider",
	name = "Max number of swimlanes to display",
	min = 1, max = 6, step = 1,
	getFunc = function() return saved.SwimlaneMaxCols end,
	width = "full",
	setFunc = function(value) POC_Settings.SetSwimlaneMaxCols(value) end,
	default = 6,
    }
    o[#o + 1] = {
	type = "checkbox",
	name = "Show login names in swimlanes",
	tooltip = "Show login name rather than current character name",
	getFunc = function()
	    return saved.AtNames
	end,
	setFunc = function(x)
	    saved.AtNames = x
	    CALLBACK_MANAGER:FireCallbacks(POC_ZONE_CHANGED)
	end,
	default = default.AtNames
    }
    o[#o + 1] = {
	type = "checkbox",
	name = GetString(POC_OPTIONS_ULTIMATE_NUMBER),
	tooltip = GetString(POC_OPTIONS_ULTIMATE_NUMBER_TOOLTIP),
	getFunc = function()
	    return saved.UltNumberShow
	end,
	setFunc = function(val) POC_Settings.SetUltNumberShow(val) end,
	default = default.UltNumberShow
    }
    o[#o + 1] = {
	type = "checkbox",
	name = GetString(POC_OPTIONS_WERE_NUMBER_ONE),
	tooltip = GetString(POC_OPTIONS_WERE_NUMBER_ONE_TOOLTIP),
	getFunc = function()
	    return saved.WereNumberOne
	end,
	setFunc = function(val) POC_Settings.SetWereNumberOne(val) end,
	default = default.WereNumberOne
    }
    o[#o + 1] = {
	type = "checkbox",
	name = "Show MIA swimlane",
	tooltip = "Show/hide swimlane containing players who are not in zone or not displayed on any other swimlane",
	getFunc = function()
	    return saved.MIA
	end,
	setFunc = function(val) POC_Settings.SetMIA(val) end,
	default = default.MIA
    }

    local LAM = LibStub("LibAddonMenu-2.0")
    local paneldata = {
	    type = "panel",
	    name = "Piece Of Candy",
	    author = "Valandil",
	    version = major .. "." .. minor .. "." .. patch,
	    slashCommand = "/poc",
	    registerForDefaults = true
    }
    LAM:RegisterAddonPanel("POCSettingsMainMenu", paneldata)
    LAM:RegisterOptionControls("POCSettingsMainMenu", o)
end

local function getmapindex(name)
    if name:len() == 0 then
	d("Reference map is " ..  GetMapNameByIndex(saved.MapIndex) .. " (" .. tostring(saved.MapIndex) .. ")")
	return
    end
    local lname = name:lower()
    for i = 1, GetNumMaps() do
	if GetMapNameByIndex(i):lower() == lname then
	    saved.MapIndex = i
	    d("Setting reference map to " .. GetMapNameByIndex(i) .. " (" .. tostring(i) .. ")")
	    return
	end
    end
    POC_Error("unknown map - " .. name)
end

-- Load SavedVariables
--
function POC_Settings.Initialize()
    saved = ZO_SavedVars:NewAccountWide(POC_Settings.SettingsName, SETTINGS_VERSION, nil, POC_Settings.Default)
    POC_Settings.SavedVariables = saved

    --  Obsolete variables
    saved.SwimlaneUltimateGroupIds = nil
    saved.StaticUltimateID = nil
    saved.SwimlaneUltGrpIds = nil
    saved.IsLgsActive = nil

    -- The last one is always MIA
    saved.SwimlaneUltIds[7] = 'MIA'

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
    SLASH_COMMANDS["/pocmap"] = getmapindex
end
