--[[
	Local variables
]]--
local LOG_ACTIVE = false

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
function POC_SettingsWindow.Initialize(logger, major, minor, patch)
    if (LOG_ACTIVE) then 
        logger:logTrace("POC_SettingsWindow.Initialize")
        logger:logDebug("major, minor, patch", major, minor, patch)
    end

    local styleChoices = {
        [1] = GetString(POC_OPTIONS_STYLE_SWIM),
        [2] = GetString(POC_OPTIONS_STYLE_SHORT_SWIM)
    }

    local panelData = {
            type = "panel",
            name = "Piece Of Candy",
            author = "TProg Taonnor & Valandil",
            version = major .. "." .. minor .. "." .. patch,
            slashCommand = "/taosGroupUltimate",
            registerForDefaults = true
    }

    local optionsData = {
            [1] = {
                    type = "header",
                    name = GetString(POC_OPTIONS_HEADER),
                  },
            [2] = {
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
                  },
            [3] = {
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
                  },
            [4] = {
                    type = "checkbox",
                    name = GetString(POC_OPTIONS_USE_LGS_LABEL),
                    tooltip = GetString(POC_OPTIONS_USE_LGS_TOOLTIP),
                    requiresReload = true,
                    getFunc = function()
                        return POC_Settings.SavedVariables.IsLgsActive
                    end,
                    setFunc = function(value)
                        POC_Settings.SetIsLgsActiveSettings(value)
                    end,
                    default = POC_Settings.Default.IsLgsActive
                  },
            [5] = {
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
                  },
            [6] = {
                    type = "slider",
                    name = GetString(POC_OPTIONS_SWIMLANE_MAX_LABEL),
                    min = 1, max = 24, step = 1,
                    getFunc = function() return POC_Settings.SavedVariables.SwimlaneMax end,
                    width = "full",
                    setFunc = function(value) POC_Settings.POC_SetSwimlaneMax(value) end,
                    default = 24,
                  },
            [7] = {
                    type = "checkbox",
                    name = GetString(POC_OPTIONS_ULTIMATE_NUMBER),
                    tooltip = GetString(POC_OPTIONS_ULTIMATE_NUMBER_TOOLTIP),
                    getFunc = function()
                        return POC_Settings.SavedVariables.UltNumberShow
                    end,
                    setFunc = function(val) POC_Settings.POC_SetUltNumberShow(val) end,
                    default = POC_Settings.Default.UltNumberShow
                  },
            [8] = {
                    type = "checkbox",
                    name = GetString(POC_OPTIONS_WERE_NUMBER_ONE),
                    tooltip = GetString(POC_OPTIONS_WERE_NUMBER_ONE_TOOLTIP),
                    getFunc = function()
                        return POC_Settings.SavedVariables.WereNumberOne
                    end,
                    setFunc = function(val) POC_Settings.POC_SetWereNumberOne(val) end,
                    default = POC_Settings.Default.WereNumberOne
                  },
    }
    
    local LAM = LibStub("LibAddonMenu-2.0")
    LAM:RegisterAddonPanel(POC_SettingsWindow.MainMenuName, panelData)
    LAM:RegisterOptionControls(POC_SettingsWindow.MainMenuName, optionsData)
end
