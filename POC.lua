-- Global variables
--
-- Callbacks
POC_GROUP_CHANGED = "POC-GroupChanged"
POC_UNIT_GROUPED_CHANGED = "POC-UnitGroupedChanged"
POC_MAP_PING_CHANGED = "POC-MapPingChanged"
POC_PLAYER_DATA_CHANGED = "POC-PlayerDataChanged"
POC_STYLE_CHANGED = "POC-StyleChanged"
POC_MOVABLE_CHANGED = "POC-MovableChanged"
POC_IS_ZONE_CHANGED = "POC-IsZoneChanged"
POC_STATIC_ULTIMATE_ID_CHANGED = "POC-StaticUltimateIDChanged"
POC_SWIMLANE_ULTIMATE_GROUP_ID_CHANGED = "POC-SwimlaneUltIdChanged"
POC_SHOW_ULTIMATE_GROUP_MENU = "POC-ShowUltMenu"
POC_SET_ULTIMATE_GROUP = "POC-SetUlt"

--[[
	Local variables
]]--
local MAJOR = "2"
local MINOR = "0"
local PATCH = "2"

local ISMOCKED = false

local LOG_NAME = "POC-DebugLogger"
local LOG_COMMAND = "/poclogs"
local TRACE_ACTIVE = false
local DEBUG_ACTIVE = false
local ERROR_ACTIVE = true
local DIRECT_PRINT = true
local CATCH_LUA_ERRORS = false

--[[
	Table POC
]]--
POC = {
    Name = "POC"
}
POC.__index = POC

--[[
	POC:initialize initializes addon
]]--
function POC:initialize()
    -- Initialize logging
    local logger = POCDebugLogger(LOG_NAME, LOG_COMMAND, TRACE_ACTIVE, DEBUG_ACTIVE, ERROR_ACTIVE, DIRECT_PRINT, CATCH_LUA_ERRORS)
    logger:logTrace("POC:initialize")
    d("Piece of Candy!")
    SLASH_COMMANDS["/rrr"] = function () ReloadUI() end

    -- Initialize settings
    POC_Settings.Initialize(logger)

    -- Initialize communication
    POC_Communicator.Initialize(logger, POC_Settings.SavedVariables.IsLgsActive, ISMOCKED)

    -- Initialize logic
    POC_GroupHandler.Initialize(logger, ISMOCKED)
    POC_MapPingHandler.Initialize(logger, ISMOCKED)
    POC_Ult.Initialize(logger)
    POC_CommandsHandler.Initialize(logger)

    -- Initialize ui
    POC_SettingsWindow.Initialize(logger, MAJOR, MINOR, PATCH)

    POC_UltMenu.Initialize(logger)

    POC_Swimlanes.Initialize(logger, ISMOCKED)

    logger:logTrace("POC:initialized")
end

--[[
	OnAddOnLoaded if POC is loaded, initialize
]]--
local function OnAddOnLoaded(eventCode, addOnName)
	if addOnName == POC.Name then

        -- Unregister Loaded Callback
        EVENT_MANAGER:UnregisterForEvent(POC.Name, EVENT_ADD_ON_LOADED)

        -- Initialize
		POC:initialize()
	end
end

-- Register Loaded Callback
EVENT_MANAGER:RegisterForEvent(POC.Name, EVENT_ADD_ON_LOADED, OnAddOnLoaded);
