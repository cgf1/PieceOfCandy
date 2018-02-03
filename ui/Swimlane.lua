--[[
	Local variables
]]--
local LOG_ACTIVE = false

local SWIMLANES = 6
local REFRESHRATE = 1000	-- ms; RegisterForUpdate is in miliseconds
local TIMEOUT = 10		-- s; GetTimeStamp() is in seconds
local BACKOFF = 10		-- BACKOFF time after timed out for setting ultimate percent ordering
local REFRESH_IF_CHANGED = 1

local widget = nil
local curstyle = ""
local registered = false
local namelen = 12
local topleft = 25
local swimlanerow

local SWIMLANEULTMAX = 24

local forcepct = nil
local sldebug = false

local group_members = {}

local me

local ping_refresh = false

local POC_Lane = {}
POC_Lane.__index = POC_Lane

local POC_Player = {
    Lane = nil
}
POC_Player.__index = POC_Player

local POC_Lanes = {}
POC_Lanes.__index = POC_Lanes

local MIAlane = 0

local saved

-- Table POC_Swimlanes
--
POC_Swimlanes = {
    IsMocked = false,
    Name = "POC-Swimlanes",
    Lanes = nil,
    SavedLanes = {},
    UltPct = nil,
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

-- set_control_movable sets the Movable and MouseEnabled flag in UI elements
--
local function set_control_movable(ismovable)
    widget:GetNamedChild("MovableControl"):SetHidden(ismovable == false)

    widget:SetMovable(ismovable)
    widget:SetMouseEnabled(ismovable)
end

-- Set hidden on control
--
local function set_control_hidden(isHidden)
    if (POC_GroupHandler.IsGrouped()) then
	widget:SetHidden(isHidden)
	POC_UltNumber.Hide(isHidden)
    else
	widget:SetHidden(true)
	POC_UltNumber.Hide(true)
    end
end

-- restore_position sets widget position
--
local function restore_position(posX, posY)
    widget:ClearAnchors()
    widget:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, posX, posY)
end

-- set_control_active sets hidden on control
--
local function set_control_active()
    local isVisible = POC_Settings.IsSwimlaneListVisible() and POC_GroupHandler.IsGrouped()
    local isHidden = not isVisible or POC_CurrentHudHiddenState()
    set_control_hidden(isHidden)

    if (isVisible) then
	if (registered) then
	    return
	end
	registered = true
	set_control_movable(saved.Movable)
	restore_position(saved.PosX, saved.PosY)

	-- EVENT_MANAGER:RegisterForUpdate(_this.Name, REFRESHRATE, _this.UpdateAll)

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
		-- xxx("Didn't refresh " .. tostring(gid))
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
    return (GetTimeStamp() - self.LastTimeStamp) > TIMEOUT
end

-- Return true if we need to back the heck off
--
function POC_Player:ShouldBackOff()
    return self.BackOff ~= nil and GetTimeStamp() <= self.BackOff
end

-- Update swimlane
--
function POC_Lane:Update(force)
    local laneid = self.Id
    if not force and laneid > MIAlane then
	return
    end
    local players = self.Players

    local n = 1
    local displayed = false
    if (laneid <= MIAlane) then
	function sortval(player)
	    local a
	    if player:TimedOut() or player.IsRemote then
		a = player.UltPct - 200
	    elseif player.IsPlayerDead or player:TimedOut() then
		a = player.UltPct - 100
	    else
		a = player.UltPct
	    end
	    return a
	end

	function compare(key1, key2)
	    player1 = players[key1]
	    player2 = players[key2]
	    a = sortval(player1)
	    b = sortval(player2)
	    -- xxx("A " .. a)
	    -- xxx("B " .. b)
	    if (a == b) then
		return player1.PingTag < player2.PingTag
	    else
		return a > b
	   end
	end

	local keys = {}
	for n in pairs(players) do
	    table.insert(keys, n)
	end

	table.sort(keys, compare)

	-- Update sorted swimlane
	for _, playername in ipairs(keys) do
	    local player = players[playername]
	    local player_grouped =  IsUnitGrouped(player.PingTag)
	    if not player_grouped or player.Lane ~= self then
		self.Players[playername] = nil
		if not player_grouped then
		    group_members[playername] = nil
		    saved.GroupMembers[playername] = nil
		end
	    else
		if n > saved.SwimlaneMax then
		    -- log here?
		    break
		end
		displayed = true
		if not player.IsMe then
		    self:UpdateCell(n, player, playername)
		    -- xxx(playername .. " " .. tostring(player.IsMe) .. " " .. player.UltPct)
		elseif not player:ShouldBackOff() then
		    local not100
		    if forcepct ~= nil then
			player.UltPct = forcepct
			_this.UltPct = forcepct
			not100 = player.UltPct	< 100
		    elseif player.UltPct  < 100 then
			_this.UltPct = nil
			not100 = true
		    elseif player.IsPlayerDead then
			_this.UltPct = 100
		    else
			_this.UltPct = 101 + saved.SwimlaneMax - n
			player.UltPct = _this.UltPct
			player.BackOff = nil
		    end
		    -- xxx(playername .. " " .. tostring(player.IsMe) .. " " .. player.UltPct)
		    self:UpdateCell(n, player, playername)
		    if (not saved.UltNumberShow or
			    not100 or
			    laneid == MIAlane or
			    POC_CurrentHudHiddenState() or
			    player.IsPlayerDead or
			    not POC_GroupHandler.IsGrouped() or
			    not POC_Settings.IsSwimlaneListVisible()) then
			POC_UltNumber.Hide(true)
			if not100 then
			    play_sound = true
			end
		    else
			local color
			if n == 1 then
			    color = "00ff00"
			else
			    color = "ff0000"
			end
			POC_UltNumberLabel:SetText("|c" .. color .. " #" .. n .. "|r")
			POC_UltNumber.Hide(false)
			if (n ~= 1) then
			    play_sound = true
			elseif (play_sound and saved.WereNumberOne) then
			    PlaySound(SOUNDS.DUEL_START)
			    play_sound = false
			end
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
    local row = self.Control:GetNamedChild("Row" .. i)
    local nameLength = string.len(playername)

    if (nameLength > namelen) then
	playername = string.sub(playername, 0, namelen) .. '..'
    end

    if not player.IsPlayerDead and player.InCombat then
	playername = "|cff0000" .. playername .. "|r"
    end

    if (sldebug) then
	playername = playername .. "   " .. player.UltPct .. "%"
    end

    local ultpct
    if player.UltPct > 100 then
	ultpct = 100
    else
	ultpct = player.UltPct
    end

    local alivealpha
    local deadalpha
    local inprogressalpha
    if not player.InRange then
	alivealpha = .5
	deadalpha = .4
	inprogressalpha = .4
-- xxx(playername, "~inrange alpha")
    else
	alivealpha = 1
	deadalpha = .8
	inprogressalpha = .7
    end

    row:SetHidden(true)
    row:GetNamedChild("SenderNameValueLabel"):SetText(playername)
    row:GetNamedChild("UltPctStatusBar"):SetValue(ultpct)

    if (player.IsPlayerDead) then
-- xxx(playername, rowi, "dead color", deadalpha)
	row:GetNamedChild("SenderNameValueLabel"):SetColor(0.5, 0.5, 0.5, .8)
	row:GetNamedChild("UltPctStatusBar"):SetColor(0.8, 0.03, 0.03, deadalpha)
    elseif player:TimedOut(player) then
-- xxx(playername, rowi, "timedout color")
	row:GetNamedChild("SenderNameValueLabel"):SetColor(0.8, 0.8, 0.8, 0.7)
	row:GetNamedChild("UltPctStatusBar"):SetColor(0.8, 0.8, 0.8, alivealpha)
    elseif (player.UltPct >= 100) then
-- xxx(playername, rowi, "ready color", alivealpha)
	row:GetNamedChild("SenderNameValueLabel"):SetColor(1, 1, 1, 1)
	row:GetNamedChild("UltPctStatusBar"):SetColor(0.03, 0.7, 0.03, alivealpha)
    else
-- xxx(playername, rowi, "inprogress color")
	row:GetNamedChild("SenderNameValueLabel"):SetColor(1, 1, 1, 0.8)
	row:GetNamedChild("UltPctStatusBar"):SetColor(0.03, 0.03, 0.7, inprogressalpha)
    end

    if (row:IsHidden()) then
	row:SetHidden(false)
    end
end

-- Updates player (potentially) in the swimlane
--
function POC_Player.Update(inplayer)
    for i = 1, 24 do
	local unitid = "group" .. tostring(i)
	local unitname = GetUnitName(unitid)
	if unitname ~= nil and unitname:len() ~= 0 then
	    local player = group_members[unitname]
	    if player == nil then
		savedplayer = saved.GroupMembers[unitname]
		if savedplayer == nil then
		    player = {}
		    player.UltPct = 0		-- not really
		else
		    saved.GroupMembers[unitname] = nil
		    player = savedplayer
		    savedplayer = nil
		end
		player.Lane = _this.Lanes['MIA']
		player.PingTag = unitid
	    elseif player.PingTag == inplayer.PingTag then
		player = inplayer
	    else
		player1 = {}
		for k,v in pairs(player) do
		    player1[k] = v
		end
		player = player1
	    end
	    player.PlayerName = unitname
	    player.LastTimeStamp = nil
	    if POC_Player.new(player, unitid) then
		need_to_fire = true
	    end
	end
    end
    if ping_refresh or (need_to_fire and ((GetTimeStamp() - last_update) > REFRESH_IF_CHANGED)) then
	need_to_fire = false
	CALLBACK_MANAGER:FireCallbacks(POC_GROUP_CHANGED, "refresh")
    end
end

function POC_Player.new(inplayer, pingtag)
    if _this.Lanes == nil then
	return
    end
    local name = inplayer.PlayerName
    local self = group_members[name]
    local saved_self = saved.GroupMembers[name]
    if self == nil then
	self = setmetatable({}, POC_Player)
	group_members[name] = self
	saved_self = setmetatable({Ult = {}}, POC_Player)
	saved.GroupMembers[name] = saved_self
	if name == GetUnitName("player") then
	    self.IsMe = true
	    saved_self.IsMe = true
	    me = self
	end
	self.LastTimeStamp = 0	-- we weren't pinged
	saved_self.LastTimeStamp = 0	-- we weren't pinged
    end

    local orig_swimlane = self.Lane
    local gid
    if inplayer.Lane ~= nil or inplayer.Ult == nil then
	gid = 'MIA'
    else
	gid = inplayer.Ult.Gid
	inplayer.Lane = _this.Lanes[gid]
	if inplayer.Lane == nil then
	    inplayer.Lane = _this.Lanes['MIA']
	    gid = 'MIA'
	end
	self.LastTimeStamp = GetTimeStamp()
	saved_self.LastTimeStamp = self.LastTimeStamp
    end

    saved_self.Ult.Gid = gid
    -- Don't need these
    if inplayer.Ult ~= nil then
	inplayer.Ult = nil
    end
    inplayer.PlayerName = nil

    inplayer.PingTag = pingtag
    inplayer.InCombat = IsUnitInCombat(inplayer.PingTag)
    inplayer.Online = IsUnitOnline(inplayer.PingTag)
    inplayer.InRange = IsUnitInGroupSupportRange(inplayer.PingTag)
    inplayer.IsPlayerDead = IsUnitDead(pingtag)

    local changed = false
    for n,v in pairs(inplayer) do
	if self[n] == nil or self[n] ~= v then
	    -- xxx(name .. " " .. tostring(n) .. "=" .. tostring(v))
	    changed = true
	    self[n] = v
	    if n ~= 'Lane' then
		saved_self[n] = v
	    end
	end
    end

    if not self.IsMe or not self:TimedOut() then
	self.BackOff = 0
	saved_self.BackOff = 0
    else
	self.BackOff = GetTimeStamp() + BACKOFF
	saved_self.BackOff = GetTimeStamp() + BACKOFF
    end

    if self.Lane.Players[name] == nil then
	self.Lane.Players[name] = self
    end
    return changed
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
    if (style ~= curstyle) then
	if curstyle ~= "" then
	    set_control_hidden(true)
	end
	curstyle = style
	if (widget ~= nil) then
	    widget:SetHidden(true)
	end
	if (style == "Compact") then
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
	    _this.SavedLanes[style] = POC_Lanes.new()
	    _this.Lanes = _this.SavedLanes[style]
	    set_control_movable(saved.Movable)
	    restore_position(saved.PosX, saved.PosY)
	    -- xxx("Saved new swimlane")
	end
	set_control_active()
    end
end

-- on_set_ult called on header clicked
--
local function on_set_ult(ult, id)
    CALLBACK_MANAGER:UnregisterCallback(POC_SET_ULTIMATE_GROUP, on_set_ult)

    if ult ~= nil and id ~= nil then
	POC_Settings.SetSwimlaneUltId(id, ult)
    else
	POC_Error("POC_Swimlanes.on_set_ult: error ult " .. tostring(ult) .. " id " .. tostring(id))
    end
end

-- SetSwimlaneUltimate sets the swimlane header icon in base of gid
--
function POC_Lanes:SetUlt(id, newult)
    local newgid = newult.Gid
xxx("Info", id, newgid)
    for gid, lane in pairs(self) do
	if lane.Id == id then
	    self[newgid] = lane -- New row
	    local icon
	    lane.Icon:SetTexture(GetAbilityIcon(newgid))
	    lane.Label:SetText(newult.Name)
	    self[gid] = nil	-- Delete old row
	    break
	end
    end
end

-- POC_Lane:Click called on header clicked
--
function POC_Lane:Click()
    if (self.Button ~= nil) then
	CALLBACK_MANAGER:RegisterCallback(POC_SET_ULTIMATE_GROUP, on_set_ult)
	CALLBACK_MANAGER:FireCallbacks(POC_SHOW_ULTIMATE_GROUP_MENU, self.Button, self.Id)
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

    local gid
    if self.Id == MIAlane then
	gid = 'MIA'
    else
	gid = saved.SwimlaneUltIds[self.Id]
    end
    local ult = POC_Ult.ById(gid)
    if (ult == nil) then
	gid = 'MIA'
	ult = POC_Ult.ById(gid)
    end
    local icon
    if ult.Name == 'MIA' then
	icon = "/POC/icons/lollipop.dds"
    else
	icon = GetAbilityIcon(gid)
    end
    self.Icon:SetTexture(icon)

    if (self.Label ~= nil) then
	self.Label:SetText(ult.Name)
    end

    self:Hide(true)

    return gid
end

function POC_Lane:Hide(displayed)
    local hide = self.Id > MIAlane or (self.Id == MIAlane and not displayed)
    self.Button:SetHidden(hide)
    self.Icon:SetHidden(hide)
    self.Label:SetHidden(hide)
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
    local lane = self[saved.SwimlaneUltIds[mialane.Id]]
    if lane == nil then
	lane = POC_Lane.new(self, mialane.Id)
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
function POC_Lane.new(lanes, i)
    local self = setmetatable({Id = i}, POC_Lane)

    gid = self:Header()
-- xxx("new", i, self.Control)

    if lanes[gid] == nil then
	lanes[gid] = self
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
    return self
end

function POC_Lanes.new()
    local self = setmetatable({}, POC_Lanes)
    MIAlane = saved.SwimlaneMaxCols + 1
    for i = 1, SWIMLANES + 1 do
	POC_Lane.new(self, i)
    end
    return self
end

function POC_Swimlanes:SaveUltNumberPos()
    saved.UltNumberPos = {self:GetLeft(),self:GetTop()}
end


function POC_UltNumber.Hide(x)
    if saved.UltNumberShow then
	POC_UltNumber:SetHidden(x)
    end
end

-- Initialize initializes _this
--
function POC_Swimlanes.Initialize(isMocked)
    xxx = POC.xxx
    saved = POC_Settings.SavedVariables

    if not POC_GroupHandler.IsGrouped() then
	saved.GroupMembers = {}
    end

    _this.IsMocked = isMocked

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
    CALLBACK_MANAGER:RegisterCallback(POC_IS_ZONE_CHANGED, set_control_active)
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
    SLASH_COMMANDS["/pocrefresh"] = function(pct)
	ping_refresh = not ping_refresh
	if ping_refresh then
	    msg("refresh on")
	else
	    msg("refresh off")
	end
    end
 end
