setfenv(1, POC)
local SETTINGS_VERSION = 5

local ultix = GetUnitName("player")

local default = {
    AcceptPVP = false,
    AtNames = false,
    AutUlt = true,
    CommOff = false,
    GroupMembers = {},
    LaneIds = {
	1,	-- Negate
	6,	-- Templar Heal
	16,	-- Destro fire ultimate
	13,	-- Warden Permafrost
	27,	-- Dawnbreaker
	26,	-- Meteor
	28,	-- Barrier
	29,	-- War horn
	12,	-- Soul tether
	14	-- Warden heal
    },
    MIA = true,
    MapIndex = 30,	-- Vvardenfell
    MyUltId = {
	[ultix] = {}
    },
    NeedsHelp = true,
    OnlyAva = false,
    Quests = {},
    RelaxedCampaignAccept = false,
    ShareQuests = true,
    ShowUnusedCols = false,
    Style = "Standard",
    SwimlaneMax = 24,
    SwimlaneMaxCols = 6,
    Tooltips = true,
    UltAlert = true,
    UltNoise = false,
    UltNumberPos = nil,
    UltNumberShow = true,
    WarnConflict = true,
    WereNumberOne = true
}

Settings = {
    Name = "POCSettings",
    SavedVariables = nil
}
Settings.__index = Settings

local saved

-- Sets SetStyleSettings and fires POC-StyleChanged callbacks
--
local function set_style(style)
    if style ~= saved.Style then
	saved.Style = style
	Swimlanes.Redo()
    end
end

-- Control whether or not to show MIA lane
--

-- Sets maximum number of cells in a swimlane
--
local function set_max_rows(max)
    if type(max) ~= 'number' then
	max = tonumber(max)
    end
    saved.SwimlaneMax = max
end

-- Sets maximum number of swimlanes
--
local function set_max_cols(max)
    if type(max) ~= 'number' then
	max = tonumber(max)
    end
    saved.SwimlaneMaxCols = max
    Swimlanes.Redo()
end

-- Set whether to show ultimate number on screen
--
local function show_ult_number(show)
    saved.UltNumberShow = show
end

-- Set whether to play a sound when you hit #1 in ultimate order
--
local function were_number_one(val)
    saved.WereNumberOne = val
end

-- Initialize/create settings window
--
local function initialize_window(version)
    local default = default
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
	disabled = function () return saved.AutUlt end,
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
    o[#o + 1] = {
	type = "checkbox",
	name = "Choose main ultimate automatically",
	tooltip = "Use whatever is in main ultimate slot as your ultimate",
	getFunc = function()
	    return saved.AutUlt
	end,
	setFunc = function(x)
	    if x ~= saved.AutUlt then
		Player.SetUlt()
		saved.AutUlt = x
	    end
	end,
	default = default.AtNames
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
	setFunc = set_style,
	default = default.Style
    }
    o[#o + 1] = {
	type = "slider",
	name = GetString(OPTIONS_SWIMLANE_MAX_LABEL),
	min = 1, max = 24, step = 1,
	getFunc = function() return saved.SwimlaneMax end,
	width = "full",
	setFunc =  set_max_rows,
	default = 24,
    }
    o[#o + 1] = {
	type = "slider",
	name = "Max number of swimlanes to display",
	min = 1, max = Ult.MaxPing - 1, step = 1,
	getFunc = function() return saved.SwimlaneMaxCols end,
	width = "full",
	setFunc = set_max_cols,
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
	setFunc = show_ult_number,
	default = default.UltNumberShow
    }
    o[#o + 1] = {
	type = "checkbox",
	name = GetString(OPTIONS_WERE_NUMBER_ONE),
	tooltip = GetString(OPTIONS_WERE_NUMBER_ONE_TOOLTIP),
	getFunc = function()
	    return saved.WereNumberOne
	end,
	setFunc = were_number_one,
	default = default.WereNumberOne
    }
    o[#o + 1] = {
	type = "checkbox",
	name = "Show MIA swimlane",
	tooltip = "Show/hide swimlane containing players who are not using this addon or are not displayed on any other swimlane",
	getFunc = function()
	    return saved.MIA
	end,
	setFunc = function (what)
	    saved.MIA = what
	    Swimlanes.Redo()
	end,
	default = default.MIA
    }
    o[#o + 1] = {
	type = "checkbox",
	name = "Show unused swimlanes",
	tooltip = "Show/hide swimlane whose ultimate is currently unused by any player",
	getFunc = function()
	    return saved.ShowUnusedCols
	end,
	setFunc = function (what)
	    saved.ShowUnusedCols = what
	    Swimlanes.Redo()
	end,
	default = default.ShowUnusedCols
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
	setFunc = Quest.ShareThem,
	default = default.ShareQuests
    }
    o[#o + 1] = {
	type = "dropdown",
	name = "Automatically request/share keep quest",
	tooltip = "Notice when you're lacking the specified quest and silently acquire it from other players in group",
	choices = Quest.Choices('keep'),
	getFunc = function()
	    return Quest.Want('keep')
	end,
	setFunc = function(val)
	    Quest.Want('keep', val)
	end
    }
    o[#o + 1] = {
	type = "dropdown",
	name = 'Automatically request "Kill Enemy" quest',
	tooltip = "Notice when you're lacking the specified \"Kill Enemy\" quest and silently acquire it from other players in group",
	choices = Quest.Choices('kill'),
	getFunc = function()
	    return Quest.Want('kill')
	end,
	setFunc = function(val)
	    Quest.Want('kill', val)
	end
    }
    o[#o + 1] = {
	type = "dropdown",
	name = "Automatically request resource quest",
	tooltip = "Notice when you're lacking the specified resource quest and silently acquire it from other players in group",
	choices = Quest.Choices('resource'),
	getFunc = function()
	    return Quest.Want('resource')
	end,
	setFunc = function(val)
	    Quest.Want('resource', val)
	end
    }
    o[#o + 1] = {
	type = "dropdown",
	name = "Automatically request conquest quest",
	tooltip = "Notice when you're lacking the specified conquest quest and silently acquire it from other players in group",
	choices = Quest.Choices('conquest'),
	getFunc = function()
	    return Quest.Want('conquest')
	end,
	setFunc = function(val)
	    Quest.Want('conquest', val)
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
	    saved.UltNoise = val
	end
    }
    o[#o + 1] = {
	type = "checkbox",
	name = "Show tooltips",
	tooltip = "Show descriptive tooltip information when mousing over header or player display cells",
	getFunc = function()
	    return saved.Tooltips
	end,
	setFunc = function(val)
	    saved.Tooltips = val
	end,
	requiresReload = true,
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
    o[#o + 1] = {
	type = "editbox",
	name = "Automatically accept group invite requests from:",
	tooltip = "List of @names or character names from whom quests will be accepted without displaying a confirmation dialog",
	isMultiline = true,
	isExtraWide = true,
	getFunc = function()
	    return Group.AutoAccept()
	end,
	setFunc = function(val)
	    Group.AutoAccept(val)
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
	    registerForDefaults = true,
	    registerForRefresh = true
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

function Settings.GetSaved()
    saved = ZO_SavedVars:NewAccountWide(Settings.Name, SETTINGS_VERSION, nil, default)
    Settings.SavedVariables = saved
    return saved
end

function Settings.Initialize(version)
    -- Obsolete variables
    saved.SwimlaneUltimateGroupIds = nil
    saved.StaticUltimateID = nil
    saved.SwimlaneUltGrpIds = nil
    saved.IsLgsActive = nil
    saved.CountdownNumberPos = nil
    saved.Movable = false
    saved.KeepQuest = nil
    saved.KillQuest = nil
    saved.ResourceQuest = nil
    saved.DELETEME = nil

    if saved.PosX ~= nil and saved.PosY ~= nil then
	saved.WinPos = {
	    X = saved.PosX,
	    Y = saved.PosY
	}
    end
    saved.PosX = nil
    saved.PosY = nil
    initialize_window(version)

    Slash("style", 'set display style: "standard" or "compact"', function(style)
	style = string.lower(style):gsub("^%l", string.upper)
	if (style ~= "Compact" and style ~= "Standard") then
	    d("POC: *** unknown style: " .. style)
	else
	    set_style(style)
	end
    end)
    Slash("map", "set map to use for communication", getmapindex)
    Slash("cols", "set max number of columns to display", set_max_cols)
end
