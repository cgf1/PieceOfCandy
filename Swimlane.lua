setfenv(1, POC)
local collectgarbage = collectgarbage
local CreateControlFromVirtual = CreateControlFromVirtual
local FormatTimeSeconds = FormatTimeSeconds
local GetAbilityDuration = GetAbilityDuration
local GetGroupSize = GetGroupSize
local GetTimeStamp = GetTimeStamp
local GetUnitDisplayName = GetUnitDisplayName
local GetUnitName = GetUnitName
local IsUnitDead = IsUnitDead
local IsUnitGroupLeader = IsUnitGroupLeader
local IsUnitGrouped = IsUnitGrouped
local IsUnitInCombat = IsUnitInCombat
local IsUnitInGroupSupportRange = IsUnitInGroupSupportRange
local IsUnitOnline = IsUnitOnline
local PlaySound = PlaySound
local table = table
local ZO_ObjectPool_CreateControl = ZO_ObjectPool_CreateControl
local ZO_DeepTableCopy = ZO_DeepTableCopy

SWIMLANES = 9
local TIMEOUT = 10		-- s; GetTimeStamp() is in seconds
local INRANGETIME = 60		-- Reset ultpct if not inrange for at least this long
local REFRESH_IF_CHANGED = 1
local MAXPLAYSOUNDTIME = 60
local GARBAGECOLLECT = 60 * 3

local widget = nil
local cellpool = nil
local registered = false
local namelen = 12
local topleft = 25
local swimlanerow

local SWIMLANEULTMAX = 24

local myults
local forcepct = nil
local sldebug = false

local max_ping

local version
local dversion

local group_members

local ping_refresh = false

local tick = 0

local icon_size = {25, 25}

local Col = {
}
Col.__index = Col

local play_sound = false
local last_played = 0
Player = {
    IsMe = false,
    Pos = 0,
    TimeStamp = 0,
    Ults = {},
}
Player.__index = Player

local me = setmetatable({
    InRangeTime = 0,
    IsDead = false,
    IsMe = true,
    Pos = 0,
    Tick = 0,
    TimeStamp = 0,
    UltMain = 0,
    Ults = {},
    Visited = false
}, Player)
Me = me

local myname = GetUnitName("player")
local ultix = myname

local Cols = {}
Cols.__index = Cols

local MIAlane = 0

local saved

local dumpme

-- Table Swimlanes
--
Swimlanes = {
    Name = "POC-Swimlanes",
    WasActive = false
}
Swimlanes.__index = Swimlanes

local swimlanes = Swimlanes

local need_to_fire = true

local msg = d
local d = nil

-- set_control_movable sets the Movable and MouseEnabled flag in UI elements
--
local function set_control_movable()
    local movable = saved.AllowMove
    if movable == nil then
	movable = true
    end
    widget:SetMovable(movable)
    widget:SetMouseEnabled(movable)
end

-- Set hidden on control
--
local function set_control_hidden(ishidden)
    if Group.IsGrouped() then
	widget:SetHidden(ishidden)
	UltNumber.Hide(ishidden)
    else
	widget:SetHidden(true)
	UltNumber.Hide(true)
    end
end

-- restore_position sets widget position
--
local function restore_position()
    if saved.WinPos == nil then
	widget:GetNamedChild("MovableControl"):SetHidden(false)
    else
	widget:ClearAnchors()
	widget:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, saved.WinPos.X, saved.WinPos.Y)
    end
end

-- set_control_active sets hidden on control
--
local function set_control_active()
    local isvisible = Settings.IsSwimlaneListVisible() and Group.IsGrouped()
    local ishidden = not isvisible or CurrentHudHiddenState()
    set_control_hidden(ishidden)

    if isvisible then
	if registered then
	    return
	end
	registered = true
	restore_position()

	CALLBACK_MANAGER:RegisterCallback(HUD_HIDDEN_STATE_CHANGED, set_control_hidden)
    elseif registered then
	registered = false
	CALLBACK_MANAGER:UnregisterCallback(HUD_HIDDEN_STATE_CHANGED, set_control_hidden)
    end
end

local function clear(verbose)
    saved.GroupMembers = {}
    group_members = saved.GroupMembers
    me.Ults = {}
    me.Pos = 0
    forcepct = nil
    ping_refresh = false
    sldebug = false
    RunClear(gc)
    local msg
    local n = collectgarbage("count")
    collectgarbage()
    n = n - collectgarbage("count")
    msg = string.format("memory cleared: freed %d Kbytes", n)
    if verbose then
	Info(msg)
    end
end

local function dump(name)
    local found = false
    local function time(t)
	local p
	if t == 0 then
	    p = 'never'
	else
	    local duration = GetTimeStamp() - t
	    p = FormatTimeSeconds(duration, TIME_FORMAT_STYLE_DURATION , TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_NONE)
	end
	return p
    end
    for n, v in pairs(group_members) do
	if string.find(n, name, 1) then
	    msg(string.format("== %s ==", n))
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
		    p = string.format("%s [%s]", name, tostring(t))
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
			if not ult.IsMIA then
			    p = string.format("%s%s%s[%s%%]", p, comma, ult.Desc, v)
			    comma = ', '
			end
		    end
		else
		    p = tostring(t)
		end
		msg(string.format("%s: %s", x, p))
	    end
	    found = true
	end
    end
    if not found then
	msg("not found")
    end
end

-- Sets visibility of labels
--
local gc = GARBAGECOLLECT
function Cols:Update(x)
    local refresh
    local displayed = false
    if x == "left" then
	need_to_fire = true
    elseif x == "joined" then
	need_to_fire = true
    end
    if x ~= 'off' and Group.IsGrouped() then
	refresh = Player.Update(true)
	displayed = not swimlanes.WasActive
    elseif not swimlanes.WasActive then
	refresh = false
    else
	refresh = true	-- just get rid of everything
	if not Group.IsGrouped() then
	    msg("POC: No longer grouped")
	end
	clear(false)
	set_control_active()
	swimlanes.WasActive = false
	Comm.Unload()
    end
    watch("Cols:Update", x, 'refresh', refresh, 'wasactive', swimlanes.WasActive)

    if refresh then
	watch("refresh")
	-- Check all swimlanes
	tick = tick + 1
	for _, v in ipairs(self) do
	    if v:Update(tick) then
		displayed = true
	    end
	end
    end

    if displayed then
	-- displayed should be false if not grouped
	set_control_active()
	if not swimlanes.WasActive then
	    msg("POC: now grouped")
	    Comm.Load()
	    Comm.SendVersion(false)
	end
	swimlanes.WasActive = true
    end
end

-- Return true if we timed out
--
function Player:TimedOut()
    local timedout = (GetTimeStamp() - self.TimeStamp) > TIMEOUT
    if timedout then
	self.HasTimedOut = true
    else
	if self.HasTimedOut then
	    Comm.SendVersion()
	end
	self.HasTimedOut = false
    end
    return timedout
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

function plunk_not_mia(self, apid, tick)
    if self.Ults[apid] == nil then
	return false
    else
	self.Tick = tick
	return true
    end
end

function plunk_mia(self, apid, tick)
    if self.Pos == 0 and self.Tick == tick then
	return false
    else
	self.Tick = tick
	return true
    end
end

local lane_apid
local function sortval_not_mia(key)
    local a
    local player = group_members[key]
    if player:TimedOut() then
	a = -2
    elseif player.IsDead then
	a = -1
    elseif not isMIA then
	a = player.Ults[lane_apid]
    elseif player.UltMain > 0 then
	a = player.Ults[player.UltMain]
    else
	a = 0
    end
    if a == nil then
	a = 0
    end
    return a, player
end

local function sortval_mia(key)
    local player = group_members[key]
    if player.Pos ~= 0 then
	return player.Pos
    end
    return 1000 + tonumber(player.PingTag:match('(%d+)$'))
end

local function compare_mia(key1, key2)
    local a = sortval_mia(key1)
    local b = sortval_mia(key2)
    return a < b
end

local function compare_not_mia(key1, key2)
    local a, player1 = sortval_not_mia(key1)
    local b, player2 = sortval_not_mia(key2)
    if a == b then
	return player1.PingTag < player2.PingTag
    else
	return a > b
   end
end

local function create_cell(pool)
    local control = ZO_ObjectPool_CreateControl('POC_Cell', pool, widget)
    return {
	Control = control,
	Name = control:GetNamedChild("PlayerName"),
	Backdrop = control:GetNamedChild("Backdrop"),
	UltPct = control:GetNamedChild("UltPct")
    }
end

local function reset_cell(tbl)
     tbl.Control:SetHidden(true)
     tbl.Control:ClearAnchors()
end

-- Update swimlane
--
local keys = {}
function Col:Update(tick)
    local laneid = self.Id
    if laneid > MIAlane then
	return
    end

    local displayed = false
    local lastlane
    if saved.MIA then
	lastlane = MIAlane
    else
	lastlane = MIAlane - 1
    end
    local n = 1
    if laneid <= lastlane then
	local isMIA = laneid == MIAlane
	local apid = self.Apid
	lane_apid = apid

	local plunk = self.Plunk
	local keys = keys
	for name, player in pairs(group_members) do
	    local pingtag = player.PingTag
	    if (not IsUnitGrouped(pingtag)) or GetUnitName(pingtag) ~= name then
		group_members[name] = nil
	    elseif plunk(player, apid, tick) then
		keys[#keys + 1] = name
	    end
	end

	table.sort(keys, self.Compare)

	-- Update sorted swimlane
	local gt100 = 100 + saved.SwimlaneMax
	while true do
	    local playername = table.remove(keys, 1)
	    if playername == nil then
		break
	    end
	    if n > saved.SwimlaneMax then
		-- log here?
		break
	    end
	    local player = group_members[playername]
	    local priult = player.UltMain == apid
	    displayed = true
	    if not player.IsMe or not priult or isMIA then
		self:UpdateCell(n, player, playername, isMIA or priult)
		if not isMIA and player.Ults[apid] and player.Ults[apid] > 100 then
		    gt100 = player.Ults[apid]
		end
	    else
		local noshow = true
		if forcepct ~= nil then
		    player.Ults[apid] = forcepct
		end
		if player.Ults[apid]  < 100 then
		    play_sound = true
		    me.Because = "ultpct < 100"
		elseif priult and not player.IsDead and player:IsInRange() then
		    player.Ults[apid] = gt100 - 1
		    noshow = false
		    me.Because = "ultpct == 100"
		else
		    -- reset order since we can't contribute
		    player.Ults[apid] = 100
		    play_sound = true
		    me.Because = "out of range or dead"
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
    while self[n] do
	cellpool:ReleaseObject(table.remove(self, n))
    end

    self:Hide(displayed)

    return displayed
end

local function colstuff(col, row)
    local sizex = icon_size[1]
    local sizey = icon_size[2]
    if saved.Style == 'Standard' then
	sizex = sizex + 75      -- room for text
    else
	sizex = sizex + 27
    end
    local x = (col - 1) * (sizex + 2)
    local y = row * (sizey + 2)
    return x, y, sizex, sizey
end

local alivealpha = 1.0
local deadalpha = 0.8
local inprogressalpha = 0.8
local normal = {
    [true] = {		-- It's the primary
	[true] = {		-- >= 100
	    center = {0.51, 0.41, 0.65},
	    name = {1, 1, 1, 1},
	    ult = {0.01, 0.69, 0.02, alivealpha}
	},
	[false] = {		-- < 100
	    center = {0.51, 0.41, 0.65},
	    name = {1, 1, 1, 0.8},
	    ult = {0.03, 0.03, 0.7, inprogressalpha},
	},
    },
    [false] = {		-- secondary
	 [true] = {		-- >= 100
	    center = {0.51, 0.63, 0.90},
	    name = {1, 1, 1, 1},
	    ult = {0.18, 0.42, 0.96, alivealpha},
	 },
	 [false] = {	-- < 100
	    center = {0.51, 0.63, 0.90},
	    name = {1, 1, 1, 0.8},
	    ult = {0.18, 0.42, 0.96, alivealpha}
	}
    }
}
local timedout = {
    center = {0.15, 0.15, 0.15},
    name = {1, 1, 1, 1},
    ult = {0.80, 0.80, 0.80, 2}
}
local isdead = {
    center = normal[true][true].center,
    name = {0.8, 0.8, 0.8, 0.8},
    ult = {0.8, 0.03, 0.03, deadalpha}
}

local tmp_colors = {}
local function colors(inrange, tbl)
    local ret = tmp_colors
    for i, x in ipairs(tbl) do
	if inrange then
	    -- ok
	elseif i < 4 then
	    x = x * 0.55
	else
	    x = x * 0.85
	end
	ret[i] = x
    end
    if #ret > #tbl then
	ret[#tbl + 1] = nil
    end
    return unpack(ret)
end

-- Update a cell
--
function Col:UpdateCell(i, player, playername, priult)
    rowtbl, key = cellpool:AcquireObject(self[i])
    local row = rowtbl.Control
    local namecell = rowtbl.Name
    local bgcell = rowtbl.Backdrop
    local ultcell = rowtbl.UltPct
    local x, y, sizex = colstuff(self.Id, i)
    if not self[i] then
	row:SetAnchor(TOPLEFT, widget, TOPLEFT, x, y)
	row:SetWidth(sizex)
	bgcell:SetWidth(sizex)
	ultcell:SetWidth(sizex)
	self[i] = key
    end
    if player.DispName then
	playername = player.DispName
    elseif saved.AtNames and player.AtName then
	playername = string.sub(player.AtName, 2)
    end

    local prefix
    if not player.IsDead and player.InCombat then
	prefix = '|cff0000'
    else
	prefix = ''
    end

    local ultpct
    local apid
    if self.Apid == 'MIA' then
	apid = player.UltMain
    else
	apid = self.Apid
    end

    if sldebug then
	playername = playername .. "   " .. player.Ults[apid] .. "%"
    end

    if player.Ults[apid] == nil then
	ultpct = 0
    elseif player.Ults[apid] > 100 then
	ultpct = 100
    else
	ultpct = player.Ults[apid]
    end

    if not sldebug and not player.DispName then
	local bdlength = sizex - 4
	-- laboriously calculate length
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
	player.DispName = playername
    end
    namecell:SetText(prefix .. playername)

    local values
    if player:TimedOut() then
	values = timedout
	watch("Col:UpdateCell", playername, "timedout")
    elseif player.IsDead then
	values = isdead
	watch("Col:UpdateCell", playername, "isdead")
    else
	values = normal[priult][ultpct >= 100]
	watch("Col:UpdateCell", playername, "normal", ultpct >= 100)
    end

    ultcell:SetValue(ultpct)
    local inrange = player:IsInRange()
    bgcell:SetCenterColor(colors(inrange, values.center))
    namecell:SetColor(colors(inrange, values.name))
    ultcell:SetColor(colors(inrange, values.ult))

    row:SetHidden(false)
end

function Player:Alert(name)
    if not saved.UltAlert then
	return
    end
    local ult = Ult.ByPing(self.UltMain)
    local aid = ult.Aid
    local duration = GetAbilityDuration(aid)
    if duration < 10000 then
	duration = 10000
    end
    local message = string.format("%s's %s", name, ult.Name)
    Alert.Show(message, duration)
end

local newversion_alert = 5
function Player.Version(pingtag, major, minor, force)
    local v = string.format("%d.%03d", major, minor)
    local dv = string.format("%d.%d", major, minor)
    watch("Player.Version", pingtag, v)
    local name = GetUnitName(pingtag)
    if group_members[name] ~= nil then
	group_members[name].Version = dv
    end
    if tonumber(v) > version then
	if newversion_alert > 0 then
	    Info(string.format("new version v%s detected (%s). You have v%s", dv, name, dversion))
	end
	newversion_alert = newversion_alert - 1
    elseif force then
	Info(string.format("version v%s detected (%s). You have v%s", dv, GetUnitName(pingtag), dversion))
    end
end

local tmp_player = {}
function Player.New(pingtag, timestamp, apid1, pct1, pos, apid2, pct2)
    local name = GetUnitName(pingtag)
    local self = group_members[name]
    watch("Player.New", name, pingtag, timestamp, apid1, pct1, apid2, pct2, pos, self)
    if self == nil then
	if name == myname then
	    self = me
	else
	    self = {
		IsMe = false,
		Pos = 0,
		Tick = 0,
		TimeStamp = 0,
		UltMain = max_ping,
		Ults = {
		    [max_ping] = 0
		},
		Visited = false
	    }
	end
	group_members[name] = setmetatable(self, Player)
    end

    if pct1 == 0 and self.UltMain and self.Ults[self.UltMain] and self.Ults[self.UltMain] > 0 then
	self:Alert(name)
    end

    if timestamp ~= nil then
	if apid1 == 0 then
	    return			-- hopefully an anomaly
	end
	-- Coming from Player.New
	if self.IsMe and pct1 >= 100 and me.Ults ~= nil and me.Ults[apid1] ~= nil and me.Ults[apid1] >= 100 then
	    pct1 = me.Ults[apid1]	-- don't mess with our calculated percent
	end
    elseif not self.Visited then
	timestamp = self.TimeStamp	-- coming from Player.Update - haven't seen before
    else
	self.Visited = false
	return self
    end

    local player = tmp_player
    player.InCombat = IsUnitInCombat(pingtag)
    player.InRange = IsUnitInGroupSupportRange(pingtag)
    player.IsLeader = IsUnitGroupLeader(pingtag)
    player.IsDead = IsUnitDead(pingtag)
    player.Online = IsUnitOnline(pingtag)
    player.PingTag = pingtag
    player.UltMain = apid1
    player.Pos = pos
    -- Consider changed if we have a timestamp and timeout is detected
    local changed = timestamp and self.TimeStamp and self:TimedOut()
    if timestamp ~= self.TimeStamp then
	self.TimeStamp = timestamp
    end
    if saved.AtNames and self.AtName == nil then
	player.AtName = GetUnitDisplayName(pingtag)
	player.DispName = nil
    end

    if apid1 ~= nil then
	-- Called from map ping
	-- If either is nil then player changed their ultimate
	if self.Ults[apid1] == nil or apid2 ~= nil and self.Ults[apid2] == nil then
	    for n in pairs(self.Ults) do
		self.Ults[n] = nil
	    end
	end
	if self.Ults[apid1] ~= pct1 then
	    self.Ults[apid1] = pct1		-- Primary ult pct changed
	    changed = true
	end
	if apid2 ~= nil and apid2 ~= max_ping and self.Ults[apid2] ~= pct2 then
	    self.Ults[apid2] = pct2		-- secondary ult pct changed
	    changed = true
	end
    end

    for n, v in pairs(player) do
	player[n] = nil
	if self[n] ~= v then
	    changed = true
	    self[n] = v
	end
    end

    self.Visited = apid1 ~= nil			-- Saw this this time around

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

    for i = 1, GetGroupSize() do
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

    if me.IsLeader then
	inrange = inrange + 2
    end

    if (inrange / nmembers) >= 0.5 then
	me.InRangeTime = GetTimeStamp()
    elseif me.InRangeTime ~= 0 and not me:HasBeenInRange() then
	me.InRangeTime = 0
	need_to_fire = true
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
function Swimlanes:OnMove(stop)
    if not stop then
	widget:GetNamedChild("MovableControl"):SetHidden(false)
    else
	widget:GetNamedChild("MovableControl"):SetHidden(true)
	saved.WinPos = {
	    X = widget:GetLeft(),
	    Y = widget:GetTop()
	}
    end
end

-- Called when header clicked to change column identifier
--
function Cols:SetLaneUlt(id, apid)
    watch("Cols:SetLaneUlt", id, apid)
    if apid ~= max_ping then
	for i = 1, saved.SwimlaneMaxCols do
	    local v = self[i]
	    if v.Apid == apid then
		watch("Cols:SetLaneUlt", _, v.Apid, '==', apid)
		return			-- already displaying this ultimate
	    end
	end
    end
    saved.LaneIds[id] = apid		-- Remember what's here
    local ult = Ult.ByPing(apid)
    local col = self[id]
    col.Apid = ult.Ping
    col.Icon:SetTexture(ult.Icon)
    if saved.Style == 'Standard' then
	col.Label:SetText(ult.Name)
    else
	col.Label:SetText('')
    end
end

-- Col:Click called on header clicked
--
function Col:Click()
    if self.Button ~= nil then
	CALLBACK_MANAGER:FireCallbacks(SHOW_ULTIMATE_GROUP_MENU, self.Button, self.Id, self.Apid)
    else
	Error("Col:Click, button nil")
    end
end

-- Create icon/label at top of column
--
function Col.New(col, i)
    local self = col or setmetatable({Id = i}, Col)
    local apid
    if i == MIAlane then
	apid = max_ping
    else
	apid = saved.LaneIds[i]
    end
    local ult = Ult.ByPing(apid)
    apid = ult.Ping
    self.Apid = apid

    local control = self.Control
    if not control then
	control = CreateControlFromVirtual('POCheader' .. i, widget, 'POC_Header')
	self.Control = control
	self.Button = control:GetNamedChild("Button")
	self.Icon = control:GetNamedChild("Icon")
	self.Label = control:GetNamedChild("Label")
    end
    local x, y, sizex, sizey = colstuff(i, 0)
    -- control:SetWidth(sizex)
    control:SetAnchor(TOPLEFT, widget, TOPLEFT, x, y)

    if i == MIAlane then
	self.Compare = compare_mia
	self.Plunk = plunk_mia
	self.Button:SetHandler("OnClicked", nil)
    else
	self.Compare = compare_not_mia
	self.Plunk = plunk_not_mia
	self.Button:SetHandler("OnClicked", function() self:Click() end)
    end

    self.Icon:SetTexture(ult.Icon)
    if saved.Style == 'Standard' then
	self.Label:SetText(ult.Name)
    else
	self.Label:SetText('')
    end

    self:Hide(true)

    -- Start fresh with any existing cells
    while self[1] do
	cellpool:ReleaseObject(table.remove(self, 1))
    end

    return self
end

function Col:Hide(displayed)
    local hide = self.Id > MIAlane or (self.Id == MIAlane and not displayed)
    self.Button:SetHidden(hide)
    self.Icon:SetHidden(hide)
    if self.Label then
	self.Label:SetHidden(hide)
    end
end

function Cols:Redo()
    self:New()
    for _, v in pairs(group_members) do
	v.DispName = nil
    end
    need_to_fire = true
    swimlanes.Sched(true)
end

function Cols:New()
    if self == nil then
	self = setmetatable({}, Cols)
    end
    local oldMIAlane = MIAlane or saved.SwimlaneMaxCols + 1
    MIAlane = saved.SwimlaneMaxCols + 1
    for i = 1, MIAlane do
	self[i] = Col.New(self[i], i)
    end
    for i = MIAlane + 1, oldMIAlane do
	self[i].Control:SetHidden(true)
    end
    return self
end

function swimlanes:SaveUltNumberPos()
    saved.UltNumberPos = {self:GetLeft(),self:GetTop()}
end

function swimlanes.Sched(clear_dispname)
    need_to_fire = true
    if clear_dispname then
	for _, v in pairs(group_members) do
	    v.DispName = nil
	end
    end
    set_control_active()
end

function UltNumber.Hide(x)
    if saved.UltNumberShow then
	if not x and me.IsDead or me.UltMain == 0 or me.Ults[me.UltMain] == nil or me.Ults[me.UltMain] < 100 then
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
    UltNumberLabel:SetText(string.format("|c%s#%s|r", color, tostring(n)))
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
    me.Because = "false because we played the sound"
end

-- Initialize Swimlanes
--
Swimlanes.Update = function(x) Cols:Update(x) end
Swimlanes.SetLaneUlt = function(apid, icon) Cols:SetLaneUlt(apid, icon) end
Swimlanes.Redo = function() Cols:Redo() end
function Swimlanes.Initialize(major, minor)
    widget = POC_Main
    saved = Settings.SavedVariables
    group_members = saved.GroupMembers
    myults = saved.MyUltId[ultix]
    if myults[1] == nil then
	myults[1] = max_ping
    end
    max_ping = Ult.MaxPing
    for n, v in pairs(group_members) do
	setmetatable(v, Player)
	if n == myname then
	    v =  ZO_DeepTableCopy(v, me)
	end
	if not v.UltMain or v.UltMain == 0 then
	    v.UltMain = max_ping
	end
	if not v.Ults[v.UltMain] then
	    v.UltMain = 0
	end
	if v.Pos == nil then
	    v.Pos = 0
	end
	v.DispName = nil
	group_members[n] = v
    end
    me.UltMain = myults[1]
    me.Ults[myults[1]] = 0

    cellpool = ZO_ObjectPool:New(create_cell, reset_cell)

    Cols:New()

    UltNumber:ClearAnchors()
    if saved.UltNumberPos == nil then
	UltNumber:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
    else
	UltNumber:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT,
				saved.UltNumberPos[1],
				saved.UltNumberPos[2])
    end
    UltNumber:SetMovable(true)
    UltNumber:SetMouseEnabled(true)
    UltNumber.Hide(true)

    version = tonumber(string.format("%d.%03d", major, minor))
    dversion = string.format("%d.%d", major, minor)

    Slash("clear", "clear POC memory, run game garbage collection", function()
	clear(true)
    end)
    Slash("pct", "debugging: set fake ultimate percentage", function(pct)
	if string.len(pct) == 0 then
	    forcepct = nil
	else
	    forcepct = tonumber(pct)
	    need_to_fire = true
	end
    end)
    Slash("sldebug", "debugging: display percentages next to names", function(pct)
	sldebug = not sldebug
	msg(sldebug)
    end)
    Slash("refresh", "debugging: force periodic update of display", function(pct)
	ping_refresh = not ping_refresh
	if ping_refresh then
	    msg("refresh on")
	else
	    msg("refresh off")
	end
    end)
    Slash("fire", "debugging: test ultimate display", function()
	for i = 1, 24 do
	    me:Alert(myname)
	end
    end)
    Slash("movable", "specify true/false to make ultimate display movable", function(x)
	local movable
	if x == "yes" or x == "true" or x == "on" then
	    movable = true
	elseif x == "no" or x == "false" or x == "off" then
	    movable = false
	elseif x ~= "" then
	    Error("Huh?")
	    return
	end
	if movable ~= nil then
	    saved.AllowMove = movable
	    set_control_movable()
	end
	Info("movable state is:", movable)
    end)
    Slash("sendver", "debugging: send POC add-on version to others in your group", function(x)
	Comm.SendVersion(true)
    end)
    Slash("dump", "debugging: show collected information for specified player", function(x) dumpme = x end)
end
