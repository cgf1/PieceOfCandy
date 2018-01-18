--[[
	Global variables
]]--
-- Callbacks
POC_GROUP_CHANGED = "TGU-GroupChanged"
POC_UNIT_GROUPED_CHANGED = "TGU-UnitGroupedChanged"
POC_MAP_PING_CHANGED = "TGU-MapPingChanged"
POC_PLAYER_DATA_CHANGED = "TGU-PlayerDataChanged"
POC_STYLE_CHANGED = "TGU-StyleChanged"
POC_MOVABLE_CHANGED = "TGU-MovableChanged"
POC_IS_ZONE_CHANGED = "TGU-IsZoneChanged"
POC_STATIC_ULTIMATE_ID_CHANGED = "TGU-StaticUltimateIDChanged"
POC_SWIMLANE_ULTIMATE_GROUP_ID_CHANGED = "TGU-SwimlaneUltimateGroupIdChanged"
POC_SHOW_ULTIMATE_GROUP_MENU = "TGU-ShowUltimateGroupMenu"
POC_SET_ULTIMATE_GROUP = "TGU-SetUltimateGroup"

--[[
	Local variables
]]--
local MAJOR = "1"
local MINOR = "5"
local PATCH = "0"

local ISMOCKED = false

local LOG_NAME = "TGU-DebugLogger"
local LOG_COMMAND = "/tgulogs"
local TRACE_ACTIVE = false
local DEBUG_ACTIVE = false
local ERROR_ACTIVE = true
local DIRECT_PRINT = true
local CATCH_LUA_ERRORS = false

--[[
	Table POC
]]--
POC = {}
POC.__index = POC

--[[
	Table Members
]]--
POC.Name = "POC"

--[[
	POC:initialize initializes addon
]]--
function POC:initialize()
    -- Initialize logging
    local logger = POCDebugLogger(LOG_NAME, LOG_COMMAND, TRACE_ACTIVE, DEBUG_ACTIVE, ERROR_ACTIVE, DIRECT_PRINT, CATCH_LUA_ERRORS)
    logger:logTrace("POC:initialize")
    d("Piece of Candy!")

    -- Initialize settings
    POC_SettingsHandler.Initialize(logger)

    -- Initialize communication
    POC_Communicator.Initialize(logger, POC_SettingsHandler.SavedVariables.IsLgsActive, ISMOCKED)

    -- Initialize logic
    POC_GroupHandler.Initialize(logger, ISMOCKED)
    POC_MapPingHandler.Initialize(logger, ISMOCKED)
    POC_UltimateGroupHandler.Initialize(logger)
    POC_CommandsHandler.Initialize(logger)

    -- Initialize ui
    POC_SettingsWindow.Initialize(logger, MAJOR, MINOR, PATCH)

    POC_UltimateGroupMenu.Initialize(logger)
    POC_GroupUltimateSelector.Initialize(logger)

    POC_SimpleList.Initialize(logger, ISMOCKED)
    POC_SwimlaneList.Initialize(logger, ISMOCKED)
    POC_CompactSwimlaneList.Initialize(logger, ISMOCKED)

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
