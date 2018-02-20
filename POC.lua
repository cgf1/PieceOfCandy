-- Callbacks
POC_GROUP_CHANGED = "POC-GroupChanged"
POC_UNIT_GROUPED_CHANGED = "POC-UnitGroupedChanged"
POC_MAP_PING_CHANGED = "POC-MapPingChanged"
POC_PLAYER_DATA_CHANGED = "POC-PlayerDataChanged"
POC_STYLE_CHANGED = "POC-StyleChanged"
POC_MOVABLE_CHANGED = "POC-MovableChanged"
POC_ZONE_CHANGED = "POC-ZoneChanged"
POC_STATIC_ULTIMATE_ID_CHANGED = "POC-StaticUltimateIDChanged"
POC_SWIMLANE_ULTIMATE_GROUP_ID_CHANGED = "POC-SwimlaneUltIdChanged"
POC_SHOW_ULTIMATE_GROUP_MENU = "POC-ShowUltMenu"
POC_SET_ULTIMATE_GROUP = "POC-SetUlt"
POC_SWIMLANE_COLMAX_CHANGED = "POC-Swimlane-ColMax"

POC_REAL_API_VERSION = 0
POC_API_VERSION = POC_REAL_API_VERSION

local MAJOR = "2"
local MINOR = "3"
local PATCH = "1"

POC = {
    Name = "POC"
}
POC.__index = POC

-- POC:initialize initializes addon
--
function POC:initialize()
    -- Initialize logging
    df("Piece of Candy! (v%d.%d.%d)", MAJOR, MINOR, PATCH)
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

    -- Initialize logic
    POC_GroupHandler.Initialize()
    POC_Ult.Initialize()

    -- Initialize ui
    POC_Settings.InitializeWindow(MAJOR, MINOR, PATCH)

    POC_UltMenu.Initialize()

    POC_Swimlanes.Initialize()

    -- Start talking, see?
    POC_Comm.Initialize()
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
