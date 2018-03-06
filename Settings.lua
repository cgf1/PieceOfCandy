setfenv(1, POC)
local SETTINGS_VERSION = 5

Settings = {
    Name = "POC-Settings",
    SettingsName = "POCSettings",
    SavedVariables = nil,
    Default = {
	AtNames = false,
	ChalKeep = false,
	ChalMine = false,
	GroupMembers = {},
	MIA = true,
	MapIndex = 30,  -- Vvardenfell
	Movable = true,
	MyUltId = {},
	OnlyAva = false,
	PosX = 0,
	PosY = 0,
	Style = "Standard",
	SwimlaneMax = 24,
	SwimlaneMaxCols = 6,
	LaneIds = {
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
Settings.__index = Settings

local ultix = GetUnitName("player")
local saved

-- Sets SetStyleSettings and fires POC-StyleChanged callbacks
--
function Settings.SetStyleSettings(style)
    saved.Style = style

    CALLBACK_MANAGER:FireCallbacks(STYLE_CHANGED)
end

-- Set our ultimate
--
function Settings.SetStaticUltimateIDSettings(ultid)
    if saved.MyUltId == nil then
	saved.MyUltId = {}
    end
    saved.MyUltId[ultix] = ultid

    CALLBACK_MANAGER:FireCallbacks(STATIC_ULTIMATE_ID_CHANGED, ultid)
end

-- Set the ultimate to use for a specific swimlane
--
function Settings.SetSwimlaneUltId(swimlane, aid)
    saved.LaneIds[swimlane] = aid

    CALLBACK_MANAGER:FireCallbacks(SWIMLANE_ULTIMATE_GROUP_ID_CHANGED, swimlane, aid)
end

-- Control whether or not to show MIA lane
--
function Settings.SetMIA(what)
    saved.MIA = what
    CALLBACK_MANAGER:FireCallbacks(SWIMLANE_COLMAX_CHANGED, "Display MIA changed")
end

-- Sets MovableSettings and fires POC-MovableChanged callbacks
--
function Settings.SetMovableSettings(movable)
    saved.Movable = movable

    CALLBACK_MANAGER:FireCallbacks(MOVABLE_CHANGED, movable)
end

-- Control whether to only display in PVP setting
--
function Settings.SetOnlyAvaSettings(onlyAva)
    saved.OnlyAva = onlyAva

    Swimlanes.Update("AVA")
end

-- Sets maximum number of cells in a swimlane
--
function Settings.SetSwimlaneMax(max)
    saved.SwimlaneMax = max
end

-- Sets maximum number of swimlanes
--
function Settings.SetSwimlaneMaxCols(max)
    saved.SwimlaneMaxCols = max
    CALLBACK_MANAGER:FireCallbacks(SWIMLANE_COLMAX_CHANGED)
end

-- Set whether to show ultimate number on screen
--
function Settings.SetUltNumberShow(show)
    saved.UltNumberShow = show
end

-- Set whether to play a sound when you hit #1 in ultimate order
--
function Settings.SetWereNumberOne(val)
    saved.WereNumberOne = val
end

-- Return Swimlane visibility
--
function Settings.IsSwimlaneListVisible()
    return Settings.IsControlsVisible()
end


-- Return control visibility
--
function Settings.IsControlsVisible()
    if not Comm.IsActive() then
	return false
    elseif saved.OnlyAva then
	return IsPlayerInAvAWorld()
    else
	return true
    end
end

-- Initialize/create settings window
--
function Settings.InitializeWindow(major, minor, patch)
    local default = Settings.Default
    local styleChoices = {
	[1] = GetString(OPTIONS_STYLE_SWIM),
	[2] = GetString(OPTIONS_STYLE_SHORT_SWIM)
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
	name = GetString(OPTIONS_HEADER),
     }
    o[#o + 1] = {
	type = "checkbox",
	name = GetString(OPTIONS_DRAG_LABEL),
	tooltip = GetString(OPTIONS_DRAG_TOOLTIP),
	getFunc = function()
	    return saved.Movable
	end,
	setFunc = function(value)
	    Settings.SetMovableSettings(value)
	end,
	default = default.Movable
    }
    o[#o + 1] = {
	type = "checkbox",
	name = GetString(OPTIONS_ONLY_AVA_LABEL),
	tooltip = GetString(OPTIONS_ONLY_AVA_TOOLTIP),
	getFunc = function()
	    return saved.OnlyAva
	end,
	setFunc = function(value)
	    Settings.SetOnlyAvaSettings(value)
	end,
	default = default.OnlyAva
    }
    o[#o + 1] = {
	type = "iconpicker",
	name = "Choose your primary ultimate",
	choices = Ult.Icons(),
	choicesTooltips = Ult.Descriptions(),
	getFunc = function()
	    return Ult.GetSaved(1)
	end,
	setFunc = function(icon)
	    Ult.SetSavedFromIcon(icon, 1)
	end,
	maxColumns = 7,
	visibleRows = 5,
	iconSize = 64
    }
    if false then
    o[#o + 1] = {
	type = "iconpicker",
	name = "Choose your secondary ultimate",
	choices = Ult.Icons(),
	choicesTooltips = Ult.Descriptions(),
	getFunc = function()
	    return Ult.GetSaved(2)
	end,
	setFunc = function(icon)
	    Ult.SetSavedFromIcon(icon, 2)
	end,
	maxColumns = 7,
	visibleRows = 5,
	iconSize = 64
    }
    end
    o[#o + 1] = {
	type = "divider",
	name = "DividerWeStand"
    }
    o[#o + 1] = {
	type = "dropdown",
	name = GetString(OPTIONS_STYLE_LABEL),
	tooltip = GetString(OPTIONS_STYLE_TOOLTIP),
	choices = styleChoices,
	getFunc = function()
	    return saved.Style
	end,
	setFunc = function(value)
	    Settings.SetStyleSettings(value)
	end,
	default = default.Style
    }
    o[#o + 1] = {
	type = "slider",
	name = GetString(OPTIONS_SWIMLANE_MAX_LABEL),
	min = 1, max = 24, step = 1,
	getFunc = function() return saved.SwimlaneMax end,
	width = "full",
	setFunc = function(value) Settings.SetSwimlaneMax(value) end,
	default = 24,
    }
    o[#o + 1] = {
	type = "slider",
	name = "Max number of swimlanes to display",
	min = 1, max = 6, step = 1,
	getFunc = function() return saved.SwimlaneMaxCols end,
	width = "full",
	setFunc = function(value) Settings.SetSwimlaneMaxCols(value) end,
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
	    if x ~= saved.AtNames then
		saved.AtNames = x
		Swimlanes.Update("Player name display style changed")
	    end
	end,
	default = default.AtNames
    }
    o[#o + 1] = {
	type = "checkbox",
	name = GetString(OPTIONS_ULTIMATE_NUMBER),
	tooltip = GetString(OPTIONS_ULTIMATE_NUMBER_TOOLTIP),
	getFunc = function()
	    return saved.UltNumberShow
	end,
	setFunc = function(val) Settings.SetUltNumberShow(val) end,
	default = default.UltNumberShow
    }
    o[#o + 1] = {
	type = "checkbox",
	name = GetString(OPTIONS_WERE_NUMBER_ONE),
	tooltip = GetString(OPTIONS_WERE_NUMBER_ONE_TOOLTIP),
	getFunc = function()
	    return saved.WereNumberOne
	end,
	setFunc = function(val) Settings.SetWereNumberOne(val) end,
	default = default.WereNumberOne
    }
    o[#o + 1] = {
	type = "checkbox",
	name = "Show MIA swimlane",
	tooltip = "Show/hide swimlane containing players who are not in zone or not displayed on any other swimlane",
	getFunc = function()
	    return saved.MIA
	end,
	setFunc = function(val) Settings.SetMIA(val) end,
	default = default.MIA
    }
    o[#o + 1] = {
	type = "divider",
	name = "DividerWeStand"
    }
    o[#o + 1] = {
	type = "checkbox",
	name = "Automatically ask for Chalman Keep quest",
	tooltip = "Notice when you're lacking the Chalman Mine quest and ask for it from other players in group",
	getFunc = function()
	    return saved.ChalKeep
	end,
	setFund = function(val)
	    saved.ChalKeep = true
	end,
	default = saved.ChalKeep
    }
    o[#o + 1] = {
	type = "checkbox",
	name = "Automatically ask for Chalman Keep quest",
	tooltip = "Notice when you're lacking the Chalman Mine quest and ask for it from other players in group",
	getFunc = function()
	    return saved.ChalMine
	end,
	setFund = function(val)
	    saved.ChalMine = true
	end,
	default = saved.ChalMine
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
    Error("unknown map - " .. name)
end

-- Load SavedVariables
--
function Settings.Initialize()
    saved = ZO_SavedVars:NewAccountWide(Settings.SettingsName, SETTINGS_VERSION, nil, Settings.Default)
    Settings.SavedVariables = saved

    --  Obsolete variables
    saved.SwimlaneUltimateGroupIds = nil
    saved.StaticUltimateID = nil
    saved.SwimlaneUltGrpIds = nil
    saved.IsLgsActive = nil

    SLASH_COMMANDS["/pocstyle"] = function(style)
	style = string.lower(style):gsub("^%l", string.upper)
	if (style ~= "Compact" and style ~= "Standard") then
	    d("POC: *** unknown style: " .. style)
	else
	    Settings.SetStyleSettings(style)
	end
    end
    SLASH_COMMANDS["/pocmap"] = getmapindex
end
