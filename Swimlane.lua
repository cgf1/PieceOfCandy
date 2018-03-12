setfenv(1, POC)
local after_style_changed = false
local SWIMLANES = 6
local TIMEOUT = 10		-- s; GetTimeStamp() is in seconds
local INRANGETIME = 60		-- Reset ultpct if not inrange for at least this long
local REFRESH_IF_CHANGED = 1
local MAXPLAYSOUNDTIME = 60

local widget = nil
local curstyle = ""
local registered = false
local namelen = 12
local topleft = 25
local swimlanerow

local SWIMLANEULTMAX = 24

local forcepct = nil
local sldebug = false

local group_members

local ping_refresh = false

local reloaded = true

local tick = 0

local Lane = {}
Lane.__index = Lane

local play_sound = false
local last_played = 0
Player = {
    IsMe = false,
    NewClient = true,
    TimeStamp = 0,
    Ults = {},
}
Player.__index = Player

local me = setmetatable({
    InRangeTime = 0,
    IsDead = false,
    IsMe = true,
    NewClient = true,
    Tick = 0,
    TimeStamp = 0,
    UltMain = 0,
    Ults = {}
}, Player)
Me = me

local myname = GetUnitName("player")
local ultix = myname

local Lanes = {}
Lanes.__index = Lanes

local MIAlane = 0

local saved

local dumpme

-- Table Swimlanes
--
Swimlanes = {
    Name = "POC-Swimlanes",
    Lanes = nil,
    SavedLanes = {},
    WasActive = false
}
Swimlanes.__index = Swimlanes

local _this = Swimlanes

local need_to_fire = true

local function _noop() end

local msg = d
local d = nil

local LAM = LibStub("LibAddonMenu-2.0")

local function dump(name)
    local found = false
    local function time(t)
	local p
	if (t == 0) then
	    p = 'never'
	else
	    local duration = GetTimeStamp() - t
	    p = FormatTimeSeconds(duration, TIME_FORMAT_STYLE_DURATION , TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_NONE)
	end
	return p
    end
    for n, v in pairs(group_members) do
	if string.find(n, name, 1) then
	    msg("== " .. n .. " ==")
	    local a = {}
	    for n in pairs(v) do
		table.insert(a, n)
	    end
	    table.sort(a)
	    for _, x in ipairs(a) do
		local t = v[x]
		local p
		if x == 'UltAid' then
		    local u = Ult.ByAid(t)
		    local name
		    if u == nil then
			name = 'unknown'
		    else
			name = u.Desc
		    end
		    p = name .. ' [' .. tostring(t) .. ']'
		    x = 'Ultimate Type'
		elseif x == 'InRangeTime' then
		    p = time(t)
		elseif x == 'TimeStamp' then
		    p = time(t)
		elseif x == 'Ults' then
		    x = "Ults"
		    p = ''
		    local comma = ''
		    for n, v in pairs(t) do
			local ult = Ult.ByPing(n)
			if ult.Name ~= 'MIA' then
			    p = p .. comma .. ult.Desc .. '[' .. v .. '%]'
			    comma = ', '
			end
		    end
		else
		    p = tostring(t)
		end
		msg(x .. ':  ' .. p)
	    end
	    found = true
	end
    end
    if not found then
	msg("not found")
    end
end

-- set_control_movable sets the Movable and MouseEnabled flag in UI elements
--
local function set_control_movable(ismovable)
    widget:GetNamedChild("MovableControl"):SetHidden(ismovable == false)

    widget:SetMovable(ismovable)
    widget:SetMouseEnabled(ismovable)
end

-- Set hidden on control
--
local function set_control_hidden(ishidden)
    if (Group.IsGrouped()) then
	widget:SetHidden(ishidden)
	UltNumber.Hide(ishidden)
    else
	widget:SetHidden(true)
	UltNumber.Hide(true)
    end
end

-- restore_position sets widget position
--
local function restore_position(x, y)
    widget:ClearAnchors()
    widget:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, x, y)
end

-- set_control_active sets hidden on control
--
local function set_control_active()
    local isvisible = Settings.IsSwimlaneListVisible() and Group.IsGrouped()
    local ishidden = not isvisible or CurrentHudHiddenState()
    set_control_hidden(ishidden)

    if (isvisible) then
	if registered then
	    return
	end
	registered = true
	set_control_movable(saved.Movable)
	restore_position(saved.PosX, saved.PosY)

	CALLBACK_MANAGER:RegisterCallback(PLAYER_DATA_CHANGED, Player.Update)
	CALLBACK_MANAGER:RegisterCallback(MOVABLE_CHANGED, set_control_movable)
	CALLBACK_MANAGER:RegisterCallback(SWIMLANE_ULTIMATE_GROUP_ID_CHANGED, function (x,y) _this.Lanes:SetUlt(x, y) end)
	CALLBACK_MANAGER:RegisterCallback(HUD_HIDDEN_STATE_CHANGED, set_control_hidden)
    elseif (registered) then
	registered = false
	-- Stop timeout timer
	-- EVENT_MANAGER:UnregisterForUpdate(_this.Name)

	-- CALLBACK_MANAGER:UnregisterCallback(GROUP_CHANGED, _this.UpdateAll)
	CALLBACK_MANAGER:UnregisterCallback(PLAYER_DATA_CHANGED, Player.Update)
	CALLBACK_MANAGER:UnregisterCallback(MOVABLE_CHANGED, set_control_movable)
	CALLBACK_MANAGER:UnregisterCallback(SWIMLANE_ULTIMATE_GROUP_ID_CHANGED, function (x,y) _this.Lanes:SetUlt(x, y) end)
	CALLBACK_MANAGER:UnregisterCallback(HUD_HIDDEN_STATE_CHANGED, set_control_hidden)
    end
end

local function clear()
    saved.GroupMembers = {}
    group_members = saved.GroupMembers
end

-- Sets visibility of labels
--
function Lanes:Update(x)
    local refresh
    local displayed = false
    if (Group.IsGrouped()) then
	refresh = Player.Update(true)
	displayed = not _this.WasActive
    elseif (not _this.WasActive) then
	refresh = false
    else
	refresh = true	-- just get rid of everything
	msg("POC: No longer grouped")
	clear()
	set_control_active()
	_this.WasActive = false
    end
    watch("Lanes:Update", refresh, _this.WasActive)

    if refresh then
	watch("refresh")
	-- Check all swimlanes
	tick = tick + 1
	local tick = tick
	for _,lane in ipairs(IdSort(self, "Id")) do
	    if lane:Update(false, tick) then
		displayed = true
	    end
	end
    end

    if displayed then
	-- displayed should be false if not grouped
	set_control_active()
	if (not _this.WasActive) then
	    msg("POC: now grouped")
	end
	_this.WasActive = true
    end
end

-- Return true if we timed out
--
function Player:TimedOut()
    return (GetTimeStamp() - self.TimeStamp) > TIMEOUT
end

-- Return true if we need to back the heck off
--
function Player:HasBeenInRange()
    return (GetTimeStamp() - self.InRangeTime) < INRANGETIME
end

-- Return true if player is in range of rest of group
--
function Player:IsInRange()
    return self.InRange and (self.InRangeTime == nil or self.InRangeTime > 0)
end

function Player:PlunkNotMIA(apid, tick)
    if self.Ults[apid] == nil then
	return false
    else
	self.Tick = tick
	return true
    end
end

function Player:PlunkMIA(apid, tick)
    if self.Tick == tick then
	return false
    else
	self.Tick = tick
	return true
    end
end

-- Update swimlane
--
function Lane:Update(force, tick)
    local laneid = self.Id
    if not force and laneid > MIAlane then
	return
    end
    local apid = self.Apid

    local displayed = false
    local lastlane
    if saved.MIA then
	lastlane = MIAlane
    else
	lastlane = MIAlane - 1
    end
    local n = 1
    if (laneid <= lastlane) then
	local isMIA = laneid == MIAlane
	local function sortval(player)
	    local a
	    if player:TimedOut() or not player:IsInRange() then
		a = player.Ults[apid] - 200
	    elseif player.IsDead then
		a = player.Ults[apid] - 100
	    else
		a = player.Ults[apid]
	    end
	    return a
	end

	local function compare(key1, key2)
	    local player1 = group_members[key1]
	    local player2 = group_members[key2]
	    local a = sortval(player1)
	    local b = sortval(player2)
	    -- xxx("A " .. a)
	    -- xxx("B " .. b)
	    if (a == b) then
		return player1.PingTag < player2.PingTag
	    else
		return a > b
	   end
	end

	local keys = {}
	local plunk = self.Plunk
	for name, player in pairs(group_members) do
	    if not IsUnitGrouped(player.PingTag) then
		group_members[name] = nil
	    elseif plunk(player, apid, tick) then
		table.insert(keys, name)
	    end
	end

	table.sort(keys, compare)

	-- Update sorted swimlane
	local gt100 = 100 + saved.SwimlaneMax
	for _, playername in ipairs(keys) do
	    if n > saved.SwimlaneMax then
		-- log here?
		break
	    end
	    local player = group_members[playername]
	    local priult = player.UltMain == apid
	    displayed = true
	    if not player.IsMe or not priult or isMIA then
		self:UpdateCell(n, player, playername, isMIA or priult)
		if not isMIA and player.Ults[apid] > 100 then
		    gt100 = player.Ults[apid]
		end
	    else
		local noshow = true
		if forcepct ~= nil then
		    player.Ults[apid] = forcepct
		end
		if player.Ults[apid]  < 100 then
		    play_sound = true
		    Me.Because = "ultpct < 100"
		elseif priult and not player.IsDead and player:IsInRange() then
		    player.Ults[apid] = gt100 - 1
		    noshow = false
		    Me.Because = "ultpct == 100"
		else
		    -- reset order since we can't contribute
		    player.Ults[apid] = 100
		    play_sound = true
		    Me.Because = "out of range or dead"
		end
		self:UpdateCell(n, player, playername, priult)
		if (noshow or not saved.UltNumberShow or
		    CurrentHudHiddenState() or player.IsDead or
		    not Group.IsGrouped() or
		    not Settings.IsSwimlaneListVisible()) then
		    UltNumber.Hide(true)
		    UltNumberLabel:SetText("")
		else
		    UltNumber.Show(n)
		end
	    end
	    n = n + 1
	end
    end

    -- Clear any abandonded cells
    for i = n, SWIMLANEULTMAX do
	local row = self.Control:GetNamedChild("Row" .. i)
	row:SetHidden(true)
    end

    self:Hide(displayed)

    return displayed
end

-- Update a cell
--
function Lane:UpdateCell(i, player, playername, priult)
    local rowi = "Row" .. i
    local row = self.Control:GetNamedChild(rowi)
    if saved.AtNames and player.AtName then
	playername = string.sub(player.AtName, 2)
    end
    local namecell = row:GetNamedChild("PlayerName")
    local bgcell = row:GetNamedChild("Backdrop")
    local ultcell = row:GetNamedChild("UltPct")

    row:SetHidden(true)

    if not player.IsDead and player.InCombat then
	playername = "|cff0000" .. playername .. "|r"
    end

    if sldebug then
	playername = playername .. "   " .. player.Ults[apid] .. "%"
    end

    local ultpct
    local apid
    if self.Apid == 'MIA' then
	apid = player.UltMain
    else
	apid = self.Apid
    end
    if player.Ults[apid] > 100 then
	ultpct = 100
    else
	ultpct = player.Ults[apid]
    end

    local alivealpha
    local deadalpha
    local inprogressalpha
    if not player:IsInRange() then
	alivealpha = .4
	deadalpha = .3
	inprogressalpha = .3
    else
	alivealpha = 1
	deadalpha = .8
	inprogressalpha = .8
    end

    local bdlength, _ = bgcell:GetWidth() - 4
    if bdlength == 0 then
	-- Not sure why this happens
	if string.len(playername) > 10 then
	    playername = string.sub(playername, 1, 10) .. '..'
	end
	namecell:SetText(playername)
    else
	local lensub = -2
	local i = 1
	namecell:SetText(playername)
	while namecell:GetWidth() > bdlength do
	    playername = string.sub(playername, 1, lensub) .. '..'
	    namecell:SetText(playername)
	    lensub = -4
	    i = i + 1
	    if i > 100 then
		break
	    end
	end
    end
    ultcell:SetValue(ultpct)
    if player.InvalidClient then
	bgcell:SetCenterColor(0.85, 0.73, 0.15)
	namecell:SetColor(1, 1, 1, 1)
	ultcell:SetColor(1, 0.80, 0.00, 1)
    elseif player:TimedOut() then
	-- YELLOW row:GetNamedChild("Backdrop"):SetCenterColor(0.95, 0.83, 0.25)
	bgcell:SetCenterColor(0.15, 0.15, 0.15)
	namecell:SetColor(1, 1, 1, 1)
	ultcell:SetColor(0.80, 0.80, 0.80, 1)
    else
	if priult then
	    bgcell:SetCenterColor(0.51, 0.41, 0.65)
	else
	    bgcell:SetCenterColor(0.51, 0.63, 0.90)
	end
	if player.IsDead then
-- xxx(playername, rowi, "dead color", deadalpha)
	    namecell:SetColor(0.5, 0.5, 0.5, 0.8)
	    ultcell:SetColor(0.8, 0.03, 0.03, deadalpha)
	elseif (player.Ults[apid] >= 100) then
-- xxx(playername, rowi, "ready color", alivealpha)
	    namecell:SetColor(1, 1, 1, 1)
	    -- row:GetNamedChild("UltPct"):SetColor(0.03, 0.7, 0.03, alivealpha)
	    if priult then
		ultcell:SetColor(0.01, 0.69, 0.02, alivealpha)
	    else
		ultcell:SetColor(0.18, 0.42, 0.96, alivealpha)
	    end
	else
-- xxx(playername, rowi, "inprogress color")
	    namecell:SetColor(1, 1, 1, 0.8)
	    if priult then
		ultcell:SetColor(0.03, 0.03, 0.7, inprogressalpha)
	    else
		ultcell:SetColor(0.18, 0.42, 0.96, alivealpha)
	    end
	end
    end

    row:SetHidden(false)
end

function Player:Alert(name)
    local ult = Ult.ByPing(self.UltMain)
    local aid = ult.Aid
    local duration = GetAbilityDuration(aid) - 500
    local first = name:match('(%S+)')
    local message = first .. "'s " .. ult.Name
    Alert.Show(message, duration)
end

function Player.New(pingtag, timestamp, apid1, pct1, apid2, pct2)
    if _this.Lanes == nil then
	return
    end
    local name = GetUnitName(pingtag)
    local self = group_members[name]
    watch("Player.New", name, pingtag, timestamp, apid1, pct1, apid2, pct2, self)
    if self == nil then
	if name == myname then
	    self = Me
	else
	    self = {
		IsMe = false,
		NewClient = false,
		Tick = 0,
		TimeStamp = 0,
		Ults = {},
		Visited = false
	    }
	end
	group_members[name] = setmetatable(self, Player)
    end


    if timestamp ~= nil then
	if self.IsMe and pct1 >= 100 and Me.Ults ~= nil and Me.Ults[apid1] ~= nil and Me.Ults[apid1] >= 100 then
	    pct1 = Me.Ults[apid1]
	end
    elseif not self.Visited then
	timestamp = self.TimeStamp	-- coming from Player.Update
    else
	self.Visited = false
	return self
    end

    local player = {
	InCombat = IsUnitInCombat(pingtag),
	InRange = IsUnitInGroupSupportRange(pingtag),
	IsLeader = IsUnitGroupLeader(pingtag),
	IsDead = IsUnitDead(pingtag),
	Online = IsUnitOnline(pingtag),
	PingTag = pingtag,
	UltMain = apid1,
    }
    local changed = timestamp and self.TimeStamp and self:TimedOut()
    if timestamp ~= self.TimeStamp then
	self.TimeStamp = timestamp
    end
    if saved.AtNames and self.AtName == nil then
	player.AtName = GetUnitDisplayName(pingtag)
    end
    local ults
    if pct1 == 0 and self.UltMain and self.Ults[self.UltMain] and self.Ults[self.UltMain] > 0 then
	self:Alert(name)
    end
    if apid1 == nil then
	if reloaded then
	    ults = self.Ults
	end
    else
	ults = {[apid1] = pct1}
	if apid2 ~= nil then
	    ults[apid2] = pct2
	    player.NewClient = true
	elseif not self.NewClient then
	    -- just one in the array
	elseif apid1 ~= self.UltMain then
	    ults = {} -- can't handle this; wait for next ping
	else
	    -- Fill in with existing second ult if any
	    for n, v in pairs(self.Ults) do
		if n ~= apid1 then
		    ults[n] = v
		    break
		end
	    end
	end
    end

    if ults then
	local ultchanged
	for apid, pct in pairs(ults) do
	    if self.Ults[apid] ~= pct then
		ultchanged = true
	    end
	end
	if ultchanged then
	    self.Ults = ults
	    changed = true
	end
    end

    for n, v in pairs(player) do
	if self[n] ~= v then
	    changed = true
	    self[n] = v
	end
    end

    self.Visited = true

    if changed then
	need_to_fire = true
    end

    return self
end

-- Updates player (potentially) in the swimlane
--
function Player.Update(clear_need_to_fire)
    local nmembers = 0
    local inrange = 0

    for i = 1, 24 do
	local unitid = "group" .. tostring(i)
	local unitname = GetUnitName(unitid)
	if unitname ~= nil and unitname:len() ~= 0 then
	    nmembers = nmembers + 1
	    player = Player.New(unitid)
	    if player:TimedOut() then
		nmembers = nmembers - 1
	    elseif player.InRange then
		inrange = inrange + 1
	    elseif player.IsLeader then
		inrange = inrange - 1
	    end
	end
    end

    if Me.IsLeader then
	inrange = inrange + 2
    end

    if (inrange / nmembers) >= 0.5 then
	Me.InRangeTime = GetTimeStamp()
    elseif not Me:HasBeenInRange() then
	Me.InRangeTime = 0
    end
    if dumpme ~= nil then
	dump(dumpme)
	dumpme = nil
    end

    local changed = sldebug or ping_refresh or need_to_fire
    if clear_need_to_fire then
	need_to_fire = false
    end
    return changed
end

-- Saves current widget position to settings
--
function Swimlanes:OnMoveStop()
    local left = widget:GetLeft()
    local top = widget:GetTop()

    saved.PosX = left
    saved.PosY = top
end

-- Style changed
--
local function style_changed()
    local style = saved.Style
    if style ~= curstyle then
	if curstyle ~= "" then
	    set_control_hidden(true)
	end
	curstyle = style
	if widget ~= nil then
	    widget:SetHidden(true)
	end
	if style == "Compact" then
	    widget = CompactSwimlaneControl
	    swimlanerow = "CompactUltSwimlaneRow"
	    namelen = 6
	    topleft = 50
	else
	    widget = SwimlaneControl
	    swimlanerow = "UltSwimlaneRow"
	    namelen = 12
	    topleft = 25
	end
	if (_this.SavedLanes[style] ~= nil) then
	    _this.Lanes = _this.SavedLanes[style]
	else
	    _this.SavedLanes[style] = Lanes.New()
	    _this.Lanes = _this.SavedLanes[style]
	    set_control_movable(saved.Movable)
	    restore_position(saved.PosX, saved.PosY)
	    -- xxx("Saved New swimlane")
	end
	set_control_active()
	need_to_fire = true
after_style_changed = true
    end
end

-- on_set_ult called on header clicked
--
local function on_set_ult(apid, id)
    CALLBACK_MANAGER:UnregisterCallback(SET_ULTIMATE_GROUP, on_set_ult)

    Settings.SetSwimlaneUltId(id, apid)
end

-- Set the swimlane header icon in base of apid
--
function Lanes:SetUlt(id, newapid)
    if self[newapid] ~= nil then
	return  -- already displaying this ultimate
    end
    for apid, lane in pairs(self) do
	if lane.Id == id then
	    self[newapid] = lane -- New row
	    lane.Apid = newapid
	    local ult = Ult.ByPing(newapid)
	    lane.Icon:SetTexture(GetAbilityIcon(ult.Aid))
	    if lane.Label ~= nil then
		lane.Label:SetText(Ult.ByPing(newapid).Name)
	    end
	    self[apid] = nil	        -- Delete old lane
	    need_to_fire = true
	    break
	end
    end
    _this.Lanes:Update("Ultimate changed")
end

-- Lane:Click called on header clicked
--
function Lane:Click()
    if (self.Button ~= nil) then
	CALLBACK_MANAGER:RegisterCallback(SET_ULTIMATE_GROUP, on_set_ult)
	CALLBACK_MANAGER:FireCallbacks(SHOW_ULTIMATE_GROUP_MENU, self.Button, self.Id, self.Apid)
    else
	Error("Lane:Click, button nil")
    end
end

function Lane:Header()
    self.Control = widget:GetNamedChild("Swimlane" .. self.Id)
    self.Button = self.Control:GetNamedChild("Header"):GetNamedChild("SelectorButtonControl"):GetNamedChild("Button")
    self.Icon = self.Control:GetNamedChild("Header"):GetNamedChild("SelectorButtonControl"):GetNamedChild("Icon")
    self.Label = self.Control:GetNamedChild("Header"):GetNamedChild("UltLabel")
    if self.Id == MIAlane then
	self.Button:SetHandler("OnClicked", nil)
    else
	self.Button:SetHandler("OnClicked", function() self:Click() end)
    end

    local apid
    if self.Id == MIAlane then
	apid = 'MIA'
	self.Plunk = Player.PlunkMIA
    else
	apid = saved.LaneIds[self.Id]
	self.Plunk = Player.PlunkNotMIA
    end
    local ult = Ult.ByPing(apid)
    if (ult == nil) then
	apid = 'MIA'
	ult = Ult.ByAid(apid)
    end
    local icon
    if ult.Name == 'MIA' then
	icon = "/POC/icons/lollipop.dds"
    else
	icon = GetAbilityIcon(ult.Aid)
    end
    self.Icon:SetTexture(icon)

    if (self.Label ~= nil) then
	self.Label:SetText(ult.Name)
    end

    self:Hide(true)

    return apid
end

function Lane:Hide(displayed)
    local hide = self.Id > MIAlane or (self.Id == MIAlane and not displayed)
    self.Button:SetHidden(hide)
    self.Icon:SetHidden(hide)
    if self.Label then
	self.Label:SetHidden(hide)
    end
end

function Lanes:Redo()
    local oldMIAlane = MIAlane
    MIAlane = saved.SwimlaneMaxCols + 1
    if MIAlane == oldMIAlane then
	return
    end
    local mialane = self['MIA']
    if mialane.Id > MIAlane then
	mialane:Update(true)
    end
    local lane = self[saved.LaneIds[mialane.Id]]
    if lane == nil then
	lane = Lane.New(self, mialane.Id)
    else
	lane.Id = mialane.Id
	lane:Header()
    end
    mialane.Id = MIAlane
    mialane:Header()

    for n, v in pairs(self) do
	v:Update(true)
    end
end

-- Create a swimlane list headers
--
function Lane.New(lanes, i)
    local self = setmetatable({Id = i}, Lane)

    apid = self:Header()
-- xxx("New", i, self.Control)

    if lanes[apid] == nil then
	lanes[apid] = self
    end

    local last_row = self.Control
    for i = 1, SWIMLANEULTMAX, 1 do
	local row = self.Control:GetNamedChild("Row" .. i)
	if row == nil then
	    row = CreateControlFromVirtual("$(parent)Row", self.Control, swimlanerow, i)
	end

	row:SetHidden(true) -- not visible initially
	row:SetDrawLayer(1)

	if (i == 1) then
	    row:SetAnchor(TOPLEFT, last_row, TOPLEFT, 0, topleft)
	else
	    row:SetAnchor(TOPLEFT, last_row, BOTTOMLEFT, 0, -2)
	end
	last_row = row
    end
    self.Apid = apid
    return self
end

function Lanes.New()
    local self = setmetatable({}, Lanes)
    MIAlane = saved.SwimlaneMaxCols + 1
    for i = 1, SWIMLANES + 1 do
	Lane.New(self, i)
    end
    return self
end

function Swimlanes:SaveUltNumberPos()
    saved.UltNumberPos = {self:GetLeft(),self:GetTop()}
end

function Swimlanes.Sched()
    need_to_fire = true
    set_control_active()
end

function UltNumber.Hide(x)
    if saved.UltNumberShow then
	if Me.IsDead or Me.UltMain == 0 or Me.Ults[Me.UltMain] < 100 then
	    x = true
	end
	UltNumber:SetHidden(x)
    end
end

function UltNumber.Show(n)
    local color
    if n == 1 then
	color = "00ff00"
    else
	color = "ff0000"
    end
    UltNumberLabel:SetText("|c" .. color .. " #" .. n .. "|r")
    UltNumber.Hide(false)
    local timenow = GetTimeStamp()
    if ((GetTimeStamp() - last_played) < MAXPLAYSOUNDTIME) then
	play_sound = false
	return
    end
    if n ~= 1 or not play_sound or not saved.WereNumberOne then
	return
    end
    PlaySound(SOUNDS.DUEL_START)
    last_played = GetTimeStamp()
    play_sound = false
    -- xxx("sound", play_sound)
    Me.Because = "false because we played the sound"
end

-- Initialize Swimlanes
--
Swimlanes.Update = function(x) _this.Lanes:Update(x) end
function Swimlanes.Initialize()
    saved = Settings.SavedVariables
    group_members = saved.GroupMembers
    for n, v in pairs(group_members) do
	setmetatable(v, Player)
	if n == myname then
	    v =  ZO_DeepTableCopy(v, Me)
	end
	group_members[n] = v
    end

    UltNumber:ClearAnchors()
    if (saved.UltNumberPos == nil) then
	UltNumber:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
    else
	UltNumber:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT,
				saved.UltNumberPos[1],
				saved.UltNumberPos[2])
    end
    UltNumber:SetMovable(true)
    UltNumber:SetMouseEnabled(true)
    UltNumber.Hide(false)

    style_changed()
    after_style_changed = false

    EVENT_MANAGER:RegisterForEvent(Settings.Name, EVENT_PLAYER_ACTIVATED, Swimlanes.Update)
    CALLBACK_MANAGER:RegisterCallback(SWIMLANE_COLMAX_CHANGED, function () _this.Lanes:Redo() end)
    CALLBACK_MANAGER:RegisterCallback(STYLE_CHANGED, style_changed)
    SLASH_COMMANDS["/pocpct"] = function(pct)
	if string.len(pct) == 0 then
	    forcepct = nil
	else
	    forcepct = tonumber(pct)
	end
    end
    SLASH_COMMANDS["/pocpingtag"] = function(pct)
	local p = tostring(GetGroupUnitTagByIndex(GetGroupIndexByUnitTag("player")))
	msg(p)
    end
    SLASH_COMMANDS["/pocsldebug"] = function(pct)
	sldebug = not sldebug
	msg(sldebug)
    end
    SLASH_COMMANDS["/pocdump"] = function(x) dumpme = x end
    SLASH_COMMANDS["/pocclear"] = clear
    SLASH_COMMANDS["/pocrefresh"] = function(pct)
	ping_refresh = not ping_refresh
	if ping_refresh then
	    msg("refresh on")
	else
	    msg("refresh off")
	end
    end
    SLASH_COMMANDS["/pocfired"] = function()
	Me:Alert(myname)
    end
end
