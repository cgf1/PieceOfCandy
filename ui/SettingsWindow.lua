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
        GetString(POC_OPTIONS_STYLE_SWIM),
        GetString(POC_OPTIONS_STYLE_SHORT_SWIM)
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
                        return POC_SettingsHandler.SavedVariables.Movable
                    end,
                    setFunc = function(value)
                        POC_SettingsHandler.SetMovableSettings(value)
                    end,
                    default = POC_SettingsHandler.Default.Movable
                  },
            [3] = {
                    type = "checkbox",
                    name = GetString(POC_OPTIONS_ONLY_AVA_LABEL),
                    tooltip = GetString(POC_OPTIONS_ONLY_AVA_TOOLTIP),
                    getFunc = function()
                        return POC_SettingsHandler.SavedVariables.OnlyAva
                    end,
                    setFunc = function(value)
                        POC_SettingsHandler.SetOnlyAvaSettings(value)
                    end,
                    default = POC_SettingsHandler.Default.OnlyAva
                  },
            [4] = {
                    type = "checkbox",
                    name = GetString(POC_OPTIONS_USE_LGS_LABEL),
                    tooltip = GetString(POC_OPTIONS_USE_LGS_TOOLTIP),
                    requiresReload = true,
                    getFunc = function()
                        return POC_SettingsHandler.SavedVariables.IsLgsActive
                    end,
                    setFunc = function(value)
                        POC_SettingsHandler.SetIsLgsActiveSettings(value)
                    end,
                    default = POC_SettingsHandler.Default.IsLgsActive
                  },
            [5] = {
                    type = "dropdown",
                    name = GetString(POC_OPTIONS_STYLE_LABEL),
                    tooltip = GetString(POC_OPTIONS_STYLE_TOOLTIP),
                    choices = styleChoices,
                    getFunc = function()
                        return POC_SettingsHandler.SavedVariables.Style
                    end,
                    setFunc = function(value)
                        POC_SettingsHandler.SetStyleSettings(value)
                    end,
                    default = POC_SettingsHandler.Default.Style
                  },
            [6] = {
                    type = "slider",
                    name = GetString(POC_OPTIONS_SWIMLANE_MAX_LABEL),
                    min = 1, max = 24, step = 1,
                    getFunc = function() return POC_SettingsHandler.SavedVariables.SwimlaneMax end,
                    width = "full",
                    setFunc = function(value) POC_SettingsHandler.POC_SetSwimlaneMax(value) end,
                    default = 24,
                  },
            [7] = {
                    type = "checkbox",
                    name = GetString(POC_OPTIONS_ULTIMATE_NUMBER),
                    tooltip = GetString(POC_OPTIONS_ULTIMATE_NUMBER_TOOLTIP),
                    getFunc = function()
                        return POC_SettingsHandler.SavedVariables.UltNumberShow
                    end,
                    setFunc = function(val) POC_SettingsHandler.POC_SetUltNumberShow(val) end,
                    default = POC_SettingsHandler.Default.UltNumberShow
                  },
            [8] = {
                    type = "checkbox",
                    name = GetString(POC_OPTIONS_WERE_NUMBER_ONE),
                    tooltip = GetString(POC_OPTIONS_WERE_NUMBER_ONE_TOOLTIP),
                    getFunc = function()
                        return POC_SettingsHandler.SavedVariables.WereNumberOne
                    end,
                    setFunc = function(val) POC_SettingsHandler.POC_SetWereNumberOne(val) end,
                    default = POC_SettingsHandler.Default.WereNumberOne
                  },
    }
    
    local LAM = LibStub("LibAddonMenu-2.0")
    LAM:RegisterAddonPanel(POC_SettingsWindow.MainMenuName, panelData)
    LAM:RegisterOptionControls(POC_SettingsWindow.MainMenuName, optionsData)
end
