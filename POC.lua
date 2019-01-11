setfenv(1, POC)
Name = "POC"

LANG = GetCVar("Language.2")

local version = '3.32'
local major = tonumber(version:match("^(%d+)"))
local minor = tonumber(version:match("\.(%d+)"))
local beta = tonumber(version:match("b(%d+)")) or '0'

local addon_conflicts = {
    GroupDamageShare = true,
    RaidNotifier = true,
    SanctsUltimateOrganiser = true,
    TaosGroupTools = true,
    TaosGroupUltimate = true
}

local conflicts = {}

-- POC:initialize initializes addon
--
local function initialize()
    LuaErrors.Initialize()
    -- Initialize logging
    df("Piece of Candy v%s", version)
    df('Type "/poc" for the settings menu.  Type "/poc help" to see available slash commands.')

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

    saved = Settings.GetSaved()

    -- Initialize available ultimates
    Ult.Initialize(saved)

    UltMenu.Initialize(saved)

    Swimlanes.Initialize(major, minor, saved)
    Group.Initialize(saved)
    Quest.Initialize(saved)
    Alert.Initialize(saved)
    Campaign.Initialize(saved)

    -- Start talking, see?
    Comm.Initialize(major, minor, beta, saved)

    if type(Test) == 'table' then
	Test.Initialize(saved)
    end

    -- Initialize settings
    Settings.Initialize(version)
end

-- OnAddOnLoaded if POC is loaded, initialize
--
local function OnAddOnLoaded(eventCode, addOnName)
    if addon_conflicts[addOnName] then
	conflicts[#conflicts + 1] = addOnName
    elseif addOnName == Name then
	-- Unregister Loaded Callback
	-- EVENT_MANAGER:UnregisterForEvent(Name, EVENT_ADD_ON_LOADED)
	initialize()
    end
end

local function player_activated()
    if saved.WarnConflict and #conflicts > 0 then
	local LMW = LibStub:GetLibrary("LibMsgWin-1.0")
	local win = LMW:CreateMsgWindow("POC_Conflicts", "|c00ee00Conflicting add-ons|r", 10000, 20000)
	win:SetDimensions(550, 180)
	win:SetAnchor(TOP, GuiRoot, CENTER, 0,0)
	win:AddText("\n|cffff00The following add-ons are known to conflict with Piece of Candy:|r\n\n")
	for _, x in ipairs(conflicts) do
	    win:AddText('|u:20:0::' .. x .. '|u')
	end
	win:AddText('\n\n|cffff00Running these together will likely result in a game crash.|r')
	win.close = CreateControlFromVirtual(nil, win, "ZO_CloseButton")
	win.close:ClearAnchors()
	win.close:SetAnchor(TOPRIGHT, luiChangeLog, TOPRIGHT, -12, 14)
	win.close:SetClickSound("Click")
	win.close:SetHandler("OnClicked", function(...) win:SetHidden(true) end)

	win:SetHidden(false)
    end
end

EVENT_MANAGER:RegisterForEvent(Name, EVENT_ADD_ON_LOADED, OnAddOnLoaded);
EVENT_MANAGER:RegisterForEvent(Name, EVENT_PLAYER_ACTIVATED, player_activated);
Slash("/rrr", "alias for /reloadui",function () ReloadUI() end)
