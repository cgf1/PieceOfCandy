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
local MINOR = "4"
local PATCH = "0"

POC = {
    Name = "POC"
}
POC.__index = POC

-- POC:initialize initializes addon
--
function POC:initialize()
    -- Initialize logging
    df("Piece of Candy! (v%d.%d.%d)", MAJOR, MINOR, PATCH)

    local strings = {
	POC_WARNING_LGS_ENABLE =             "Warning: Enable LibGroupSocket to send -> /lgs 1",
	POC_OPTIONS_HEADER =                 "Options",
	POC_OPTIONS_DRAG_LABEL =             "Drag elements",
	POC_OPTIONS_DRAG_TOOLTIP =           "If activated, you can drag all elements.",
	POC_OPTIONS_ONLY_AVA_LABEL =         "Show only in AvA",
	POC_OPTIONS_ONLY_AVA_TOOLTIP =       "If activated, all elements will only be visible in Cyrodiil (AvA).",
	POC_OPTIONS_USE_LGS_LABEL =          "Communication via LibGroupSocket",
	POC_OPTIONS_USE_LGS_TOOLTIP =        "If activated, the addon will try to activate communication via LibGroupSocket. LibGroupSocket must be installed as own addon.",
	POC_OPTIONS_USE_SORTING_LABEL =      "Sort lists by ultimate progress",
	POC_OPTIONS_USE_SORTING_TOOLTIP =    "If activated, all lists will be sorted by ultimate progress (Maximum on top).",
	POC_OPTIONS_STYLE_LABEL =            "Choose style",
	POC_OPTIONS_STYLE_TOOLTIP =          "Choose your style: Standard or Compact",
	POC_OPTIONS_STYLE_SWIM =             "Standard",
	POC_OPTIONS_STYLE_SHORT_SWIM =       "Compact",
	POC_OPTIONS_SWIMLANE_MAX_LABEL =     "Max number of ultimates to display in a swimlane",
	POC_OPTIONS_ULTIMATE_NUMBER =        "Show your Ultimate number",
	POC_OPTIONS_ULTIMATE_NUMBER_TOOLTIP ="Display your position in the list for your selected Ultimate",
	POC_OPTIONS_WERE_NUMBER_ONE =        "Play a sound when you hit #1",
	POC_OPTIONS_WERE_NUMBER_ONE_TOOLTIP ="Play a sound when you hit #1 position in the list for your selected Ultimate",
    }

    for id, val in pairs(strings) do
	ZO_CreateStringId(id, val)
	SafeAddVersion(id, 1)
    end

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
