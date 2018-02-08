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
POC_SWIMLANE_COLMAX_CHANGED = "POC-Swimlane-ColMax"

POC_REAL_API_VERSION = 1
POC_API_VERSION = POC_REAL_API_VERSION

local MAJOR = "2"
local MINOR = "1"
local PATCH = "4"

local ISMOCKED = false

local LOG_NAME = "POC-DebugLogger"
local LOG_COMMAND = "/poclogs"

POC = {
    Name = "POC"
}
POC.__index = POC

-- POC:initialize initializes addon
--
function POC:initialize()
    -- Initialize logging
    d("Piece of Candy! (v" .. MAJOR .. "." .. MINOR .. "." .. PATCH .. ")")
    SLASH_COMMANDS["/rrr"] = function () ReloadUI() end
    SLASH_COMMANDS["/pocapi"] = function(n)
	n = n:gsub("^%s*(.-)%s*$", "%1")
	if string.len(n) == 0 then
	    POC_API_VERSION = POC_REAL_API_VERSION
	else
	    POC_API_VERSION = tonumber(n)
	end
	d(POC_API_VERSION)
    end

    -- Initialize settings
    POC_Settings.Initialize()

    -- Initialize communication
    POC_Communicator.Initialize(ISMOCKED)

    -- Initialize logic
    POC_GroupHandler.Initialize(ISMOCKED)
    POC_MapPing.Initialize(ISMOCKED)
    POC_Ult.Initialize()
    POC_CommandsHandler.Initialize()

    -- Initialize ui
    POC_SettingsWindow.Initialize(MAJOR, MINOR, PATCH)

    POC_UltMenu.Initialize()

    POC_Swimlanes.Initialize()
end

-- OnAddOnLoaded if POC is loaded, initialize
--
local function OnAddOnLoaded(eventCode, addOnName)
    if addOnName == POC.Name then
	-- Unregister Loaded Callback
	EVENT_MANAGER:UnregisterForEvent(POC.Name, EVENT_ADD_ON_LOADED)
	-- Initialize
	POC:initialize()
    end
end

function POC.xxx(...)
    local args = {...}
    local accum = ''
    local space = ''
    for _,n in ipairs(args) do
	accum = accum .. space .. tostring(n)
	space = ' '
    end
    d(accum)
end

-- Register Loaded Callback
EVENT_MANAGER:RegisterForEvent(POC.Name, EVENT_ADD_ON_LOADED, OnAddOnLoaded);
