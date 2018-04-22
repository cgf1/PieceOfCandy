setfenv(1, POC)
Name = "POC"
-- Callbacks
SHOW_ULTIMATE_GROUP_MENU = "POC-ShowUltMenu"

LANG = GetCVar("Language.2")

local version = '3.15'
local major = tonumber(version:match("^(%d+)"))
local minor = tonumber(version:match("\.(%d+)"))

-- POC:initialize initializes addon
--
local function initialize()
    LuaErrors.Initialize()
    -- Initialize logging
    df("Piece of Candy! v%s", version)

    local strings = {
	OPTIONS_HEADER =		 "Options",
	OPTIONS_ONLY_AVA_LABEL =	 "Show only in AvA",
	OPTIONS_ONLY_AVA_TOOLTIP =	 "If activated, all elements will only be visible in Cyrodiil (AvA).",
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

    WM = GetWindowManager()

    -- Initialize settings
    Settings.Initialize()

    saved = Settings.SavedVariables	-- convenience

    Ult.Initialize()

    -- Initialize ui
    Settings.InitializeWindow(version)

    UltMenu.Initialize()

    Swimlanes.Initialize(major, minor)
    Group.Initialize(saved)
    Quest.Initialize()
    Alert.Initialize()
    Campaign.Initialize()

    -- Start talking, see?
    Comm.Initialize(major, minor)
end

-- OnAddOnLoaded if POC is loaded, initialize
--
local function OnAddOnLoaded(eventCode, addOnName)
    if addOnName == Name then
	-- Unregister Loaded Callback
	EVENT_MANAGER:UnregisterForEvent(Name, EVENT_ADD_ON_LOADED)
	initialize()
    end
end

-- Register Loaded Callback
EVENT_MANAGER:RegisterForEvent(Name, EVENT_ADD_ON_LOADED, OnAddOnLoaded);
Slash("/rrr", "alias for /reloadui",function () ReloadUI() end)
