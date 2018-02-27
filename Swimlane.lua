local SWIMLANES = 6
local TIMEOUT = 10		-- s; GetTimeStamp() is in seconds
local INRANGETIME = 60		-- Reset ultpct if not inrange for at least this long
local REFRESH_IF_CHANGED = 1
local MAXPLAYSOUNDTIME = 30

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

local POC_Lane = {}
POC_Lane.__index = POC_Lane

local play_sound = false
local last_played = 0
POC_Player = {
    IsMe = false,
    NewClient = true,
    TimeStamp = 0,
    Ults = {},
}
POC_Player.__index = POC_Player

local me = setmetatable({
    IsDead = false,
    IsMe = true,
    NewClient = true,
    TimeStamp = 0,
    Ults = {}
}, POC_Player)
POC_Me = me

local myname = GetUnitName("player")

local POC_Lanes = {}
POC_Lanes.__index = POC_Lanes

local MIAlane = 0

local saved
local myults

-- Table POC_Swimlanes
--
POC_Swimlanes = {
    Name = "POC-Swimlanes",
    Lanes = nil,
    SavedLanes = {},
    WasActive = false,
}
POC_Swimlanes.__index = POC_Swimlanes

local _this = POC_Swimlanes

local last_update = 0
local need_to_fire = 0

if POC_UltNumber == nil then
    POC_UltNumber = {}	-- Just for linux
end

local function _noop() end

local xxx
local msg = d
local d = nil

local LAM = LibStub("LibAddonMenu-2.0")

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
    if (POC_GroupHandler.IsGrouped()) then
	widget:SetHidden(ishidden)
	POC_UltNumber.Hide(ishidden)
    else
	widget:SetHidden(true)
	POC_UltNumber.Hide(true)
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
    local isvisible = POC_Settings.IsSwimlaneListVisible() and POC_GroupHandler.IsGrouped()
    local ishidden = not isvisible or POC_CurrentHudHiddenState()
    set_control_hidden(ishidden)

    if (isvisible) then
	if registered then
	    return
	end
	registered = true
	set_control_movable(saved.Movable)
	restore_position(saved.PosX, saved.PosY)

	CALLBACK_MANAGER:RegisterCallback(POC_PLAYER_DATA_CHANGED, POC_Player.Update)
	CALLBACK_MANAGER:RegisterCallback(POC_MOVABLE_CHANGED, set_control_movable)
	CALLBACK_MANAGER:RegisterCallback(POC_SWIMLANE_ULTIMATE_GROUP_ID_CHANGED, function (x,y) _this.Lanes:SetUlt(x, y) end)
	CALLBACK_MANAGER:RegisterCallback(POC_HUD_HIDDEN_STATE_CHANGED, set_control_hidden)
    elseif (registered) then
	registered = false
	-- Stop timeout timer
	-- EVENT_MANAGER:UnregisterForUpdate(_this.Name)

	-- CALLBACK_MANAGER:UnregisterCallback(POC_GROUP_CHANGED, _this.UpdateAll)
	CALLBACK_MANAGER:UnregisterCallback(POC_PLAYER_DATA_CHANGED, POC_Player.Update)
	CALLBACK_MANAGER:UnregisterCallback(POC_MOVABLE_CHANGED, set_control_movable)
	CALLBACK_MANAGER:UnregisterCallback(POC_SWIMLANE_ULTIMATE_GROUP_ID_CHANGED, function (x,y) _this.Lanes:SetUlt(x, y) end)
	CALLBACK_MANAGER:UnregisterCallback(POC_HUD_HIDDEN_STATE_CHANGED, set_control_hidden)
    end
end

-- Sets visibility of labels
--
function POC_Lanes:Update(x)
    local refresh
    local displayed = false
    if (POC_GroupHandler.IsGrouped()) then
	refresh = true
	displayed = not _this.WasActive
    elseif (not _this.WasActive) then
	refresh = false
    else
	refresh = true	-- just get rid of everything
	msg("POC: No longer grouped")
	set_control_active()
	_this.WasActive = false
    end

    if refresh then
	-- Check all swimlanes
	last_update = GetTimeStamp()
	for _,lane in ipairs(POC_IdSort(self, "Id")) do
	    if lane:Update(false) then
		displayed = true
	    else
		-- xxx("Didn't refresh " .. tostring(apid))
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
function POC_Player:TimedOut()
    return (GetTimeStamp() - self.TimeStamp) > TIMEOUT
end

-- Return true if we need to back the heck off
--
function POC_Player:HasBeenInRange()
    return (GetTimeStamp() - self.InRangeTime) < INRANGETIME
end

-- Update swimlane
--
function POC_Lane:Update(force)
    local laneid = self.Id
    if not force and laneid > MIAlane then
	return
    end
    local apid = self.Apid
    local players = self.Players

    local displayed = false
    local lastlane
    if saved.MIA then
	lastlane = MIAlane
    else
	lastlane = MIAlane - 1
    end
    local n = 1
    if (laneid <= lastlane) then
	function sortval(player)
	    local a
	    if player:TimedOut() or player.IsRemote then
		a = player.Ults[apid] - 200
	    elseif player.IsDead or player:TimedOut() then
		a = player.Ults[apid] - 100
	    else
		a = player.Ults[apid]
	    end
	    return a
	end

	function compare(key1, key2)
	    local player1 = players[key1]
	    local player2 = players[key2]
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
	for name, v in pairs(players) do
	    if v.Ults[apid] == nil then
		self[name] = nil
	    else
		table.insert(keys, name)
	    end
	end

	table.sort(keys, compare)

	-- Update sorted swimlane
	local gt100 = 101 + saved.SwimlaneMax 
	for _, playername in ipairs(keys) do
	    local player = players[playername]
	    if not IsUnitGrouped(player.PingTag) then
		group_members[playername] = nil
	    else
		if n > saved.SwimlaneMax then
		    -- log here?
		    break
		end
		displayed = true
		if not player.IsMe then
		    self:UpdateCell(n, player, playername)
		    if player.Ults[apid] > 100 then
			gt100 = player.Ults[apid]
		    end
		else
		    local noshow = true
		    if forcepct ~= nil then
			player.Ults[apid] = forcepct
		    end
		    if player.Ults[apid]  < 100 then
			play_sound = true
			POC_Me.Because = "ultpct < 100"
		    elseif not player.IsDead and player:HasBeenInRange() then
			player.Ults[apid] = gt100 - 1
			noshow = false
			POC_Me.Because = "ultpct == 100"
		    else
			-- reset order since we can't contribute
			player.Ults[apid] = 100
			play_sound = true
			POC_Me.Because = "out of range or dead"
		    end
		    -- xxx(playername .. " " .. tostring(player.IsMe) .. " " .. player.UltPct)
		    self:UpdateCell(n, player, playername)
		    if (noshow or not saved.UltNumberShow or laneid == MIAlane or
			POC_CurrentHudHiddenState() or player.IsDead or
			not POC_GroupHandler.IsGrouped() or
			not POC_Settings.IsSwimlaneListVisible()) then
			POC_UltNumber.Hide(true)
			POC_UltNumberLabel:SetText("")
		    else
			POC_UltNumber.Show(n)
		    end
		end
		n = n + 1
	    end
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
function POC_Lane:UpdateCell(i, player, playername)
    local rowi = "Row" .. i
    local apid = self.Apid
    local row = self.Control:GetNamedChild(rowi)
    if saved.AtNames then
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
    if player.Ults[apid] > 100 then
	ultpct = 100
    else
	ultpct = player.Ults[apid]
    end

    local alivealpha
    local deadalpha
    local inprogressalpha
    if not player.InRange then
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
	row:GetNamedChild("Backdrop"):SetCenterColor(0.51, 0.41, 0.65)
	if (player.IsDead) then
-- xxx(playername, rowi, "dead color", deadalpha)
	    namecell:SetColor(0.5, 0.5, 0.5, 0.8)
	    ultcell:SetColor(0.8, 0.03, 0.03, deadalpha)
	elseif (player.Ults[apid] >= 100) then
-- xxx(playername, rowi, "ready color", alivealpha)
	    namecell:SetColor(1, 1, 1, 1)
	    -- row:GetNamedChild("UltPct"):SetColor(0.03, 0.7, 0.03, alivealpha)
	    ultcell:SetColor(0.01, 0.69, 0.02, alivealpha)
	else
-- xxx(playername, rowi, "inprogress color")
	    namecell:SetColor(1, 1, 1, 0.8)
	    ultcell:SetColor(0.03, 0.03, 0.7, inprogressalpha)
	end
    end

    row:SetHidden(false)
end

-- Updates player (potentially) in the swimlane
--
function POC_Player.Update(pingtag, apid1, pct1, apid2, pct2)
    local nmembers = 0
    local inrange = 0
    local timenow = GetTimeStamp()
    local inname = GetUnitName(pingtag)
-- msg(tostring(apid1), tostring(pct1), tostring(apid2), tostring(pct2))
    for i = 1, 24 do
	local unitid = "group" .. tostring(i)
	local unitname = GetUnitName(unitid)
	if unitname ~= nil and unitname:len() ~= 0 then
	    nmembers = nmembers + 1
	    local player
	    if inname == unitname then
		player = {
		    TimeStamp = timenow,
		}
		player.Ults = {[apid1] = pct1}
		if apid2 == nil then
		    player.NewClient = false
		else
		    player.Ults[apid2] = pct2
		    player.NewClient = true
		end
	    else
		local gplayer = group_members[unitname]
		if gplayer ~= nil then
		    player = ZO_DeepTableCopy(gplayer)
		else
		    local savedplayer = saved.GroupMembers[unitname]
		    if savedplayer == nil then
			player = {
			    NewClient = false,
			    TimeStamp = 0,
			    Ults = {MIA = 0}
			}
		    else
			-- This should only happen when coming back from, e.g., /reloadui
			-- So, let New() repopulate.
			player = savedplayer
			-- Remove any left over cruft from an older version
			if player.NewClient ~= nil then
			    player.NewClient = false
			    player.Ults[player.UltAid] = player.UltPct
			end
			for n, _ in pairs(player) do
			    if POC_Player[n] == nil then
				player[n] = nil
			    end
			end
			player.TimeStamp = 0
		    end
		end
	    end
	    player.PingTag = unitid
	    local changed, player1 = POC_Player.New(player, unitname, unitid)
	    if changed then
		need_to_fire = true
	    end
	    if player1:TimedOut() then
		nmembers = nmembers - 1
	    elseif player1.InRange then
		inrange = inrange + 1
	    elseif player1.IsLeader then
		inrange = inrange - 1
	    end
	end
    end

    if POC_Me.IsLeader then
	inrange = inrange + 2
    end

    if (inrange / nmembers) >= 0.5 then
	POC_Me.InRangeTime = timenow
    elseif POC_Me.InRangeTime == nil then
	POC_Me.InRangeTime = 0
    end

    if sldebug or ping_refresh or (need_to_fire and ((timenow - last_update) > REFRESH_IF_CHANGED)) then
	need_to_fire = false
	CALLBACK_MANAGER:FireCallbacks(POC_GROUP_CHANGED, "refresh")
    end
end

function POC_Player.New(inplayer, name, pingtag)
    if _this.Lanes == nil then
	return
    end
    local self = group_members[name]
    if self == nil then
	if name == myname then
	    self = POC_Me
	else
	    self = {
		IsMe = false,
		TimeStamp = 0,
		Ults = {}
	    }
	end
	group_members[name] = setmetatable(self, POC_Player)
    end

    inplayer.PingTag = pingtag
    inplayer.IsLeader = IsUnitGroupLeader(pingtag)
    inplayer.InCombat = IsUnitInCombat(pingtag)
    inplayer.Online = IsUnitOnline(pingtag)
    inplayer.InRange = IsUnitInGroupSupportRange(pingtag)
    inplayer.IsDead = IsUnitDead(pingtag)
    if saved.AtNames and self.AtName == nil then
	inplayer.AtName = GetUnitDisplayName(pingtag)
    end

    local changed = inplayer.TimeStamp ~= nil and self.TimeStamp ~= nil and self:TimedOut()
    if not inplayer.NewClient and inplayer.Ults and self.NewClient then
	for n, v in pairs(inplayer.Ults) do
	    if self.Ults[n] ~= nil then
		self.Ults[n] = v
	    end
	end
	inplayer.Ults = nil
	inplayer.NewClient = nil
    end
    for n, v in pairs(inplayer) do
	if self[n] ~= v then
	    if n ~= 'Ults' then
		-- xxx(name .. " " .. tostring(n) .. "=" .. tostring(v))
		if n ~= 'TimeStamp' then
		    changed = true
		end
	    else
		for n1, v1 in pairs(inplayer.Ults) do
		    if self.Ults[n1] ~= v1 then
			changed = true
		    end
		    local lane = _this.Lanes[n1]
		    if _this.Lanes[n1] == nil then
			lane = _this.Lanes['MIA']
		    end
		    lane.Players[name] = self
		end
	    end
	    self[n] = v
	end
    end

    return changed, self
end

-- Saves current widget position to settings
--
function POC_Swimlanes:OnMoveStop()
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
	    widget = POC_CompactSwimlaneControl
	    swimlanerow = "CompactUltSwimlaneRow"
	    namelen = 6
	    topleft = 50
	else
	    widget = POC_SwimlaneControl
	    swimlanerow = "UltSwimlaneRow"
	    namelen = 12
	    topleft = 25
	end
	if (_this.SavedLanes[style] ~= nil) then
	    _this.Lanes = _this.SavedLanes[style]
	else
	    _this.SavedLanes[style] = POC_Lanes.New()
	    _this.Lanes = _this.SavedLanes[style]
	    set_control_movable(saved.Movable)
	    restore_position(saved.PosX, saved.PosY)
	    -- xxx("Saved New swimlane")
	end
	set_control_active()
    end
end

-- on_set_ult called on header clicked
--
local function on_set_ult(apid, id)
    CALLBACK_MANAGER:UnregisterCallback(POC_SET_ULTIMATE_GROUP, on_set_ult)

    POC_Settings.SetSwimlaneUltId(id, apid)
end

-- Set the swimlane header icon in base of apid
--
function POC_Lanes:SetUlt(id, newapid)
    if self[newapid] ~= nil then
	return  -- already displaying this ultimate
    end
    for apid, lane in pairs(self) do
	if lane.Id == id then
	    self[newapid] = lane -- New row
	    lane.Apid = newpaid
	    local ult = POC_Ult.ByPing(newapid)
	    lane.Icon:SetTexture(GetAbilityIcon(ult.Aid))
	    if lane.Label ~= nil then
		lane.Label:SetText(POC_Ult.ByPing(newapid).Name)
	    end
	    self[apid] = nil	-- Delete old row
	    break
	end
    end
    CALLBACK_MANAGER:FireCallbacks(POC_ZONE_CHANGED)
end

-- POC_Lane:Click called on header clicked
--
function POC_Lane:Click()
    if (self.Button ~= nil) then
	CALLBACK_MANAGER:RegisterCallback(POC_SET_ULTIMATE_GROUP, on_set_ult)
	CALLBACK_MANAGER:FireCallbacks(POC_SHOW_ULTIMATE_GROUP_MENU, self.Button, self.Id, self.Apid)
    else
	POC_Error("POC_Lane:Click, button nil")
    end
end

function POC_Lane:Header()
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
    else
	apid = saved.LaneIds[self.Id]
    end
    local ult = POC_Ult.ByPing(apid)
    if (ult == nil) then
	apid = 'MIA'
	ult = POC_Ult.ByAid(apid)
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

function POC_Lane:Hide(displayed)
    local hide = self.Id > MIAlane or (self.Id == MIAlane and not displayed)
    self.Button:SetHidden(hide)
    self.Icon:SetHidden(hide)
    if self.Label then
	self.Label:SetHidden(hide)
    end
end

function POC_Lanes:Redo()
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
	lane = POC_Lane.New(self, mialane.Id)
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
function POC_Lane.New(lanes, i)
    local self = setmetatable({Id = i}, POC_Lane)

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
    self.Players = {}
    self.Apid = apid
    return self
end

function POC_Lanes.New()
    local self = setmetatable({}, POC_Lanes)
    MIAlane = saved.SwimlaneMaxCols + 1
    for i = 1, SWIMLANES + 1 do
	POC_Lane.New(self, i)
    end
    return self
end

function POC_Swimlanes:SaveUltNumberPos()
    saved.UltNumberPos = {self:GetLeft(),self:GetTop()}
end


function POC_UltNumber.Hide(x)
    if saved.UltNumberShow then
	if POC_Me.IsDead or not POC_Me.Ults[myults[1]] or POC_Me.Ults[myults[1]] < 100 then
	    x = true
	end
	POC_UltNumber:SetHidden(x)
    end
end

function POC_UltNumber.Show(n)
    local color
    if n == 1 then
	color = "00ff00"
    else
	color = "ff0000"
    end
    POC_UltNumberLabel:SetText("|c" .. color .. " #" .. n .. "|r")
    POC_UltNumber.Hide(false)
    local timenow = GetTimeStamp()
    if n ~= 1 or not play_sound or not saved.WereNumberOne or
       ((GetTimeStamp() - last_played) < MAXPLAYSOUNDTIME) then
	return
    end
    PlaySound(SOUNDS.DUEL_START)
    last_played = GetTimeStamp()
    play_sound = false
    -- xxx("sound", play_sound)
    POC_Me.Because = "false because we played the sound"
end

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
    for n, v in pairs(saved.GroupMembers) do
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
		    local u = POC_Ult.ByAid(t)
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
			local ult = POC_Ult.ByPing(n)
			p = p .. comma .. ult.Desc .. '[' .. v .. ']'
			comma = ', '
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
	msg("nil")
    end
end
-- Initialize initializes _this
--
function POC_Swimlanes.Initialize()
    xxx = POC.xxx
    saved = POC_Settings.SavedVariables
    myults = saved.MyUltId
    group_members = saved.GroupMembers
    for n, v in pairs(group_members) do
	if n == myname then
	    group_members[n] = nil
	else
	    group_members[n] = setmetatable(v, POC_Player)
	    group_members[n].Lane = nil
	end
    end

    POC_UltNumber:ClearAnchors()
    if (saved.UltNumberPos == nil) then
	POC_UltNumber:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
    else
	POC_UltNumber:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT,
				saved.UltNumberPos[1],
				saved.UltNumberPos[2])
    end
    POC_UltNumber:SetMovable(true)
    POC_UltNumber:SetMouseEnabled(true)
    POC_UltNumber.Hide(false)

    style_changed()

    CALLBACK_MANAGER:RegisterCallback(POC_SWIMLANE_COLMAX_CHANGED, function () _this.Lanes:Redo() end)
    CALLBACK_MANAGER:RegisterCallback(POC_STYLE_CHANGED, style_changed)
    CALLBACK_MANAGER:RegisterCallback(POC_GROUP_CHANGED, function (x) _this.Lanes:Update(x) end)
    CALLBACK_MANAGER:RegisterCallback(POC_ZONE_CHANGED, function() set_control_active() need_to_fire = true end)
    CALLBACK_MANAGER:RegisterCallback(POC_UNIT_GROUPED_CHANGED, set_control_active)
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
    SLASH_COMMANDS["/pocdump"] = dump
    SLASH_COMMANDS["/pocrefresh"] = function(pct)
	ping_refresh = not ping_refresh
	if ping_refresh then
	    msg("refresh on")
	else
	    msg("refresh off")
	end
    end
end
