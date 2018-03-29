setfenv(1, POC)
Name = "POC"
-- Callbacks
MAP_PING_CHANGED = "POC-MapPingChanged"
STYLE_CHANGED = "POC-StyleChanged"
MOVABLE_CHANGED = "POC-MovableChanged"
STATIC_ULTIMATE_ID_CHANGED = "POC-StaticUltimateIDChanged"
SWIMLANE_ULTIMATE_GROUP_ID_CHANGED = "POC-SwimlaneUltIdChanged"
SHOW_ULTIMATE_GROUP_MENU = "POC-ShowUltMenu"
SET_ULTIMATE_GROUP = "POC-SetUlt"
SWIMLANE_COLMAX_CHANGED = "POC-Swimlane-ColMax"
ALERT = "POC-Alert"

LANG = GetCVar("Language.2")

local version = '3.6'
local major = tonumber(version:match("^(%d+)"))
local minor = tonumber(version:match("\.(%d+)"))

-- POC:initialize initializes addon
--
function POC:initialize()
    -- Initialize logging
    df("Piece of Candy! (v%s)", version)

    local strings = {
	WARNING_LGS_ENABLE =		 "Warning: Enable LibGroupSocket to send -> /lgs 1",
	OPTIONS_HEADER =		 "Options",
	OPTIONS_DRAG_LABEL =		 "Drag elements",
	OPTIONS_DRAG_TOOLTIP =		 "If activated, you can drag all elements.",
	OPTIONS_ONLY_AVA_LABEL =	 "Show only in AvA",
	OPTIONS_ONLY_AVA_TOOLTIP =	 "If activated, all elements will only be visible in Cyrodiil (AvA).",
	OPTIONS_USE_LGS_LABEL =		 "Communication via LibGroupSocket",
	OPTIONS_USE_LGS_TOOLTIP =	 "If activated, the addon will try to activate communication via LibGroupSocket. LibGroupSocket must be installed as own addon.",
	OPTIONS_USE_SORTING_LABEL =	 "Sort lists by ultimate progress",
	OPTIONS_USE_SORTING_TOOLTIP =	 "If activated, all lists will be sorted by ultimate progress (Maximum on top).",
	OPTIONS_STYLE_LABEL =		 "Choose style",
	OPTIONS_STYLE_TOOLTIP =		 "Choose your style: Standard or Compact",
	OPTIONS_STYLE_SWIM =		 "Standard",
	OPTIONS_STYLE_SHORT_SWIM =	 "Compact",
	OPTIONS_SWIMLANE_MAX_LABEL =	 "Max number of ultimates to display in a swimlane",
	OPTIONS_ULTIMATE_NUMBER =	 "Show your Ultimate number",
	OPTIONS_ULTIMATE_NUMBER_TOOLTIP ="Display your position in the list for your selected Ultimate",
	OPTIONS_WERE_NUMBER_ONE =	 "Play a sound when you hit #1",
	OPTIONS_WERE_NUMBER_ONE_TOOLTIP ="Play a sound when you hit #1 position in the list for your selected Ultimate",
    }

    for id, val in pairs(strings) do
	ZO_CreateStringId(id, val)
	SafeAddVersion(id, 1)
    end

    -- Initialize settings
    Settings.Initialize()

    saved = Settings.SavedVariables	-- convenience

    Ult.Initialize()

    -- Initialize ui
    Settings.InitializeWindow(version)

    UltMenu.Initialize()

    Swimlanes.Initialize(major, minor)
    Group.Initialize(Settings.SavedVariables)
    Quest.Initialize()
    Alert.Initialize()

    -- Start talking, see?
    Comm.Initialize(major, minor)
end

-- OnAddOnLoaded if POC is loaded, initialize
--
local function OnAddOnLoaded(eventCode, addOnName)
    if addOnName == Name then
	-- Unregister Loaded Callback
	EVENT_MANAGER:UnregisterForEvent(Name, EVENT_ADD_ON_LOADED)
	-- Initialize
	initialize()
    end
end

-- Register Loaded Callback
EVENT_MANAGER:RegisterForEvent(Name, EVENT_ADD_ON_LOADED, OnAddOnLoaded);
Slash("/rrr", "alias for /reloadui",function () ReloadUI() end)
