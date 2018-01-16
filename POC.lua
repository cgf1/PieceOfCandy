--[[
	Global variables
]]--
-- Callbacks
TGU_GROUP_CHANGED = "TGU-GroupChanged"
TGU_UNIT_GROUPED_CHANGED = "TGU-UnitGroupedChanged"
TGU_MAP_PING_CHANGED = "TGU-MapPingChanged"
TGU_PLAYER_DATA_CHANGED = "TGU-PlayerDataChanged"
TGU_STYLE_CHANGED = "TGU-StyleChanged"
TGU_MOVABLE_CHANGED = "TGU-MovableChanged"
TGU_IS_ZONE_CHANGED = "TGU-IsZoneChanged"
TGU_STATIC_ULTIMATE_ID_CHANGED = "TGU-StaticUltimateIDChanged"
TGU_SWIMLANE_ULTIMATE_GROUP_ID_CHANGED = "TGU-SwimlaneUltimateGroupIdChanged"
TGU_SHOW_ULTIMATE_GROUP_MENU = "TGU-ShowUltimateGroupMenu"
TGU_SET_ULTIMATE_GROUP = "TGU-SetUltimateGroup"

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
    TGU_SettingsHandler.Initialize(logger)

    -- Initialize communication
    TGU_Communicator.Initialize(logger, TGU_SettingsHandler.SavedVariables.IsLgsActive, ISMOCKED)

    -- Initialize logic
    TGU_GroupHandler.Initialize(logger, ISMOCKED)
    TGU_MapPingHandler.Initialize(logger, ISMOCKED)
    TGU_UltimateGroupHandler.Initialize(logger)
    TGU_CommandsHandler.Initialize(logger)

    -- Initialize ui
    TGU_SettingsWindow.Initialize(logger, MAJOR, MINOR, PATCH)

    TGU_UltimateGroupMenu.Initialize(logger)
    TGU_GroupUltimateSelector.Initialize(logger)

    TGU_SimpleList.Initialize(logger, ISMOCKED)
    TGU_SwimlaneList.Initialize(logger, ISMOCKED)
    TGU_CompactSwimlaneList.Initialize(logger, ISMOCKED)

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
