--[[
	Local variables
]]--
--[[
	Table SettingsWindow
]]--
POC_SettingsWindow = {}
POC_SettingsWindow.__index = POC_SettingsWindow

--[[
	Table Members
]]--
POC_SettingsWindow.MainMenuName = "POCSettingsMainMenu"

--[[
	Initialize creates settings window
]]--
function POC_SettingsWindow.Initialize(major, minor, patch)
    local styleChoices = {
	[1] = GetString(POC_OPTIONS_STYLE_SWIM),
	[2] = GetString(POC_OPTIONS_STYLE_SHORT_SWIM)
    }

    local panelData = {
	    type = "panel",
	    name = "Piece Of Candy",
	    author = "TProg Taonnor & Valandil",
	    version = major .. "." .. minor .. "." .. patch,
	    slashCommand = "/poc",
	    registerForDefaults = true
    }

    local optionsData = {}
    local o = optionsData
    o[#o + 1] = {
	type = "header",
	name = GetString(POC_OPTIONS_HEADER),
     }
    o[#o + 1] = {
	type = "checkbox",
	name = GetString(POC_OPTIONS_DRAG_LABEL),
	tooltip = GetString(POC_OPTIONS_DRAG_TOOLTIP),
	getFunc = function()
	    return POC_Settings.SavedVariables.Movable
	end,
	setFunc = function(value)
	    POC_Settings.SetMovableSettings(value)
	end,
	default = POC_Settings.Default.Movable
    }
    o[#o + 1] = {
	type = "checkbox",
	name = GetString(POC_OPTIONS_ONLY_AVA_LABEL),
	tooltip = GetString(POC_OPTIONS_ONLY_AVA_TOOLTIP),
	getFunc = function()
	    return POC_Settings.SavedVariables.OnlyAva
	end,
	setFunc = function(value)
	    POC_Settings.SetOnlyAvaSettings(value)
	end,
	default = POC_Settings.Default.OnlyAva
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
	iconSize = 40
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
	    return POC_Settings.SavedVariables.Style
	end,
	setFunc = function(value)
	    POC_Settings.SetStyleSettings(value)
	end,
	default = POC_Settings.Default.Style
    }
    o[#o + 1] = {
	type = "slider",
	name = GetString(POC_OPTIONS_SWIMLANE_MAX_LABEL),
	min = 1, max = 24, step = 1,
	getFunc = function() return POC_Settings.SavedVariables.SwimlaneMax end,
	width = "full",
	setFunc = function(value) POC_Settings.SetSwimlaneMax(value) end,
	default = 24,
    }
    o[#o + 1] = {
	type = "slider",
	name = "Max number of swimlanes to display",
	min = 1, max = 6, step = 1,
	getFunc = function() return POC_Settings.SavedVariables.SwimlaneMaxCols end,
	width = "full",
	setFunc = function(value) POC_Settings.SetSwimlaneMaxCols(value) end,
	default = 6,
    }
    o[#o + 1] = {
	type = "checkbox",
	name = GetString(POC_OPTIONS_ULTIMATE_NUMBER),
	tooltip = GetString(POC_OPTIONS_ULTIMATE_NUMBER_TOOLTIP),
	getFunc = function()
	    return POC_Settings.SavedVariables.UltNumberShow
	end,
	setFunc = function(val) POC_Settings.SetUltNumberShow(val) end,
	default = POC_Settings.Default.UltNumberShow
    }
    o[#o + 1] = {
	type = "checkbox",
	name = GetString(POC_OPTIONS_WERE_NUMBER_ONE),
	tooltip = GetString(POC_OPTIONS_WERE_NUMBER_ONE_TOOLTIP),
	getFunc = function()
	    return POC_Settings.SavedVariables.WereNumberOne
	end,
	setFunc = function(val) POC_Settings.SetWereNumberOne(val) end,
	default = POC_Settings.Default.WereNumberOne
    }
    o[#o + 1] = {
	type = "checkbox",
	name = "Show MIA swimlane",
	tooltip = "Show/hide swimlane containing players who are not in zone or not displayed on any other swimlane",
	getFunc = function()
	    return POC_Settings.SavedVariables.MIA
	end,
	setFunc = function(val) POC_Settings.SetMIA(val) end,
	default = POC_Settings.Default.MIA
    }

    local LAM = LibStub("LibAddonMenu-2.0")
    LAM:RegisterAddonPanel(POC_SettingsWindow.MainMenuName, panelData)
    LAM:RegisterOptionControls(POC_SettingsWindow.MainMenuName, optionsData)
end
