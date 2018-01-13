--[[
	Addon: Taos Group Ultimate
	Author: TProg Taonnor
	Created by @Taonnor
]]--

--[[
	Local variables
]]--
local LOG_ACTIVE = false

--[[
	Table SettingsWindow
]]--
TGU_SettingsWindow = {}
TGU_SettingsWindow.__index = TGU_SettingsWindow

--[[
	Table Members
]]--
TGU_SettingsWindow.MainMenuName = "TaosGroupUltimateSettingsMainMenu"

--[[
	Initialize creates settings window
]]--
function TGU_SettingsWindow.Initialize(logger, major, minor, patch)
    if (LOG_ACTIVE) then 
        logger:logTrace("TGU_SettingsWindow.Initialize")
        logger:logDebug("major, minor, patch", major, minor, patch)
    end

    local styleChoices = {
        [1] = GetString(TGU_OPTIONS_STYLE_SIMPLE),
        [2] = GetString(TGU_OPTIONS_STYLE_SWIM),
        [3] = GetString(TGU_OPTIONS_STYLE_SHORT_SWIM),
    }

	local panelData = {
		type = "panel",
		name = "Taos Group Ultimate",
		author = "TProg Taonnor",
		version = major .. "." .. minor .. "." .. patch,
		slashCommand = "/taosGroupUltimate",
		registerForDefaults = true
	}

	local optionsData = {
		[1] = {
			type = "header",
			name = GetString(TGU_OPTIONS_HEADER),
		},
		[2] = {
			type = "checkbox",
			name = GetString(TGU_OPTIONS_DRAG_LABEL),
			tooltip = GetString(TGU_OPTIONS_DRAG_TOOLTIP),
			getFunc = 
               function() 
                   return TGU_SettingsHandler.SavedVariables.Movable
               end,
			setFunc = 
               function(value) 
                   TGU_SettingsHandler.SetMovableSettings(value)
			   end,
			default = TGU_SettingsHandler.Default.Movable
		},
        [3] = {
			type = "checkbox",
			name = GetString(TGU_OPTIONS_ONLY_AVA_LABEL),
			tooltip = GetString(TGU_OPTIONS_ONLY_AVA_TOOLTIP),
			getFunc = 
               function() 
                   return TGU_SettingsHandler.SavedVariables.OnlyAva
               end,
			setFunc = 
               function(value) 
                   TGU_SettingsHandler.SetOnlyAvaSettings(value)
			   end,
			default = TGU_SettingsHandler.Default.OnlyAva
		},
        [4] = {
			type = "checkbox",
			name = GetString(TGU_OPTIONS_USE_LGS_LABEL),
			tooltip = GetString(TGU_OPTIONS_USE_LGS_TOOLTIP),
            requiresReload = true,
			getFunc = 
               function() 
                   return TGU_SettingsHandler.SavedVariables.IsLgsActive
               end,
			setFunc = 
               function(value) 
                   TGU_SettingsHandler.SetIsLgsActiveSettings(value)
			   end,
			default = TGU_SettingsHandler.Default.IsLgsActive
		},
        [5] = {
			type = "checkbox",
			name = GetString(TGU_OPTIONS_USE_SORTING_LABEL),
			tooltip = GetString(TGU_OPTIONS_USE_SORTING_TOOLTIP),
			getFunc = 
               function() 
                   return TGU_SettingsHandler.SavedVariables.IsSortingActive
               end,
			setFunc = 
               function(value) 
                   TGU_SettingsHandler.SetIsSortingActiveSettings(value)
			   end,
			default = TGU_SettingsHandler.Default.IsSortingActive
		},
        [6] = {
			type = "dropdown",
			name = GetString(TGU_OPTIONS_STYLE_LABEL),
			tooltip = GetString(TGU_OPTIONS_STYLE_TOOLTIP),
            choices = styleChoices,
			getFunc = 
               function() 
                   return styleChoices[TGU_SettingsHandler.SavedVariables.Style]
               end,
			setFunc = 
               function(value) 
                   for index, name in ipairs(styleChoices) do
                      if (name == value) then
                         TGU_SettingsHandler.SetStyleSettings(index)
                         break
                      end
                   end
			   end,
			default = styleChoices[TGU_SettingsHandler.Default.Style]
		},
	}
	
	local LAM = LibStub("LibAddonMenu-2.0")
	LAM:RegisterAddonPanel(TGU_SettingsWindow.MainMenuName, panelData)
	LAM:RegisterOptionControls(TGU_SettingsWindow.MainMenuName, optionsData)
end