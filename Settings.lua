setfenv(1, POC)
local SETTINGS_VERSION = 5

Settings = {
    Name = "POC-Settings",
    SettingsName = "POCSettings",
    SavedVariables = nil,
    Default = {
	AcceptPVP = false,
	AtNames = false,
	ChalKeep = false,
	ChalMine = false,
	GroupMembers = {},
	LaneIds = {
	    1,	-- Negate
	    6,	-- Templar Heal
	    16, -- Destro fire ultimate
	    13, -- Warden Permafrost
	    27, -- Dawnbreaker
	    26, -- Meteor
	    28, -- Barrier
	    29, -- War horn
	    12, -- Soul tether
	    14	-- Warden heal
	},
	MIA = true,
	MapIndex = 30,	-- Vvardenfell
	MyUltId = {},
	NeedsHelp = true,
	OnlyAva = false,
	RelaxedCampaignAccept = false,
	ShareQuests = true,
	Style = "Standard",
	SwimlaneMax = 24,
	SwimlaneMaxCols = 6,
	UltAlert = true,
	UltNoise = false,
	UltNumberPos = nil,
	UltNumberShow = true,
	WarnConflict = true,
	WereNumberOne = true
    }
}
Settings.__index = Settings

local ultix = GetUnitName("player")
local saved

-- Sets SetStyleSettings and fires POC-StyleChanged callbacks
--
function Settings.SetStyleSettings(style)
    if style ~= saved.Style then
	saved.Style = style
	Swimlanes.Redo()
    end
end

-- Control whether or not to show MIA lane
--
function Settings.SetMIA(what)
    saved.MIA = what
    Swimlanes.Redo()
end

-- Sets maximum number of cells in a swimlane
--
function Settings.SetSwimlaneMax(max)
    if type(max) ~= 'number' then
	max = tonumber(max)
    end
    saved.SwimlaneMax = max
end

-- Sets maximum number of swimlanes
--
function Settings.SetSwimlaneMaxCols(max)
    if type(max) ~= 'number' then
	max = tonumber(max)
    end
    saved.SwimlaneMaxCols = max
    Swimlanes.Redo()
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

-- Initialize/create settings window
--
function Settings.InitializeWindow(version)
    local default = Settings.Default
    local styleChoices = {
	[1] = GetString(OPTIONS_STYLE_SWIM),
	[2] = GetString(OPTIONS_STYLE_SHORT_SWIM)
    }
    local o = {}
    o[#o + 1] = {
	type = "header",
	name = GetString(OPTIONS_HEADER),
    }
    o[#o + 1] = {
	type = "checkbox",
	name = GetString(OPTIONS_ONLY_AVA_LABEL),
	tooltip = GetString(OPTIONS_ONLY_AVA_TOOLTIP),
	getFunc = function()
	    return saved.OnlyAva
	end,
	setFunc = function(value)
	    saved.OnlyAva = value
	    Swimlanes.Update("AVA")
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
	iconSize = 32
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
	min = 1, max = SWIMLANES, step = 1,
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
		Swimlanes.Sched(true)
		Swimlanes.Update("Player name display style changed", true)
	    end
	end,
	default = default.AtNames
    }
    o[#o + 1] = {
	type = "checkbox",
	name = "Show ultimate alerts",
	tooltip = "Display player's ultimate on screen shortly after ultimate is used",
	getFunc = function()
	    return saved.UltAlert
	end,
	setFunc = function(val) saved.UltAlert = val end,
	default = default.UltAlert
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
	name = "Automatically share quests",
	tooltip = "Automatically share Chalman and Kill Enemy players when needed/requested",
	getFunc = function()
	    return saved.ShareQuests
	end,
	setFunc = Quest.Share,
	default = default.ShareQuests
    }
    o[#o + 1] = {
	type = "checkbox",
	name = "Automatically request Chalman Keep quest",
	tooltip = "Notice when you're lacking the Chalman Keep quest and silently acquire it from other players in group",
	getFunc = function()
	    return Quest.Want(KEEP_INDEX)
	end,
	setFunc = function(val)
	    Quest.Want(KEEP_INDEX, val)
	end
    }
    o[#o + 1] = {
	type = "checkbox",
	name = "Automatically request Chalman Mine quest",
	tooltip = "Notice when you're lacking the Chalman Mine quest and silently acquire it from other players in group",
	getFunc = function()
	    return Quest.Want(RESOURCE_INDEX)
	end,
	setFunc = function(val)
	    Quest.Want(RESOURCE_INDEX, val)
	end
    }
    o[#o + 1] = {
	type = "checkbox",
	name = 'Accept "Needs Help" alerts from group members',
	tooltip = "Display a \"Needs Help\" message and a sound when someone in your group presses a key.  Requires setting a key in Controls",
	getFunc = function()
	    return saved.NeedsHelp
	end,
	setFunc = function(val)
	    saved.NeedsHelp = true
	end,
	default = default.NeedsHelp
    }
    o[#o + 1] = {
	type = "checkbox",
	name = "Automatically accept request to enter Cyrodiil",
	tooltip = "Automatically accept the \"Do you want to enter Cyrodiil?\" prompt for your specified (current default is \"Vivec\") campaign",
	getFunc = function()
	    return saved.AcceptPVP
	end,
	setFunc = function(val)
	    saved.AcceptPVP = true
	end
    }
    o[#o + 1] = {
	type = "checkbox",
	name = "Only accept request for campaign specified via /poccampaign",
	tooltip = "Accept all requests to enter campaign, regardless of whether they are for your main campaign",
	getFunc = function()
	    return saved.RelaxedCampaiginAccept
	end,
	setFunc = function(val)
	    saved.RelaxedCampaignAccept = true
	end
    }
    o[#o + 1] = {
	type = "checkbox",
	name = "Play a distinctive noise when your ultimate fires",
	tooltip = "Automatically plays a noise when your ultimate actually goes off",
	getFunc = function()
	    return saved.UltNoise
	end,
	setFunc = function(val)
	    saved.UltNoise = true
	end
    }
    o[#o + 1] = {
	type = "checkbox",
	name = "Warn when conflicting add-ons are detected",
	tooltip = "Display a warning window when a conflicting add-on (like Sanct's Ultimate Organizer) is detected",
	getFunc = function()
	    return saved.WarnConflict
	end,
	setFunc = function(val)
	    saved.WarnConflict = val
	end
    }

    local LAM = LibStub("LibAddonMenu-2.0")
    local manager = GetAddOnManager()
    local name, title, author, description
    for i = 1, manager:GetNumAddOns() do
	name, title, author, description = manager:GetAddOnInfo(i)
	if name == "POC" then
	    break
	end
    end

    local paneldata = {
	    type = "panel",
	    name = title,
	    displayName = "|c00B50F" .. title .. "|r",
	    author = author,
	    description = description,
	    version = version,
	    registerForDefaults = true
    }
    Panel = LAM:RegisterAddonPanel("POCSettingsMainMenu", paneldata)
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

    --	Obsolete variables
    saved.SwimlaneUltimateGroupIds = nil
    saved.StaticUltimateID = nil
    saved.SwimlaneUltGrpIds = nil
    saved.IsLgsActive = nil
    saved.CountdownNumberPos = nil
    saved.Movable = nil
    if saved.PosX ~= nil and saved.PosY ~= nil then
	saved.WinPos = {
	    X = saved.PosX,
	    Y = saved.PosY
	}
    end
    saved.PosX = nil
    saved.PosY = nil
    if saved.SwimlaneMaxCols > SWIMLANES then
	saved.SwimlaneMaxCols = SWIMLANES
    end

    Slash("style", 'set display style: "standard" or "compact"', function(style)
	style = string.lower(style):gsub("^%l", string.upper)
	if (style ~= "Compact" and style ~= "Standard") then
	    d("POC: *** unknown style: " .. style)
	else
	    Settings.SetStyleSettings(style)
	end
    end)
    Slash("map", "set map to use for communication", getmapindex)
    Slash("cols", "set max number of columns to display", Settings.SetSwimlaneMaxCols)
end
